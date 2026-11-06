class_name SettingsDialog
extends Control

## Settings Dialog for Mumbai Drive
## Allows adjusting volume, graphic presets, and inspecting controls.

signal closed

@export var volume_slider_path: NodePath = "CenterContainer/Card/VBox/VolumeRow/VolumeSlider"
@export var quality_option_path: NodePath = "CenterContainer/Card/VBox/QualityRow/QualityOption"
@export var close_btn_path: NodePath = "CenterContainer/Card/VBox/CloseBtn"

var _volume_slider: HSlider
var _quality_option: OptionButton
var _close_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	_volume_slider = get_node_or_null(volume_slider_path)
	_quality_option = get_node_or_null(quality_option_path)
	_close_btn = get_node_or_null(close_btn_path)
	
	if _volume_slider:
		_volume_slider.value_changed.connect(_on_volume_changed)
		
	if _quality_option:
		_quality_option.clear()
		_quality_option.add_item("Balanced (Default)")
		_quality_option.add_item("Low (Web / Older Laptops)")
		_quality_option.add_item("High")
		_quality_option.item_selected.connect(_on_quality_selected)
		
	if _close_btn:
		_close_btn.pressed.connect(_on_close_pressed)

func _on_volume_changed(val: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx >= 0:
		if val <= 0.01:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var db := linear_to_db(val)
			AudioServer.set_bus_volume_db(bus_idx, db)

func _on_quality_selected(index: int) -> void:
	var viewport := get_viewport()
	if not viewport:
		return
	match index:
		0: # Balanced
			viewport.msaa_3d = Viewport.MSAA_2X
		1: # Low
			viewport.msaa_3d = Viewport.MSAA_DISABLED
		2: # High
			viewport.msaa_3d = Viewport.MSAA_4X

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

