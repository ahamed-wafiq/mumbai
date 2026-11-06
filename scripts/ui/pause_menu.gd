class_name PauseMenu
extends Control

## Pause Menu for Mumbai Drive
## Runs with process_mode = Node.PROCESS_MODE_ALWAYS to process input during pause.

signal resume_requested
signal restart_requested
signal settings_requested

@export var resume_btn_path: NodePath = "CenterContainer/Card/VBox/ResumeBtn"
@export var restart_btn_path: NodePath = "CenterContainer/Card/VBox/RestartBtn"
@export var settings_btn_path: NodePath = "CenterContainer/Card/VBox/SettingsBtn"
@export var menu_btn_path: NodePath = "CenterContainer/Card/VBox/MainMenuBtn"

var _resume_btn: Button
var _restart_btn: Button
var _settings_btn: Button
var _menu_btn: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	_resume_btn = get_node_or_null(resume_btn_path)
	_restart_btn = get_node_or_null(restart_btn_path)
	_settings_btn = get_node_or_null(settings_btn_path)
	_menu_btn = get_node_or_null(menu_btn_path)
	
	if _resume_btn:
		_resume_btn.pressed.connect(_on_resume_pressed)
	if _restart_btn:
		_restart_btn.pressed.connect(_on_restart_pressed)
	if _settings_btn:
		_settings_btn.pressed.connect(_on_settings_pressed)
	if _menu_btn:
		_menu_btn.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if visible:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func pause_game() -> void:
	visible = true
	get_tree().paused = true
	if _resume_btn:
		_resume_btn.grab_focus()

func resume_game() -> void:
	visible = false
	get_tree().paused = false
	resume_requested.emit()

func _on_resume_pressed() -> void:
	resume_game()

func _on_restart_pressed() -> void:
	resume_game()
	restart_requested.emit()

func _on_settings_pressed() -> void:
	settings_requested.emit()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")

