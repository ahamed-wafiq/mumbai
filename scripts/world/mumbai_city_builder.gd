class_name MumbaiCityBuilder
extends Node3D

## MumbaiCityBuilder
## Procedurally constructs the authentic, geographically accurate Marine Drive
## (Queen's Necklace) urban corridor with dense road curves, lane markings,
## sidewalks, seaside promenade, streetlights, and buildings flanking both sides.

@export var build_on_ready: bool = true

# Materials
var mat_asphalt: StandardMaterial3D
var mat_yellow_line: StandardMaterial3D
var mat_white_line: StandardMaterial3D
var mat_sidewalk: StandardMaterial3D
var mat_seawall: StandardMaterial3D
var mat_art_deco_cream: StandardMaterial3D
var mat_art_deco_terracotta: StandardMaterial3D
var mat_modern_glass: StandardMaterial3D
var mat_heritage_stone: StandardMaterial3D
var mat_window: StandardMaterial3D
var mat_lamp_glow: StandardMaterial3D

func _ready() -> void:
	_init_materials()
	if build_on_ready:
		build_city()

func _init_materials() -> void:
	# CULL_DISABLED ensures ribbons and surfaces are 100% visible from all camera angles
	mat_asphalt = StandardMaterial3D.new()
	mat_asphalt.albedo_color = Color(0.12, 0.13, 0.15, 1.0)
	mat_asphalt.roughness = 0.85
	mat_asphalt.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat_yellow_line = StandardMaterial3D.new()
	mat_yellow_line.albedo_color = Color(1.0, 0.72, 0.05, 1.0)
	mat_yellow_line.emission_enabled = true
	mat_yellow_line.emission = Color(1.0, 0.72, 0.05, 1.0)
	mat_yellow_line.emission_energy_multiplier = 0.5
	mat_yellow_line.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat_white_line = StandardMaterial3D.new()
	mat_white_line.albedo_color = Color(0.95, 0.96, 0.98, 1.0)
	mat_white_line.emission_enabled = true
	mat_white_line.emission = Color(0.95, 0.96, 0.98, 1.0)
	mat_white_line.emission_energy_multiplier = 0.4
	mat_white_line.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat_sidewalk = StandardMaterial3D.new()
	mat_sidewalk.albedo_color = Color(0.42, 0.45, 0.49, 1.0)
	mat_sidewalk.roughness = 0.75
	mat_sidewalk.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat_seawall = StandardMaterial3D.new()
	mat_seawall.albedo_color = Color(0.55, 0.58, 0.62, 1.0)
	mat_seawall.roughness = 0.65
	mat_seawall.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mat_art_deco_cream = StandardMaterial3D.new()
	mat_art_deco_cream.albedo_color = Color(0.85, 0.80, 0.70, 1.0)
	mat_art_deco_cream.roughness = 0.7
	
	mat_art_deco_terracotta = StandardMaterial3D.new()
	mat_art_deco_terracotta.albedo_color = Color(0.76, 0.54, 0.42, 1.0)
	mat_art_deco_terracotta.roughness = 0.75
	
	mat_modern_glass = StandardMaterial3D.new()
	mat_modern_glass.albedo_color = Color(0.18, 0.24, 0.32, 1.0)
	mat_modern_glass.metallic = 0.75
	mat_modern_glass.roughness = 0.2
	
	mat_heritage_stone = StandardMaterial3D.new()
	mat_heritage_stone.albedo_color = Color(0.62, 0.58, 0.52, 1.0)
	mat_heritage_stone.roughness = 0.85
	
	mat_window = StandardMaterial3D.new()
	mat_window.albedo_color = Color(0.1, 0.15, 0.2, 1.0)
	mat_window.metallic = 0.9
	mat_window.roughness = 0.15
	
	mat_lamp_glow = StandardMaterial3D.new()
	mat_lamp_glow.albedo_color = Color(1.0, 0.92, 0.75, 1.0)
	mat_lamp_glow.emission_enabled = true
	mat_lamp_glow.emission = Color(1.0, 0.88, 0.65, 1.0)
	mat_lamp_glow.emission_energy_multiplier = 4.0

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

## Builds buildings directly flanking the road on both sides
func _build_all_buildings(_points: PackedVector3Array) -> void:
	var buildings_root := Node3D.new()
	buildings_root.name = "MarineDriveBuildings"
	add_child(buildings_root)
	
	# List of buildings positioned immediately along the road corridor
	var buildings: Array[Dictionary] = [
		# --- DIRECTLY IN FRONT OF PLAYER SPAWN (Heading North Z <= 50) ---
		{"name": "Marine Drive Promenade Mansions", "x": 16.0, "z": 0.0, "w": 32.0, "d": 28.0, "h": 26.0, "mat": mat_art_deco_cream},
		{"name": "Chowpatty View Seafront Court", "x": 16.0, "z": -40.0, "w": 30.0, "d": 26.0, "h": 28.0, "mat": mat_art_deco_terracotta},
		{"name": "Taraporewala Aquarium & Research Pavilion", "x": 16.0, "z": -85.0, "w": 40.0, "d": 30.0, "h": 20.0, "mat": mat_modern_glass},
		{"name": "Princess Street Heritage Residence", "x": 15.0, "z": -140.0, "w": 34.0, "d": 28.0, "h": 25.0, "mat": mat_art_deco_cream},
		{"name": "Charni Road Art Deco Block", "x": -10.0, "z": -210.0, "w": 36.0, "d": 28.0, "h": 24.0, "mat": mat_art_deco_terracotta},
		{"name": "Queen's View Residential Tower", "x": -25.0, "z": -290.0, "w": 35.0, "d": 30.0, "h": 36.0, "mat": mat_modern_glass},
		{"name": "Walkeshwar Coastal Tower A", "x": -45.0, "z": -380.0, "w": 38.0, "d": 32.0, "h": 42.0, "mat": mat_modern_glass},
		{"name": "Walkeshwar Coastal Tower B", "x": -50.0, "z": -460.0, "w": 36.0, "d": 30.0, "h": 38.0, "mat": mat_modern_glass},
		{"name": "Wilson College Heritage Hall", "x": -120.0, "z": -650.0, "w": 65.0, "d": 45.0, "h": 26.0, "mat": mat_heritage_stone},
		{"name": "Girgaon Chowpatty Pavilions", "x": -320.0, "z": -900.0, "w": 70.0, "d": 40.0, "h": 22.0, "mat": mat_heritage_stone},
		
		# --- WEST SIDE / WALKESHWAR HILL (Overlooking the Bay) ---
		{"name": "Malabar Hill Overlook Tower", "x": -90.0, "z": -500.0, "w": 40.0, "d": 35.0, "h": 48.0, "mat": mat_modern_glass},
		{"name": "Walkeshwar Sea-Facing Enclave", "x": -160.0, "z": -700.0, "w": 45.0, "d": 38.0, "h": 34.0, "mat": mat_art_deco_cream},
		
		# --- IMMEDIATELY AT AND BEHIND SPAWN (Heading South Z >= 50) ---
		{"name": "Soona Mahal (Art Deco Heritage 1937)", "x": 16.0, "z": 80.0, "w": 32.0, "d": 26.0, "h": 22.0, "mat": mat_art_deco_cream},
		{"name": "Zaver Mahal (Art Deco Heritage 1937)", "x": 16.0, "z": 130.0, "w": 34.0, "d": 26.0, "h": 25.0, "mat": mat_art_deco_terracotta},
		{"name": "Keval Mahal (Art Deco Heritage 1937)", "x": 16.0, "z": 180.0, "w": 34.0, "d": 26.0, "h": 22.0, "mat": mat_art_deco_cream},
		{"name": "Kapur Mahal (Art Deco Heritage)", "x": 16.0, "z": 240.0, "w": 35.0, "d": 26.0, "h": 24.0, "mat": mat_art_deco_cream},
		{"name": "Churchgate Court Executive Suites", "x": 17.0, "z": 310.0, "w": 38.0, "d": 30.0, "h": 35.0, "mat": mat_modern_glass},
		
		# --- VEER NARIMAN ROAD CORNER (Z ~ 400) ---
		{"name": "Eros Cinema (Art Deco Landmark 1938)", "x": 20.0, "z": 380.0, "w": 45.0, "d": 35.0, "h": 32.0, "mat": mat_art_deco_terracotta},
		{"name": "Churchgate Station Terminal Tower", "x": 80.0, "z": 360.0, "w": 55.0, "d": 45.0, "h": 65.0, "mat": mat_modern_glass},
		{"name": "Wankhede Stadium (Cricket Grandstand)", "x": 75.0, "z": 460.0, "w": 110.0, "d": 90.0, "h": 38.0, "mat": mat_heritage_stone},
		{"name": "InterContinental Marine Drive", "x": 18.0, "z": 480.0, "w": 42.0, "d": 30.0, "h": 36.0, "mat": mat_modern_glass},
		
		# --- BRABOURNE & NARIMAN POINT ROW (Z >= 600) ---
		{"name": "Sea Green Hotel", "x": 17.0, "z": 580.0, "w": 32.0, "d": 24.0, "h": 22.0, "mat": mat_art_deco_cream},
		{"name": "Brabourne Stadium (CCI Pavilion)", "x": 70.0, "z": 750.0, "w": 105.0, "d": 85.0, "h": 28.0, "mat": mat_heritage_stone},
		{"name": "Marine Plaza Hotel", "x": 18.0, "z": 900.0, "w": 38.0, "d": 28.0, "h": 34.0, "mat": mat_modern_glass},
		{"name": "Mafatlal Commercial Centre", "x": 22.0, "z": 1050.0, "w": 48.0, "d": 36.0, "h": 62.0, "mat": mat_modern_glass},
		{"name": "The Oberoi & Trident Towers", "x": 24.0, "z": 1300.0, "w": 65.0, "d": 50.0, "h": 117.0, "mat": mat_modern_glass},
		{"name": "Express Towers (Nariman Point)", "x": 25.0, "z": 1500.0, "w": 55.0, "d": 45.0, "h": 105.0, "mat": mat_modern_glass},
		{"name": "Air India Building (Iconic Landmark)", "x": 22.0, "z": 1720.0, "w": 58.0, "d": 44.0, "h": 78.0, "mat": mat_modern_glass},
		{"name": "NCPA Theatre Complex", "x": 26.0, "z": 1980.0, "w": 80.0, "d": 60.0, "h": 26.0, "mat": mat_heritage_stone}
	]
	
	for b in buildings:
		var b_node := _create_architectural_building(
			b["name"],
			Vector3(b["x"], 0.0, b["z"]),
			b["w"],
			b["d"],
			b["h"],
			b["mat"]
		)
		buildings_root.add_child(b_node)

## Creates a detailed 3D building with facade, accent trim, and collision
func _create_architectural_building(b_name: String, pos: Vector3, width: float, depth: float, height: float, facade_mat: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = b_name.replace(" ", "_")
	body.position = Vector3(pos.x + (width * 0.5), 0.0, pos.z)
	body.collision_layer = 1
	body.collision_mask = 0
	
	# 1. Main Facade Block
	var main_box := BoxMesh.new()
	main_box.size = Vector3(width, height, depth)
	main_box.material = facade_mat
	
	var main_inst := MeshInstance3D.new()
	main_inst.name = "Facade"
	main_inst.mesh = main_box
	main_inst.position = Vector3(0.0, height * 0.5, 0.0)
	body.add_child(main_inst)
	
	# 2. Roof Parapet Trim with Mumbai Orange accent
	var trim_box := BoxMesh.new()
	trim_box.size = Vector3(width + 0.6, 0.8, depth + 0.6)
	var trim_mat := StandardMaterial3D.new()
	trim_mat.albedo_color = Color(1.0, 0.42, 0.0, 1.0)
	trim_box.material = trim_mat
	
	var trim_inst := MeshInstance3D.new()
	trim_inst.name = "RoofTrim"
	trim_inst.mesh = trim_box
	trim_inst.position = Vector3(0.0, height + 0.4, 0.0)
	body.add_child(trim_inst)
	
	# 3. Rooftop tank / tower
	var tank_cyl := CylinderMesh.new()
	tank_cyl.top_radius = minf(width, depth) * 0.15
	tank_cyl.bottom_radius = minf(width, depth) * 0.15
	tank_cyl.height = 3.5
	var tank_mat := StandardMaterial3D.new()
	tank_mat.albedo_color = Color(0.2, 0.22, 0.25, 1.0)
	tank_cyl.material = tank_mat
	
	var tank_inst := MeshInstance3D.new()
	tank_inst.mesh = tank_cyl
	tank_inst.position = Vector3(width * 0.2, height + 2.5, depth * 0.1)
	body.add_child(tank_inst)
	
	# 4. Box Collision Shape for vehicle crashes
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, height, depth)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0.0, height * 0.5, 0.0)
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
