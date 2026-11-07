import bpy
import mathutils

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='assets/models/aventador_real.glb')

print("--- BOUNDS INSPECTION ---")
min_coord = mathutils.Vector((float('inf'), float('inf'), float('inf')))
max_coord = mathutils.Vector((float('-inf'), float('-inf'), float('-inf')))

for obj in bpy.data.objects:
    if obj.type == 'MESH':
        for corner in obj.bound_box:
            world_corner = obj.matrix_world @ mathutils.Vector(corner)
            for i in range(3):
                min_coord[i] = min(min_coord[i], world_corner[i])
                max_coord[i] = max(max_coord[i], world_corner[i])

print(f"Total bounds min: {min_coord}")
print(f"Total bounds max: {max_coord}")
size = max_coord - min_coord
print(f"Total bounds size: {size}")

# Inspect wheel / tire objects
print("--- WHEEL OBJECTS ---")
for obj in bpy.data.objects:
    if any(k in obj.name.lower() for k in ['wheel', 'tire', 'brake', 'rim', 'hub']):
        print(f"{obj.name} | parent: {obj.parent.name if obj.parent else None} | loc: {obj.matrix_world.translation} | dim: {obj.dimensions}")

