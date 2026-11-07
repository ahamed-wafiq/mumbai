class_name MumbaiCityBuilder
extends Node3D

## MumbaiCityBuilder
## Procedurally constructs the authentic, geographically accurate Marine Drive
## (Queen's Necklace) urban corridor with dense road curves, lane markings,
## sidewalks, seaside promenade, streetlights, and buildings flanking both sides.

@export var build_on_ready: bool = true

# Shader preloads for advanced rendering
var _asphalt_shader: Shader = preload("res://assets/shaders/asphalt_road.gdshader")
var _facade_shader: Shader = preload("res://assets/shaders/building_facade.gdshader")

# Materials
var mat_asphalt: Material
var mat_yellow_line: StandardMaterial3D
var mat_white_line: StandardMaterial3D
var mat_sidewalk: StandardMaterial3D
var mat_seawall: StandardMaterial3D
var mat_art_deco_cream: Material
var mat_art_deco_terracotta: Material
var mat_modern_glass: Material
var mat_heritage_stone: Material
var mat_window: StandardMaterial3D
var mat_lamp_glow: StandardMaterial3D
var _geo: GeoConverter

func _ready() -> void:
	_geo = GeoConverter.new(18.9437, 72.8232)
	_init_materials()
	if build_on_ready:
		build_city()

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
	# 1. High-Fidelity Coastal Wet Asphalt Road Shader
	if _asphalt_shader:
		var road_sm := ShaderMaterial.new()
		road_sm.shader = _asphalt_shader
		road_sm.set_shader_parameter("asphalt_color", Color(0.04, 0.04, 0.045, 1.0))
		road_sm.set_shader_parameter("tire_track_color", Color(0.02, 0.02, 0.025, 1.0))
		road_sm.set_shader_parameter("wetness_sheen", 0.35)
		road_sm.set_shader_parameter("road_roughness", 0.75)
		mat_asphalt = road_sm
	else:
		var default_asphalt := StandardMaterial3D.new()
		default_asphalt.albedo_color = Color(0.04, 0.04, 0.045, 1.0)
		default_asphalt.roughness = 0.8
		default_asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat_asphalt = default_asphalt
	
	mat_yellow_line = StandardMaterial3D.new()
	mat_yellow_line.albedo_color = Color(1.0, 0.75, 0.08, 1.0)
	mat_yellow_line.emission_enabled = true
	mat_yellow_line.emission = Color(1.0, 0.75, 0.08, 1.0)
	mat_yellow_line.emission_energy_multiplier = 1.2
	mat_yellow_line.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat_white_line = StandardMaterial3D.new()
	mat_white_line.albedo_color = Color(0.96, 0.97, 0.99, 1.0)
	mat_white_line.emission_enabled = true
	mat_white_line.emission = Color(0.96, 0.97, 0.99, 1.0)
	mat_white_line.emission_energy_multiplier = 0.8
	mat_white_line.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Art Deco Promenade Pavers
	mat_sidewalk = StandardMaterial3D.new()
	mat_sidewalk.albedo_color = Color(0.55, 0.52, 0.48, 1.0)
	mat_sidewalk.roughness = 0.65
	mat_sidewalk.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# Marine Drive Seawall Granite / Basalt
	mat_seawall = StandardMaterial3D.new()
	mat_seawall.albedo_color = Color(0.48, 0.50, 0.52, 1.0)
	mat_seawall.roughness = 0.55
	mat_seawall.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	# 2. Architectural Facade Shaders for Landmark Buildings
	mat_art_deco_cream = _create_facade_mat(
		Color(0.85, 0.80, 0.70, 1.0), Color(0.95, 0.48, 0.15, 1.0), Color(0.10, 0.16, 0.22, 1.0),
		3.5, 0.65, 0.55, 1.3, 0.85, 0.12
	)
	
	mat_art_deco_terracotta = _create_facade_mat(
		Color(0.78, 0.52, 0.40, 1.0), Color(0.95, 0.80, 0.65, 1.0), Color(0.12, 0.18, 0.20, 1.0),
		3.6, 0.70, 0.60, 1.4, 0.88, 0.10
	)
	
	mat_modern_glass = _create_facade_mat(
		Color(0.24, 0.28, 0.35, 1.0), Color(0.30, 0.70, 0.90, 1.0), Color(0.08, 0.14, 0.20, 1.0),
		3.8, 0.75, 0.65, 1.6, 0.92, 0.08
	)
	
	mat_heritage_stone = _create_facade_mat(
		Color(0.70, 0.62, 0.52, 1.0), Color(0.48, 0.40, 0.32, 1.0), Color(0.15, 0.16, 0.18, 1.0),
		4.2, 0.50, 0.65, 0.9, 0.40, 0.25
	)
	
	mat_window = StandardMaterial3D.new()
	mat_window.albedo_color = Color(0.1, 0.15, 0.2, 1.0)
	mat_window.metallic = 0.9
	mat_window.roughness = 0.15
	
	# Queen's Necklace Streetlamp Warm Golden Glow
	mat_lamp_glow = StandardMaterial3D.new()
	mat_lamp_glow.albedo_color = Color(1.0, 0.88, 0.65, 1.0)
	mat_lamp_glow.emission_enabled = true
	mat_lamp_glow.emission = Color(1.0, 0.88, 0.65, 1.0)
	mat_lamp_glow.emission_energy_multiplier = 5.0

## Builds the full Marine Drive urban corridor
func build_city() -> void:
	# 1. Densely sampled spline points along Marine Drive (every 12m)
	var spline_points := _get_dense_marine_drive_spline()
	
	# 2. Build Road & Promenade meshes
	_build_marine_drive_road(spline_points)
	
	# 3. Build cross-streets (Veer Nariman Rd, Madam Cama Rd)
	_build_cross_streets()
	
	# 4. Build real architectural buildings flanking the road
	_build_all_buildings(spline_points)
	
	# 5. Place streetlights along both sides
	_build_streetlights(spline_points)

## Densely sampled curve points along the Queen's Necklace (12m spacing)
func _get_dense_marine_drive_spline() -> PackedVector3Array:
	var control_nodes: Array[Vector3] = [
		Vector3(-69.0, 0.05, 2180.0),   # Nariman Point / NCPA
		Vector3(-45.0, 0.05, 1850.0),   # Air India approach
		Vector3(-32.0, 0.05, 1738.0),   # Express Towers / Trident
		Vector3(-15.0, 0.05, 1500.0),   # Marine Plaza Hotel
		Vector3(-5.4, 0.05, 1295.0),    # Sea Green Hotel
		Vector3(4.0, 0.05, 1050.0),     # Kapur Mahal / Zaver Mahal
		Vector3(10.6, 0.05, 852.0),     # Brabourne / InterContinental
		Vector3(8.0, 0.05, 630.0),      # Keval Mahal / Soona Mahal
		Vector3(5.5, 0.05, 409.0),      # Wankhede / Veer Nariman junction
		Vector3(3.0, 0.05, 200.0),      # Churchgate promenade approach
		Vector3(1.0, 0.05, 50.0),       # Near player spawn
		Vector3(0.0, 0.05, 0.0),        # Marine Drive midpoint
		Vector3(-15.0, 0.05, -150.0),   # Taraporewala Aquarium approach
		Vector3(-35.0, 0.05, -350.0),   # Princess Street curve
		Vector3(-57.3, 0.05, -476.0),   # Princess Street Flyover
		Vector3(-120.0, 0.05, -650.0),  # Marine Lines curve
		Vector3(-220.0, 0.05, -800.0),  # Charni Road coastal bend
		Vector3(-325.7, 0.05, -923.0),  # Wilson College curve
		Vector3(-600.0, 0.05, -1120.0), # Walkeshwar approach
		Vector3(-1057.6, 0.05, -1375.0) # Girgaon Chowpatty beach
	]
	
	var dense := PackedVector3Array()
	var step_size := 12.0
	
	for i in range(control_nodes.size() - 1):
		var p0 := control_nodes[max(0, i - 1)]
		var p1 := control_nodes[i]
		var p2 := control_nodes[i + 1]
		var p3 := control_nodes[min(control_nodes.size() - 1, i + 2)]
		
		var dist := p1.distance_to(p2)
		var segments := int(ceil(dist / step_size))
		
		for s in range(segments):
			var t := float(s) / float(segments)
			var pt := _catmull_rom(p0, p1, p2, p3, t)
			dense.append(pt)
			
	dense.append(control_nodes[control_nodes.size() - 1])
	return dense

func _catmull_rom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)

## Builds 18m asphalt road, center yellow double-line, white lane dashes,
## curbs, sidewalks, and seaside promenade wall with collision
func _build_marine_drive_road(points: PackedVector3Array) -> void:
	var road_root := Node3D.new()
	road_root.name = "MarineDriveRoadNetwork"
	add_child(road_root)
	
	var road_width := 18.0
	var sidewalk_width := 4.5
	
	# 1. Main Asphalt Surface Mesh (Y = 0.06)
	var road_mesh := _extrude_ribbon(points, road_width, 0.06)
	var road_inst := MeshInstance3D.new()
	road_inst.name = "AsphaltSurface"
	road_inst.mesh = road_mesh
	road_inst.material_override = mat_asphalt
	road_root.add_child(road_inst)
	
	# Solid Static Collision for drivable road surface
	var road_col := StaticBody3D.new()
	road_col.name = "RoadCollision"
	road_col.collision_layer = 1
	road_col.collision_mask = 0
	var shape := CollisionShape3D.new()
	shape.shape = road_mesh.create_trimesh_shape()
	road_col.add_child(shape)
	road_root.add_child(road_col)
	
	# 2. Yellow Double Center Divider Line (Y = 0.08)
	var yellow_mesh := _extrude_ribbon(points, 0.4, 0.08)
	var yellow_inst := MeshInstance3D.new()
	yellow_inst.name = "CenterDividerYellow"
	yellow_inst.mesh = yellow_mesh
	yellow_inst.material_override = mat_yellow_line
	road_root.add_child(yellow_inst)
	
	# 3. White Lane Dashes (Left & Right Lanes at Y = 0.075)
	var white_left := _extrude_offset_ribbon(points, -4.5, 0.25, 0.075)
	var white_left_inst := MeshInstance3D.new()
	white_left_inst.name = "WhiteLaneDashLeft"
	white_left_inst.mesh = white_left
	white_left_inst.material_override = mat_white_line
	road_root.add_child(white_left_inst)
	
	var white_right := _extrude_offset_ribbon(points, 4.5, 0.25, 0.075)
	var white_right_inst := MeshInstance3D.new()
	white_right_inst.name = "WhiteLaneDashRight"
	white_right_inst.mesh = white_right
	white_right_inst.material_override = mat_white_line
	road_root.add_child(white_right_inst)
	
	# 4. East Sidewalk (City side adjacent to buildings)
	var east_offset := (road_width * 0.5) + (sidewalk_width * 0.5)
	var east_walk := _extrude_offset_ribbon(points, east_offset, sidewalk_width, 0.18)
	var east_walk_inst := MeshInstance3D.new()
	east_walk_inst.name = "SidewalkEast"
	east_walk_inst.mesh = east_walk
	east_walk_inst.material_override = mat_sidewalk
	road_root.add_child(east_walk_inst)
	
	# 5. West Sidewalk & Promenade (Sea side overlooking Arabian Sea)
	var west_offset := -((road_width * 0.5) + (sidewalk_width * 0.5))
	var west_walk := _extrude_offset_ribbon(points, west_offset, sidewalk_width, 0.18)
	var west_walk_inst := MeshInstance3D.new()
	west_walk_inst.name = "PromenadeSidewalkWest"
	west_walk_inst.mesh = west_walk
	west_walk_inst.material_override = mat_sidewalk
	road_root.add_child(west_walk_inst)
	
	# 6. Sea Wall Barrier Wall along Promenade edge
	var seawall_offset := -((road_width * 0.5) + sidewalk_width + 0.35)
	var seawall_mesh := _extrude_offset_ribbon(points, seawall_offset, 0.7, 0.85)
	var seawall_inst := MeshInstance3D.new()
	seawall_inst.name = "SeaWallBarrier"
	seawall_inst.mesh = seawall_mesh
	seawall_inst.material_override = mat_seawall
	road_root.add_child(seawall_inst)
	
	var seawall_col := StaticBody3D.new()
	seawall_col.collision_layer = 1
	var sw_shape := CollisionShape3D.new()
	sw_shape.shape = seawall_mesh.create_trimesh_shape()
	seawall_col.add_child(sw_shape)
	road_root.add_child(seawall_col)

## Builds connecting cross-streets (Veer Nariman Road, Madam Cama Road)
func _build_cross_streets() -> void:
	var cross_root := Node3D.new()
	cross_root.name = "CrossStreets"
	add_child(cross_root)
	
	# 1. Veer Nariman Road (Churchgate link heading east into Fort)
	var vn_pts := PackedVector3Array([
		Vector3(9.0, 0.06, 409.0),
		Vector3(80.0, 0.06, 408.0),
		Vector3(180.0, 0.06, 407.0),
		Vector3(320.0, 0.06, 405.0),
		Vector3(480.0, 0.06, 405.0)
	])
	var vn_mesh := _extrude_ribbon(vn_pts, 15.0, 0.06)
	var vn_inst := MeshInstance3D.new()
	vn_inst.name = "VeerNarimanRoad"
	vn_inst.mesh = vn_mesh
	vn_inst.material_override = mat_asphalt
	cross_root.add_child(vn_inst)
	
	var vn_col := StaticBody3D.new()
	vn_col.collision_layer = 1
	var vn_shape := CollisionShape3D.new()
	vn_shape.shape = vn_mesh.create_trimesh_shape()
	vn_col.add_child(vn_shape)
	cross_root.add_child(vn_col)
	
	# Yellow line on Veer Nariman Rd
	var vn_yellow := _extrude_ribbon(vn_pts, 0.35, 0.08)
	var vn_y_inst := MeshInstance3D.new()
	vn_y_inst.mesh = vn_yellow
	vn_y_inst.material_override = mat_yellow_line
	cross_root.add_child(vn_y_inst)
	
	# 2. Madam Cama Road (Mantralaya link)
	var mc_pts := PackedVector3Array([
		Vector3(-30.0, 0.06, 1738.0),
		Vector3(100.0, 0.06, 1730.0),
		Vector3(250.0, 0.06, 1720.0),
		Vector3(450.0, 0.06, 1715.0)
	])
	var mc_mesh := _extrude_ribbon(mc_pts, 15.0, 0.06)
	var mc_inst := MeshInstance3D.new()
	mc_inst.name = "MadamCamaRoad"
	mc_inst.mesh = mc_mesh
	mc_inst.material_override = mat_asphalt
	cross_root.add_child(mc_inst)
	
	var mc_col := StaticBody3D.new()
	mc_col.collision_layer = 1
	var mc_shape := CollisionShape3D.new()
	mc_shape.shape = mc_mesh.create_trimesh_shape()
	mc_col.add_child(mc_shape)
	cross_root.add_child(mc_col)

## Builds real architectural landmark buildings directly from GeoJSON footprints
func _build_all_buildings(_points: PackedVector3Array) -> void:
	var buildings_root := Node3D.new()
	buildings_root.name = "RealMumbaiLandmarks"
	add_child(buildings_root)
	
	var geojson_path := "res://data/geojson/mumbai_buildings.geojson"
	var loaded_from_geojson := false
	
	if FileAccess.file_exists(geojson_path):
		var file := FileAccess.open(geojson_path, FileAccess.READ)
		if file:
			var json_obj := JSON.new()
			if json_obj.parse(file.get_as_text()) == OK:
				var data: Dictionary = json_obj.data
				var features: Array = data.get("features", [])
				print("[MumbaiCityBuilder] Loading %d real landmark footprints from %s..." % [features.size(), geojson_path])
				
				for feat in features:
					var props: Dictionary = feat.get("properties", {})
					var geom: Dictionary = feat.get("geometry", {})
					var b_name: String = str(props.get("name", "Landmark Building"))
					var height: float = maxf(float(props.get("height", 24.0)), 8.0)
					var b_type: String = str(props.get("building", "commercial"))
					
					var coords_list: Array = geom.get("coordinates", [])
					if coords_list.size() > 0 and coords_list[0].size() >= 3:
						var ring: Array = coords_list[0]
						var world_pts: PackedVector3Array = []
						for pt in ring:
							var lon: float = float(pt[0])
							var lat: float = float(pt[1])
							var wpos := _geo.geo_to_world(lat, lon, 0.0)
							world_pts.append(wpos)
							
						var b_node := _create_real_footprint_building(b_name, world_pts, height, b_type)
						if b_node:
							buildings_root.add_child(b_node)
							loaded_from_geojson = true
							
	if not loaded_from_geojson:
		print("[MumbaiCityBuilder] Landmark GeoJSON not found, skipping corridor landmarks.")

## Extrudes a true polygon footprint into a 3D architectural building
func _create_real_footprint_building(b_name: String, world_pts: PackedVector3Array, height: float, b_type: String) -> Node3D:
	var count := world_pts.size()
	if count < 3:
		return null
		
	# Road setback: ensure landmark buildings never overlap the Marine Drive curve or cross-streets
	var md_spline: PackedVector3Array = _get_dense_marine_drive_spline()
	var vn_pts: PackedVector3Array = PackedVector3Array([
		Vector3(9.0, 0.06, 409.0), Vector3(80.0, 0.06, 408.0), Vector3(180.0, 0.06, 407.0), Vector3(320.0, 0.06, 405.0), Vector3(480.0, 0.06, 405.0)
	])
	var mc_pts: PackedVector3Array = PackedVector3Array([
		Vector3(-30.0, 0.06, 1738.0), Vector3(100.0, 0.06, 1730.0), Vector3(250.0, 0.06, 1720.0), Vector3(450.0, 0.06, 1715.0)
	])
	
	var max_infringe: float = 0.0
	var push_dir_x: float = 0.0
	var push_dir_z: float = 0.0
	
	for i in range(count):
		var px: float = world_pts[i].x
		var pz: float = world_pts[i].z
		
		# Check Marine Drive (18m road + 4.5m sidewalk + 1.5m buffer -> safe dist 15.0m)
		for j in range(md_spline.size() - 1):
			var ax: float = md_spline[j].x
			var az: float = md_spline[j].z
			var bx: float = md_spline[j + 1].x
			var bz: float = md_spline[j + 1].z
			var dx: float = bx - ax
			var dz: float = bz - az
			var l2: float = dx * dx + dz * dz
			var t: float = clampf(((px - ax) * dx + (pz - az) * dz) / maxf(l2, 0.0001), 0.0, 1.0)
			var proj_x: float = ax + t * dx
			var proj_z: float = az + t * dz
			var dist: float = sqrt((px - proj_x) * (px - proj_x) + (pz - proj_z) * (pz - proj_z))
			if dist < 15.0:
				var needed: float = 15.0 - dist
				if needed > max_infringe:
					max_infringe = needed
					var dlen: float = sqrt((px - proj_x) * (px - proj_x) + (pz - proj_z) * (pz - proj_z))
					if dlen > 0.001:
						push_dir_x = (px - proj_x) / dlen
						push_dir_z = (pz - proj_z) / dlen
						
		# Check Madam Cama & Veer Nariman cross-streets (safe dist 9.5m)
		for cr in [vn_pts, mc_pts]:
			for j in range(cr.size() - 1):
				var ax: float = cr[j].x
				var az: float = cr[j].z
				var bx: float = cr[j + 1].x
				var bz: float = cr[j + 1].z
				var dx: float = bx - ax
				var dz: float = bz - az
				var l2: float = dx * dx + dz * dz
				var t: float = clampf(((px - ax) * dx + (pz - az) * dz) / maxf(l2, 0.0001), 0.0, 1.0)
				var proj_x: float = ax + t * dx
				var proj_z: float = az + t * dz
				var dist: float = sqrt((px - proj_x) * (px - proj_x) + (pz - proj_z) * (pz - proj_z))
				if dist < 9.5:
					var needed: float = 9.5 - dist
					if needed > max_infringe:
						max_infringe = needed
						var dlen: float = sqrt((px - proj_x) * (px - proj_x) + (pz - proj_z) * (pz - proj_z))
						if dlen > 0.001:
							push_dir_x = (px - proj_x) / dlen
							push_dir_z = (pz - proj_z) / dlen
							
	if max_infringe > 6.0:
		return null # Deeply blocking road, cull landmark
		
	if max_infringe > 0.0:
		var shift_x: float = push_dir_x * (max_infringe + 1.0)
		var shift_z: float = push_dir_z * (max_infringe + 1.0)
		for i in range(count):
			world_pts[i].x += shift_x
			world_pts[i].z += shift_z
		
	# Compute centroid
	var sum_x: float = 0.0
	var sum_z: float = 0.0
	for i in range(count - 1):
		sum_x += world_pts[i].x
		sum_z += world_pts[i].z
	var center := Vector3(sum_x / float(max(1, count - 1)), 0.0, sum_z / float(max(1, count - 1)))
	
	# Local points relative to center
	var local_pts: PackedVector3Array = []
	for i in range(count - 1):
		local_pts.append(Vector3(world_pts[i].x - center.x, 0.0, world_pts[i].z - center.z))
	local_pts.append(local_pts[0]) # Close loop
	
	var body := StaticBody3D.new()
	body.name = "Landmark_" + b_name.replace(" ", "_").replace("/", "_").replace("(", "").replace(")", "")
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	
	# Choose material
	var facade_mat := mat_modern_glass
	match b_type:
		"heritage", "monument", "stadium", "university", "civic":
			facade_mat = mat_heritage_stone
		"apartments", "residential":
			facade_mat = mat_art_deco_cream
		"hotel":
			facade_mat = mat_art_deco_terracotta
		_:
			facade_mat = mat_modern_glass
			
	# Extrude 3D building mesh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Walls
	for i in range(local_pts.size() - 1):
		var p1 := local_pts[i]
		var p2 := local_pts[i + 1]
		if p1.distance_squared_to(p2) < 0.001:
			continue
			
		var b1 := Vector3(p1.x, 0.0, p1.z)
		var b2 := Vector3(p2.x, 0.0, p2.z)
		var t1 := Vector3(p1.x, height, p1.z)
		var t2 := Vector3(p2.x, height, p2.z)
		
		var edge := (b2 - b1).normalized()
		var wall_norm := edge.cross(Vector3.UP).normalized()
		var uv_u := (b2 - b1).length() / 4.0
		var uv_v := height / 3.5
		
		st.set_normal(wall_norm)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(b1)
		
		st.set_normal(wall_norm)
		st.set_uv(Vector2(0, uv_v))
		st.add_vertex(t1)
		
		st.set_normal(wall_norm)
		st.set_uv(Vector2(uv_u, 0))
		st.add_vertex(b2)
		
		st.set_normal(wall_norm)
		st.set_uv(Vector2(0, uv_v))
		st.add_vertex(t1)
		
		st.set_normal(wall_norm)
		st.set_uv(Vector2(uv_u, uv_v))
		st.add_vertex(t2)
		
		st.set_normal(wall_norm)
		st.set_uv(Vector2(uv_u, 0))
		st.add_vertex(b2)
		
	# Roof
	var roof_center := Vector3(0.0, height, 0.0)
	for i in range(local_pts.size() - 1):
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
	var mesh := st.commit()
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "Facade"
	mesh_inst.mesh = mesh
	mesh_inst.material_override = facade_mat
	body.add_child(mesh_inst)
	
	# Collision
	var shape := mesh.create_trimesh_shape()
	if shape:
		var col := CollisionShape3D.new()
		col.shape = shape
		body.add_child(col)
		
	return body

## Places coastal lampposts every 25 meters along both sides of Marine Drive
func _build_streetlights(points: PackedVector3Array) -> void:
	var lights_root := Node3D.new()
	lights_root.name = "StreetLights"
	add_child(lights_root)
	
	var pole_mesh := CylinderMesh.new()
	pole_mesh.top_radius = 0.08
	pole_mesh.bottom_radius = 0.12
	pole_mesh.height = 6.0
	var pole_mat := StandardMaterial3D.new()
	pole_mat.albedo_color = Color(0.18, 0.2, 0.22, 1.0)
	pole_mat.metallic = 0.8
	pole_mesh.material = pole_mat
	
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.25
	bulb_mesh.height = 0.5
	bulb_mesh.material = mat_lamp_glow
	
	# Place lamp every other waypoint (~24 meters)
	for i in range(0, points.size() - 1, 2):
		var p := points[i]
		var forward := Vector3.FORWARD
		if i < points.size() - 1:
			forward = (points[i + 1] - p).normalized()
		var right := forward.cross(Vector3.UP).normalized()
		
		# Lamp on Promenade edge
		var p_sea := p - (right * 11.5)
		_create_lamp_post(lights_root, p_sea, pole_mesh, bulb_mesh)
		
		# Lamp on City sidewalk edge
		var p_city := p + (right * 11.5)
		_create_lamp_post(lights_root, p_city, pole_mesh, bulb_mesh)

func _create_lamp_post(parent: Node3D, pos: Vector3, pole_mesh: Mesh, bulb_mesh: Mesh) -> void:
	var lamp := Node3D.new()
	lamp.position = pos
	
	var pole := MeshInstance3D.new()
	pole.mesh = pole_mesh
	pole.position = Vector3(0.0, 3.0, 0.0)
	lamp.add_child(pole)
	
	var bulb := MeshInstance3D.new()
	bulb.mesh = bulb_mesh
	bulb.position = Vector3(0.0, 5.8, 0.0)
	lamp.add_child(bulb)
	
	var omni := OmniLight3D.new()
	omni.light_color = Color(1.0, 0.88, 0.72, 1.0)
	omni.light_energy = 2.2
	omni.omni_range = 18.0
	omni.omni_attenuation = 1.3
	omni.position = Vector3(0.0, 5.5, 0.0)
	lamp.add_child(omni)
	
	parent.add_child(lamp)

## Extrudes a flat ribbon mesh with correct COUNTER-CLOCKWISE winding order (front-facing from above)
func _extrude_ribbon(points: PackedVector3Array, width: float, y_elev: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_w := width * 0.5
	var count := points.size()
	
	for i in range(count):
		var p := points[i]
		var forward := Vector3.FORWARD
		if i < count - 1:
			forward = (points[i + 1] - p).normalized()
		elif i > 0:
			forward = (p - points[i - 1]).normalized()
		var right := forward.cross(Vector3.UP).normalized()
		
		var left_v := p - (right * half_w) + Vector3.UP * y_elev
		var right_v := p + (right * half_w) + Vector3.UP * y_elev
		
		var uv_y := float(i) * 2.0
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, uv_y))
		st.add_vertex(left_v)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, uv_y))
		st.add_vertex(right_v)
		
	# Counter-clockwise triangle indices (visible from above)
	for i in range(count - 1):
		var idx_tl := i * 2
		var idx_tr := i * 2 + 1
		var idx_bl := (i + 1) * 2
		var idx_br := (i + 1) * 2 + 1
		
		# Triangle 1: idx_tl -> idx_bl -> idx_tr
		st.add_index(idx_tl)
		st.add_index(idx_bl)
		st.add_index(idx_tr)
		
		# Triangle 2: idx_tr -> idx_bl -> idx_br
		st.add_index(idx_tr)
		st.add_index(idx_bl)
		st.add_index(idx_br)
		
	st.generate_normals()
	return st.commit()

## Extrudes a ribbon offset laterally with counter-clockwise winding order
func _extrude_offset_ribbon(points: PackedVector3Array, offset_dist: float, width: float, y_elev: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var half_w := width * 0.5
	var count := points.size()
	
	for i in range(count):
		var p := points[i]
		var forward := Vector3.FORWARD
		if i < count - 1:
			forward = (points[i + 1] - p).normalized()
		elif i > 0:
			forward = (p - points[i - 1]).normalized()
		var right := forward.cross(Vector3.UP).normalized()
		
		var center_pt := p + (right * offset_dist)
		var left_v := center_pt - (right * half_w) + Vector3.UP * y_elev
		var right_v := center_pt + (right * half_w) + Vector3.UP * y_elev
		
		var uv_y := float(i) * 2.0
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(0, uv_y))
		st.add_vertex(left_v)
		
		st.set_normal(Vector3.UP)
		st.set_uv(Vector2(1, uv_y))
		st.add_vertex(right_v)
		
	# Counter-clockwise triangle indices
	for i in range(count - 1):
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
