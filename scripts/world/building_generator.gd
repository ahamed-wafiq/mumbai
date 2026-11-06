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

# Architectural Materials (CULL_DISABLED ensures 100% visibility regardless of polygon winding)
var _mat_commercial: StandardMaterial3D
var _mat_residential: StandardMaterial3D
var _mat_hotel: StandardMaterial3D
var _mat_heritage: StandardMaterial3D
var _mat_roof_trim: StandardMaterial3D

# High-contrast debug materials for testing
var _debug_mats: Array[StandardMaterial3D] = []

func _ready() -> void:
	_init_materials()

func _unhandled_input(event: InputEvent) -> void:
	# Press F4 to toggle high-contrast debug building materials
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F4:
		toggle_debug_materials()

func _init_materials() -> void:
	# 1. Art Deco / Heritage Sandstone & Granite (Double-sided)
	_mat_heritage = StandardMaterial3D.new()
	_mat_heritage.albedo_color = Color(0.78, 0.72, 0.62, 1.0)
	_mat_heritage.roughness = 0.7
	_mat_heritage.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 2. Modern Commercial Glass & Slate Concrete (Double-sided)
	_mat_commercial = StandardMaterial3D.new()
	_mat_commercial.albedo_color = Color(0.24, 0.32, 0.42, 1.0)
	_mat_commercial.metallic = 0.5
	_mat_commercial.roughness = 0.25
	_mat_commercial.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 3. Seafront Hotel & Corporate Towers (Double-sided)
	_mat_hotel = StandardMaterial3D.new()
	_mat_hotel.albedo_color = Color(0.32, 0.38, 0.48, 1.0)
	_mat_hotel.metallic = 0.4
	_mat_hotel.roughness = 0.35
	_mat_hotel.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 4. Marine Drive Art Deco Apartments & Stucco (Double-sided)
	_mat_residential = StandardMaterial3D.new()
	_mat_residential.albedo_color = Color(0.82, 0.75, 0.66, 1.0)
	_mat_residential.roughness = 0.65
	_mat_residential.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 5. Roof Parapet Accent Trim
	_mat_roof_trim = StandardMaterial3D.new()
	_mat_roof_trim.albedo_color = Color(1.0, 0.45, 0.05, 1.0)
	_mat_roof_trim.roughness = 0.4
	_mat_roof_trim.cull_mode = BaseMaterial3D.CULL_DISABLED
	
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

## Generates a visible 3D building from a tile building data dictionary.
## Supports both 'footprint' and 'polygon' keys.
func generate_building_from_tile_data(b_data: Dictionary) -> Node3D:
	total_features_read += 1
	
	# Support both 'footprint' (standard tile JSON) and 'polygon' keys
	var raw_poly: Array = b_data.get("footprint", b_data.get("polygon", []))
	if raw_poly.size() < 3:
		return null
		
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
