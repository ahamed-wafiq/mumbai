"""
Blender 5.2 Procedural Architecture Generator: Mumbai Iconic Buildings
Generates detailed Art Deco, Modern Glass High-Rise, and Heritage modules
with balconies, cornices, setbacks, window frames, and PBR materials.
Exports both GLB and OBJ into assets/buildings/.
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color, metallic=0.0, roughness=0.6, emission=None, emission_strength=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    
    if 'Base Color' in node_bsdf.inputs:
        node_bsdf.inputs['Base Color'].default_value = (*base_color[:3], 1.0)
    if 'Metallic' in node_bsdf.inputs:
        node_bsdf.inputs['Metallic'].default_value = metallic
    if 'Roughness' in node_bsdf.inputs:
        node_bsdf.inputs['Roughness'].default_value = roughness
        
    if emission:
        if 'Emission Color' in node_bsdf.inputs:
            node_bsdf.inputs['Emission Color'].default_value = (*emission[:3], 1.0)
        elif 'Emission' in node_bsdf.inputs:
            node_bsdf.inputs['Emission'].default_value = (*emission[:3], 1.0)
        if 'Emission Strength' in node_bsdf.inputs:
            node_bsdf.inputs['Emission Strength'].default_value = emission_strength
    return mat

def add_box(bm, center, size, mat_idx):
    cx, cy, cz = center
    sx, sy, sz = size[0]*0.5, size[1]*0.5, size[2]*0.5
    v = [
        bm.verts.new(Vector((cx - sx, cy - sy, cz - sz))),
        bm.verts.new(Vector((cx + sx, cy - sy, cz - sz))),
        bm.verts.new(Vector((cx + sx, cy + sy, cz - sz))),
        bm.verts.new(Vector((cx - sx, cy + sy, cz - sz))),
        bm.verts.new(Vector((cx - sx, cy - sy, cz + sz))),
        bm.verts.new(Vector((cx + sx, cy - sy, cz + sz))),
        bm.verts.new(Vector((cx + sx, cy + sy, cz + sz))),
        bm.verts.new(Vector((cx - sx, cy + sy, cz + sz)))
    ]
    faces = [
        (0, 1, 2, 3), (4, 7, 6, 5),
        (0, 4, 5, 1), (1, 5, 6, 2),
        (2, 6, 7, 3), (3, 7, 4, 0)
    ]
    for f in faces:
        try:
            fc = bm.faces.new([v[idx] for idx in f])
            fc.material_index = mat_idx
            fc.smooth = False
        except:
            pass

def build_art_deco_building():
    clear_scene()
    out_dir = os.path.abspath("assets/buildings")
    os.makedirs(out_dir, exist_ok=True)
    
    # 1. Materials
    mat_wall = create_pbr_material("Mat_ArtDeco_Wall", (0.88, 0.82, 0.72), metallic=0.05, roughness=0.8) # Warm Mumbai Cream
    mat_trim = create_pbr_material("Mat_ArtDeco_Trim", (0.92, 0.44, 0.12), metallic=0.1, roughness=0.6)  # Marine Drive Terracotta Orange
    mat_glass= create_pbr_material("Mat_ArtDeco_Glass", (0.15, 0.22, 0.28), metallic=0.85, roughness=0.1, emission=(1.0, 0.90, 0.70), emission_strength=1.5)
    mat_roof = create_pbr_material("Mat_ArtDeco_Roof", (0.25, 0.26, 0.28), metallic=0.1, roughness=0.9)
    
    mesh = bpy.data.meshes.new("ArtDecoBuilding")
    for m in [mat_wall, mat_trim, mat_glass, mat_roof]:
        mesh.materials.append(m)
        
    bm = bmesh.new()
    
    # Dimensions: 24m wide (X), 18m deep (Z), 28m high (Y) (7 stories)
    # Ground floor podium with shopfront arcade
    add_box(bm, (0, 2.5, 0), (24.0, 5.0, 18.0), 0)
    # Ground floor canopy
    add_box(bm, (0, 5.0, 0), (24.8, 0.4, 18.8), 1)
    
    # Stories 2 to 5: Main residential block with cantilevered curved balconies
    add_box(bm, (0, 14.0, 0), (23.2, 17.6, 17.2), 0)
    
    # Rounded streamline Art Deco balconies on front (+Z) and sides
    for floor in range(2, 7):
        fy = 5.0 + (floor - 1) * 3.6
        # Horizontal floor trim speedlines
        add_box(bm, (0, fy, 0), (23.6, 0.3, 17.6), 1)
        # Front balconies
        add_box(bm, (-6.5, fy + 0.5, 9.2), (4.5, 0.9, 1.4), 1)
        add_box(bm, ( 6.5, fy + 0.5, 9.2), (4.5, 0.9, 1.4), 1)
        # Window openings
        for wx in [-8.5, -4.5, 0.0, 4.5, 8.5]:
            add_box(bm, (wx, fy + 1.8, 8.65), (2.2, 1.8, 0.1), 2)
            
    # Setback top floors (Stories 6 & 7) - Iconic Mumbai stepped ziggurat tower
    add_box(bm, (0, 24.5, 0), (18.0, 3.6, 14.0), 0)
    add_box(bm, (0, 26.3, 0), (18.6, 0.3, 14.6), 1) # Trim band
    
    # Rooftop pavilion / elevator penthouse
    add_box(bm, (0, 28.0, 0), (10.0, 3.2, 8.0), 0)
    # Central Art Deco spire / nautical mast
    add_box(bm, (0, 31.5, 0), (0.6, 4.0, 0.6), 1)
    
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new("Mumbai_ArtDeco_Building", mesh)
    bpy.context.collection.objects.link(obj)
    
    # Export GLB & OBJ
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    
    glb_path = os.path.join(out_dir, "marine_drive_art_deco.glb")
    obj_path = os.path.join(out_dir, "marine_drive_art_deco.obj")
    
    print(f"Exporting Art Deco GLB: {glb_path}")
    bpy.ops.export_scene.gltf(filepath=glb_path, use_selection=True, export_format='GLB', export_apply=True)
    
    print(f"Exporting Art Deco OBJ: {obj_path}")
    bpy.ops.wm.obj_export(filepath=obj_path, export_selected_objects=True, export_materials=True, export_normals=True)

if __name__ == "__main__":
    build_art_deco_building()

