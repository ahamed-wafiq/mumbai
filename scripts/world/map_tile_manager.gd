class_name MapTileManager
extends Node

## MapTileManager for Mumbai Drive
## Loads, builds, and frees 500m x 500m geographical chunk tiles
## containing real OpenStreetMap roads, buildings, and ground geometry.

signal tile_loaded(tile_coord: Vector2i, tile_node: Node3D)
signal tile_unloaded(tile_coord: Vector2i)

@export var tile_size_meters: float = 500.0
@export var tiles_data_directory: String = "res://data/tiles/"
@export var road_generator_path: NodePath = "../RoadGenerator"
@export var building_generator_path: NodePath = "../BuildingGenerator"

var _road_gen: RoadGenerator
var _bld_gen: BuildingGenerator
var _active_tiles: Dictionary = {} # Vector2i -> Node3D
var _tile_manifest: Dictionary = {}
var _ground_material: StandardMaterial3D

func _ready() -> void:
	_road_gen = get_node_or_null(road_generator_path)
	_bld_gen = get_node_or_null(building_generator_path)
	
	_ground_material = StandardMaterial3D.new()
	_ground_material.albedo_color = Color(0.18, 0.20, 0.22, 1.0)
	_ground_material.roughness = 0.95
	
	# Load master tile manifest if available
	var manifest_path := tiles_data_directory + "tile_manifest.json"
	if FileAccess.file_exists(manifest_path):
		var file := FileAccess.open(manifest_path, FileAccess.READ)
		if file:
			var text := file.get_as_text()
			var json_obj := JSON.new()
			if json_obj.parse(text) == OK:
				_tile_manifest = json_obj.data

## Converts a 3D world position into grid tile coordinates (gx, gz)
func world_to_tile_coord(pos: Vector3) -> Vector2i:
	var gx := int(floor(pos.x / tile_size_meters))
	var gz := int(floor(pos.z / tile_size_meters))
	return Vector2i(gx, gz)

## Checks if a tile is currently active in the scene tree
func is_tile_loaded(coord: Vector2i) -> bool:
	return _active_tiles.has(coord)

## Loads and generates a 3D geographical tile from JSON data
func load_tile(coord: Vector2i, parent_node: Node3D) -> Node3D:
	if is_tile_loaded(coord):
		return _active_tiles[coord]
		
	var tile_filename := "%stile_%d_%d.json" % [tiles_data_directory, coord.x, coord.y]
	if not FileAccess.file_exists(tile_filename):
		# No OSM data in this empty chunk, create empty placeholder container
		return null
		
	var file := FileAccess.open(tile_filename, FileAccess.READ)
	if not file:
		return null
		
	var json_parser := JSON.new()
	if json_parser.parse(file.get_as_text()) != OK:
		return null
		
	var tile_data: Dictionary = json_parser.data
	var tile_root := Node3D.new()
	tile_root.name = "Tile_%d_%d" % [coord.x, coord.y]
	parent_node.add_child(tile_root)
	
	# 1. Base Ground Plane for this tile
	var cx := (float(coord.x) + 0.5) * tile_size_meters
	var cz := (float(coord.y) + 0.5) * tile_size_meters
	_create_tile_ground(tile_root, cx, cz)
	
	# 2. Instantiate Real OSM Roads in this tile
	if _road_gen:
		var roads_arr: Array = tile_data.get("roads", [])
		for r_data in roads_arr:
			var road_node := _road_gen.generate_road_from_tile_data(r_data)
			if road_node:
				tile_root.add_child(road_node)
				
	# 3. Instantiate Real OSM Buildings in this tile
	if _bld_gen:
		var blds_arr: Array = tile_data.get("buildings", [])
		for b_data in blds_arr:
			var bld_node := _bld_gen.generate_building_from_tile_data(b_data)
			if bld_node:
				tile_root.add_child(bld_node)
				
	_active_tiles[coord] = tile_root
	tile_loaded.emit(coord, tile_root)
	return tile_root

## Unloads a tile and frees all its meshes & collisions from RAM
func unload_tile(coord: Vector2i) -> void:
	if not _active_tiles.has(coord):
		return
		
	var tile_node: Node3D = _active_tiles[coord]
	_active_tiles.erase(coord)
	
	if is_instance_valid(tile_node):
		tile_node.queue_free()
		
	tile_unloaded.emit(coord)

## Creates a flat low-poly ground patch with collision for this tile
func _create_tile_ground(parent: Node3D, cx: float, cz: float) -> void:
	var ground_body := StaticBody3D.new()
	ground_body.name = "Ground"
	ground_body.position = Vector3(cx, -0.05, cz)
	ground_body.collision_layer = 1
	ground_body.collision_mask = 0
	
	# Mesh
	var p_mesh := PlaneMesh.new()
	p_mesh.size = Vector2(tile_size_meters, tile_size_meters)
	p_mesh.material = _ground_material
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = p_mesh
	ground_body.add_child(mesh_inst)
	
	# Collision
	var shape := BoxShape3D.new()
	shape.size = Vector3(tile_size_meters, 0.2, tile_size_meters)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	ground_body.add_child(col)
	
	parent.add_child(ground_body)
