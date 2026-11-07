"""
Blender 5.2 Supercar Post-Processor: Authentic Lamborghini Aventador
1. Automatically verifies / downloads authentic CAD model if missing.
2. Resolves absolute project paths so it runs from any directory or inside Blender IDE.
3. Normalizes coordinate bounds (centered at X=0, Y=0, tires on Z=0 ground).
4. Configures high-end PBR materials (Giallo Auge pearl paint, carbon fiber, LED emissions, tinted glass).
5. Exports both GLB (lamborghini_car.glb) and OBJ (lamborghini_body.obj + .mtl) for Godot 4.
"""

import bpy
import os
import sys
import urllib.request
from mathutils import Vector

AVENTADOR_SOURCE_URL = "https://raw.githubusercontent.com/supercar3d/supercar_3D_asssets/main/basic/lamborghini/aventador/aventador.glb"

def get_project_root():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, "..", ".."))

def ensure_source_model(models_dir):
    os.makedirs(models_dir, exist_ok=True)
    source_path = os.path.join(models_dir, "aventador_real.glb")
    if not os.path.exists(source_path) or os.path.getsize(source_path) < 1000000:
        print(f"Downloading authentic Lamborghini Aventador model from:\n{AVENTADOR_SOURCE_URL} ...")
        urllib.request.urlretrieve(AVENTADOR_SOURCE_URL, source_path)
        print(f"Downloaded: {source_path} ({os.path.getsize(source_path):,} bytes)")
    return source_path

def process_aventador():
    project_root = get_project_root()
    models_dir = os.path.join(project_root, "assets", "models")
    source_glb = ensure_source_model(models_dir)
    
    out_glb = os.path.join(models_dir, "lamborghini_car.glb")
    out_obj = os.path.join(models_dir, "lamborghini_body.obj")
    
    print(f"Loading model into Blender: {source_glb}")
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=source_glb)
    
    # Calculate overall bounding box across all mesh objects
    min_c = Vector((float('inf'), float('inf'), float('inf')))
    max_c = Vector((float('-inf'), float('-inf'), float('-inf')))
    mesh_count = 0
    
    for obj in bpy.data.objects:
        if obj.type == 'MESH':
            mesh_count += 1
            for corner in obj.bound_box:
                wc = obj.matrix_world @ Vector(corner)
                for i in range(3):
                    min_c[i] = min(min_c[i], wc[i])
                    max_c[i] = max(max_c[i], wc[i])
                    
    if mesh_count == 0:
        print("ERROR: No mesh objects found in source GLB!")
        return False
        
    center_x = (min_c.x + max_c.x) * 0.5
    center_y = (min_c.y + max_c.y) * 0.5
    bottom_z = min_c.z
    
    print(f"Bounds: min={min_c}, max={max_c}")
    print(f"Centering shift: X={-center_x:.4f}, Y={-center_y:.4f}, Z={-bottom_z:.4f}")
    
    # Shift top-level root objects so car sits on ground at (0, 0, 0)
    shift = Vector((-center_x, -center_y, -bottom_z))
    for obj in bpy.data.objects:
        if obj.parent is None:
            obj.location += shift
            
    # Apply high-end PBR materials
    for mat in bpy.data.materials:
        if not mat.node_tree:
            continue
        nodes = mat.node_tree.nodes
        bsdf = next((n for n in nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if not bsdf:
            continue
            
        mname = mat.name.lower()
        
        # 1. Main Lamborghini Pearlescent Paint (Giallo Auge)
        if 'body' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.98, 0.78, 0.05, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.95
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.08
            if 'Coat Weight' in bsdf.inputs:
                bsdf.inputs['Coat Weight'].default_value = 1.0
            elif 'Clearcoat' in bsdf.inputs:
                bsdf.inputs['Clearcoat'].default_value = 1.0
                
        # 2. Carbon Fiber Aerodynamics
        elif 'carbon' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.08, 0.08, 0.09, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.5
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.32
                
        # 3. Tinted Canopy Glass
        elif 'glass' in mname or 'window' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.03, 0.04, 0.06, 0.92)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.95
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.04
                
        # 4. Rear Red LED Taillights
        elif 'red_light' in mname:
            if 'Emission Color' in bsdf.inputs:
                bsdf.inputs['Emission Color'].default_value = (1.0, 0.02, 0.02, 1.0)
            elif 'Emission' in bsdf.inputs:
                bsdf.inputs['Emission'].default_value = (1.0, 0.02, 0.02, 1.0)
            if 'Emission Strength' in bsdf.inputs:
                bsdf.inputs['Emission Strength'].default_value = 5.0
                
        # 5. Front LED Headlights
        elif 'front_light' in mname:
            if 'Emission Color' in bsdf.inputs:
                bsdf.inputs['Emission Color'].default_value = (1.0, 0.98, 0.92, 1.0)
            elif 'Emission' in bsdf.inputs:
                bsdf.inputs['Emission'].default_value = (1.0, 0.98, 0.92, 1.0)
            if 'Emission Strength' in bsdf.inputs:
                bsdf.inputs['Emission Strength'].default_value = 6.0
                
        # 6. Titanium Exhaust
        elif 'exhaust' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.42, 0.45, 0.50, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.95
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.15
                
        # 7. Forged Alloy Rims
        elif 'hubcap' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.24, 0.25, 0.27, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.95
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.18
                
        # 8. Brake Caliper (Yellow Brembo)
        elif 'brake_2' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.98, 0.78, 0.05, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.75
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.20
                
        # 9. Performance Tires
        elif 'tire' in mname:
            if 'Base Color' in bsdf.inputs:
                bsdf.inputs['Base Color'].default_value = (0.08, 0.08, 0.09, 1.0)
            if 'Metallic' in bsdf.inputs:
                bsdf.inputs['Metallic'].default_value = 0.02
            if 'Roughness' in bsdf.inputs:
                bsdf.inputs['Roughness'].default_value = 0.85
                
    # Select all objects for export
    for obj in bpy.data.objects:
        obj.select_set(True)
        
    print(f"Exporting GLB to: {out_glb}")
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    
    print(f"Exporting OBJ to: {out_obj}")
    bpy.ops.wm.obj_export(
        filepath=out_obj,
        export_selected_objects=True,
        export_materials=True,
        export_normals=True,
        export_uv=True
    )
    
    print("SUCCESS: Blender Lamborghini processing complete!")
    return True

if __name__ == '__main__':
    process_aventador()
