#!/usr/bin/env python3
"""
Mumbai Drive - Lamborghini Supercar 3D Model Generator
Generates high-precision Wavefront OBJ models for Lamborghini Aventador / SVJ style supercar:
- Aerodynamic low-slung wedge chassis with sculpted hood & front splitter
- Signature Y-shaped front DRLs and rear taillights
- Massive mid-engine side air intakes & cooling radiators
- Sloped rear engine louvers & high-mounted SVJ carbon wing
- Aggressive rear aerodynamic diffuser & central dual titanium exhaust
- Detailed directional low-profile supercar alloy wheel with brake disc & caliper
"""

import os
import math

MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets", "models")
os.makedirs(MODELS_DIR, exist_ok=True)

class OBJBuilder:
    def __init__(self):
        self.vertices = []
        self.normals = []
        self.uvs = []
        self.groups = {} # mat_name -> list of faces
        self.current_mat = "default"

    def set_material(self, mat_name):
        self.current_mat = mat_name
        if mat_name not in self.groups:
            self.groups[mat_name] = []

    def add_vertex(self, x, y, z):
        self.vertices.append((round(x, 4), round(y, 4), round(z, 4)))
        return len(self.vertices)

    def add_normal(self, nx, ny, nz):
        self.normals.append((round(nx, 4), round(ny, 4), round(nz, 4)))
        return len(self.normals)

    def add_uv(self, u, v):
        self.uvs.append((round(u, 4), round(v, 4)))
        return len(self.uvs)

    def add_quad(self, v1, v2, v3, v4, n=None):
        # Two triangles: (v1, v2, v3) and (v1, v3, v4)
        if self.current_mat not in self.groups:
            self.groups[self.current_mat] = []
        self.groups[self.current_mat].append((v1, v2, v3, n))
        self.groups[self.current_mat].append((v1, v3, v4, n))

    def add_tri(self, v1, v2, v3, n=None):
        if self.current_mat not in self.groups:
            self.groups[self.current_mat] = []
        self.groups[self.current_mat].append((v1, v2, v3, n))

    def export(self, filepath):
        with open(filepath, "w", encoding="utf-8") as f:
            f.write("# Mumbai Drive Lamborghini Supercar 3D Model\n")
            for x, y, z in self.vertices:
                f.write(f"v {x} {y} {z}\n")
            for nx, ny, nz in self.normals:
                f.write(f"vn {nx} {ny} {nz}\n")
            for u, v in self.uvs:
                f.write(f"vt {u} {v}\n")
            for mat, faces in self.groups.items():
                f.write(f"usemtl {mat}\n")
                for face in faces:
                    if len(face) == 4 and face[3] is not None:
                        n = face[3]
                        f.write(f"f {face[0]}//{n} {face[1]}//{n} {face[2]}//{n}\n")
                    else:
                        f.write(f"f {face[0]} {face[1]} {face[2]}\n")
        print(f"Exported {filepath}: {len(self.vertices)} verts, {sum(len(f) for f in self.groups.values())} triangles across {len(self.groups)} materials.")

def generate_lamborghini_body():
    obj = OBJBuilder()
    
    # -------------------------------------------------------------
    # 1. FRONT SPLITTER & LOWER CHASSIS (Carbon Fiber)
    # -------------------------------------------------------------
    obj.set_material("Mat_CarbonFiber")
    
    # Front carbon splitter blade (low ground-effect aerodynamic tray)
    # Forward center tip at Z = -2.48, sides sweep back to Z = -2.15, X = +-1.02
    v_sp_tip = obj.add_vertex(0.0, 0.08, -2.48)
    v_sp_fl = obj.add_vertex(-0.55, 0.08, -2.40)
    v_sp_fr = obj.add_vertex(0.55, 0.08, -2.40)
    v_sp_wl = obj.add_vertex(-1.02, 0.09, -2.15) # winglet tip L
    v_sp_wr = obj.add_vertex(1.02, 0.09, -2.15)  # winglet tip R
    v_sp_cl = obj.add_vertex(-0.85, 0.09, -1.75) # side skirt approach L
    v_sp_cr = obj.add_vertex(0.85, 0.09, -1.75)
    v_sp_mid = obj.add_vertex(0.0, 0.09, -1.75)
    
    obj.add_tri(v_sp_tip, v_sp_fl, v_sp_mid)
    obj.add_tri(v_sp_tip, v_sp_mid, v_sp_fr)
    obj.add_tri(v_sp_fl, v_sp_wl, v_sp_mid)
    obj.add_tri(v_sp_fr, v_sp_mid, v_sp_wr)
    obj.add_tri(v_sp_wl, v_sp_cl, v_sp_mid)
    obj.add_tri(v_sp_wr, v_sp_mid, v_sp_cr)

    # Front Splitter Vertical Winglets (Aero Endplates)
    v_sp_wl_top = obj.add_vertex(-1.02, 0.22, -2.15)
    v_sp_wr_top = obj.add_vertex(1.02, 0.22, -2.15)
    v_sp_cl_top = obj.add_vertex(-0.88, 0.20, -1.75)
    v_sp_cr_top = obj.add_vertex(0.88, 0.20, -1.75)
    obj.add_quad(v_sp_wl, v_sp_wl_top, v_sp_cl_top, v_sp_cl)
    obj.add_quad(v_sp_wr, v_sp_cr, v_sp_cr_top, v_sp_wr_top)

    # Side Skirt Aerodynamic Blades (Under door rocker panels)
    v_sk_rl = obj.add_vertex(-1.04, 0.10, 0.85) # rear scoop base L
    v_sk_rr = obj.add_vertex(1.04, 0.10, 0.85)
    v_sk_mid_l = obj.add_vertex(-0.96, 0.10, -0.25)
    v_sk_mid_r = obj.add_vertex(0.96, 0.10, -0.25)
    
    obj.add_quad(v_sp_cl, v_sk_mid_l, v_sk_rl, v_sk_rl) # left blade
    obj.add_quad(v_sp_cr, v_sk_rr, v_sk_mid_r, v_sp_cr) # right blade

    # -------------------------------------------------------------
    # 2. MAIN BODYWORK & HOOD (Lamborghini Giallo Auge Pearl Yellow)
    # -------------------------------------------------------------
    obj.set_material("Mat_LamboPaint")
    
    # Sharp Shark Nose & Front Bumper
    v_nose_center = obj.add_vertex(0.0, 0.32, -2.38) # central bull emblem point
    v_nose_left = obj.add_vertex(-0.48, 0.34, -2.32)
    v_nose_right = obj.add_vertex(0.48, 0.34, -2.32)
    
    # Front Air Dam Intake lower recesses (Hexagonal intake frames)
    v_intake_ll = obj.add_vertex(-0.85, 0.14, -2.18)
    v_intake_lr = obj.add_vertex(-0.35, 0.14, -2.25)
    v_intake_rl = obj.add_vertex(0.35, 0.14, -2.25)
    v_intake_rr = obj.add_vertex(0.85, 0.14, -2.18)
    
    # Connect lower splitter to nose
    obj.add_quad(v_sp_tip, v_sp_fl, v_nose_left, v_nose_center)
    obj.add_quad(v_sp_tip, v_nose_center, v_nose_right, v_sp_fr)
    
    # Front Fenders (Muscle arches over front wheels)
    v_fender_fl = obj.add_vertex(-0.98, 0.56, -1.85)
    v_fender_fr = obj.add_vertex(0.98, 0.56, -1.85)
    v_fender_top_l = obj.add_vertex(-0.96, 0.68, -1.30)
    v_fender_top_r = obj.add_vertex(0.96, 0.68, -1.30)
    v_fender_back_l = obj.add_vertex(-0.92, 0.66, -0.75)
    v_fender_back_r = obj.add_vertex(0.92, 0.66, -0.75)

    obj.add_quad(v_nose_left, v_fender_fl, v_fender_top_l, v_fender_top_l)
    obj.add_quad(v_nose_right, v_fender_top_r, v_fender_fl, v_nose_right)

    # Sculpted Front Hood (Dual creased aerodynamic bonnet)
    v_hood_center_low = obj.add_vertex(0.0, 0.42, -2.05)
    v_hood_crease_l = obj.add_vertex(-0.38, 0.48, -1.65)
    v_hood_crease_r = obj.add_vertex(0.38, 0.48, -1.65)
    v_hood_base_center = obj.add_vertex(0.0, 0.66, -0.75) # windshield base center
    v_hood_base_l = obj.add_vertex(-0.48, 0.68, -0.75)
    v_hood_base_r = obj.add_vertex(0.48, 0.68, -0.75)

    # Hood surface facets
    obj.add_tri(v_nose_center, v_nose_left, v_hood_center_low)
    obj.add_tri(v_nose_center, v_hood_center_low, v_nose_right)
    obj.add_quad(v_hood_center_low, v_nose_left, v_hood_crease_l, v_hood_base_l)
    obj.add_quad(v_hood_center_low, v_hood_base_center, v_hood_base_r, v_hood_crease_r)
    obj.add_quad(v_hood_center_low, v_hood_base_l, v_hood_base_center, v_hood_center_low)
    obj.add_quad(v_nose_right, v_hood_center_low, v_hood_crease_r, v_hood_base_r)
    obj.add_quad(v_fender_fl, v_hood_crease_l, v_fender_top_l, v_fender_top_l)
    obj.add_quad(v_fender_fr, v_fender_top_r, v_hood_crease_r, v_fender_fr)
    obj.add_quad(v_fender_top_l, v_hood_base_l, v_fender_back_l, v_fender_back_l)
    obj.add_quad(v_fender_top_r, v_fender_back_r, v_hood_base_r, v_fender_top_r)

    # Scissor Doors & Sculpted Side Radiator Intake Scoops
    v_door_bot_l = obj.add_vertex(-0.88, 0.22, 0.15)
    v_door_bot_r = obj.add_vertex(0.88, 0.22, 0.15)
    v_door_shoulder_l = obj.add_vertex(-0.84, 0.68, 0.15)
    v_door_shoulder_r = obj.add_vertex(0.84, 0.68, 0.15)
    
    # Giant Rear Intake Radiator Scoop Openings (V12 cooling ducts)
    v_scoop_lip_l = obj.add_vertex(-1.06, 0.72, 0.75) # prominent intake shoulder
    v_scoop_lip_r = obj.add_vertex(1.06, 0.72, 0.75)
    v_scoop_in_l = obj.add_vertex(-0.75, 0.50, 0.85)  # internal tunnel
    v_scoop_in_r = obj.add_vertex(0.75, 0.50, 0.85)

    obj.add_quad(v_fender_back_l, v_fender_back_l, v_door_shoulder_l, v_door_bot_l)
    obj.add_quad(v_fender_back_r, v_door_bot_r, v_door_shoulder_r, v_fender_back_r)
    obj.add_quad(v_door_shoulder_l, v_scoop_lip_l, v_sk_rl, v_door_bot_l)
    obj.add_quad(v_door_shoulder_r, v_door_bot_r, v_sk_rr, v_scoop_lip_r)

    # Rear Muscular Fenders
    v_rear_fender_top_l = obj.add_vertex(-1.05, 0.78, 1.35)
    v_rear_fender_top_r = obj.add_vertex(1.05, 0.78, 1.35)
    v_rear_fender_back_l = obj.add_vertex(-0.98, 0.74, 2.05)
    v_rear_fender_back_r = obj.add_vertex(0.98, 0.74, 2.05)

    obj.add_quad(v_scoop_lip_l, v_rear_fender_top_l, v_sk_rl, v_sk_rl)
    obj.add_quad(v_scoop_lip_r, v_sk_rr, v_rear_fender_top_r, v_scoop_lip_r)
    obj.add_quad(v_rear_fender_top_l, v_rear_fender_back_l, v_rear_fender_back_l, v_sk_rl)
    obj.add_quad(v_rear_fender_top_r, v_sk_rr, v_rear_fender_back_r, v_rear_fender_top_r)

    # Rear Fascia & Decklid Edge
    v_rear_deck_center = obj.add_vertex(0.0, 0.76, 2.15)
    v_rear_deck_l = obj.add_vertex(-0.55, 0.75, 2.15)
    v_rear_deck_r = obj.add_vertex(0.55, 0.75, 2.15)

    obj.add_quad(v_rear_fender_back_l, v_rear_deck_l, v_rear_deck_center, v_rear_fender_back_l)
    obj.add_quad(v_rear_fender_back_r, v_rear_fender_back_r, v_rear_deck_center, v_rear_deck_r)

    # -------------------------------------------------------------
    # 3. GREENHOUSE COCKPIT & WINDOWS (Tinted Glass)
    # -------------------------------------------------------------
    obj.set_material("Mat_LamboGlass")
    
    # Supercar Raked Windshield & Low Roof Canopy (Height = 1.14m)
    v_roof_front_center = obj.add_vertex(0.0, 1.12, 0.05)
    v_roof_front_l = obj.add_vertex(-0.46, 1.10, 0.05)
    v_roof_front_r = obj.add_vertex(0.46, 1.10, 0.05)
    
    v_roof_rear_center = obj.add_vertex(0.0, 1.10, 0.65)
    v_roof_rear_l = obj.add_vertex(-0.48, 1.08, 0.65)
    v_roof_rear_r = obj.add_vertex(0.48, 1.08, 0.65)

    # Windshield (65 degree rake)
    obj.add_quad(v_hood_base_l, v_roof_front_l, v_roof_front_center, v_hood_base_center)
    obj.add_quad(v_hood_base_center, v_roof_front_center, v_roof_front_r, v_hood_base_r)

    # Glass Roof Top
    obj.add_quad(v_roof_front_l, v_roof_rear_l, v_roof_rear_center, v_roof_front_center)
    obj.add_quad(v_roof_front_center, v_roof_rear_center, v_roof_rear_r, v_roof_front_r)

    # Hexagonal Side Windows
    obj.add_tri(v_hood_base_l, v_fender_back_l, v_roof_front_l)
    obj.add_tri(v_hood_base_r, v_roof_front_r, v_fender_back_r)
    obj.add_quad(v_roof_front_l, v_fender_back_l, v_door_shoulder_l, v_roof_rear_l)
    obj.add_quad(v_roof_front_r, v_roof_rear_r, v_door_shoulder_r, v_fender_back_r)

    # Sloped Engine Louver Glass Cover
    v_engine_mid_l = obj.add_vertex(-0.35, 0.90, 1.40)
    v_engine_mid_r = obj.add_vertex(0.35, 0.90, 1.40)
    v_engine_mid_c = obj.add_vertex(0.0, 0.92, 1.40)

    obj.add_quad(v_roof_rear_l, v_engine_mid_l, v_engine_mid_c, v_roof_rear_center)
    obj.add_quad(v_roof_rear_center, v_engine_mid_c, v_engine_mid_r, v_roof_rear_r)
    obj.add_quad(v_engine_mid_l, v_rear_deck_l, v_rear_deck_center, v_engine_mid_c)
    obj.add_quad(v_engine_mid_c, v_rear_deck_center, v_rear_deck_r, v_engine_mid_r)

    # -------------------------------------------------------------
    # 4. HEADLIGHTS & Y-SHAPED DRLs
    # -------------------------------------------------------------
    obj.set_material("Mat_Headlights")
    
    # Left Y-DRL Facet
    v_hl_l1 = obj.add_vertex(-0.52, 0.44, -2.18)
    v_hl_l2 = obj.add_vertex(-0.78, 0.50, -1.95)
    v_hl_l3 = obj.add_vertex(-0.62, 0.46, -1.90)
    obj.add_tri(v_hl_l1, v_hl_l2, v_hl_l3)

    # Right Y-DRL Facet
    v_hl_r1 = obj.add_vertex(0.52, 0.44, -2.18)
    v_hl_r2 = obj.add_vertex(0.78, 0.50, -1.95)
    v_hl_r3 = obj.add_vertex(0.62, 0.46, -1.90)
    obj.add_tri(v_hl_r1, v_hl_r3, v_hl_r2)

    # -------------------------------------------------------------
    # 5. TAILLIGHTS (Signature Horizontal Crimson Y-Lamps)
    # -------------------------------------------------------------
    obj.set_material("Mat_Taillights")
    
    # Left Y Taillight
    v_tl_l1 = obj.add_vertex(-0.45, 0.62, 2.22)
    v_tl_l2 = obj.add_vertex(-0.85, 0.64, 2.18)
    v_tl_l3 = obj.add_vertex(-0.85, 0.56, 2.18)
    v_tl_l4 = obj.add_vertex(-0.45, 0.56, 2.22)
    obj.add_quad(v_tl_l1, v_tl_l2, v_tl_l3, v_tl_l4)

    # Right Y Taillight
    v_tl_r1 = obj.add_vertex(0.45, 0.62, 2.22)
    v_tl_r2 = obj.add_vertex(0.85, 0.64, 2.18)
    v_tl_r3 = obj.add_vertex(0.85, 0.56, 2.18)
    v_tl_r4 = obj.add_vertex(0.45, 0.56, 2.22)
    obj.add_quad(v_tl_r1, v_tl_r4, v_tl_r3, v_tl_r2)

    # -------------------------------------------------------------
    # 6. CENTRAL DUAL TITANIUM EXHAUST (High Mounted V12 Outlets)
    # -------------------------------------------------------------
    obj.set_material("Mat_TitaniumExhaust")
    
    # Dual Hexagonal Center Pipes (Z = 2.30, Y = 0.52)
    v_ex_tl = obj.add_vertex(-0.16, 0.56, 2.28)
    v_ex_tr = obj.add_vertex(0.16, 0.56, 2.28)
    v_ex_bl = obj.add_vertex(-0.16, 0.46, 2.28)
    v_ex_br = obj.add_vertex(0.16, 0.46, 2.28)
    obj.add_quad(v_ex_tl, v_ex_tr, v_ex_br, v_ex_bl)

    # -------------------------------------------------------------
    # 7. SVJ MOTORSPORT REAR WING & DIFFUSER (Carbon Fiber)
    # -------------------------------------------------------------
    obj.set_material("Mat_CarbonFiber")
    
    # Aggressive Underbody Rear Diffuser (Fins extending to Z = 2.42)
    v_dif_bl = obj.add_vertex(-0.88, 0.12, 2.38)
    v_dif_br = obj.add_vertex(0.88, 0.12, 2.38)
    v_dif_tl = obj.add_vertex(-0.88, 0.35, 2.25)
    v_dif_tr = obj.add_vertex(0.88, 0.35, 2.25)
    obj.add_quad(v_dif_bl, v_dif_tl, v_dif_tr, v_dif_br)

    # Diffuser Vertical Aero Fins (4 aerodynamic strakes)
    for fin_x in [-0.55, -0.20, 0.20, 0.55]:
        v_f1 = obj.add_vertex(fin_x, 0.08, 2.00)
        v_f2 = obj.add_vertex(fin_x, 0.28, 2.10)
        v_f3 = obj.add_vertex(fin_x, 0.28, 2.42)
        v_f4 = obj.add_vertex(fin_x, 0.08, 2.40)
        obj.add_quad(v_f1, v_f2, v_f3, v_f4)

    # High-Mounted SVJ Carbon Rear Wing (Swan-neck Stanchions & Airfoil)
    # Stanchion Left
    v_st_l1 = obj.add_vertex(-0.45, 0.74, 1.75)
    v_st_l2 = obj.add_vertex(-0.45, 1.15, 1.95)
    v_st_l3 = obj.add_vertex(-0.42, 1.15, 1.95)
    v_st_l4 = obj.add_vertex(-0.42, 0.74, 1.75)
    obj.add_quad(v_st_l1, v_st_l2, v_st_l3, v_st_l4)

    # Stanchion Right
    v_st_r1 = obj.add_vertex(0.42, 0.74, 1.75)
    v_st_r2 = obj.add_vertex(0.42, 1.15, 1.95)
    v_st_r3 = obj.add_vertex(0.45, 1.15, 1.95)
    v_st_r4 = obj.add_vertex(0.45, 0.74, 1.75)
    obj.add_quad(v_st_r1, v_st_r2, v_st_r3, v_st_r4)

    # Aerodynamic Wing Airfoil Span (Width = 2.05m, Chord = 0.38m)
    v_w_fl = obj.add_vertex(-1.02, 1.18, 1.90)
    v_w_fr = obj.add_vertex(1.02, 1.18, 1.90)
    v_w_rl = obj.add_vertex(-1.00, 1.14, 2.28)
    v_w_rr = obj.add_vertex(1.00, 1.14, 2.28)
    
    # Top and bottom surfaces
    obj.add_quad(v_w_fl, v_w_rl, v_w_rr, v_w_fr) # top foil
    obj.add_quad(v_w_fr, v_w_rr, v_w_rl, v_w_fl) # bottom foil

    # Wing Endplates (Outer vertical aerodynamic plates)
    v_ep_lt = obj.add_vertex(-1.02, 1.30, 2.10)
    v_ep_lb = obj.add_vertex(-1.02, 1.05, 2.10)
    obj.add_tri(v_w_fl, v_ep_lt, v_w_rl)
    obj.add_tri(v_w_rl, v_ep_lb, v_w_fl)

    v_ep_rt = obj.add_vertex(1.02, 1.30, 2.10)
    v_ep_rb = obj.add_vertex(1.02, 1.05, 2.10)
    obj.add_tri(v_w_fr, v_w_rr, v_ep_rt)
    obj.add_tri(v_w_rr, v_w_fr, v_ep_rb)

    obj_path = os.path.join(MODELS_DIR, "lamborghini_body.obj")
    obj.export(obj_path)

def generate_lamborghini_wheel():
    obj = OBJBuilder()
    
    # Low-Profile Supercar Sport Tire (Pirelli P Zero Corsa style)
    # Radius = 0.36m, Width = 0.28m, oriented along Z/X
    segments = 24
    radius_tire = 0.36
    radius_rim = 0.24
    half_width = 0.14
    
    # 1. Rubber Tire Tread & Sidewalls
    obj.set_material("Mat_Tire")
    outer_circle_out = []
    outer_circle_in = []
    inner_circle_out = []
    inner_circle_in = []
    
    for i in range(segments):
        ang = (2.0 * math.pi * i) / segments
        y = math.cos(ang) * radius_tire
        z = math.sin(ang) * radius_tire
        y_rim = math.cos(ang) * radius_rim
        z_rim = math.sin(ang) * radius_rim
        
        outer_circle_out.append(obj.add_vertex(half_width, y, z))
        outer_circle_in.append(obj.add_vertex(-half_width, y, z))
        inner_circle_out.append(obj.add_vertex(half_width - 0.02, y_rim, z_rim))
        inner_circle_in.append(obj.add_vertex(-half_width + 0.02, y_rim, z_rim))
        
    for i in range(segments):
        nxt = (i + 1) % segments
        # Tread surface
        obj.add_quad(outer_circle_out[i], outer_circle_out[nxt], outer_circle_in[nxt], outer_circle_in[i])
        # Outer sidewall
        obj.add_quad(outer_circle_out[i], inner_circle_out[i], inner_circle_out[nxt], outer_circle_out[nxt])
        # Inner sidewall
        obj.add_quad(outer_circle_in[i], outer_circle_in[nxt], inner_circle_in[nxt], inner_circle_in[i])

    # 2. Forged Y-Spoke Alloy Rim (Satin Graphite / Chrome)
    obj.set_material("Mat_Rim")
    hub_radius = 0.07
    hub_out = []
    for i in range(segments):
        ang = (2.0 * math.pi * i) / segments
        y = math.cos(ang) * hub_radius
        z = math.sin(ang) * hub_radius
        hub_out.append(obj.add_vertex(half_width - 0.04, y, z))
        
    # Rim outer lip cylinder
    for i in range(segments):
        nxt = (i + 1) % segments
        # 5 double-spoke pattern: spoke on alternating segments
        if i % 2 == 0 or (i % 5 < 3):
            obj.add_quad(inner_circle_out[i], hub_out[i], hub_out[nxt], inner_circle_out[nxt])
            
    # Center Hub Nut
    v_hub_cap = obj.add_vertex(half_width - 0.02, 0.0, 0.0)
    for i in range(segments):
        nxt = (i + 1) % segments
        obj.add_tri(hub_out[i], v_hub_cap, hub_out[nxt])

    # 3. Ventilated Carbon-Ceramic Brake Disc & Brembo Caliper
    obj.set_material("Mat_BrakeDisc")
    v_disc_c = obj.add_vertex(0.0, 0.0, 0.0)
    disc_radius = 0.20
    disc_pts = []
    for i in range(16):
        ang = (2.0 * math.pi * i) / 16
        y = math.cos(ang) * disc_radius
        z = math.sin(ang) * disc_radius
        disc_pts.append(obj.add_vertex(0.0, y, z))
    for i in range(16):
        nxt = (i + 1) % 16
        obj.add_tri(disc_pts[i], disc_pts[nxt], v_disc_c)

    # Brembo Sport Brake Caliper (Lamborghini Yellow)
    obj.set_material("Mat_BrakeCaliper")
    # Caliper clamped on top-forward quadrant
    v_cal_1 = obj.add_vertex(0.04, 0.12, -0.16)
    v_cal_2 = obj.add_vertex(0.04, 0.22, -0.06)
    v_cal_3 = obj.add_vertex(-0.04, 0.22, -0.06)
    v_cal_4 = obj.add_vertex(-0.04, 0.12, -0.16)
    obj.add_quad(v_cal_1, v_cal_2, v_cal_3, v_cal_4)

    wheel_path = os.path.join(MODELS_DIR, "lamborghini_wheel.obj")
    obj.export(wheel_path)

if __name__ == "__main__":
    generate_lamborghini_body()
    generate_lamborghini_wheel()
    print("Lamborghini 3D models generated successfully!")
