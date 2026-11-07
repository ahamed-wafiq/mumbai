class_name CarController
extends CharacterBody3D

## Mumbai Drive - Robust Arcade Vehicle Controller
## High-reliability CharacterBody3D arcade physics.
## Smooth acceleration, progressive braking, reverse, handbrake,
## speed-sensitive steering, anti-drift lateral grip, and gear calculation.

signal speed_updated(speed_kmh: float, gear: String)
signal debug_telemetry_updated(data: Dictionary)
signal vehicle_switched(car_data: Dictionary)

@export_group("Engine & Speed")
@export var max_speed_kmh: float = 160.0         # Top forward speed in km/h
@export var max_reverse_speed_kmh: float = 40.0  # Top reverse speed in km/h
@export var acceleration: float = 22.0           # Forward acceleration rate (m/s^2)
@export var reverse_acceleration: float = 12.0   # Reverse acceleration rate (m/s^2)
@export var braking_power: float = 35.0          # Normal brake force (m/s^2)
@export var handbrake_power: float = 55.0        # Handbrake stopping force (m/s^2)
@export var coasting_friction: float = 6.0       # Natural drag when off throttle (m/s^2)

@export_group("Handling & Grip")
@export var max_steer_angle_deg: float = 32.0    # Visual wheel steer angle (degrees)
@export var steer_speed: float = 2.6             # Turn rate in radians/sec
@export var high_speed_steer_factor: float = 0.45# Steering sensitivity dampener at top speed
@export var stationary_steer_rate: float = 0.75  # Turning rate while stationary (rad/s)
@export var lateral_grip: float = 25.0           # Anti-drift lateral friction
@export var gravity: float = 20.0                # Gravity downward acceleration

@export_group("Visuals & Cameras")
@export var wheel_fl_node: NodePath = "Visuals/Wheels/WheelFL"
@export var wheel_fr_node: NodePath = "Visuals/Wheels/WheelFR"
@export var wheel_rl_node: NodePath = "Visuals/Wheels/WheelRL"
@export var wheel_rr_node: NodePath = "Visuals/Wheels/WheelRR"
@export var car_mesh_node: NodePath = "Visuals/Body/LamborghiniMesh"
@export var brake_light_node: NodePath = "Visuals/BrakeLights"
@export var third_person_cam_node: NodePath = "Cameras/ThirdPersonCamera"
@export var first_person_cam_node: NodePath = "Cameras/FirstPersonCamera"

# Persisted Vehicle Physics State
var forward_speed: float = 0.0     # Forward/reverse velocity in m/s (positive = forward)
var lateral_speed: float = 0.0     # Sideways velocity in m/s
var visual_steer: float = 0.0      # Current visual steer angle
var wheel_roll_angle: float = 0.0  # Wheel roll spin angle
var current_gear: String = "N"     # Display gear: R, N, 1, 2, 3
var initial_transform: Transform3D # Saved spawn transform
var is_first_person: bool = false

# Node references
var _wheel_fl: Node3D
var _wheel_fr: Node3D
var _wheel_rl: Node3D
var _wheel_rr: Node3D
var _brake_lights: Node3D
var _cam_third: Camera3D
var _cam_first: Camera3D
var _car_mesh_instance: MeshInstance3D

# Telemetry for debugging
var debug_data: Dictionary = {}

func _ready() -> void:
	initial_transform = global_transform
	
	# Configure CharacterBody3D ground snapping for smooth vehicle driving
	floor_snap_length = 0.5
	floor_constant_speed = true
	floor_stop_on_slope = false
	floor_max_angle = deg_to_rad(45.0)
	up_direction = Vector3.UP
	
	_wheel_fl = get_node_or_null(wheel_fl_node)
	_wheel_fr = get_node_or_null(wheel_fr_node)
	_wheel_rl = get_node_or_null(wheel_rl_node)
	_wheel_rr = get_node_or_null(wheel_rr_node)
	_brake_lights = get_node_or_null(brake_light_node)
	_cam_third = get_node_or_null(third_person_cam_node)
	_cam_first = get_node_or_null(first_person_cam_node)
	_car_mesh_instance = get_node_or_null(car_mesh_node)
	
	apply_car_config(GarageManager.get_selected_car())
	_set_camera_mode(false)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_camera") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_C):
		toggle_camera()
	elif event.is_action_pressed("reset_vehicle") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R):
		reset_vehicle()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_T:
		switch_to_next_car()

func _physics_process(delta: float) -> void:
	# 1. Read Inputs (Checking both InputMap actions and physical key fallbacks)
	var accel_input := _read_input("accelerate", KEY_W, KEY_UP)
	var brake_input := _read_input("brake_reverse", KEY_S, KEY_DOWN)
	var steer_left := _read_input("steer_left", KEY_A, KEY_LEFT)
	var steer_right := _read_input("steer_right", KEY_D, KEY_RIGHT)
	var handbrake_input := _read_input("handbrake", KEY_SPACE)
	
	var steer_axis := steer_left - steer_right # Positive = Left
	var is_braking := false
	
	var max_fwd_ms := max_speed_kmh / 3.6
	var max_rev_ms := max_reverse_speed_kmh / 3.6
	
	# 2. Acceleration, Braking & Reverse State Machine
	if handbrake_input > 0.1:
		# Handbrake: rapid deceleration to 0
		forward_speed = move_toward(forward_speed, 0.0, handbrake_power * delta)
		is_braking = true
	elif accel_input > 0.05:
		if forward_speed < -0.5:
			# Moving backward: pressing W acts as front brake first
			forward_speed = move_toward(forward_speed, 0.0, braking_power * accel_input * delta)
			is_braking = true
		else:
			# Accelerate forward
			forward_speed = move_toward(forward_speed, max_fwd_ms, acceleration * accel_input * delta)
	elif brake_input > 0.05:
		if forward_speed > 0.5:
			# Moving forward: pressing S acts as rear brake
			forward_speed = move_toward(forward_speed, 0.0, braking_power * brake_input * delta)
			is_braking = true
		else:
			# Stopped or rolling back: engage reverse gear
			forward_speed = move_toward(forward_speed, -max_rev_ms, reverse_acceleration * brake_input * delta)
	else:
		# Off-throttle: rolling natural coasting friction
		forward_speed = move_toward(forward_speed, 0.0, coasting_friction * delta)
	
	# 3. Dynamic Steering Physics
	if absf(steer_axis) > 0.02:
		var speed_ratio := clampf(absf(forward_speed) / max_fwd_ms, 0.0, 1.0)
		var speed_factor := lerpf(1.0, high_speed_steer_factor, speed_ratio)
		
		var effective_turn_rate := 0.0
		if absf(forward_speed) < 0.5:
			# Stationary / Low-speed steering: allow orienting the vehicle while standing still
			effective_turn_rate = steer_axis * stationary_steer_rate
		else:
			# In motion: turn direction matches gear (forward vs reverse)
			var dir_sign: float = 1.0 if forward_speed >= 0.0 else -1.0
			effective_turn_rate = steer_axis * steer_speed * speed_factor * dir_sign
			
		rotate_y(effective_turn_rate * delta)
	
	# 4. Anti-Drift Lateral Damping
	lateral_speed = move_toward(lateral_speed, 0.0, lateral_grip * delta)
	
	# 5. Calculate Real-World Velocities & Ground Snapping
	var forward_basis := -global_transform.basis.z.normalized()
	var right_basis := global_transform.basis.x.normalized()
	
	var horizontal_motion := (forward_basis * forward_speed) + (right_basis * lateral_speed)
	
	# Apply gravity & floor adherence
	var y_vel := velocity.y
	if not is_on_floor():
		y_vel -= gravity * delta
	else:
		y_vel = -2.0 # Ground sticking force to prevent bouncing
		
	velocity = Vector3(horizontal_motion.x, y_vel, horizontal_motion.z)
	
	# 6. Execute CharacterBody3D Physics Move
	move_and_slide()
	
	# 7. Wall Collision Handling
	# If the front or rear collides with a wall/building, stop forward momentum
	if is_on_wall():
		var wall_norm := get_wall_normal()
		if forward_basis.dot(wall_norm) < -0.3 and forward_speed > 0.0:
			forward_speed = 0.0
		elif forward_basis.dot(wall_norm) > 0.3 and forward_speed < 0.0:
			forward_speed = 0.0
	
	# 8. Compute Real Display Speed & Gears (N, 1, 2, 3, R)
	# Calculate actual speed from horizontal displacement
	var actual_speed_kmh := Vector2(velocity.x, velocity.z).length() * 3.6
	
	if handbrake_input > 0.1 and absf(forward_speed) < 0.5:
		current_gear = "P"
	elif forward_speed < -0.3:
		current_gear = "R"
	elif absf(forward_speed) < 0.3:
		current_gear = "N"
	else:
		if actual_speed_kmh < 55.0:
			current_gear = "1"
		elif actual_speed_kmh < 95.0:
			current_gear = "2"
		elif actual_speed_kmh < 145.0:
			current_gear = "3"
		elif actual_speed_kmh < 195.0:
			current_gear = "4"
		elif actual_speed_kmh < 245.0:
			current_gear = "5"
		elif actual_speed_kmh < 290.0:
			current_gear = "6"
		else:
			current_gear = "7"
			
	speed_updated.emit(actual_speed_kmh, current_gear)
	
	# 9. Visual Animations
	_update_visuals(steer_axis, forward_speed, is_braking, delta)
	
	# 10. Update Debug Telemetry
	debug_data = {
		"w_pressed": accel_input > 0.05,
		"s_pressed": brake_input > 0.05,
		"a_pressed": steer_left > 0.05,
		"d_pressed": steer_right > 0.05,
		"handbrake": handbrake_input > 0.05,
		"forward_speed_ms": roundf(forward_speed * 10.0) / 10.0,
		"speed_kmh": roundf(actual_speed_kmh * 10.0) / 10.0,
		"gear": current_gear,
		"grounded": is_on_floor(),
		"position": global_position,
		"velocity": velocity
	}
	debug_telemetry_updated.emit(debug_data)

## Updates steering wheel pivots, tire spin, and brake light emission
func _update_visuals(steer_axis: float, speed_ms: float, is_braking: bool, delta: float) -> void:
	var target_angle := steer_axis * deg_to_rad(max_steer_angle_deg)
	visual_steer = lerpf(visual_steer, target_angle, 14.0 * delta)
	
	if _wheel_fl:
		_wheel_fl.rotation.y = visual_steer
	if _wheel_fr:
		_wheel_fr.rotation.y = visual_steer
		
	var wheel_radius := 0.36
	var roll_delta := (speed_ms / wheel_radius) * delta
	wheel_roll_angle -= roll_delta
	
	if _wheel_fl and _wheel_fl.get_child_count() > 0:
		_wheel_fl.get_child(0).rotation.x = wheel_roll_angle
	if _wheel_fr and _wheel_fr.get_child_count() > 0:
		_wheel_fr.get_child(0).rotation.x = wheel_roll_angle
	if _wheel_rl and _wheel_rl.get_child_count() > 0:
		_wheel_rl.get_child(0).rotation.x = wheel_roll_angle
	if _wheel_rr and _wheel_rr.get_child_count() > 0:
		_wheel_rr.get_child(0).rotation.x = wheel_roll_angle
		
	if _brake_lights:
		_brake_lights.visible = is_braking or (current_gear == "R")

## Toggles between Third-person chase camera and First-person cockpit camera
func toggle_camera() -> void:
	_set_camera_mode(not is_first_person)

func _set_camera_mode(first_person: bool) -> void:
	is_first_person = first_person
	if _cam_first and _cam_third:
		_cam_first.current = is_first_person
		_cam_third.current = not is_first_person

## Resets the car position upright onto the road
func reset_vehicle() -> void:
	velocity = Vector3.ZERO
	forward_speed = 0.0
	lateral_speed = 0.0
	global_transform = initial_transform
	global_position.y += 0.5
	rotation.x = 0.0
	rotation.z = 0.0
	current_gear = "N"

## Helper reading InputMap actions with physical keyboard fallback
func _read_input(action_name: String, key_primary: Key, key_secondary: Key = KEY_NONE) -> float:
	if InputMap.has_action(action_name) and Input.is_action_pressed(action_name):
		return Input.get_action_strength(action_name)
	if Input.is_key_pressed(key_primary):
		return 1.0
	if key_secondary != KEY_NONE and Input.is_key_pressed(key_secondary):
		return 1.0
	return 0.0

## Dynamically applies vehicle model mesh, orientation, and physics tuning
func apply_car_config(car_data: Dictionary) -> void:
	if _car_mesh_instance and car_data.has("mesh_path"):
		var mesh_path: String = car_data["mesh_path"]
		if ResourceLoader.exists(mesh_path):
			var mesh_res = load(mesh_path)
			if mesh_res is Mesh:
				_car_mesh_instance.mesh = mesh_res
				_car_mesh_instance.rotation.y = car_data.get("rot_y", 0.0)
	
	max_speed_kmh = car_data.get("top_speed", 340.0)
	acceleration = car_data.get("acceleration", 36.0)
	braking_power = car_data.get("braking", 48.0)
	lateral_grip = car_data.get("grip", 35.0)
	vehicle_switched.emit(car_data)

## Cycles to the next available supercar in real-time
func switch_to_next_car() -> void:
	var next_data := GarageManager.next_car()
	apply_car_config(next_data)
