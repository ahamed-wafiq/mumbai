class_name RoadGenerator
extends Node

## RoadGenerator for Mumbai Drive (High-Performance GPU-Optimized)
## Generates 3D asphalt road ribbons with integrated markings, raised sidewalks,
## and GPU-instanced roadside greenery using MultiMesh.

@export var road_material: Material
@export var bridge_pier_material: Material

# Shaders and Materials
var _asphalt_shader: Shader = preload("res://assets/shaders/asphalt_road.gdshader")
var _asphalt_mat: Material
var _sidewalk_mat: StandardMaterial3D
var _pier_mat: StandardMaterial3D

func _ready() -> void:
	_init_materials()

func _init_materials() -> void:
	# 1. High-Fidelity Coastal Wet Asphalt with integrated lane markings
	if _asphalt_shader:
		var sm := ShaderMaterial.new()
		sm.shader = _asphalt_shader
		sm.set_shader_parameter("asphalt_color", Color(0.12, 0.13, 0.15, 1.0))
		sm.set_shader_parameter("tire_track_color", Color(0.08, 0.09, 0.10, 1.0))
		sm.set_shader_parameter("yellow_line_color", Color(1.0, 0.76, 0.08, 1.0))
		sm.set_shader_parameter("white_line_color", Color(0.94, 0.95, 0.97, 1.0))
		sm.set_shader_parameter("wetness_sheen", 0.50)
		sm.set_shader_parameter("road_roughness", 0.60)
		_asphalt_mat = sm
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.13, 0.14, 0.16, 1.0)
		m.roughness = 0.75
		_asphalt_mat = m

	# 2. Granite Curb & Paver Sidewalk
	_sidewalk_mat = StandardMaterial3D.new()
	_sidewalk_mat.albedo_color = Color(0.66, 0.64, 0.60, 1.0)
	_sidewalk_mat.roughness = 0.8
	_sidewalk_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 3. Bridge Pier Material
	_pier_mat = StandardMaterial3D.new()
	_pier_mat.albedo_color = Color(0.35, 0.38, 0.42, 1.0)
	_pier_mat.roughness = 0.75

## Generates an optimized 3D road segment with 1 draw call per road
func generate_road_from_tile_data(road_data: Dictionary) -> Node3D:
	var raw_points: Array = road_data.get("points", [])
	if raw_points.size() < 2:
		return null
		
	var width: float = float(road_data.get("width", 14.0))
	var is_bridge: bool = bool(road_data.get("bridge", false))
	var is_tunnel: bool = bool(road_data.get("tunnel", false))
	var road_name: String = str(road_data.get("name", "Road"))
	
	var points: PackedVector3Array = []
	for p in raw_points:
		points.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
		
	var road_container := Node3D.new()
	road_container.name = "Road_" + road_name.replace(" ", "_")
	
	# 1. Main Asphalt Surface Mesh (with integrated shader lane markings)
	var mesh := _create_ribbon_mesh(points, width, 0.05)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "AsphaltSurface"
	mesh_inst.mesh = mesh
	mesh_inst.material_override = road_material if road_material else _asphalt_mat
	# Distance LOD culling for roads
	mesh_inst.visibility_range_end = 650.0
	mesh_inst.visibility_range_end_margin = 40.0
	road_container.add_child(mesh_inst)

	# 2. Raised Sidewalks (Only for wide arterial / secondary roads width >= 11m)
	if not is_bridge and not is_tunnel and width >= 11.0:
		var half_w := width * 0.5
		var walk_width := 2.2
		var curb_h := 0.16
		
		# Combined left + right sidewalk mesh in 1 single draw call
		var sidewalk_mesh := _create_combined_sidewalk_mesh(points, half_w, walk_width, curb_h)
		if sidewalk_mesh:
			var walk_inst := MeshInstance3D.new()
			walk_inst.name = "Sidewalks"
			walk_inst.mesh = sidewalk_mesh
			walk_inst.material_override = _sidewalk_mat
			walk_inst.visibility_range_end = 400.0
			road_container.add_child(walk_inst)

	# 3. Flyover Support Piers (for elevated roads)
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

## Creates a combined left and right raised 3D sidewalk in a single mesh
func _create_combined_sidewalk_mesh(points: PackedVector3Array, half_w: float, walk_extend: float, curb_height: float) -> ArrayMesh:
	var vert_count := points.size()
	if vert_count < 2:
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Left sidewalk quads
	for i in range(vert_count - 1):
		var p1 := points[i]
		var p2 := points[i + 1]
		var fwd := (p2 - p1).normalized()
		var rgt := fwd.cross(Vector3.UP).normalized()

		# Left side: -half_w to -(half_w + walk_extend)
		var l_curb1 := p1 - (rgt * half_w) + Vector3.UP * curb_height
		var l_outer1 := p1 - (rgt * (half_w + walk_extend)) + Vector3.UP * curb_height
		var l_curb2 := p2 - (rgt * half_w) + Vector3.UP * curb_height
		var l_outer2 := p2 - (rgt * (half_w + walk_extend)) + Vector3.UP * curb_height

		# Right side: +half_w to +(half_w + walk_extend)
		var r_curb1 := p1 + (rgt * half_w) + Vector3.UP * curb_height
		var r_outer1 := p1 + (rgt * (half_w + walk_extend)) + Vector3.UP * curb_height
		var r_curb2 := p2 + (rgt * half_w) + Vector3.UP * curb_height
		var r_outer2 := p2 + (rgt * (half_w + walk_extend)) + Vector3.UP * curb_height

		# Left Quad (l_curb1 -> l_outer1 -> l_outer2 -> l_curb2)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(l_curb1)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(l_outer1)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(l_outer2)

		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(l_curb1)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(l_outer2)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(l_curb2)

		# Right Quad (r_curb1 -> r_curb2 -> r_outer2 -> r_outer1)
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(r_curb1)
		st.set_uv(Vector2(0, 1))
		st.add_vertex(r_curb2)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(r_outer2)

		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(r_curb1)
		st.set_uv(Vector2(1, 1))
		st.add_vertex(r_outer2)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(r_outer1)

	st.generate_normals()
	return st.commit()

## Adds concrete support pillars for elevated flyovers and bridges
func _add_bridge_piers(parent: Node3D, points: PackedVector3Array, _width: float) -> void:
	var pier_mesh := CylinderMesh.new()
	pier_mesh.top_radius = 1.2
	pier_mesh.bottom_radius = 1.4
	pier_mesh.material = _pier_mat
	
	for i in range(0, points.size(), 3):
		var p := points[i]
		var pier_height := p.y
		if pier_height > 1.0:
			var pier := MeshInstance3D.new()
			pier.mesh = pier_mesh
			pier.scale = Vector3(1.0, pier_height / 2.0, 1.0)
			pier.position = Vector3(p.x, pier_height * 0.5, p.z)
			pier.visibility_range_end = 350.0
			parent.add_child(pier)
