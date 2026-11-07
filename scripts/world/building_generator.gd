class_name BuildingGenerator
extends Node

## BuildingGenerator for Mumbai Drive (High-Performance GPU-Optimized)
## Extrudes real OpenStreetMap building footprints into single-draw-call 3D meshes
## with authentic architectural typologies, realistic height variations, rooftop parapets,
## elevator penthouses, distance LOD culling, and strict zero-overlap road protection.

@export var default_floor_height: float = 3.5
@export var building_material: Material
@export var debug_bright_materials: bool = false # Toggleable bright debug colors

# Real-time Telemetry Counters
var total_features_read: int = 0
var valid_polygons: int = 0
var meshes_created: int = 0
var visible_buildings: int = 0

# Architectural Materials (8 Diverse Procedural Facade Shaders)
var _facade_shader: Shader = preload("res://assets/shaders/building_facade.gdshader")
var _mat_art_deco_cream: Material
var _mat_art_deco_coral: Material
var _mat_heritage_basalt: Material
var _mat_street_shop: Material
var _mat_residential_pastel: Material
var _mat_commercial: Material
var _mat_skyscraper_silver: Material
var _mat_hotel_luxury: Material

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
	# 1. Classic Marine Drive Art Deco (Cream & Terracotta Orange)
	_mat_art_deco_cream = _create_facade_mat(
		Color(0.86, 0.82, 0.73, 1.0),
		Color(0.95, 0.46, 0.14, 1.0),
		Color(0.10, 0.16, 0.22, 1.0),
		3.5, 0.65, 0.55, 1.3, 0.85, 0.12
	)
	
	# 2. Promenade Coastal Art Deco (Coral Pink & Ivory Trim)
	_mat_art_deco_coral = _create_facade_mat(
		Color(0.82, 0.58, 0.50, 1.0),
		Color(0.96, 0.92, 0.84, 1.0),
		Color(0.12, 0.18, 0.24, 1.0),
		3.6, 0.68, 0.58, 1.4, 0.88, 0.10
	)
	
	# 3. Victorian Gothic & Heritage Institutions (Mumbai Kurla Basalt & Teak)
	_mat_heritage_basalt = _create_facade_mat(
		Color(0.68, 0.60, 0.50, 1.0),
		Color(0.42, 0.35, 0.28, 1.0),
		Color(0.14, 0.15, 0.17, 1.0),
		4.2, 0.48, 0.65, 0.9, 0.40, 0.25
	)
	
	# 4. Bustling Mumbai Street Shops (Ochre Walls, Illuminated Shopfronts)
	_mat_street_shop = _create_facade_mat(
		Color(0.78, 0.68, 0.54, 1.0),
		Color(0.85, 0.30, 0.20, 1.0),
		Color(0.15, 0.18, 0.22, 1.0),
		3.2, 0.72, 0.52, 1.8, 0.70, 0.18
	)
	
	# 5. Coastal Residential Apartments (Mint Green / Pastel Yellow Plaster)
	_mat_residential_pastel = _create_facade_mat(
		Color(0.72, 0.78, 0.72, 1.0),
		Color(0.92, 0.90, 0.85, 1.0),
		Color(0.12, 0.16, 0.20, 1.0),
		3.2, 0.60, 0.52, 1.1, 0.80, 0.15
	)
	
	# 6. Modern Commercial Slate Concrete & Cyan Architectural Accent
	_mat_commercial = _create_facade_mat(
		Color(0.24, 0.28, 0.35, 1.0),
		Color(0.30, 0.70, 0.90, 1.0),
		Color(0.08, 0.14, 0.20, 1.0),
		3.8, 0.78, 0.68, 1.6, 0.92, 0.08
	)
	
	# 7. Modern Silver Mirrored Glass Skyscraper Curtain Wall
	_mat_skyscraper_silver = _create_facade_mat(
		Color(0.75, 0.78, 0.82, 1.0),
		Color(0.92, 0.95, 1.0, 1.0),
		Color(0.10, 0.16, 0.25, 1.0),
		4.0, 0.82, 0.75, 1.7, 0.95, 0.05
	)
	
	# 8. Seafront Luxury Hotels (Ivory Travertine Marble & Brass Spandrels)
	_mat_hotel_luxury = _create_facade_mat(
		Color(0.88, 0.85, 0.80, 1.0),
		Color(0.85, 0.68, 0.28, 1.0),
		Color(0.10, 0.20, 0.22, 1.0),
		3.8, 0.72, 0.62, 1.5, 0.88, 0.10
	)
	
	# Debug Materials
	var debug_colors := [
		Color(0.0, 0.85, 1.0, 1.0),
		Color(1.0, 0.75, 0.0, 1.0),
		Color(1.0, 0.35, 0.1, 1.0),
		Color(0.2, 0.95, 0.4, 1.0),
		Color(0.9, 0.25, 0.85, 1.0),
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

## Helper distance from 2D point (px, pz) to 2D line segment (ax, az)-(bx, bz)
func _dist_point_to_seg(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> Array:
	var dx: float = bx - ax
	var dz: float = bz - az
	var len_sq: float = dx * dx + dz * dz
	if len_sq < 0.0001:
		var d0: float = sqrt((px - ax) * (px - ax) + (pz - az) * (pz - az))
		return [d0, ax, az, 0.0, 0.0]
	var t: float = clampf(((px - ax) * dx + (pz - az) * dz) / len_sq, 0.0, 1.0)
	var proj_x: float = ax + t * dx
	var proj_z: float = az + t * dz
	var dist: float = sqrt((px - proj_x) * (px - proj_x) + (pz - proj_z) * (pz - proj_z))
	return [dist, proj_x, proj_z, dx, dz]

const MARINE_DRIVE_CORRIDOR: Array[Vector2] = [
	Vector2(-69.0, 2180.0), Vector2(-45.0, 1850.0), Vector2(-32.0, 1738.0),
	Vector2(-15.0, 1500.0), Vector2(-5.4, 1295.0), Vector2(4.0, 1050.0),
	Vector2(10.6, 852.0), Vector2(8.0, 630.0), Vector2(5.5, 409.0),
	Vector2(3.0, 200.0), Vector2(1.0, 50.0), Vector2(0.0, 0.0),
	Vector2(-15.0, -150.0), Vector2(-35.0, -350.0), Vector2(-57.3, -476.0),
	Vector2(-120.0, -650.0), Vector2(-220.0, -800.0), Vector2(-325.7, -923.0),
	Vector2(-600.0, -1120.0), Vector2(-1057.6, -1375.0)
]

const CROSS_STREET_VN: Array[Vector2] = [
	Vector2(9.0, 409.0), Vector2(80.0, 408.0), Vector2(180.0, 407.0), Vector2(320.0, 405.0), Vector2(480.0, 405.0)
]

const CROSS_STREET_MC: Array[Vector2] = [
	Vector2(-30.0, 1738.0), Vector2(100.0, 1730.0), Vector2(250.0, 1720.0), Vector2(450.0, 1715.0)
]

## Helper: tests whether 2D segment (p1-p2) intersects segment (q1-q2)
func _segments_intersect_2d(p1: Vector2, p2: Vector2, q1: Vector2, q2: Vector2) -> bool:
	var d1: float = (q2.x - q1.x) * (p1.y - q1.y) - (q2.y - q1.y) * (p1.x - q1.x)
	var d2: float = (q2.x - q1.x) * (p2.y - q1.y) - (q2.y - q1.y) * (p2.x - q1.x)
	var d3: float = (p2.x - p1.x) * (q1.y - p1.y) - (p2.y - p1.y) * (q1.x - p1.x)
	var d4: float = (p2.x - p1.x) * (q2.y - p1.y) - (p2.y - p1.y) * (q2.x - p1.x)
	return ((d1 > 0.0 and d2 < 0.0) or (d1 < 0.0 and d2 > 0.0)) and ((d3 > 0.0 and d4 < 0.0) or (d3 < 0.0 and d4 > 0.0))

## Rigorous road clearance and designated building plot verification
func _apply_road_clearance(raw_poly: Array, roads: Array) -> Array:
	if raw_poly.size() < 3:
		return []
		
	var pt_count: int = raw_poly.size()
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	for p in raw_poly:
		sum_x += float(p[0])
		sum_z += float(p[2])
	var cx: float = sum_x / float(pt_count)
	var cz: float = sum_z / float(pt_count)
	
	# 1. Marine Drive Queen's Necklace corridor check
	for i in range(MARINE_DRIVE_CORRIDOR.size() - 1):
		var p0: Vector2 = MARINE_DRIVE_CORRIDOR[i]
		var p1: Vector2 = MARINE_DRIVE_CORRIDOR[i + 1]
		var res: Array = _dist_point_to_seg(cx, cz, p0.x, p0.y, p1.x, p1.y)
		if float(res[0]) < 14.5:
			return [] # Centroid inside Marine Drive roadway or promenade
			
	# 2. Cross-streets check (Veer Nariman & Madam Cama)
	for i in range(CROSS_STREET_VN.size() - 1):
		var res_vn: Array = _dist_point_to_seg(cx, cz, CROSS_STREET_VN[i].x, CROSS_STREET_VN[i].y, CROSS_STREET_VN[i+1].x, CROSS_STREET_VN[i+1].y)
		if float(res_vn[0]) < 9.5:
			return [] # Centroid in Veer Nariman Road
	for i in range(CROSS_STREET_MC.size() - 1):
		var res_mc: Array = _dist_point_to_seg(cx, cz, CROSS_STREET_MC[i].x, CROSS_STREET_MC[i].y, CROSS_STREET_MC[i+1].x, CROSS_STREET_MC[i+1].y)
		if float(res_mc[0]) < 9.5:
			return [] # Centroid in Madam Cama Road
			
	# 3. Check centroid against tile road segments and junction nodes
	for r in roads:
		var pts: Array = r.get("points", [])
		var hw: float = float(r.get("width", 8.0)) * 0.5
		if pts.size() >= 2:
			var p_start = pts[0]
			var p_end = pts[pts.size() - 1]
			var d_start: float = sqrt((cx - float(p_start[0])) * (cx - float(p_start[0])) + (cz - float(p_start[2])) * (cz - float(p_start[2])))
			var d_end: float = sqrt((cx - float(p_end[0])) * (cx - float(p_end[0])) + (cz - float(p_end[2])) * (cz - float(p_end[2])))
			if d_start < (hw + 2.0) or d_end < (hw + 2.0):
				return [] # Centroid inside road intersection
				
			for i in range(pts.size() - 1):
				var res = _dist_point_to_seg(cx, cz, float(pts[i][0]), float(pts[i][2]), float(pts[i+1][0]), float(pts[i+1][2]))
				if float(res[0]) < (hw + 1.5):
					return [] # Centroid on road asphalt
					
	# 4. Check all footprint vertices against road corridors
	var max_infringe: float = 0.0
	var push_dir_x: float = 0.0
	var push_dir_z: float = 0.0
	
	for p in raw_poly:
		var px: float = float(p[0])
		var pz: float = float(p[2])
		
		# Check Marine Drive
		for i in range(MARINE_DRIVE_CORRIDOR.size() - 1):
			var res_md: Array = _dist_point_to_seg(px, pz, MARINE_DRIVE_CORRIDOR[i].x, MARINE_DRIVE_CORRIDOR[i].y, MARINE_DRIVE_CORRIDOR[i+1].x, MARINE_DRIVE_CORRIDOR[i+1].y)
			var d_md: float = float(res_md[0])
			var safe_md: float = 14.5
			if d_md < safe_md:
				var needed_md: float = safe_md - d_md
				if needed_md > max_infringe:
					max_infringe = needed_md
					var dir_len: float = sqrt((px - float(res_md[1])) * (px - float(res_md[1])) + (pz - float(res_md[2])) * (pz - float(res_md[2])))
					if dir_len > 0.001:
						push_dir_x = (px - float(res_md[1])) / dir_len
						push_dir_z = (pz - float(res_md[2])) / dir_len
						
		# Check tile roads
		for r in roads:
			var pts: Array = r.get("points", [])
			var safe_dist: float = float(r.get("width", 8.0)) * 0.5 + 2.0
			for i in range(pts.size() - 1):
				var res = _dist_point_to_seg(px, pz, float(pts[i][0]), float(pts[i][2]), float(pts[i+1][0]), float(pts[i+1][2]))
				var d: float = float(res[0])
				if d < safe_dist:
					var needed: float = safe_dist - d
					if needed > max_infringe:
						max_infringe = needed
						var dir_len: float = sqrt((px - float(res[1])) * (px - float(res[1])) + (pz - float(res[2])) * (pz - float(res[2])))
						if dir_len > 0.001:
							push_dir_x = (px - float(res[1])) / dir_len
							push_dir_z = (pz - float(res[2])) / dir_len
							
	# If deeply infringing (> 3.5m), cull immediately to avoid moving into other plots
	if max_infringe > 3.5:
		return []
		
	# If minor infringement (<= 3.5m), rigidly translate ENTIRE building (never distort vertices)
	var final_poly: Array = []
	var shift_x: float = push_dir_x * (max_infringe + 0.5) if max_infringe > 0.0 else 0.0
	var shift_z: float = push_dir_z * (max_infringe + 0.5) if max_infringe > 0.0 else 0.0
	
	for p in raw_poly:
		final_poly.append([float(p[0]) + shift_x, float(p[1]), float(p[2]) + shift_z])
		
	# 5. Strict Re-Verification: Ensure zero shifted vertices sit within safe distance of any road
	for p in final_poly:
		var qx: float = float(p[0])
		var qz: float = float(p[2])
		for i in range(MARINE_DRIVE_CORRIDOR.size() - 1):
			var res_md: Array = _dist_point_to_seg(qx, qz, MARINE_DRIVE_CORRIDOR[i].x, MARINE_DRIVE_CORRIDOR[i].y, MARINE_DRIVE_CORRIDOR[i+1].x, MARINE_DRIVE_CORRIDOR[i+1].y)
			if float(res_md[0]) < 13.5:
				return [] # Still in Marine Drive
		for r in roads:
			var pts: Array = r.get("points", [])
			var hw: float = float(r.get("width", 8.0)) * 0.5
			for i in range(pts.size() - 1):
				var res = _dist_point_to_seg(qx, qz, float(pts[i][0]), float(pts[i][2]), float(pts[i+1][0]), float(pts[i+1][2]))
				if float(res[0]) < (hw + 0.5):
					return [] # Still on road asphalt
					
	# 6. Edge Intersection Check: ensure no building wall intersects any road segment
	for i in range(final_poly.size()):
		var j: int = (i + 1) % final_poly.size()
		var bp1 := Vector2(float(final_poly[i][0]), float(final_poly[i][2]))
		var bp2 := Vector2(float(final_poly[j][0]), float(final_poly[j][2]))
		for r in roads:
			var pts: Array = r.get("points", [])
			for k in range(pts.size() - 1):
				var rp1 := Vector2(float(pts[k][0]), float(pts[k][2]))
				var rp2 := Vector2(float(pts[k+1][0]), float(pts[k+1][2]))
				if _segments_intersect_2d(bp1, bp2, rp1, rp2):
					return [] # Building wall intersects road centerline, cull
					
	return final_poly

## Computes 2D polygon area using Shoelace formula
func _calc_poly_area(pts: Array) -> float:
	var n: int = pts.size()
	if n < 3:
		return 0.0
	var area: float = 0.0
	for i in range(n):
		var j: int = (i + 1) % n
		area += float(pts[i][0]) * float(pts[j][2]) - float(pts[j][0]) * float(pts[i][2])
	return absf(area) * 0.5

## Generates a visible 3D building with 1 single draw call and distance LOD culling
func generate_building_from_tile_data(b_data: Dictionary, roads_in_tile: Array = []) -> Node3D:
	total_features_read += 1
	
	var raw_poly: Array = b_data.get("footprint", b_data.get("polygon", []))
	if raw_poly.size() < 3:
		return null
		
	# Apply strict road clearance & designated plot boundary placement
	raw_poly = _apply_road_clearance(raw_poly, roads_in_tile)
	if raw_poly.size() < 3:
		return null
		
	var area: float = _calc_poly_area(raw_poly)
	if area < 16.0:
		return null # Filter slivers
		
	valid_polygons += 1
	
	var b_type: String = str(b_data.get("type", b_data.get("building_type", "residential"))).to_lower()
	var b_name: String = str(b_data.get("name", "Building"))
	var is_estimated: bool = bool(b_data.get("estimated", true))
	var height: float = float(b_data.get("height", 14.0))
	
	# Centroid calculation
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	var pt_count: int = raw_poly.size()
	var is_closed: bool = (pt_count > 3 and 
		absf(float(raw_poly[0][0]) - float(raw_poly[pt_count - 1][0])) < 0.01 and 
		absf(float(raw_poly[0][2]) - float(raw_poly[pt_count - 1][2])) < 0.01)
	var count_for_center: int = (pt_count - 1) if is_closed else pt_count
	
	for i in range(count_for_center):
		sum_x += float(raw_poly[i][0])
		sum_z += float(raw_poly[i][2])
		
	var center := Vector3(sum_x / float(count_for_center), 0.0, sum_z / float(count_for_center))
	var pos_hash: int = abs(int(center.x * 31.0 + center.z * 17.0))
	
	# Authentic Mumbai Height Variation
	if is_estimated or height == 14.0 or height == 22.0:
		if b_type == "hotel":
			height = 36.0 + float(pos_hash % 8) * 4.0
		elif b_type in ["commercial", "office"]:
			if area > 800.0 or center.z > 1400.0:
				height = 55.0 + float(pos_hash % 12) * 6.5
			else:
				height = 28.0 + float(pos_hash % 6) * 3.5
		elif b_type in ["school", "university", "civic", "courthouse", "heritage"]:
			height = 16.0 + float(pos_hash % 4) * 2.5
		elif b_type in ["retail", "shop", "kiosk"]:
			height = 8.0 + float(pos_hash % 4) * 1.5
		else:
			if area < 140.0:
				height = 9.0 + float(pos_hash % 3) * 2.0
			elif area < 450.0:
				height = 18.0 + float(pos_hash % 5) * 3.0
			elif area < 900.0:
				height = 32.0 + float(pos_hash % 7) * 4.0
			else:
				height = 58.0 + float(pos_hash % 10) * 7.0
	height = maxf(height, 7.5)
	
	# Convert footprint points to local space relative to center
	var local_pts: PackedVector3Array = []
	for i in range(count_for_center):
		var p = raw_poly[i]
		local_pts.append(Vector3(float(p[0]) - center.x, 0.0, float(p[2]) - center.z))
	local_pts.append(local_pts[0])
	
	# Extrude visible 3D mesh with parapets and integrated rooftop structures
	var mesh := _extrude_building_mesh(local_pts, height, pos_hash)
	if not mesh:
		return null
		
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Bld_" + b_name.replace(" ", "_")
	mesh_inst.position = center
	mesh_inst.mesh = mesh
	
	# Distance LOD culling for buildings (prevents distant GPU fillrate stalls)
	mesh_inst.visibility_range_end = 450.0
	mesh_inst.visibility_range_end_margin = 30.0
	
	# Architectural Style & Material Assignment
	var chosen_mat: Material
	if debug_bright_materials and _debug_mats.size() > 0:
		var hash_idx: int = pos_hash % _debug_mats.size()
		chosen_mat = _debug_mats[hash_idx]
	elif building_material:
		chosen_mat = building_material
	else:
		if b_type == "hotel":
			chosen_mat = _mat_hotel_luxury
		elif b_type in ["commercial", "office"]:
			chosen_mat = _mat_skyscraper_silver if height > 55.0 else _mat_commercial
		elif b_type in ["civic", "courthouse", "monument", "university", "school", "heritage", "place_of_worship"]:
			chosen_mat = _mat_heritage_basalt
		elif b_type in ["retail", "shop", "kiosk"]:
			chosen_mat = _mat_street_shop
		else:
			if center.x >= 5.0 and center.x <= 130.0 and center.z >= -1400.0 and center.z <= 2200.0:
				var deco_variant: int = pos_hash % 3
				match deco_variant:
					0: chosen_mat = _mat_art_deco_cream
					1: chosen_mat = _mat_art_deco_coral
					_: chosen_mat = _mat_hotel_luxury
			elif area < 160.0:
				chosen_mat = _mat_street_shop
			elif height > 55.0:
				chosen_mat = _mat_skyscraper_silver
			else:
				var res_variant: int = pos_hash % 4
				match res_variant:
					0: chosen_mat = _mat_art_deco_cream
					1: chosen_mat = _mat_art_deco_coral
					2: chosen_mat = _mat_residential_pastel
					_: chosen_mat = _mat_heritage_basalt
					
	mesh_inst.material_override = chosen_mat
	
	# Optimized Static Collision: Only add collision for buildings within 35m of drivable road
	if absf(center.x) <= 35.0:
		var aabb := mesh.get_aabb()
		if aabb.size.x > 1.0 and aabb.size.z > 1.0:
			var static_body := StaticBody3D.new()
			static_body.name = "Collision"
			static_body.collision_layer = 1
			static_body.collision_mask = 0
			
			var col_shape := CollisionShape3D.new()
			var box_shape := BoxShape3D.new()
			box_shape.size = Vector3(aabb.size.x, height, aabb.size.z)
			col_shape.shape = box_shape
			col_shape.position = Vector3(0, height * 0.5, 0)
			static_body.add_child(col_shape)
			mesh_inst.add_child(static_body)
			
	meshes_created += 1
	visible_buildings += 1
	return mesh_inst

## Extrudes walls, roof, parapet, and integrated rooftop penthouse into 1 single ArrayMesh
func _extrude_building_mesh(local_pts: PackedVector3Array, height: float, pos_hash: int) -> ArrayMesh:
	var count := local_pts.size()
	if count < 3:
		return null
		
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var parapet_height: float = 0.9
	
	# 1. Extrude Vertical Walls
	for i in range(count - 1):
		var p1 := local_pts[i]
		var p2 := local_pts[i + 1]
		
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
		
		# Rooftop Parapet Wall (t1 -> pr1 -> pr2 -> t2)
		var pr1 := Vector3(p1.x, height + parapet_height, p1.z)
		var pr2 := Vector3(p2.x, height + parapet_height, p2.z)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, uv_v))
		st.add_vertex(t1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, uv_v + 0.3))
		st.add_vertex(pr1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(uv_scale, uv_v))
		st.add_vertex(t2)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, uv_v + 0.3))
		st.add_vertex(pr1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(uv_scale, uv_v + 0.3))
		st.add_vertex(pr2)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(uv_scale, uv_v))
		st.add_vertex(t2)
		
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

	# 3. Integrated Rooftop Elevator Penthouse (for buildings height >= 16m)
	if height >= 16.0:
		var ph_w := 4.0
		var ph_d := 4.0
		var ph_h := 3.2
		var ph_base_y := height
		var ph_top_y := height + ph_h
		
		var cx := float((pos_hash % 3) - 1) * 1.5
		var cz := float(((pos_hash / 3) % 3) - 1) * 1.5
		
		var c0 := Vector3(cx - ph_w*0.5, ph_base_y, cz - ph_d*0.5)
		var c1 := Vector3(cx + ph_w*0.5, ph_base_y, cz - ph_d*0.5)
		var c2 := Vector3(cx + ph_w*0.5, ph_base_y, cz + ph_d*0.5)
		var c3 := Vector3(cx - ph_w*0.5, ph_base_y, cz + ph_d*0.5)
		
		var t0 := Vector3(c0.x, ph_top_y, c0.z)
		var t1 := Vector3(c1.x, ph_top_y, c1.z)
		var t2 := Vector3(c2.x, ph_top_y, c2.z)
		var t3 := Vector3(c3.x, ph_top_y, c3.z)
		
		var ph_quads := [
			[c0, t0, t1, c1, Vector3.FORWARD], # South
			[c1, t1, t2, c2, Vector3.RIGHT],   # East
			[c2, t2, t3, c3, Vector3.BACK],    # North
			[c3, t3, t0, c0, Vector3.LEFT],    # West
			[t0, t3, t2, t1, Vector3.UP]       # Penthouse Top Roof
		]
		
		for q in ph_quads:
			var n: Vector3 = q[4]
			st.set_normal(n)
			st.set_uv(Vector2(0, 0))
			st.add_vertex(q[0])
			st.set_normal(n)
			st.set_uv(Vector2(0, 1))
			st.add_vertex(q[1])
			st.set_normal(n)
			st.set_uv(Vector2(1, 1))
			st.add_vertex(q[2])
			
			st.set_normal(n)
			st.set_uv(Vector2(0, 0))
			st.add_vertex(q[0])
			st.set_normal(n)
			st.set_uv(Vector2(1, 1))
			st.add_vertex(q[2])
			st.set_normal(n)
			st.set_uv(Vector2(1, 0))
			st.add_vertex(q[3])
		
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
