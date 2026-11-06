class_name VehicleCamera
extends Camera3D

## Smooth Chase Camera for Mumbai Drive
## Follows the vehicle with smooth position and rotation damping,
## dynamic FOV based on speed, and pitch control.

@export var target_node: NodePath
@export var follow_distance: float = 5.5
@export var follow_height: float = 2.4
@export var position_damping: float = 8.0
@export var rotation_damping: float = 6.0
@export var base_fov: float = 70.0
@export var max_fov: float = 80.0

var _target: Node3D

func _ready() -> void:
	if not target_node.is_empty():
		_target = get_node_or_null(target_node)
	elif get_parent() is Node3D:
		_target = get_parent()
		
	if is_instance_valid(_target):
		var target_forward: Vector3 = -_target.global_transform.basis.z.normalized()
		global_position = _target.global_position - (target_forward * follow_distance) + Vector3.UP * follow_height
		look_at(_target.global_position + Vector3.UP * 1.2, Vector3.UP)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(_target) or not current:
		return
	
	# Compute ideal camera position behind the car
	var target_forward: Vector3 = -_target.global_transform.basis.z.normalized()
	var ideal_pos: Vector3 = _target.global_position - (target_forward * follow_distance) + Vector3.UP * follow_height
	
	# Smoothly interpolate position
	global_position = global_position.lerp(ideal_pos, position_damping * delta)
	
	# Look slightly above car center
	var look_target: Vector3 = _target.global_position + Vector3.UP * 1.2
	var desired_look_dir := (look_target - global_position).normalized()
	
	if desired_look_dir.length_squared() > 0.001:
		look_at(look_target, Vector3.UP)
	
	# Dynamic FOV based on vehicle speed
	if _target is CharacterBody3D:
		var speed_ratio: float = clampf(_target.velocity.length() / 40.0, 0.0, 1.0)
		fov = lerpf(base_fov, max_fov, speed_ratio)

