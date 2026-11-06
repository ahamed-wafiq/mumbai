class_name WorldStreamer
extends Node

## WorldStreamer for Mumbai Drive
## Dynamically loads and unloads geographical world tiles around the player's car.
## Keeps memory footprint lightweight for standard laptops and WebGL 2.0 browsers.

@export var player_target_path: NodePath = "../Car"
@export var tile_manager_path: NodePath = "../MapTileManager"
@export var tiles_container_path: NodePath = "../StreamedWorld"
@export var load_radius_tiles: int = 1   # 1 tile radius = 3x3 active grid (1500m x 1500m)
@export var unload_radius_tiles: int = 2 # Tiles farther than 2 are freed from RAM
@export var update_distance_threshold: float = 40.0 # Only check streaming when moved 40m

var _player: Node3D
var _tile_manager: MapTileManager
var _tiles_container: Node3D
var _last_update_pos: Vector3 = Vector3(99999, 0, 99999)
var _current_center_tile: Vector2i = Vector2i(99999, 99999)

func _ready() -> void:
	_player = get_node_or_null(player_target_path)
	_tile_manager = get_node_or_null(tile_manager_path)
	_tiles_container = get_node_or_null(tiles_container_path)
	if not _tiles_container:
		_tiles_container = get_parent()
		
	# Initial force load around player start position
	if _player and _tile_manager:
		_update_streaming(_player.global_position, true)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_player) or not is_instance_valid(_tile_manager):
		return
		
	var player_pos := _player.global_position
	if player_pos.distance_squared_to(_last_update_pos) >= (update_distance_threshold * update_distance_threshold):
		_last_update_pos = player_pos
		_update_streaming(player_pos, false)

func _update_streaming(player_pos: Vector3, force: bool) -> void:
	var center_tile := _tile_manager.world_to_tile_coord(player_pos)
	if center_tile == _current_center_tile and not force:
		return
		
	_current_center_tile = center_tile
	
	# 1. Load active tiles in radius
	for dx in range(-load_radius_tiles, load_radius_tiles + 1):
		for dz in range(-load_radius_tiles, load_radius_tiles + 1):
			var tile_coord := Vector2i(center_tile.x + dx, center_tile.y + dz)
			if not _tile_manager.is_tile_loaded(tile_coord):
				_tile_manager.load_tile(tile_coord, _tiles_container)
				
	# 2. Unload distant tiles to save RAM and draw calls
	var active_keys := _tile_manager._active_tiles.keys().duplicate()
	for active_coord in active_keys:
		var dist_x: int = abs(active_coord.x - center_tile.x)
		var dist_z: int = abs(active_coord.y - center_tile.y)
		if dist_x > unload_radius_tiles or dist_z > unload_radius_tiles:
			_tile_manager.unload_tile(active_coord)
