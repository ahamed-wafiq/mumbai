class_name MainMenu
extends Control

## Main Menu Controller for Mumbai Drive
## Handles navigation to the driving prototype, vehicle selection garage, settings popup, and platform exit.

@export var play_btn_path: NodePath = "Layout/Center/Card/VBox/PlayBtn"
@export var settings_btn_path: NodePath = "Layout/Center/Card/VBox/SettingsBtn"
@export var exit_btn_path: NodePath = "Layout/Center/Card/VBox/ExitBtn"
@export var settings_dialog_path: NodePath = "SettingsDialog"

@export var car_name_label_path: NodePath = "Layout/Center/Card/VBox/GarageContainer/SelectorHBox/CarNameLabel"
@export var car_stats_label_path: NodePath = "Layout/Center/Card/VBox/GarageContainer/CarStatsLabel"
@export var prev_car_btn_path: NodePath = "Layout/Center/Card/VBox/GarageContainer/SelectorHBox/PrevCarBtn"
@export var next_car_btn_path: NodePath = "Layout/Center/Card/VBox/GarageContainer/SelectorHBox/NextCarBtn"

var _play_btn: Button
var _settings_btn: Button
var _exit_btn: Button
var _settings_dialog: SettingsDialog

var _car_name_label: Label
var _car_stats_label: Label
var _prev_car_btn: Button
var _next_car_btn: Button

func _ready() -> void:
	_play_btn = get_node_or_null(play_btn_path)
	_settings_btn = get_node_or_null(settings_btn_path)
	_exit_btn = get_node_or_null(exit_btn_path)
	_settings_dialog = get_node_or_null(settings_dialog_path)
	
	_car_name_label = get_node_or_null(car_name_label_path)
	_car_stats_label = get_node_or_null(car_stats_label_path)
	_prev_car_btn = get_node_or_null(prev_car_btn_path)
	_next_car_btn = get_node_or_null(next_car_btn_path)
	
	if _play_btn:
		_play_btn.pressed.connect(_on_play_pressed)
		_play_btn.grab_focus()
		
	if _settings_btn:
		_settings_btn.pressed.connect(_on_settings_pressed)
		
	if _exit_btn:
		if OS.has_feature("web"):
			_exit_btn.visible = false
		else:
			_exit_btn.pressed.connect(_on_exit_pressed)
			
	if _prev_car_btn:
		_prev_car_btn.pressed.connect(_on_prev_car_pressed)
	if _next_car_btn:
		_next_car_btn.pressed.connect(_on_next_car_pressed)
		
	_update_car_display()

func _update_car_display() -> void:
	var car_data := GarageManager.get_selected_car()
	if _car_name_label:
		_car_name_label.text = car_data.get("name", "Supercar")
		_car_name_label.modulate = car_data.get("badge_color", Color.WHITE)
	if _car_stats_label:
		_car_stats_label.text = "%s • Top Speed: %.0f KM/H" % [car_data.get("tagline", ""), car_data.get("top_speed", 320.0)]

func _on_prev_car_pressed() -> void:
	GarageManager.prev_car()
	_update_car_display()

func _on_next_car_pressed() -> void:
	GarageManager.next_car()
	_update_car_display()

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/prototype_city.tscn")

func _on_settings_pressed() -> void:
	if _settings_dialog:
		_settings_dialog.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()
