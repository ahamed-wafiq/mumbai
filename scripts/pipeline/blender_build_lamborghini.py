"""
Blender 5.2 Procedural Model Generator: GTA 5 Style Lamborghini Supercar
Generates high-fidelity, high-poly meshes with smooth shading, bevels,
PBR materials, and exports both GLB (glTF 2.0) and OBJ formats.
"""

import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix

def clear_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)

def create_pbr_material(name, base_color, metallic=0.0, roughness=0.5, clearcoat=0.0, emission=None, emission_strength=1.0, alpha=1.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    nodes.clear()
    
    node_out = nodes.new(type='ShaderNodeOutputMaterial')
    node_bsdf = nodes.new(type='ShaderNodeBsdfPrincipled')
    links.new(node_bsdf.outputs['BSDF'], node_out.inputs['Surface'])
    
    # Configure Principled BSDF inputs (Blender 4.x / 5.x compatible)
    if 'Base Color' in node_bsdf.inputs:
        node_bsdf.inputs['Base Color'].default_value = (*base_color[:3], alpha)
    if 'Metallic' in node_bsdf.inputs:
        node_bsdf.inputs['Metallic'].default_value = metallic
    if 'Roughness' in node_bsdf.inputs:
        node_bsdf.inputs['Roughness'].default_value = roughness
    if 'Coat Weight' in node_bsdf.inputs:
        node_bsdf.inputs['Coat Weight'].default_value = clearcoat
    elif 'Clearcoat' in node_bsdf.inputs:
        node_bsdf.inputs['Clearcoat'].default_value = clearcoat
        
    if emission:
        if 'Emission Color' in node_bsdf.inputs:
            node_bsdf.inputs['Emission Color'].default_value = (*emission[:3], 1.0)
        elif 'Emission' in node_bsdf.inputs:
            node_bsdf.inputs['Emission'].default_value = (*emission[:3], 1.0)
        if 'Emission Strength' in node_bsdf.inputs:
            node_bsdf.inputs['Emission Strength'].default_value = emission_strength
            
    if alpha < 1.0:
        mat.blend_method = 'BLEND'
    return mat

def build_lamborghini():
    clear_scene()
    
    # 1. Materials Setup
    mat_yellow = create_pbr_material("Mat_LamboYellow", (0.98, 0.76, 0.04), metallic=0.92, roughness=0.08, clearcoat=1.0)
    mat_glass  = create_pbr_material("Mat_LamboGlass",  (0.04, 0.05, 0.07), metallic=0.95, roughness=0.04, alpha=0.92)
    mat_carbon = create_pbr_material("Mat_CarbonFiber", (0.08, 0.09, 0.10), metallic=0.45, roughness=0.32)
    mat_head   = create_pbr_material("Mat_Headlights",  (1.00, 0.98, 0.92), metallic=0.1, roughness=0.1, emission=(1.0, 0.98, 0.92), emission_strength=5.0)
    mat_tail   = create_pbr_material("Mat_Taillights",  (0.95, 0.02, 0.02), metallic=0.1, roughness=0.1, emission=(1.0, 0.02, 0.02), emission_strength=6.0)
    mat_exhaust= create_pbr_material("Mat_TitaniumExhaust", (0.45, 0.48, 0.52), metallic=0.95, roughness=0.18)
    
    mat_tire   = create_pbr_material("Mat_Tire", (0.10, 0.10, 0.11), metallic=0.02, roughness=0.85)
    mat_rim    = create_pbr_material("Mat_Rim",  (0.24, 0.25, 0.27), metallic=0.94, roughness=0.18)
    mat_disc   = create_pbr_material("Mat_BrakeDisc", (0.35, 0.36, 0.38), metallic=0.85, roughness=0.25)
    mat_caliper= create_pbr_material("Mat_BrakeCaliper", (0.98, 0.78, 0.05), metallic=0.75, roughness=0.20)
    
    materials_list = [mat_yellow, mat_glass, mat_carbon, mat_head, mat_tail, mat_exhaust]
    
    # -------------------------------------------------------------
    # 2. Main Body Creation (BMesh modeling with symmetry & smooth normals)
    # -------------------------------------------------------------
    body_mesh = bpy.data.meshes.new("LamborghiniChassis")
    for m in materials_list:
        body_mesh.materials.append(m)
        
    bm = bmesh.new()
    
    # Cross section profiles along Z axis (from nose Z=-2.4 to tail Z=+2.3)
    # Each profile defines half-cross-section (X >= 0) points: (X, Y)
    # Profile format: [ (x, y) for bottom_sill, wheel_arch_lower, beltline, shoulder, roof_edge, roof_center ]
    
    stations = [
        # Nose tip
        {"z": -2.35, "pts": [(0.0, 0.12), (0.45, 0.14), (0.78, 0.18), (0.75, 0.26), (0.50, 0.32), (0.0, 0.35)], "mat": 2}, # Carbon splitter
        # Front bumper intake
        {"z": -2.15, "pts": [(0.0, 0.10), (0.55, 0.14), (0.92, 0.22), (0.88, 0.36), (0.62, 0.44), (0.0, 0.48)], "mat": 0},
        # Headlights / front hood start
        {"z": -1.85, "pts": [(0.0, 0.10), (0.62, 0.15), (0.96, 0.28), (0.94, 0.46), (0.66, 0.58), (0.0, 0.62)], "mat": 0},
        # Front wheel arch apex
        {"z": -1.35, "pts": [(0.0, 0.12), (0.68, 0.18), (1.00, 0.38), (0.98, 0.62), (0.70, 0.72), (0.0, 0.75)], "mat": 0},
        # Base of windshield / A-pillar
        {"z": -0.85, "pts": [(0.0, 0.14), (0.70, 0.18), (0.98, 0.48), (0.95, 0.72), (0.65, 0.94), (0.0, 1.02)], "mat": 0},
        # Cockpit peak / B-pillar
        {"z": -0.15, "pts": [(0.0, 0.14), (0.72, 0.18), (1.00, 0.50), (0.96, 0.78), (0.62, 1.14), (0.0, 1.18)], "mat": 1}, # Glass roof
        # Mid-cabin / Engine intake start
        {"z": 0.55, "pts": [(0.0, 0.14), (0.74, 0.18), (1.02, 0.52), (0.98, 0.80), (0.60, 1.12), (0.0, 1.15)], "mat": 1},
        # Rear engine deck / Side scoops
        {"z": 1.15, "pts": [(0.0, 0.14), (0.76, 0.20), (1.05, 0.56), (1.02, 0.82), (0.68, 0.96), (0.0, 1.00)], "mat": 0},
        # Rear wheel arch apex
        {"z": 1.45, "pts": [(0.0, 0.14), (0.78, 0.22), (1.06, 0.58), (1.04, 0.82), (0.72, 0.92), (0.0, 0.94)], "mat": 0},
        # Rear haunch / spoiler base
        {"z": 1.95, "pts": [(0.0, 0.16), (0.72, 0.24), (1.02, 0.54), (0.98, 0.78), (0.70, 0.84), (0.0, 0.86)], "mat": 0},
        # Rear fascia / taillights
        {"z": 2.25, "pts": [(0.0, 0.22), (0.65, 0.28), (0.96, 0.50), (0.92, 0.72), (0.65, 0.78), (0.0, 0.80)], "mat": 4},
        # Rear diffuser end
        {"z": 2.38, "pts": [(0.0, 0.26), (0.55, 0.30), (0.88, 0.45), (0.84, 0.65), (0.58, 0.72), (0.0, 0.74)], "mat": 2}
    ]
    
    # Build ring vertices for both Left (+X) and Right (-X) sides
    rings = []
    for st in stations:
        z = st["z"]
        pts = st["pts"]
        ring_v = []
        # Right side (+X)
        for x, y in pts:
            ring_v.append(bm.verts.new(Vector((x, y, z))))
        # Left side (-X) (in reverse order to maintain smooth manifold loop)
        for x, y in reversed(pts[:-1]):
            ring_v.append(bm.verts.new(Vector((-x, y, z))))
        rings.append((ring_v, st["mat"]))
        
    bm.verts.ensure_lookup_table()
    
    # Bridge adjacent rings
    for i in range(len(rings) - 1):
        r1, mat1 = rings[i]
        r2, mat2 = rings[i+1]
        n = len(r1)
        for j in range(n):
            j_next = (j + 1) % n
            v1 = r1[j]
            v2 = r1[j_next]
            v3 = r2[j_next]
            v4 = r2[j]
            try:
                face = bm.faces.new((v1, v2, v3, v4))
                face.material_index = mat1
                face.smooth = True
            except:
                pass
                
    # Cap front nose
    front_ring = rings[0][0]
    try:
        f_front = bm.faces.new(front_ring)
        f_front.material_index = 2
        f_front.smooth = True
    except:
        pass
        
    # Cap rear fascia
    rear_ring = rings[-1][0]
    try:
        f_rear = bm.faces.new(list(reversed(rear_ring)))
        f_rear.material_index = 2
        f_rear.smooth = True
    except:
        pass
        
    # -------------------------------------------------------------
    # 3. Add High-Performance Aerodynamic Elements
    # -------------------------------------------------------------
    def add_box(center, size, mat_idx, parent_bm):
        cx, cy, cz = center
        sx, sy, sz = size[0]*0.5, size[1]*0.5, size[2]*0.5
        v = [
            parent_bm.verts.new(Vector((cx - sx, cy - sy, cz - sz))),
            parent_bm.verts.new(Vector((cx + sx, cy - sy, cz - sz))),
            parent_bm.verts.new(Vector((cx + sx, cy + sy, cz - sz))),
            parent_bm.verts.new(Vector((cx - sx, cy + sy, cz - sz))),
            parent_bm.verts.new(Vector((cx - sx, cy - sy, cz + sz))),
            parent_bm.verts.new(Vector((cx + sx, cy - sy, cz + sz))),
            parent_bm.verts.new(Vector((cx + sx, cy + sy, cz + sz))),
            parent_bm.verts.new(Vector((cx - sx, cy + sy, cz + sz)))
        ]
        faces = [
            (0, 1, 2, 3), (4, 7, 6, 5),
            (0, 4, 5, 1), (1, 5, 6, 2),
            (2, 6, 7, 3), (3, 7, 4, 0)
        ]
        for f in faces:
            try:
                fc = parent_bm.faces.new([v[idx] for idx in f])
                fc.material_index = mat_idx
                fc.smooth = True
            except:
                pass
                
    # Front Lower Carbon Splitters
    add_box((0.0, 0.10, -2.38), (1.80, 0.04, 0.25), 2, bm)
    add_box((0.85, 0.16, -2.32), (0.05, 0.14, 0.28), 2, bm) # Left winglet
    add_box((-0.85, 0.16, -2.32), (0.05, 0.14, 0.28), 2, bm) # Right winglet
    
    # Front Aggressive LED Headlights (Y-shape signature)
    add_box((0.62, 0.52, -1.92), (0.32, 0.08, 0.24), 3, bm)
    add_box((-0.62, 0.52, -1.92), (0.32, 0.08, 0.24), 3, bm)
    
    # Windshield Glass Surface
    add_box((0.0, 0.88, -0.45), (1.18, 0.05, 0.85), 1, bm)
    
    # Side Carbon Wing Mirrors
    add_box((1.02, 0.78, -0.65), (0.24, 0.12, 0.22), 2, bm)
    add_box((-1.02, 0.78, -0.65), (0.24, 0.12, 0.22), 2, bm)
    
    # Rear Louvered Engine Cover (stepped glass & carbon slats)
    for l_idx in range(4):
        lz = 0.45 + l_idx * 0.28
        ly = 1.10 - l_idx * 0.07
        add_box((0.0, ly, lz), (0.92 - l_idx*0.06, 0.03, 0.18), 1, bm)
        
    # High-Performance SVJ Rear Wing (Aerofoil & Twin Stalks)
    add_box((0.0, 1.15, 2.18), (1.92, 0.05, 0.38), 2, bm) # Carbon aerofoil
    add_box((0.92, 1.20, 2.18), (0.04, 0.20, 0.42), 2, bm) # Right wing endplate
    add_box((-0.92, 1.20, 2.18), (0.04, 0.20, 0.42), 2, bm) # Left wing endplate
    add_box((0.38, 0.98, 2.10), (0.04, 0.28, 0.12), 2, bm) # Mount pylon R
    add_box((-0.38, 0.98, 2.10), (0.04, 0.28, 0.12), 2, bm) # Mount pylon L
    
    # Signature Y-Shaped LED Taillights
    add_box((0.65, 0.72, 2.26), (0.48, 0.08, 0.06), 4, bm)
    add_box((-0.65, 0.72, 2.26), (0.48, 0.08, 0.06), 4, bm)
    
    # Dual Hexagonal Center Exhaust Tips
    add_box((0.14, 0.54, 2.32), (0.16, 0.12, 0.16), 5, bm)
    add_box((-0.14, 0.54, 2.32), (0.16, 0.12, 0.16), 5, bm)
    
    # Rear Multi-Fin Diffuser
    add_box((0.0, 0.24, 2.35), (1.65, 0.05, 0.32), 2, bm)
    for fin_x in [-0.6, -0.35, -0.12, 0.12, 0.35, 0.6]:
        add_box((fin_x, 0.20, 2.35), (0.03, 0.12, 0.34), 2, bm)

    bm.to_mesh(body_mesh)
    bm.free()
    
    body_obj = bpy.data.objects.new("Lamborghini_Body", body_mesh)
    bpy.context.collection.objects.link(body_obj)
    
    # Apply Subdivision Surface modifier for smooth, aerodynamic curves
    subsurf = body_obj.modifiers.new(name="Subdivision", type='SUBSURF')
    subsurf.levels = 1
    subsurf.render_levels = 2
    
    # Apply Bevel modifier for sharp automotive panel edge highlights
    bevel = body_obj.modifiers.new(name="Bevel", type='BEVEL')
    bevel.width = 0.012
    bevel.segments = 2
    
    # -------------------------------------------------------------
    # 4. Detailed 5-Y-Spoke Forged Wheel Creation
    # -------------------------------------------------------------
    wheel_mesh = bpy.data.meshes.new("LamborghiniWheel")
    wheel_materials = [mat_tire, mat_rim, mat_disc, mat_caliper]
    for m in wheel_materials:
        wheel_mesh.materials.append(m)
        
    bm_w = bmesh.new()
    
    # Tire Outer Geometry (Torus / Cylinder Ring with rounded sidewall)
    tire_r_outer = 0.36
    tire_r_inner = 0.24
    tire_width   = 0.32
    segments     = 32
    
    # Create tire cylinder
    v_outer_1 = []
    v_outer_2 = []
    v_inner_1 = []
    v_inner_2 = []
    
    for s in range(segments):
        th = 2.0 * math.pi * s / segments
        cos_t = math.cos(th)
        sin_t = math.sin(th)
        
        # Outer tread surface
        v_outer_1.append(bm_w.verts.new(Vector((-tire_width*0.5, sin_t*tire_r_outer, cos_t*tire_r_outer))))
        v_outer_2.append(bm_w.verts.new(Vector(( tire_width*0.5, sin_t*tire_r_outer, cos_t*tire_r_outer))))
        
        # Inner bead / rim interface
        v_inner_1.append(bm_w.verts.new(Vector((-tire_width*0.42, sin_t*tire_r_inner, cos_t*tire_r_inner))))
        v_inner_2.append(bm_w.verts.new(Vector(( tire_width*0.42, sin_t*tire_r_inner, cos_t*tire_r_inner))))
        
    bm_w.verts.ensure_lookup_table()
    
    # Tread & sidewall faces
    for s in range(segments):
        s_next = (s + 1) % segments
        # Tread
        f_tread = bm_w.faces.new((v_outer_1[s], v_outer_2[s], v_outer_2[s_next], v_outer_1[s_next]))
        f_tread.material_index = 0
        f_tread.smooth = True
        # Sidewall Outer (+X)
        f_side_out = bm_w.faces.new((v_outer_2[s], v_inner_2[s], v_inner_2[s_next], v_outer_2[s_next]))
        f_side_out.material_index = 0
        f_side_out.smooth = True
        # Sidewall Inner (-X)
        f_side_in = bm_w.faces.new((v_inner_1[s], v_outer_1[s], v_outer_1[s_next], v_inner_1[s_next]))
        f_side_in.material_index = 0
        f_side_in.smooth = True
        
    # Rim Barrel & Lip
    v_rim_1 = []
    v_rim_2 = []
    for s in range(segments):
        th = 2.0 * math.pi * s / segments
        v_rim_1.append(bm_w.verts.new(Vector((-tire_width*0.40, math.sin(th)*(tire_r_inner*0.98), math.cos(th)*(tire_r_inner*0.98)))))
        v_rim_2.append(bm_w.verts.new(Vector(( tire_width*0.40, math.sin(th)*(tire_r_inner*0.98), math.cos(th)*(tire_r_inner*0.98)))))
        
    for s in range(segments):
        s_next = (s + 1) % segments
        f_rim = bm_w.faces.new((v_rim_1[s], v_rim_2[s], v_rim_2[s_next], v_rim_1[s_next]))
        f_rim.material_index = 1
        f_rim.smooth = True
        
    # 5-Split-Y Forged Alloy Spokes
    spoke_count = 5
    for sp in range(spoke_count):
        spoke_angle = 2.0 * math.pi * sp / spoke_count
        for branch in [-0.15, 0.15]:
            ang = spoke_angle + branch
            sp_dir = Vector((0.0, math.sin(ang), math.cos(ang)))
            # Create spoke prism
            sp_len = tire_r_inner * 0.92
            cx = tire_width * 0.32
            
            p1 = Vector((cx, 0.0, 0.0))
            p2 = Vector((cx - 0.04, sp_dir.y * sp_len, sp_dir.z * sp_len))
            
            v_sp = [
                bm_w.verts.new(p1 + Vector((0, -0.02, -0.02))),
                bm_w.verts.new(p1 + Vector((0,  0.02, -0.02))),
                bm_w.verts.new(p2 + Vector((0,  0.03,  0.03))),
                bm_w.verts.new(p2 + Vector((0, -0.03,  0.03)))
            ]
            try:
                fc = bm_w.faces.new(v_sp)
                fc.material_index = 1
                fc.smooth = True
            except:
                pass
                
    # Center Lock Nut
    nut_verts = []
    for n in range(6):
        nth = 2.0 * math.pi * n / 6
        nut_verts.append(bm_w.verts.new(Vector((tire_width*0.38, math.sin(nth)*0.065, math.cos(nth)*0.065))))
    try:
        f_nut = bm_w.faces.new(nut_verts)
        f_nut.material_index = 1
    except:
        pass
        
    # Cross-Drilled Ceramic Brake Rotor / Disc
    disc_r = tire_r_inner * 0.85
    disc_v1 = []
    disc_v2 = []
    for s in range(24):
        th = 2.0 * math.pi * s / 24
        disc_v1.append(bm_w.verts.new(Vector((0.04, math.sin(th)*disc_r, math.cos(th)*disc_r))))
        disc_v2.append(bm_w.verts.new(Vector((0.06, math.sin(th)*disc_r, math.cos(th)*disc_r))))
    for s in range(24):
        s_next = (s + 1) % 24
        fc_disc = bm_w.faces.new((disc_v1[s], disc_v2[s], disc_v2[s_next], disc_v1[s_next]))
        fc_disc.material_index = 2
        fc_disc.smooth = True
        
    # Yellow Multi-Piston Brembo Brake Caliper
    add_box((0.05, disc_r * 0.72, 0.0), (0.06, 0.16, 0.18), 3, bm_w)
    
    bm_w.to_mesh(wheel_mesh)
    bm_w.free()
    
    wheel_obj = bpy.data.objects.new("Lamborghini_Wheel", wheel_mesh)
    bpy.context.collection.objects.link(wheel_obj)
    
    # -------------------------------------------------------------
    # 5. Export Assets to Project
    # -------------------------------------------------------------
    output_dir = os.path.abspath("assets/models")
    os.makedirs(output_dir, exist_ok=True)
    
    body_obj_path = os.path.join(output_dir, "lamborghini_body.obj")
    wheel_obj_path = os.path.join(output_dir, "lamborghini_wheel.obj")
    car_glb_path = os.path.join(output_dir, "lamborghini_car.glb")
    wheel_glb_path = os.path.join(output_dir, "lamborghini_wheel.glb")
    
    # Apply modifiers to body mesh for export
    bpy.context.view_layer.objects.active = body_obj
    body_obj.select_set(True)
    wheel_obj.select_set(False)
    
    # Export Body OBJ
    print(f"Exporting Body OBJ: {body_obj_path}")
    bpy.ops.wm.obj_export(
        filepath=body_obj_path,
        export_selected_objects=True,
        export_materials=True,
        export_normals=True,
        export_uv=True,
        apply_modifiers=True
    )
    
    # Export Wheel OBJ
    bpy.context.view_layer.objects.active = wheel_obj
    body_obj.select_set(False)
    wheel_obj.select_set(True)
    print(f"Exporting Wheel OBJ: {wheel_obj_path}")
    bpy.ops.wm.obj_export(
        filepath=wheel_obj_path,
        export_selected_objects=True,
        export_materials=True,
        export_normals=True,
        export_uv=True,
        apply_modifiers=True
    )
    
    # Export Wheel GLB
    print(f"Exporting Wheel GLB: {wheel_glb_path}")
    bpy.ops.export_scene.gltf(
        filepath=wheel_glb_path,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    
    # Export Complete Car GLB (with body + wheels placed at 4 corners)
    body_obj.select_set(True)
    wheel_obj.select_set(False)
    
    # Create 4 wheel instances for the complete glTF scene
    fl = wheel_obj.copy()
    fl.location = Vector((-0.98, 0.36, -1.35))
    bpy.context.collection.objects.link(fl)
    
    fr = wheel_obj.copy()
    fr.location = Vector((0.98, 0.36, -1.35))
    fr.scale = Vector((-1, 1, 1))
    bpy.context.collection.objects.link(fr)
    
    rl = wheel_obj.copy()
    rl.location = Vector((-1.02, 0.36, 1.35))
    bpy.context.collection.objects.link(rl)
    
    rr = wheel_obj.copy()
    rr.location = Vector((1.02, 0.36, 1.35))
    rr.scale = Vector((-1, 1, 1))
    bpy.context.collection.objects.link(rr)
    
    for obj in [body_obj, fl, fr, rl, rr]:
        obj.select_set(True)
        
    print(f"Exporting Complete Car GLB: {car_glb_path}")
    bpy.ops.export_scene.gltf(
        filepath=car_glb_path,
        use_selection=True,
        export_format='GLB',
        export_apply=True
    )
    
    print("SUCCESS: Blender Lamborghini generation complete!")

if __name__ == "__main__":
    build_lamborghini()
