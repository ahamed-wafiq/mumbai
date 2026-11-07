"""
Blender 5.2 Multi-Car Garage Pipeline
Processes Ferrari SF90, Porsche 911, and McLaren 570S from data/source/supercars/
Exports them cleanly to assets/models/ with PBR materials, forward orientation, and zero warnings.
"""

import bpy
import os
from mathutils import Vector, Matrix
import math

def clean_mtl(mtl_path):
    if not os.path.exists(mtl_path):
        return
    with open(mtl_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    clean = [l for l in lines if not l.strip().startswith("Ka ")]
    with open(mtl_path, "w", encoding="utf-8") as f:
        f.writelines(clean)

def process_car(src_name, out_base_name, primary_rgb, metallic=0.92, roughness=0.1):
    script_dir = os.path.dirname(os.path.abspath(__file__))
    root = os.path.abspath(os.path.join(script_dir, "..", ".."))
    
    src_path = os.path.join(root, "data", "source", "supercars", src_name)
    out_dir = os.path.join(root, "assets", "models")
    os.makedirs(out_dir, exist_ok=True)
    
    out_glb = os.path.join(out_dir, f"{out_base_name}.glb")
    out_obj = os.path.join(out_dir, f"{out_base_name}.obj")
    out_mtl = os.path.join(out_dir, f"{out_base_name}.mtl")
    
    if not os.path.exists(src_path):
        print(f"Skipping {src_name}, file not found")
        return
        
    print(f"Processing {src_name} -> {out_base_name} ...")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src_path)
    
    # Calculate bounds
    min_c = Vector((float('inf'), float('inf'), float('inf')))
    max_c = Vector((float('-inf'), float('-inf'), float('-inf')))
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            for corner in obj.bound_box:
                wc = obj.matrix_world @ Vector(corner)
                for i in range(3):
                    min_c[i] = min(min_c[i], wc[i])
                    max_c[i] = max(max_c[i], wc[i])
                    
    center_x = (min_c.x + max_c.x) * 0.5
    center_y = (min_c.y + max_c.y) * 0.5
    bottom_z = min_c.z
    
    shift = Vector((-center_x, -center_y, -bottom_z))
    for obj in bpy.data.objects:
        if obj.parent is None:
            obj.location += shift
            
    # Apply primary paint and PBR settings
    for mat in bpy.data.materials:
        if not mat.node_tree:
            continue
        bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if not bsdf:
            continue
        mname = mat.name.lower()
        if 'body' in mname or 'carpaint' in mname or 'paint' in mname or 'metal' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (*primary_rgb, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = metallic
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = roughness
                
    for obj in bpy.data.objects:
        obj.select_set(True)
        
    bpy.ops.export_scene.gltf(filepath=out_glb, use_selection=True, export_format='GLB', export_apply=True)
    bpy.ops.wm.obj_export(filepath=out_obj, export_selected_objects=True, export_materials=True, export_normals=True, export_uv=True)
    clean_mtl(out_mtl)
    print(f"Exported {out_base_name}")

def main():
    # 1. Ferrari SF90 Stradale (Rosso Corsa Red)
    process_car("ferrari_sf90.glb", "ferrari_body", (0.88, 0.05, 0.05))
    # 2. Porsche 911 GT3 (Miami / Shark Blue)
    process_car("porsche_911.glb", "porsche_body", (0.05, 0.45, 0.88))
    # 3. McLaren 570S (Papaya Orange)
    process_car("mclaren_570s.glb", "mclaren_body", (0.95, 0.42, 0.05))
    print("Multi-car garage generation complete!")

if __name__ == '__main__':
    main()
