class_name InGameHUD
extends Control

## Modern Minimalist HUD for Mumbai Drive
## Displays digital speedometer, gear badge, location badge,
## controls reminder bar, and toggleable debug telemetry panel (F3).

@export var speed_label_path: NodePath = "BottomRight/SpeedCard/VBox/SpeedRow/SpeedValue"
@export var gear_label_path: NodePath = "BottomRight/SpeedCard/VBox/SpeedRow/GearBadge"
@export var speed_bar_path: NodePath = "BottomRight/SpeedCard/VBox/SpeedBar"
@export var location_label_path: NodePath = "TopLeft/LocationCard/HBox/VBox/LocationName"
@export var coords_label_path: NodePath = "TopLeft/LocationCard/HBox/VBox/Coords"
@export var debug_panel_path: NodePath = "TopRight/DebugCard"
@export var debug_label_path: NodePath = "TopRight/DebugCard/DebugText"

var _speed_label: Label
var _gear_label: Label
var _speed_bar: ProgressBar
var _location_label: Label
var _coords_label: Label
var _debug_panel: PanelContainer
var _debug_label: RichTextLabel

func _ready() -> void:
	_speed_label = get_node_or_null(speed_label_path)
	_gear_label = get_node_or_null(gear_label_path)
	_speed_bar = get_node_or_null(speed_bar_path)
	_location_label = get_node_or_null(location_label_path)
	_coords_label = get_node_or_null(coords_label_path)
	_debug_panel = get_node_or_null(debug_panel_path)
	_debug_label = get_node_or_null(debug_label_path)
	
	update_speed(0.0, "N")

func _unhandled_input(event: InputEvent) -> void:
	# Press F3 to toggle debug telemetry panel
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		if _debug_panel:
			_debug_panel.visible = not _debug_panel.visible

## Connects to CarController.speed_updated
func update_speed(speed_kmh: float, gear: String) -> void:
	var rounded_speed := int(roundf(speed_kmh))
	
	if _speed_label:
		_speed_label.text = str(rounded_speed)
		
	if _gear_label:
		_gear_label.text = gear
		match gear:
			"1", "2", "3", "D":
				_gear_label.modulate = Color(1.0, 0.45, 0.0) # Orange
			"R":
				_gear_label.modulate = Color(1.0, 0.25, 0.25) # Red
			"P":
				_gear_label.modulate = Color(0.7, 0.75, 0.8)  # Silver/Gray
			"N":
				_gear_label.modulate = Color(1.0, 0.85, 0.2)  # Yellow
				
	if _speed_bar:
		_speed_bar.value = clampf(speed_kmh, 0.0, 160.0)

## Updates coordinates and location information
func update_location(zone_name: String, lat: float, lon: float) -> void:
	if _location_label:
		_location_label.text = zone_name
	if _coords_label:
		_coords_label.text = "%.4f° N, %.4f° E" % [lat, lon]

## Updates real-time vehicle debug telemetry
func update_debug_telemetry(data: Dictionary) -> void:
	if not _debug_label or not _debug_panel or not _debug_panel.visible:
		return
		
	var w_str: String = "[color=#48BB78]ACTIVE[/color]" if data.get("w_pressed", false) else "[color=#718096]OFF[/color]"
	var s_str: String = "[color=#F56565]BRAKE[/color]" if data.get("s_pressed", false) else "[color=#718096]OFF[/color]"
	var a_str: String = "L" if data.get("a_pressed", false) else "-"
	var d_str: String = "R" if data.get("d_pressed", false) else "-"
	var hb_str: String = "[color=#E53E3E]ON[/color]" if data.get("handbrake", false) else "OFF"
	var ground_str: String = "[color=#48BB78]YES[/color]" if data.get("grounded", false) else "[color=#E53E3E]IN AIR[/color]"
	
	var pos: Vector3 = data.get("position", Vector3.ZERO)
	var vel: Vector3 = data.get("velocity", Vector3.ZERO)
	var spd: float = data.get("speed_kmh", 0.0)
	var fwd_ms: float = data.get("forward_speed_ms", 0.0)
	
	var b_read: int = data.get("bld_read", 0)
	var b_valid: int = data.get("bld_valid", 0)
	var b_mesh: int = data.get("bld_meshes", 0)
	var b_vis: int = data.get("bld_visible", 0)
	var t_act: int = data.get("tiles_active", 0)
	var b_bright: bool = data.get("bld_bright", false)
	var bright_str: String = "[color=#48BB78]ON (Vibrant)[/color]" if b_bright else "[color=#A0AEC0]OFF (Realistic)[/color]"
	
	var text := """[b]MUMBAI DRIVE TELEMETRY (F3)[/b]
• Throttle (W): %s  |  Brake (S): %s
• Steer: [%s %s]  |  Handbrake: %s  |  Floor: %s
• Speed: [b][color=#FF6B00]%.1f KM/H[/color][/b] (%.1f m/s)
• Position: (%.1f, %.1f, %.1f)
[b]3D BUILDINGS & WORLD STREAMING[/b]
• 3D Meshes Created: [color=#48BB78]%d[/color] (from %d valid polys / %d read)
• Active Streamed Tiles: [color=#48BB78]%d[/color] | Visible Blds: %d
• Bright Debug Material (F4): %s""" % [
		w_str, s_str, a_str, d_str, hb_str, ground_str,
		spd, fwd_ms, pos.x, pos.y, pos.z,
		b_mesh, b_valid, b_read, t_act, b_vis, bright_str
	]
	
	_debug_label.text = text
