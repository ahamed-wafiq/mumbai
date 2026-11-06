class_name MainMenu
extends Control

## Main Menu Controller for Mumbai Drive
## Handles navigation to the driving prototype, settings popup, and platform exit.

@export var play_btn_path: NodePath = "Layout/Center/Card/VBox/PlayBtn"
@export var settings_btn_path: NodePath = "Layout/Center/Card/VBox/SettingsBtn"
@export var exit_btn_path: NodePath = "Layout/Center/Card/VBox/ExitBtn"
@export var settings_dialog_path: NodePath = "SettingsDialog"

var _play_btn: Button
var _settings_btn: Button
var _exit_btn: Button
var _settings_dialog: SettingsDialog

func _ready() -> void:
	_play_btn = get_node_or_null(play_btn_path)
	_settings_btn = get_node_or_null(settings_btn_path)
	_exit_btn = get_node_or_null(exit_btn_path)
	_settings_dialog = get_node_or_null(settings_dialog_path)
	
	if _play_btn:
		_play_btn.pressed.connect(_on_play_pressed)
		_play_btn.grab_focus()
		
	if _settings_btn:
		_settings_btn.pressed.connect(_on_settings_pressed)
		
	if _exit_btn:
		# In Web builds, browser security prevents exiting the process, so hide exit button
		if OS.has_feature("web"):
			_exit_btn.visible = false
		else:
			_exit_btn.pressed.connect(_on_exit_pressed)

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/world/prototype_city.tscn")

func _on_settings_pressed() -> void:
	if _settings_dialog:
		_settings_dialog.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

