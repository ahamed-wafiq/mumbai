class_name RoadGenerator
extends Node

## RoadGenerator for Mumbai Drive
## Generates high-fidelity 3D asphalt road ribbons, raised curbs, paved sidewalks,
## lane markings, street lamps, and lush urban roadside greenery.

@export var road_material: Material
@export var marking_material: Material
@export var bridge_pier_material: Material

# Shaders and Materials
var _asphalt_shader: Shader = preload("res://assets/shaders/asphalt_road.gdshader")
var _asphalt_mat: Material
var _marking_yellow: StandardMaterial3D
var _marking_white: StandardMaterial3D
var _curb_mat: StandardMaterial3D
var _sidewalk_mat: StandardMaterial3D
var _grass_mat: StandardMaterial3D
var _tree_trunk_mat: StandardMaterial3D
var _tree_leaf_mat: StandardMaterial3D
var _lamp_metal_mat: StandardMaterial3D
var _lamp_glow_mat: StandardMaterial3D

# Shared Primitives for Optimization
var _tree_trunk_mesh: CylinderMesh
var _tree_foliage_mesh: SphereMesh

func _ready() -> void:
	_init_materials()
	_init_shared_meshes()

func _init_materials() -> void:
	# 1. High-Fidelity Coastal Wet Asphalt
	if _asphalt_shader:
		var sm := ShaderMaterial.new()
		sm.shader = _asphalt_shader
		sm.set_shader_parameter("asphalt_color", Color(0.12, 0.13, 0.15, 1.0))
		sm.set_shader_parameter("tire_track_color", Color(0.08, 0.09, 0.10, 1.0))
		sm.set_shader_parameter("wetness_sheen", 0.50)
		sm.set_shader_parameter("road_roughness", 0.60)
		_asphalt_mat = sm
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.13, 0.14, 0.16, 1.0)
		m.roughness = 0.75
		_asphalt_mat = m

	# 2. Road Markings
	_marking_yellow = StandardMaterial3D.new()
	_marking_yellow.albedo_color = Color(1.0, 0.76, 0.08, 1.0)
	_marking_yellow.emission_enabled = true
	_marking_yellow.emission = Color(1.0, 0.76, 0.08, 1.0)
	_marking_yellow.emission_energy_multiplier = 0.5
	_marking_yellow.roughness = 0.4
	_marking_yellow.cull_mode = BaseMaterial3D.CULL_DISABLED

	_marking_white = StandardMaterial3D.new()
	_marking_white.albedo_color = Color(0.94, 0.95, 0.97, 1.0)
	_marking_white.emission_enabled = true
	_marking_white.emission = Color(0.94, 0.95, 0.97, 1.0)
	_marking_white.emission_energy_multiplier = 0.4
	_marking_white.roughness = 0.4
	_marking_white.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 3. Granite Curb & Paver Sidewalk
	_curb_mat = StandardMaterial3D.new()
	_curb_mat.albedo_color = Color(0.40, 0.42, 0.44, 1.0) # Basalt curb stone
	_curb_mat.roughness = 0.7
	_curb_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_sidewalk_mat = StandardMaterial3D.new()
	_sidewalk_mat.albedo_color = Color(0.66, 0.64, 0.60, 1.0) # Light paver concrete
	_sidewalk_mat.roughness = 0.8
	_sidewalk_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 4. Urban Landscaped Greenery
	_grass_mat = StandardMaterial3D.new()
	_grass_mat.albedo_color = Color(0.24, 0.44, 0.18, 1.0) # Lush manicured grass lawn
	_grass_mat.roughness = 0.85
	_grass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	_tree_trunk_mat = StandardMaterial3D.new()
	_tree_trunk_mat.albedo_color = Color(0.32, 0.24, 0.18, 1.0)
	_tree_trunk_mat.roughness = 0.9

	_tree_leaf_mat = StandardMaterial3D.new()
	_tree_leaf_mat.albedo_color = Color(0.18, 0.46, 0.16, 1.0)
	_tree_leaf_mat.roughness = 0.7
	_tree_leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	# 5. Street Furniture
	_lamp_metal_mat = StandardMaterial3D.new()
	_lamp_metal_mat.albedo_color = Color(0.25, 0.28, 0.30, 1.0)
	_lamp_metal_mat.metallic = 0.7
	_lamp_metal_mat.roughness = 0.35

	_lamp_glow_mat = StandardMaterial3D.new()
	_lamp_glow_mat.albedo_color = Color(1.0, 0.88, 0.65, 1.0)
	_lamp_glow_mat.emission_enabled = true
	_lamp_glow_mat.emission = Color(1.0, 0.88, 0.65, 1.0)
	_lamp_glow_mat.emission_energy_multiplier = 4.0

func _init_shared_meshes() -> void:
	_tree_trunk_mesh = CylinderMesh.new()
	_tree_trunk_mesh.top_radius = 0.18
	_tree_trunk_mesh.bottom_radius = 0.26
	_tree_trunk_mesh.height = 3.6
	_tree_trunk_mesh.material = _tree_trunk_mat

	_tree_foliage_mesh = SphereMesh.new()
	_tree_foliage_mesh.radius = 1.9
	_tree_foliage_mesh.height = 3.4
	_tree_foliage_mesh.radial_segments = 10
	_tree_foliage_mesh.rings = 6
	_tree_foliage_mesh.material = _tree_leaf_mat

## Generates a complete 3D road corridor with raised curbs, sidewalks, markings, greenery, and collision
func generate_road_from_tile_data(road_data: Dictionary) -> Node3D:
	var raw_points: Array = road_data.get("points", [])
	if raw_points.size() < 2:
		return null
		
	var width: float = float(road_data.get("width", 14.0))
	var lanes: int = int(road_data.get("lanes", 4))
	var is_bridge: bool = bool(road_data.get("bridge", false))
	var is_tunnel: bool = bool(road_data.get("tunnel", false))
	var road_name: String = str(road_data.get("name", "Road"))
	
	var points: PackedVector3Array = []
	for p in raw_points:
		points.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
		
	var road_container := Node3D.new()
	road_container.name = "Road_" + road_name.replace(" ", "_")
	
	# 1. Main Asphalt Surface Mesh
	var mesh := _create_ribbon_mesh(points, width, 0.05)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "AsphaltSurface"
	mesh_inst.mesh = mesh
	mesh_inst.material_override = road_material if road_material else _asphalt_mat
	road_container.add_child(mesh_inst)
	
	# 2. Road Markings
	# 2a. Double Yellow Center Line
	var divider_mesh := _create_ribbon_mesh(points, 0.38, 0.065)
	var divider_inst := MeshInstance3D.new()
	divider_inst.name = "CenterDivider"
	divider_inst.mesh = divider_mesh
	divider_inst.material_override = _marking_yellow
	road_container.add_child(divider_inst)

	# 2b. Solid White Outer Shoulder Lines
	var half_w := width * 0.5
	var shoulder_offset := half_w - 0.4
	if shoulder_offset > 1.5:
		var left_white := _create_offset_ribbon_mesh(points, -shoulder_offset, 0.18, 0.062)
		var left_inst := MeshInstance3D.new()
		left_inst.mesh = left_white
		left_inst.material_override = _marking_white
		road_container.add_child(left_inst)

		var right_white := _create_offset_ribbon_mesh(points, shoulder_offset, 0.18, 0.062)
		var right_inst := MeshInstance3D.new()
		right_inst.mesh = right_white
		right_inst.material_override = _marking_white
		road_container.add_child(right_inst)

	# 3. Raised 3D Sidewalks & Curbs (Only for ground-level roads)
	if not is_bridge and not is_tunnel and width >= 7.0:
		var curb_width := 0.25
		var walk_width := 2.0
		var curb_h := 0.16
		
		# Left Sidewalk (Curb + Walkway)
		var left_walk := _create_sidewalk_mesh(points, -half_w, -walk_width, curb_h)
		var left_walk_inst := MeshInstance3D.new()
		left_walk_inst.name = "LeftSidewalk"
		left_walk_inst.mesh = left_walk
		left_walk_inst.material_override = _sidewalk_mat
		road_container.add_child(left_walk_inst)

		# Right Sidewalk
		var right_walk := _create_sidewalk_mesh(points, half_w, walk_width, curb_h)
		var right_walk_inst := MeshInstance3D.new()
		right_walk_inst.name = "RightSidewalk"
		right_walk_inst.mesh = right_walk
		right_walk_inst.material_override = _sidewalk_mat
		road_container.add_child(right_walk_inst)

		# 4. Urban Greenery (Trees & Streetlights along sidewalks)
		_spawn_roadside_props(road_container, points, half_w + 1.2, curb_h)

	# 5. Flyover Structural Pillars
	if is_bridge:
		_add_bridge_piers(road_container, points, width)
		
	# 6. Trimesh Drivable Static Collision
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

## Creates an offset ribbon mesh (e.g. for shoulder lines or bus lanes)
func _create_offset_ribbon_mesh(points: PackedVector3Array, center_offset: float, line_width: float, y_offset: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half_lw := line_width * 0.5
	var vert_count := points.size()
	
	for i in range(vert_count):
		var p := points[i]
		var forward := Vector3.FORWARD
		if i < vert_count - 1:
			forward = (points[i + 1] - p).normalized()
		elif i > 0:
			forward = (p - points[i - 1]).normalized()
		var right := forward.cross(Vector3.UP).normalized()
		var center_pt := p + (right * center_offset) + Vector3.UP * y_offset
		var left_v := center_pt - (right * half_lw)
		var right_v := center_pt + (right * half_lw)
		
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

## Creates a raised 3D sidewalk with a vertical curb face and horizontal paver top
func _create_sidewalk_mesh(points: PackedVector3Array, start_offset: float, walk_extend: float, curb_height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vert_count := points.size()
	
	for i in range(vert_count):
		var p := points[i]
		var forward := Vector3.FORWARD
		if i < vert_count - 1:
			forward = (points[i + 1] - p).normalized()
		elif i > 0:
			forward = (p - points[i - 1]).normalized()
		var right := forward.cross(Vector3.UP).normalized()

		var curb_bottom := p + (right * start_offset) + Vector3.UP * 0.02
		var curb_top := p + (right * start_offset) + Vector3.UP * curb_height
		var walk_outer := p + (right * (start_offset + walk_extend)) + Vector3.UP * curb_height
		
		var uv_y := float(i) * 1.5
		
		# Curb vertical face
		st.set_normal(-right if start_offset > 0 else right)
		st.set_uv(Vector2(0, uv_y))
		st.add_vertex(curb_bottom)
		st.set_uv(Vector2(0.2, uv_y))
		st.add_vertex(curb_top)
		
		# Sidewalk horizontal surface
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1.0, uv_y))
		st.add_vertex(walk_outer)

	for i in range(vert_count - 1):
		var b0 := i * 3
		var b1 := (i + 1) * 3
		
		# Vertical curb face quad (curb_bottom -> curb_top)
		st.add_index(b0)
		st.add_index(b1)
		st.add_index(b0 + 1)
		st.add_index(b0 + 1)
		st.add_index(b1)
		st.add_index(b1 + 1)
		
		# Horizontal sidewalk surface quad (curb_top -> walk_outer)
		st.add_index(b0 + 1)
		st.add_index(b1 + 1)
		st.add_index(b0 + 2)
		st.add_index(b0 + 2)
		st.add_index(b1 + 1)
		st.add_index(b1 + 2)

	st.generate_normals()
	return st.commit()

## Spawns procedural 3D street trees and streetlight fixtures along roadside sidewalks
func _spawn_roadside_props(parent: Node3D, points: PackedVector3Array, side_offset: float, base_y: float) -> void:
	if points.size() < 3:
		return

	# Walk along points and place props at regular intervals
	var accumulated_dist: float = 0.0
	var next_tree_dist: float = 28.0
	var next_lamp_dist: float = 42.0

	for i in range(points.size() - 1):
		var p1 := points[i]
		var p2 := points[i + 1]
		var seg_len := p1.distance_to(p2)
		var forward := (p2 - p1).normalized()
		var right := forward.cross(Vector3.UP).normalized()

		accumulated_dist += seg_len
		
		# Tree placement
		if accumulated_dist >= next_tree_dist:
			next_tree_dist = accumulated_dist + 35.0
			var tree_pos := p1 + (right * side_offset) + Vector3.UP * base_y
			_create_street_tree(parent, tree_pos)

		# Streetlamp placement (on alternate side)
		if accumulated_dist >= next_lamp_dist:
			next_lamp_dist = accumulated_dist + 45.0
			var lamp_pos := p1 - (right * (side_offset - 0.4)) + Vector3.UP * base_y
			_create_streetlight(parent, lamp_pos, forward)

## Instantiates a 3D urban tree (cylinder trunk + spherical layered canopy)
func _create_street_tree(parent: Node3D, pos: Vector3) -> void:
	var tree_node := Node3D.new()
	tree_node.position = pos

	# Trunk
	var trunk_inst := MeshInstance3D.new()
	trunk_inst.mesh = _tree_trunk_mesh
	trunk_inst.position = Vector3(0, 1.8, 0)
	tree_node.add_child(trunk_inst)

	# Main Foliage Canopy
	var canopy_inst := MeshInstance3D.new()
	canopy_inst.mesh = _tree_foliage_mesh
	canopy_inst.position = Vector3(0, 3.8, 0)
	tree_node.add_child(canopy_inst)

	# Upper Canopy Crown
	var crown_inst := MeshInstance3D.new()
	crown_inst.mesh = _tree_foliage_mesh
	crown_inst.scale = Vector3(0.75, 0.65, 0.75)
	crown_inst.position = Vector3(0, 4.6, 0)
	tree_node.add_child(crown_inst)

	parent.add_child(tree_node)

## Instantiates a slender curved streetlight pole with warm emission luminaire
func _create_streetlight(parent: Node3D, pos: Vector3, road_forward: Vector3) -> void:
	var lamp_node := Node3D.new()
	lamp_node.position = pos

	# Vertical Pole
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.06
	pole_mesh.bottom_radius = 0.10
	pole_mesh.height = 6.2
	pole_mesh.material = _lamp_metal_mat

	var pole_inst := MeshInstance3D.new()
	pole_inst.mesh = pole_mesh
	pole_inst.position = Vector3(0, 3.1, 0)
	lamp_node.add_child(pole_inst)

	# Overhang Arm
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.08, 0.08, 1.4)
	arm_mesh.material = _lamp_metal_mat

	var arm_inst := MeshInstance3D.new()
	arm_inst.mesh = arm_mesh
	arm_inst.position = Vector3(0, 6.1, 0.5)
	lamp_node.add_child(arm_inst)

	# Luminaire Fixture
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.24, 0.12, 0.45)
	head_mesh.material = _lamp_glow_mat

	var head_inst := MeshInstance3D.new()
	head_inst.mesh = head_mesh
	head_inst.position = Vector3(0, 5.95, 1.1)
	lamp_node.add_child(head_inst)

	parent.add_child(lamp_node)

## Adds concrete support pillars for elevated flyovers and bridges
func _add_bridge_piers(parent: Node3D, points: PackedVector3Array, _width: float) -> void:
	var pier_mesh := CylinderMesh.new()
	pier_mesh.top_radius = 1.2
	pier_mesh.bottom_radius = 1.4
	
	var pier_mat := StandardMaterial3D.new()
	pier_mat.albedo_color = Color(0.35, 0.38, 0.42, 1.0)
	pier_mesh.material = pier_mat
	
	for i in range(0, points.size(), 2):
		var p := points[i]
		var pier_height := p.y
		if pier_height > 1.0:
			var pier := MeshInstance3D.new()
			pier.mesh = pier_mesh
			pier.scale = Vector3(1.0, pier_height / 2.0, 1.0)
			pier.position = Vector3(p.x, pier_height * 0.5, p.z)
			parent.add_child(pier)
