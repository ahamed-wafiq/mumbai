class_name BuildingGenerator
extends Node

## BuildingGenerator for Mumbai Drive
## Extrudes real OpenStreetMap building footprints into visible 3D meshes with
## actual or typology-estimated heights, double-sided materials, and collision.

@export var default_floor_height: float = 3.5
@export var building_material: Material
@export var debug_bright_materials: bool = false # Toggleable bright debug colors

# Real-time Telemetry Counters
var total_features_read: int = 0
var valid_polygons: int = 0
var meshes_created: int = 0
var visible_buildings: int = 0

# Architectural Materials (Procedural Facade Shaders)
var _facade_shader: Shader = preload("res://assets/shaders/building_facade.gdshader")
var _mat_commercial: Material
var _mat_residential: Material
var _mat_hotel: Material
var _mat_heritage: Material
var _mat_roof_trim: Material

# High-contrast debug materials for testing
var _debug_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	_init_materials()

func _unhandled_input(event: InputEvent) -> void:
	# Press F4 to toggle high-contrast debug building materials
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		toggle_debug_materials()

func _create_facade_mat(wall_col: Color, trim_col: Color, win_col: Color, floor_h: float, win_w: float, win_h: float, emiss_str: float, metallic_val: float, rough_val: float) -> Material:
	if _facade_shader:
		var sm := ShaderMaterial.new()
		sm.shader = _facade_shader
		sm.set_shader_parameter("wall_color", wall_col)
		sm.set_shader_parameter("trim_color", trim_col)
		sm.set_shader_parameter("window_color", win_col)
		sm.set_shader_parameter("floor_height", floor_h)
		sm.set_shader_parameter("window_width", win_w)
		sm.set_shader_parameter("window_height", win_h)
		sm.set_shader_parameter("emission_strength", emiss_str)
		sm.set_shader_parameter("emission_color", Color(1.0, 0.88, 0.65, 1.0))
		sm.set_shader_parameter("glass_metallic", metallic_val)
		sm.set_shader_parameter("window_roughness", rough_val)
		sm.set_shader_parameter("wall_roughness", 0.75)
		return sm
	else:
		var m := StandardMaterial3D.new()
		m.albedo_color = wall_col
		m.roughness = 0.7
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		return m

func _init_materials() -> void:
	# 1. Marine Drive Art Deco Apartments & Residential Mansions
	_mat_residential = _create_facade_mat(
		Color(0.85, 0.80, 0.72, 1.0), # Warm Art Deco Cream
		Color(0.95, 0.48, 0.15, 1.0), # Terracotta Orange trim
		Color(0.10, 0.16, 0.22, 1.0), # Deep reflective glass
		3.5, 0.65, 0.55, 1.3, 0.85, 0.12
	)
	
	# 2. Modern Commercial Glass & Slate Corporate Headquarters
	_mat_commercial = _create_facade_mat(
		Color(0.24, 0.28, 0.35, 1.0), # Slate charcoal concrete
		Color(0.30, 0.70, 0.90, 1.0), # Cyan / chrome architectural accent
		Color(0.08, 0.14, 0.20, 1.0), # Reflective blue glass
		3.8, 0.75, 0.65, 1.6, 0.92, 0.08
	)
	
	# 3. Seafront Luxury Hotels (The Oberoi, Trident, InterContinental)
	_mat_hotel = _create_facade_mat(
		Color(0.80, 0.78, 0.74, 1.0), # Ivory travertine marble
		Color(0.95, 0.75, 0.25, 1.0), # Gold / brass spandrel trim
		Color(0.12, 0.18, 0.20, 1.0), # Emerald glass tint
		3.6, 0.70, 0.60, 1.5, 0.88, 0.10
	)
	
	# 4. Victorian Gothic & Heritage Institutions (High Court, CSMT, Wilson College)
	_mat_heritage = _create_facade_mat(
		Color(0.70, 0.62, 0.52, 1.0), # Mumbai Kurla yellow basalt
		Color(0.48, 0.40, 0.32, 1.0), # Dark teak wood & stone trim
		Color(0.15, 0.16, 0.18, 1.0), # Arched dark pane glass
		4.2, 0.50, 0.65, 0.9, 0.40, 0.25
	)
	
	# 5. Parapet trim
	var m_trim := StandardMaterial3D.new()
	m_trim.albedo_color = Color(1.0, 0.45, 0.05, 1.0)
	m_trim.roughness = 0.4
	m_trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mat_roof_trim = m_trim
	
	# 6. Vibrant Debug Materials (High visibility)
	var debug_colors := [
		Color(0.0, 0.85, 1.0, 1.0),  # Bright Cyan
		Color(1.0, 0.75, 0.0, 1.0),  # Vibrant Gold
		Color(1.0, 0.35, 0.1, 1.0),  # Neon Orange
		Color(0.2, 0.95, 0.4, 1.0),  # Bright Emerald
		Color(0.9, 0.25, 0.85, 1.0), # Vivid Magenta
	]
	_debug_mats.clear()
	for col in debug_colors:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.roughness = 0.3
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_debug_mats.append(mat)

## Toggles high-contrast bright materials across all active building meshes
func toggle_debug_materials() -> void:
	debug_bright_materials = not debug_bright_materials
	print("[BuildingGenerator] High-contrast debug building materials: ", "ENABLED" if debug_bright_materials else "DISABLED")

## Applies geometric road clearance to building polygon vertices
## Rigidly shifts buildings away from road corridors preserving their exact architectural geometry
func _apply_road_clearance(raw_poly: Array) -> Array:
	if raw_poly.is_empty():
		return raw_poly
		
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	var min_x: float = 999999.0
	var max_x: float = -999999.0
	
	for pt in raw_poly:
		var px: float = float(pt[0])
		var pz: float = float(pt[2])
		sum_x += px
		sum_z += pz
		min_x = minf(min_x, px)
		max_x = maxf(max_x, px)
		
	var count: float = float(raw_poly.size())
	var center_x: float = sum_x / count
	var center_z: float = sum_z / count
	
	# Marine Drive Queen's Necklace corridor clearance:
	# Centerline is at X ~ 0 to 1.0, road half-width 9.0m, sidewalk extends to 13.5m.
	if center_z >= -1400.0 and center_z <= 2200.0:
		if center_x >= 0.0:
			# City side: ensure all building vertices sit safely behind sidewalk (X >= 13.8m)
			if min_x < 13.8:
				var shift_x: float = 13.8 - min_x
				var shifted: Array = []
				for pt in raw_poly:
					shifted.append([float(pt[0]) + shift_x, float(pt[1]), float(pt[2])])
				return shifted
		else:
			# Sea side: ensure all building vertices sit past promenade wall (X <= -16.0m)
			if max_x > -16.0:
				var shift_x: float = -16.0 - max_x
				var shifted: Array = []
				for pt in raw_poly:
					shifted.append([float(pt[0]) + shift_x, float(pt[1]), float(pt[2])])
				return shifted
				
	return raw_poly

## Generates a visible 3D building from a tile building data dictionary.
## Supports both 'footprint' and 'polygon' keys.
func generate_building_from_tile_data(b_data: Dictionary) -> Node3D:
	total_features_read += 1
	
	# Support both 'footprint' (standard tile JSON) and 'polygon' keys
	var raw_poly: Array = b_data.get("footprint", b_data.get("polygon", []))
	if raw_poly.size() < 3:
		return null
		
	# Apply road clearance pushback to avoid buildings encroaching into road lanes
	raw_poly = _apply_road_clearance(raw_poly)
		
	valid_polygons += 1
	
	var height: float = maxf(float(b_data.get("height", 14.0)), 6.0)
	var b_type: String = str(b_data.get("type", b_data.get("building_type", "residential")))
	var b_name: String = str(b_data.get("name", "Building"))
	
	# Compute building centroid in world coordinates
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	var pt_count: int = raw_poly.size()
	
	# Check if polygon is closed (last point == first point)
	var is_closed: bool = (pt_count > 3 and 
		absf(float(raw_poly[0][0]) - float(raw_poly[pt_count - 1][0])) < 0.01 and 
		absf(float(raw_poly[0][2]) - float(raw_poly[pt_count - 1][2])) < 0.01)
	var count_for_center: int = (pt_count - 1) if is_closed else pt_count
	
	for i in range(count_for_center):
		sum_x += float(raw_poly[i][0])
		sum_z += float(raw_poly[i][2])
		
	var center := Vector3(sum_x / float(count_for_center), 0.0, sum_z / float(count_for_center))
	
	# Cull any erroneous building whose entire centroid sits inside the road corridor
	if absf(center.x) < 8.0 and center.z >= -1400.0 and center.z <= 2200.0:
		return null
		
	# Convert footprint points to local space relative to center
	var local_pts: PackedVector3Array = []
	for i in range(count_for_center):
		var p = raw_poly[i]
		local_pts.append(Vector3(float(p[0]) - center.x, 0.0, float(p[2]) - center.z))
	# Ensure loop is closed for wall extrusion
	local_pts.append(local_pts[0])
	
	# Create parent node placed at centroid
	var building_node := Node3D.new()
	building_node.name = "Bld_" + b_name.replace(" ", "_")
	building_node.position = center
	
	# Extrude visible 3D mesh (walls + roof)
	var mesh := _extrude_building_mesh(local_pts, height)
	if not mesh:
		return null
		
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "BuildingMesh"
	mesh_inst.mesh = mesh
	
	# Assign material
	var chosen_mat: Material
	if debug_bright_materials and _debug_mats.size() > 0:
		var hash_idx: int = abs(b_name.hash()) % _debug_mats.size()
		chosen_mat = _debug_mats[hash_idx]
	elif building_material:
		chosen_mat = building_material
	else:
		match b_type:
			"commercial", "office":
				chosen_mat = _mat_commercial
			"hotel":
				chosen_mat = _mat_hotel
			"monument", "civic", "courthouse", "stadium", "university", "heritage":
				chosen_mat = _mat_heritage
			_:
				chosen_mat = _mat_residential
				
	mesh_inst.material_override = chosen_mat
	building_node.add_child(mesh_inst)
	
	# Add Static Collision for vehicle collisions
	var static_body := StaticBody3D.new()
	static_body.name = "Collision"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var col_shape := CollisionShape3D.new()
	var tri_shape := mesh.create_trimesh_shape()
	if tri_shape:
		col_shape.shape = tri_shape
		static_body.add_child(col_shape)
		building_node.add_child(static_body)
	
	meshes_created += 1
	visible_buildings += 1
	return building_node

## Extrudes a 2D local footprint into 3D walls and flat roof with double-sided rendering
func _extrude_building_mesh(local_pts: PackedVector3Array, height: float) -> ArrayMesh:
	var count := local_pts.size()
	if count < 3:
		return null
		
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 1. Extrude Vertical Walls
	for i in range(count - 1):
		var p1 := local_pts[i]
		var p2 := local_pts[i + 1]
		
		# Skip duplicate consecutive vertices
		if p1.distance_squared_to(p2) < 0.001:
			continue
			
		var b1 := Vector3(p1.x, 0.0, p1.z)
		var b2 := Vector3(p2.x, 0.0, p2.z)
		var t1 := Vector3(p1.x, height, p1.z)
		var t2 := Vector3(p2.x, height, p2.z)
		
		var edge := (b2 - b1).normalized()
		var wall_normal := edge.cross(Vector3.UP).normalized()
		var wall_len := (b2 - b1).length()
		var uv_scale := wall_len / 4.0
		var uv_v := height / 3.5
		
		# Triangle 1 (b1 -> t1 -> b2)
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(b1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, uv_v))
		st.add_vertex(t1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(uv_scale, 0))
		st.add_vertex(b2)
		
		# Triangle 2 (t1 -> t2 -> b2)
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, uv_v))
		st.add_vertex(t1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(uv_scale, uv_v))
		st.add_vertex(t2)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(uv_scale, 0))
		st.add_vertex(b2)
		
	# 2. Triangulate Horizontal Roof using Centroid Fan
	var roof_center := Vector3.ZERO
	var valid_roof_pts: int = 0
	for i in range(count - 1):
		roof_center += local_pts[i]
		valid_roof_pts += 1
		
	if valid_roof_pts > 0:
		roof_center /= float(valid_roof_pts)
	roof_center.y = height
	
	for i in range(count - 1):
		var v1 := Vector3(local_pts[i].x, height, local_pts[i].z)
		var v2 := Vector3(local_pts[i + 1].x, height, local_pts[i + 1].z)
		
		if v1.distance_squared_to(v2) < 0.001:
			continue
			
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(v1)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(v2)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0.5, 0.5))
		st.add_vertex(roof_center)
		
	st.generate_normals()
	return st.commit()

## Returns real-time debug telemetry statistics
func get_debug_stats() -> Dictionary:
	return {
		"total_features_read": total_features_read,
		"valid_polygons": valid_polygons,
		"meshes_created": meshes_created,
		"visible_buildings": visible_buildings,
		"debug_bright_materials": debug_bright_materials
	}
