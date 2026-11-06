class_name RoadGenerator
extends Node

## RoadGenerator for Mumbai Drive
## Generates 3D asphalt road ribbons, markings, bridges, and drivable collision surfaces
## from real OpenStreetMap road vectors.

@export var road_material: Material
@export var marking_material: Material
@export var bridge_pier_material: Material

var _asphalt_mat: StandardMaterial3D
var _marking_yellow: StandardMaterial3D
var _marking_white: StandardMaterial3D

func _ready() -> void:
	# Default fallback materials if not assigned
	_asphalt_mat = StandardMaterial3D.new()
	_asphalt_mat.albedo_color = Color(0.15, 0.16, 0.18, 1.0)
	_asphalt_mat.roughness = 0.85
	_asphalt_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_marking_yellow = StandardMaterial3D.new()
	_marking_yellow.albedo_color = Color(1.0, 0.72, 0.05, 1.0)
	_marking_yellow.roughness = 0.5
	_marking_yellow.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	_marking_white = StandardMaterial3D.new()
	_marking_white.albedo_color = Color(0.92, 0.94, 0.96, 1.0)
	_marking_white.roughness = 0.5
	_marking_white.cull_mode = BaseMaterial3D.CULL_DISABLED

## Generates a 3D road segment from a tile road dictionary
func generate_road_from_tile_data(road_data: Dictionary) -> Node3D:
	var raw_points: Array = road_data.get("points", [])
	if raw_points.size() < 2:
		return null
		
	var width: float = float(road_data.get("width", 14.0))
	var _lanes: int = int(road_data.get("lanes", 4))
	var is_bridge: bool = bool(road_data.get("bridge", false))
	var road_name: String = str(road_data.get("name", "Road"))
	
	var points: PackedVector3Array = []
	for p in raw_points:
		points.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
		
	var road_container := Node3D.new()
	road_container.name = "Road_" + road_name.replace(" ", "_")
	
	# 1. Main Asphalt Surface Mesh
	var mesh := _create_ribbon_mesh(points, width)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "AsphaltSurface"
	mesh_inst.mesh = mesh
	mesh_inst.material_override = road_material if road_material else _asphalt_mat
	road_container.add_child(mesh_inst)
	
	# 2. Road Markings (Yellow Center Line)
	var divider_mesh := _create_ribbon_mesh(points, 0.35, 0.02)
	var divider_inst := MeshInstance3D.new()
	divider_inst.name = "CenterDivider"
	divider_inst.mesh = divider_mesh
	divider_inst.material_override = _marking_yellow
	road_container.add_child(divider_inst)
	
	# 3. If bridge/flyover, generate structural piers down to ground
	if is_bridge:
		_add_bridge_piers(road_container, points, width)
		
	# 4. Trimesh Drivable Static Collision
	var static_body := StaticBody3D.new()
	static_body.name = "RoadCollision"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var col_shape := CollisionShape3D.new()
	col_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(col_shape)
	road_container.add_child(static_body)
	
	return road_container

## Extrudes a flat 3D ribbon along a series of center-line points
func _create_ribbon_mesh(points: PackedVector3Array, width: float, y_offset: float = 0.05) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_w := width * 0.5
	var vert_count := points.size()
	
	for i in range(vert_count):
		var p := points[i]
		var forward := Vector3.FORWARD
		
		if i < vert_count - 1:
			forward = (points[i + 1] - p).normalized()
		elif i > 0:
			forward = (p - points[i - 1]).normalized()
			
		var right := forward.cross(Vector3.UP).normalized()
		var left_v := p - (right * half_w) + Vector3.UP * y_offset
		var right_v := p + (right * half_w) + Vector3.UP * y_offset
		
		var uv_y := float(i) * 2.0
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, uv_y))
		st.add_vertex(left_v)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, uv_y))
		st.add_vertex(right_v)
		
	for i in range(vert_count - 1):
		var idx_tl := i * 2
		var idx_tr := i * 2 + 1
		var idx_bl := (i + 1) * 2
		var idx_br := (i + 1) * 2 + 1
		
		st.add_index(idx_tl)
		st.add_index(idx_bl)
		st.add_index(idx_tr)
		
		st.add_index(idx_tr)
		st.add_index(idx_bl)
		st.add_index(idx_br)
		
	st.generate_normals()
	return st.commit()

## Adds concrete support pillars for elevated flyovers and bridges
func _add_bridge_piers(parent: Node3D, points: PackedVector3Array, _width: float) -> void:
	var pier_mesh := CylinderMesh.new()
	pier_mesh.top_radius = 1.2
	pier_mesh.bottom_radius = 1.4
	
	var pier_mat := StandardMaterial3D.new()
	pier_mat.albedo_color = Color(0.35, 0.38, 0.42, 1.0)
	pier_mesh.material = pier_mat
	
	# Place a pier every 30-50 meters
	for i in range(0, points.size(), 2):
		var p := points[i]
		var pier_height := p.y
		if pier_height > 1.0:
			var pier := MeshInstance3D.new()
			pier.mesh = pier_mesh
			pier.scale = Vector3(1.0, pier_height / 2.0, 1.0)
			pier.position = Vector3(p.x, pier_height * 0.5, p.z)
			parent.add_child(pier)
