class_name TerrainGenerator
extends Node

## TerrainGenerator for Mumbai Drive
## Generates ground terrain meshes and coastal sea levels.
## Designed for performance-friendly chunking across Greater Mumbai.

@export var ground_material: Material
@export var ocean_material: Material
@export var sea_level_elevation: float = 0.0

## Creates a flat or elevation-mapped ground plane chunk
func create_ground_chunk(size: Vector2, center_pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "GroundChunk"
	body.position = center_pos
	
	# Mesh
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = size
	if ground_material:
		plane_mesh.material = ground_material
		
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = plane_mesh
	body.add_child(mesh_inst)
	
	# Collision
	var shape := BoxShape3D.new()
	shape.size = Vector3(size.x, 1.0, size.y)
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = Vector3(0, -0.5, 0)
	body.add_child(col)
	
	return body

## Creates a coastal sea plane for Mumbai's west / Arabian Sea coast
func create_ocean_plane(size: Vector2, center_pos: Vector3) -> MeshInstance3D:
	var ocean_mesh := PlaneMesh.new()
	ocean_mesh.size = size
	if ocean_material:
		ocean_mesh.material = ocean_material
		
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "OceanPlane"
	mesh_inst.mesh = ocean_mesh
	mesh_inst.position = Vector3(center_pos.x, sea_level_elevation - 0.5, center_pos.z)
	return mesh_inst

