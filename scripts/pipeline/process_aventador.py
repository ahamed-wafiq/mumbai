"""
Blender 5.2 Supercar Post-Processor: Authentic Lamborghini Aventador
1. Imports aventador_real.glb
2. Normalizes position (centered at X=0, Y=0, wheels touching Z=0)
3. Configures high-end PBR materials (Giallo Auge pearl paint, carbon fiber, LED emissions, tinted glass)
4. Exports as res://assets/models/lamborghini_car.glb
"""

import bpy
import bmesh
from mathutils import Vector, Matrix

def process_aventador():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath='assets/models/aventador_real.glb')
    
    # Calculate overall bounding box
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
    
    print(f"Original Bounds: min={min_c}, max={max_c}")
    print(f"Shift: X={-center_x}, Y={-center_y}, Z={-bottom_z}")
    
    # Shift top-level root objects so car sits on ground at (0, 0, 0)
    shift = Vector((-center_x, -center_y, -bottom_z))
    for obj in bpy.data.objects:
        if obj.parent is None:
            obj.location += shift
            
    # Apply high-end PBR materials
    for mat in bpy.data.materials:
        if not mat.use_nodes:
            mat.use_nodes = True
        nodes = mat.node_tree.nodes
        bsdf = None
        for n in nodes:
            if n.type == 'BSDF_PRINCIPLED':
                bsdf = n
                break
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
        
    out_glb = 'assets/models/lamborghini_car.glb'
    print(f"Exporting processed authentic Lamborghini to {out_glb}")
    bpy.ops.export_scene.gltf(
        filepath=out_glb,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    print("SUCCESS: Export completed!")

if __name__ == '__main__':
    process_aventador()
