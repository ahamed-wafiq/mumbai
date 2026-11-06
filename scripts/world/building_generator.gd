class_name BuildingGenerator
extends Node

## BuildingGenerator for Mumbai Drive
## Extrudes real OpenStreetMap building footprints into 3D meshes with
## actual or estimated heights, architectural roof trims, and collision.

@export var default_floor_height: float = 3.5
@export var building_material: Material

var _mat_commercial: StandardMaterial3D
var _mat_residential: StandardMaterial3D
var _mat_hotel: StandardMaterial3D
var _mat_heritage: StandardMaterial3D
var _mat_roof_trim: StandardMaterial3D

func _ready() -> void:
	# Art Deco / Heritage Sandstone & Granite
	_mat_heritage = StandardMaterial3D.new()
	_mat_heritage.albedo_color = Color(0.72, 0.65, 0.54, 1.0)
	_mat_heritage.roughness = 0.8
	
	# Modern Commercial Glass & Charcoal Concrete
	_mat_commercial = StandardMaterial3D.new()
	_mat_commercial.albedo_color = Color(0.18, 0.22, 0.27, 1.0)
	_mat_commercial.metallic = 0.6
	_mat_commercial.roughness = 0.25
	
	# Premium Seafront Hotel
	_mat_hotel = StandardMaterial3D.new()
	_mat_hotel.albedo_color = Color(0.28, 0.32, 0.38, 1.0)
	_mat_hotel.metallic = 0.4
	_mat_hotel.roughness = 0.4
	
	# Marine Drive Art Deco Apartments
	_mat_residential = StandardMaterial3D.new()
	_mat_residential.albedo_color = Color(0.68, 0.62, 0.56, 1.0)
	_mat_residential.roughness = 0.75
	
	# Roof Parapet Accent Trim (Mumbai Sunset Orange)
	_mat_roof_trim = StandardMaterial3D.new()
	_mat_roof_trim.albedo_color = Color(1.0, 0.42, 0.0, 1.0)
	_mat_roof_trim.roughness = 0.4

## Generates a 3D building from a tile building data dictionary
func generate_building_from_tile_data(b_data: Dictionary) -> Node3D:
	var raw_poly: Array = b_data.get("polygon", [])
	if raw_poly.size() < 3:
		return null
		
	var height: float = float(b_data.get("height", 15.0))
	var b_type: String = str(b_data.get("building_type", "residential"))
	var b_name: String = str(b_data.get("name", "Building"))
	var center_arr: Array = b_data.get("center", [0.0, 0.0, 0.0])
	var center := Vector3(float(center_arr[0]), 0.0, float(center_arr[2]))
	
	# Convert footprint relative to center
	var local_pts: PackedVector3Array = []
	for p in raw_poly:
		var v := Vector3(float(p[0]), 0.0, float(p[2])) - center
		local_pts.append(v)
		
	var building_node := Node3D.new()
	building_node.name = "Bld_" + b_name.replace(" ", "_")
	building_node.position = center
	
	# Extrude 3D mesh (walls + roof)
	var mesh := _extrude_building_mesh(local_pts, height)
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "BuildingMesh"
	mesh_inst.mesh = mesh
	
	# Assign material based on architectural category
	var chosen_mat := _mat_residential
	match b_type:
		"commercial", "office":
			chosen_mat = _mat_commercial
		"hotel":
			chosen_mat = _mat_hotel
		"monument", "civic", "courthouse", "stadium":
			chosen_mat = _mat_heritage
		_:
			chosen_mat = _mat_residential
			
	mesh_inst.material_override = building_material if building_material else chosen_mat
	building_node.add_child(mesh_inst)
	
	# Add Static Collision
	var static_body := StaticBody3D.new()
	static_body.name = "Collision"
	static_body.collision_layer = 1
	static_body.collision_mask = 0
	
	var col_shape := CollisionShape3D.new()
	col_shape.shape = mesh.create_trimesh_shape()
	static_body.add_child(col_shape)
	building_node.add_child(static_body)
	
	return building_node

## Extrudes a 2D footprint into 3D walls and flat roof
func _extrude_building_mesh(local_pts: PackedVector3Array, height: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var count := local_pts.size()
	
	# 1. Extrude Walls
	for i in range(count - 1):
		var p1 := local_pts[i]
		var p2 := local_pts[i + 1]
		
		var b1 := Vector3(p1.x, 0.0, p1.z)
		var b2 := Vector3(p2.x, 0.0, p2.z)
		var t1 := Vector3(p1.x, height, p1.z)
		var t2 := Vector3(p2.x, height, p2.z)
		
		var wall_normal := (b2 - b1).cross(Vector3.UP).normalized()
		
		# Quad 1
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, 0))
		st.add_vertex(b1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, height / 3.5))
		st.add_vertex(t1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(b2)
		
		# Quad 2
		st.set_normal(wall_normal)
		st.set_uv(Vector2(0, height / 3.5))
		st.add_vertex(t1)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(1, height / 3.5))
		st.add_vertex(t2)
		
		st.set_normal(wall_normal)
		st.set_uv(Vector2(1, 0))
		st.add_vertex(b2)
		
	# 2. Triangulate Roof using simple centroid fan
	var roof_center := Vector3.ZERO
	for i in range(count - 1):
		roof_center += local_pts[i]
	roof_center /= float(max(1, count - 1))
	roof_center.y = height
	
	for i in range(count - 1):
		var v1 := Vector3(local_pts[i].x, height, local_pts[i].z)
		var v2 := Vector3(local_pts[i + 1].x, height, local_pts[i + 1].z)
		
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
