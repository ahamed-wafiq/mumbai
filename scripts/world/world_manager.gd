class_name WorldManager
extends Node3D

## World Manager for Mumbai Drive
## Coordinates the real geographical simulation: GPS tracking (UTM Zone 43N),
## HUD readouts, pause menu, and restart handling.

@export var car_node_path: NodePath = "Car"
@export var hud_node_path: NodePath = "HUD"
@export var pause_menu_node_path: NodePath = "PauseMenu"
@export var settings_dialog_node_path: NodePath = "SettingsDialog"
@export var tile_manager_path: NodePath = "MapTileManager"
@export var building_generator_path: NodePath = "BuildingGenerator"

var _car: CarController
var _hud: InGameHUD
var _pause_menu: PauseMenu
var _settings_dialog: SettingsDialog
var _tile_manager: MapTileManager
var _bld_gen: BuildingGenerator
var _geo: GeoConverter

func _ready() -> void:
	_car = get_node_or_null(car_node_path)
	_hud = get_node_or_null(hud_node_path)
	_pause_menu = get_node_or_null(pause_menu_node_path)
	_settings_dialog = get_node_or_null(settings_dialog_node_path)
	_tile_manager = get_node_or_null(tile_manager_path)
	_bld_gen = get_node_or_null(building_generator_path)
	_geo = GeoConverter.new(18.9437, 72.8232)
	
	if _car and _hud:
		_car.speed_updated.connect(_hud.update_speed)
		_car.debug_telemetry_updated.connect(_on_debug_telemetry_updated)
		_car.vehicle_switched.connect(_hud.show_vehicle_toast)
		
	if _pause_menu:
		_pause_menu.restart_requested.connect(_on_restart_requested)
		_pause_menu.settings_requested.connect(_on_settings_requested)
		
	if _settings_dialog:
		_settings_dialog.closed.connect(_on_settings_closed)

func _process(_delta: float) -> void:
	if not is_instance_valid(_car) or not is_instance_valid(_hud):
		return
		
	# Convert local 3D world meters into real-world Mumbai GPS coordinates using UTM 43N
	var car_pos := _car.global_position
	var geo_coords := _geo.world_to_geo(car_pos)
	var current_lat := geo_coords.x
	var current_lon := geo_coords.y
	
	# Determine neighbourhood based on actual latitude
	var zone_name := "Marine Drive • Netaji Subhash Chandra Bose Rd"
	if current_lat > 19.22:
		zone_name = "Western Suburbs • Borivali / Dahisar"
	elif current_lat > 19.12:
		zone_name = "Western Suburbs • Andheri / Jogeshwari"
	elif current_lat > 19.04:
		zone_name = "Western Suburbs • Bandra / BKC"
	elif current_lat > 19.00:
		zone_name = "South Mumbai • Worli / Sea Link"
	elif current_lat > 18.945:
		zone_name = "South Mumbai • Girgaon Chowpatty"
	elif current_lat > 18.930:
		zone_name = "Marine Drive • Churchgate Promenade"
	elif current_lat > 18.920:
		zone_name = "South Mumbai • Nariman Point"
	else:
		zone_name = "South Mumbai • Colaba Point"
		
	_hud.update_location(zone_name, current_lat, current_lon)

func _on_debug_telemetry_updated(data: Dictionary) -> void:
	if _bld_gen:
		data["bld_read"] = _bld_gen.total_features_read
		data["bld_valid"] = _bld_gen.valid_polygons
		data["bld_meshes"] = _bld_gen.meshes_created
		data["bld_visible"] = _bld_gen.visible_buildings
		data["bld_bright"] = _bld_gen.debug_bright_materials
	if _tile_manager:
		data["tiles_active"] = _tile_manager._active_tiles.size()
		data["tiles_loaded_total"] = _tile_manager.total_tiles_loaded_count
	if _hud:
		_hud.update_debug_telemetry(data)

func _on_restart_requested() -> void:
	if _car:
		_car.reset_vehicle()

func _on_settings_requested() -> void:
	if _settings_dialog:
		_settings_dialog.visible = true

func _on_settings_closed() -> void:
	if _pause_menu and get_tree().paused:
		_pause_menu.visible = true
