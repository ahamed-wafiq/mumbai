import bpy
from mathutils import Vector

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath='assets/models/aventador_real.glb')

for obj in bpy.data.objects:
    if obj.type == 'MESH':
        mats = [m.name for m in obj.data.materials if m]
        if 'Red_Lights' in mats:
            center = sum((Vector(b) for b in obj.bound_box), Vector()) / 8.0
            print(f"Taillights object: {obj.name} center: {obj.matrix_world @ center}")
        if 'Glass_Lights' in mats:
            center = sum((Vector(b) for b in obj.bound_box), Vector()) / 8.0
            print(f"Lights object: {obj.name} center: {obj.matrix_world @ center}")
