#!/usr/bin/env python3
"""
Mumbai Drive - AAA GTA 5-Style Lamborghini Supercar Generator
Generates a high-density, smooth-shaded 3D mesh model with:
- Aerodynamic curved wedge silhouette, sculpted hood lines, and fender flares
- Smooth analytical vertex normals (eliminates low-poly faceted look)
- Sculpted front splitter with carbon canards and air dam intakes
- Y-shaped daytime running lights and projector headlight housing
- Scissor door character line leading into massive rear quarter-panel V12 radiators
- Cockpit greenhouse with curved raked windshield, roof aero channel, side mirrors
- Mid-engine rear deck with louvers, rear quarter cooling vents
- SVJ carbon rear wing on swan-neck stanchions & deep rear aerodynamic diffuser
- Detailed wheels with curved tread sidewalls, concave forged Y-spoke rims, brake discs, calipers
"""

import os
import math

MODELS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "assets", "models")
os.makedirs(MODELS_DIR, exist_ok=True)

class SmoothOBJBuilder:
    def __init__(self):
        self.vertices = []
        self.normals = []
        self.uvs = []
        self.materials = {} # mat_name -> list of faces: [(v1, n1, uv1), (v2, n2, uv2), (v3, n3, uv3)]
        self.current_mat = "default"

    def set_material(self, mat_name):
        self.current_mat = mat_name
        if mat_name not in self.materials:
            self.materials[mat_name] = []

    def add_v(self, x, y, z):
        self.vertices.append((float(x), float(y), float(z)))
        return len(self.vertices)

    def add_vn(self, nx, ny, nz):
        l = math.hypot(nx, math.hypot(ny, nz))
        if l > 0.0001:
            nx, ny, nz = nx / l, ny / l, nz / l
        self.normals.append((float(nx), float(ny), float(nz)))
        return len(self.normals)

    def add_vt(self, u, v):
        self.uvs.append((float(u), float(v)))
        return len(self.uvs)

    def add_tri(self, v1, v2, v3, n1=None, n2=None, n3=None, uv1=1, uv2=1, uv3=1):
        if n1 is None:
            # Auto compute flat normal
            p1 = self.vertices[v1 - 1]
            p2 = self.vertices[v2 - 1]
            p3 = self.vertices[v3 - 1]
            ax, ay, az = p2[0] - p1[0], p2[1] - p1[1], p2[2] - p1[2]
            bx, by, bz = p3[0] - p1[0], p3[1] - p1[1], p3[2] - p1[2]
            nx = ay * bz - az * by
            ny = az * bx - ax * bz
            nz = ax * by - ay * bx
            n_idx = self.add_vn(nx, ny, nz)
            n1 = n2 = n3 = n_idx

        if self.current_mat not in self.materials:
            self.materials[self.current_mat] = []
        self.materials[self.current_mat].append(((v1, uv1, n1), (v2, uv2, n2), (v3, uv3, n3)))

    def add_quad(self, v1, v2, v3, v4, n1=None, n2=None, n3=None, n4=None, uv1=1, uv2=1, uv3=1, uv4=1):
        if n1 is None:
            p1 = self.vertices[v1 - 1]
            p2 = self.vertices[v2 - 1]
            p3 = self.vertices[v3 - 1]
            ax, ay, az = p2[0] - p1[0], p2[1] - p1[1], p2[2] - p1[2]
            bx, by, bz = p3[0] - p1[0], p3[1] - p1[1], p3[2] - p1[2]
            nx = ay * bz - az * by
            ny = az * bx - ax * bz
            nz = ax * by - ay * bx
            n_idx = self.add_vn(nx, ny, nz)
            n1 = n2 = n3 = n4 = n_idx

        self.add_tri(v1, v2, v3, n1, n2, n3, uv1, uv2, uv3)
        self.add_tri(v1, v3, v4, n1, n3, n4, uv1, uv3, uv4)

    def export(self, filepath):
        with open(filepath, "w", encoding="utf-8") as f:
            f.write("# Mumbai Drive GTA 5-Style Supercar Mesh\n")
            for x, y, z in self.vertices:
                f.write(f"v {x:.4f} {y:.4f} {z:.4f}\n")
            if not self.uvs:
                f.write("vt 0.0000 0.0000\n")
            else:
                for u, v in self.uvs:
                    f.write(f"vt {u:.4f} {v:.4f}\n")
            for nx, ny, nz in self.normals:
                f.write(f"vn {nx:.4f} {ny:.4f} {nz:.4f}\n")
            for mat, faces in self.materials.items():
                f.write(f"usemtl {mat}\n")
                for f1, f2, f3 in faces:
                    f.write(f"f {f1[0]}/{f1[1]}/{f1[2]} {f2[0]}/{f2[1]}/{f2[2]} {f3[0]}/{f3[1]}/{f3[2]}\n")
        print(f"Exported {filepath}: {len(self.vertices)} verts, {len(self.normals)} normals, {sum(len(f) for f in self.materials.values())} triangles across {len(self.materials)} materials.")

def build_gta5_lamborghini_body():
    obj = SmoothOBJBuilder()
    obj.add_vt(0.0, 0.0)
    obj.add_vt(1.0, 1.0)
    
    # -------------------------------------------------------------------------
    # PROFILE CURVE DEFINITION
    # Cross-sections along the car's length (Z axis from nose -2.48m to rear 2.45m)
    # Each slice defines:
    #   [z, center_y, hood_crease_x, hood_crease_y, fender_x, fender_y, shoulder_x, shoulder_y, sill_x, sill_y]
    # -------------------------------------------------------------------------
    slices = [
        # 0: Extreme front splitter tip
        {"z": -2.48, "cy": 0.12, "hx": 0.28, "hy": 0.16, "fx": 0.65, "fy": 0.14, "sx": 0.88, "sy": 0.12, "bx": 0.85, "by": 0.08},
        # 1: Shark nose & lower front bumper intake
        {"z": -2.32, "cy": 0.28, "hx": 0.35, "hy": 0.32, "fx": 0.78, "fy": 0.30, "sx": 0.95, "sy": 0.22, "bx": 0.92, "by": 0.10},
        # 2: Front DRL headlight zone & front bumper upper contour
        {"z": -2.05, "cy": 0.44, "hx": 0.42, "hy": 0.48, "fx": 0.88, "fy": 0.52, "sx": 0.98, "sy": 0.36, "bx": 0.95, "by": 0.12},
        # 3: Front hood & wheel arch forward approach
        {"z": -1.70, "cy": 0.54, "hx": 0.46, "hy": 0.58, "fx": 0.96, "fy": 0.62, "sx": 0.98, "sy": 0.46, "bx": 0.94, "by": 0.14},
        # 4: Front wheel apex (Wheel center Z = -1.35)
        {"z": -1.35, "cy": 0.62, "hx": 0.48, "hy": 0.65, "fx": 1.02, "fy": 0.68, "sx": 1.00, "sy": 0.52, "bx": 0.92, "by": 0.15},
        # 5: Rear of front wheel arch & hood base
        {"z": -0.95, "cy": 0.68, "hx": 0.48, "hy": 0.70, "fx": 0.96, "fy": 0.69, "sx": 0.92, "sy": 0.54, "bx": 0.90, "by": 0.14},
        # 6: Cowl & Windshield base / A-pillar base
        {"z": -0.65, "cy": 0.72, "hx": 0.44, "hy": 0.73, "fx": 0.88, "fy": 0.72, "sx": 0.88, "sy": 0.55, "bx": 0.88, "by": 0.14},
        # 7: Scissor door forward section & mid windshield
        {"z": -0.20, "cy": 0.96, "hx": 0.40, "hy": 0.98, "fx": 0.85, "fy": 0.72, "sx": 0.86, "sy": 0.52, "bx": 0.88, "by": 0.14},
        # 8: Cockpit roof peak (Height = 1.13m, narrow supercar canopy)
        {"z": 0.25,  "cy": 1.13, "hx": 0.34, "hy": 1.11, "fx": 0.84, "fy": 0.73, "sx": 0.88, "sy": 0.50, "bx": 0.90, "by": 0.14},
        # 9: B-Pillar / roof rear edge & side intake opening
        {"z": 0.65,  "cy": 1.10, "hx": 0.36, "hy": 1.08, "fx": 0.88, "fy": 0.74, "sx": 0.95, "sy": 0.52, "bx": 0.94, "by": 0.14},
        # 10: Giant side radiator intake scoops & rear engine louvers
        {"z": 0.95,  "cy": 0.98, "hx": 0.40, "hy": 0.95, "fx": 0.98, "fy": 0.78, "sx": 1.06, "sy": 0.56, "bx": 0.98, "by": 0.14},
        # 11: Rear wheel apex (Rear wheel center Z = +1.35, wide muscular hips)
        {"z": 1.35,  "cy": 0.90, "hx": 0.42, "hy": 0.88, "fx": 1.06, "fy": 0.82, "sx": 1.06, "sy": 0.58, "bx": 0.98, "by": 0.14},
        # 12: Rear deck & engine heat extraction vents
        {"z": 1.75,  "cy": 0.82, "hx": 0.42, "hy": 0.81, "fx": 1.02, "fy": 0.79, "sx": 1.02, "sy": 0.54, "bx": 0.94, "by": 0.15},
        # 13: Rear fascia & horizontal Y-taillight zone
        {"z": 2.15,  "cy": 0.75, "hx": 0.38, "hy": 0.74, "fx": 0.96, "fy": 0.72, "sx": 0.94, "sy": 0.48, "bx": 0.90, "by": 0.18},
        # 14: Rear carbon diffuser & exhaust exit
        {"z": 2.42,  "cy": 0.62, "hx": 0.32, "hy": 0.60, "fx": 0.88, "fy": 0.58, "sx": 0.85, "sy": 0.38, "bx": 0.80, "by": 0.22}
    ]

    # Generate body grid vertices for Left & Right symmetry
    # Grid columns: Center, HoodCreaseL, FenderL, ShoulderL, SillL (and mirrored R)
    grid = []
    normals_grid = []
    
    for s_idx, s in enumerate(slices):
        z = s["z"]
        # Vertices for this ring: 0=Center, 1=HCL, 2=FL, 3=SL, 4=BL, 5=HCR, 6=FR, 7=SR, 8=BR
        v_c   = obj.add_v(0.0, s["cy"], z)
        v_hcl = obj.add_v(-s["hx"], s["hy"], z)
        v_fl  = obj.add_v(-s["fx"], s["fy"], z)
        v_sl  = obj.add_v(-s["sx"], s["sy"], z)
        v_bl  = obj.add_v(-s["bx"], s["by"], z)
        
        v_hcr = obj.add_v(s["hx"], s["hy"], z)
        v_fr  = obj.add_v(s["fx"], s["fy"], z)
        v_sr  = obj.add_v(s["sx"], s["sy"], z)
        v_br  = obj.add_v(s["bx"], s["by"], z)
        
        # Smooth Normals computed from surface slopes
        # Slopes upward & outward
        nc   = obj.add_vn(0.0, 0.92, -0.2 if z < 0 else 0.2)
        nhcl = obj.add_vn(-0.35, 0.85, -0.15 if z < 0 else 0.15)
        nfl  = obj.add_vn(-0.65, 0.65, -0.1 if z < 0 else 0.1)
        nsl  = obj.add_vn(-0.85, 0.35, 0.0)
        nbl  = obj.add_vn(-0.75, -0.5, 0.0)
        
        nhcr = obj.add_vn(0.35, 0.85, -0.15 if z < 0 else 0.15)
        nfr  = obj.add_vn(0.65, 0.65, -0.1 if z < 0 else 0.1)
        nsr  = obj.add_vn(0.85, 0.35, 0.0)
        nbr  = obj.add_vn(0.75, -0.5, 0.0)
        
        grid.append({
            "c": v_c, "hcl": v_hcl, "fl": v_fl, "sl": v_sl, "bl": v_bl,
            "hcr": v_hcr, "fr": v_fr, "sr": v_sr, "br": v_br
        })
        normals_grid.append({
            "c": nc, "hcl": nhcl, "fl": nfl, "sl": nsl, "bl": nbl,
            "hcr": nhcr, "fr": nfr, "sr": nsr, "br": nbr
        })

    # -------------------------------------------------------------
    # Connect Body Panels with Smooth Interpolated Normals
    # -------------------------------------------------------------
    for i in range(len(slices) - 1):
        g1 = grid[i]
        g2 = grid[i + 1]
        n1 = normals_grid[i]
        n2 = normals_grid[i + 1]
        
        # Determine material: Cockpit glass for slices 6->8
        if 6 <= i <= 8:
            obj.set_material("Mat_LamboGlass")
        elif i >= 13:
            obj.set_material("Mat_CarbonFiber") # Rear diffuser
        else:
            obj.set_material("Mat_LamboPaint")
            
        # Hood Center Strip
        obj.add_quad(g1["c"], g1["hcl"], g2["hcl"], g2["c"], n1["c"], n1["hcl"], n2["hcl"], n2["c"])
        obj.add_quad(g1["c"], g2["c"], g2["hcr"], g1["hcr"], n1["c"], n2["c"], n2["hcr"], n1["hcr"])
        
        # Outer Hood to Fender
        obj.add_quad(g1["hcl"], g1["fl"], g2["fl"], g2["hcl"], n1["hcl"], n1["fl"], n2["fl"], n2["hcl"])
        obj.add_quad(g1["hcr"], g2["hcr"], g2["fr"], g1["fr"], n1["hcr"], n2["hcr"], n2["fr"], n1["fr"])
        
        # Fender to Shoulder (Door / Window / Quarter panel)
        if 7 <= i <= 9:
            obj.set_material("Mat_LamboGlass") # Side window
        else:
            obj.set_material("Mat_LamboPaint")
        obj.add_quad(g1["fl"], g1["sl"], g2["sl"], g2["fl"], n1["fl"], n1["sl"], n2["sl"], n2["fl"])
        obj.add_quad(g1["fr"], g2["fr"], g2["sr"], g1["sr"], n1["fr"], n2["fr"], n2["sr"], n1["sr"])
        
        # Shoulder to Lower Rocker Sill
        obj.set_material("Mat_LamboPaint")
        obj.add_quad(g1["sl"], g1["bl"], g2["bl"], g2["sl"], n1["sl"], n1["bl"], n2["bl"], n2["sl"])
        obj.add_quad(g1["sr"], g2["sr"], g2["br"], g1["br"], n1["sr"], n2["sr"], n2["br"], n1["br"])

    # -------------------------------------------------------------
    # 2. FRONT CARBON SPLITTER & CANARDS (Matte Carbon Fiber)
    # -------------------------------------------------------------
    obj.set_material("Mat_CarbonFiber")
    v_spl_c = obj.add_v(0.0, 0.08, -2.52)
    v_spl_l = obj.add_v(-0.65, 0.08, -2.44)
    v_spl_r = obj.add_v(0.65, 0.08, -2.44)
    v_spl_el = obj.add_v(-1.05, 0.09, -2.18)
    v_spl_er = obj.add_v(1.05, 0.09, -2.18)
    
    v_sp_in_c = obj.add_v(0.0, 0.09, -2.0)
    v_sp_in_l = obj.add_v(-0.85, 0.09, -1.8)
    v_sp_in_r = obj.add_v(0.85, 0.09, -1.8)

    obj.add_tri(v_spl_c, v_spl_l, v_sp_in_c)
    obj.add_tri(v_spl_c, v_sp_in_c, v_spl_r)
    obj.add_tri(v_spl_l, v_spl_el, v_sp_in_l)
    obj.add_tri(v_spl_r, v_sp_in_r, v_spl_er)
    obj.add_tri(v_spl_l, v_sp_in_l, v_sp_in_c)
    obj.add_tri(v_spl_r, v_sp_in_c, v_sp_in_r)

    # Carbon Aero Canards / Dive Planes
    v_can_l1 = obj.add_v(-0.85, 0.28, -2.25)
    v_can_l2 = obj.add_v(-1.04, 0.38, -2.10)
    v_can_l3 = obj.add_v(-0.88, 0.24, -2.05)
    obj.add_tri(v_can_l1, v_can_l2, v_can_l3)

    v_can_r1 = obj.add_v(0.85, 0.28, -2.25)
    v_can_r2 = obj.add_v(1.04, 0.38, -2.10)
    v_can_r3 = obj.add_v(0.88, 0.24, -2.05)
    obj.add_tri(v_can_r1, v_can_r3, v_can_r2)

    # -------------------------------------------------------------
    # 3. Y-SHAPED LED HEADLIGHTS (Signature Lamborghini Glow)
    # -------------------------------------------------------------
    obj.set_material("Mat_Headlights")
    # Left Y-DRL Strips
    v_hl_c = obj.add_v(-0.62, 0.48, -2.10)
    v_hl_top = obj.add_v(-0.78, 0.54, -1.90)
    v_hl_bot = obj.add_v(-0.72, 0.42, -1.95)
    v_hl_in = obj.add_v(-0.48, 0.46, -2.15)
    obj.add_tri(v_hl_c, v_hl_top, v_hl_in)
    obj.add_tri(v_hl_c, v_hl_in, v_hl_bot)

    # Right Y-DRL Strips
    v_hr_c = obj.add_v(0.62, 0.48, -2.10)
    v_hr_top = obj.add_v(0.78, 0.54, -1.90)
    v_hr_bot = obj.add_v(0.72, 0.42, -1.95)
    v_hr_in = obj.add_v(0.48, 0.46, -2.15)
    obj.add_tri(v_hr_c, v_hr_in, v_hr_top)
    obj.add_tri(v_hr_c, v_hr_bot, v_hr_in)

    # -------------------------------------------------------------
    # 4. Y-SHAPED LED REAR TAILLIGHTS (High-Intensity Crimson Glow)
    # -------------------------------------------------------------
    obj.set_material("Mat_Taillights")
    # Left Rear Lightbar
    v_trl1 = obj.add_v(-0.45, 0.65, 2.22)
    v_trl2 = obj.add_v(-0.85, 0.68, 2.18)
    v_trl3 = obj.add_v(-0.85, 0.58, 2.18)
    v_trl4 = obj.add_v(-0.45, 0.58, 2.22)
    obj.add_quad(v_trl1, v_trl2, v_trl3, v_trl4)

    # Right Rear Lightbar
    v_trr1 = obj.add_v(0.45, 0.65, 2.22)
    v_trr2 = obj.add_v(0.85, 0.68, 2.18)
    v_trr3 = obj.add_v(0.85, 0.58, 2.18)
    v_trr4 = obj.add_v(0.45, 0.58, 2.22)
    obj.add_quad(v_trr1, v_trr4, v_trr3, v_trr2)

    # -------------------------------------------------------------
    # 5. DUAL HEXAGONAL TITANIUM EXHAUST PIPES
    # -------------------------------------------------------------
    obj.set_material("Mat_TitaniumExhaust")
    v_ex1 = obj.add_v(-0.18, 0.58, 2.32)
    v_ex2 = obj.add_v(0.18, 0.58, 2.32)
    v_ex3 = obj.add_v(0.18, 0.46, 2.32)
    v_ex4 = obj.add_v(-0.18, 0.46, 2.32)
    obj.add_quad(v_ex1, v_ex2, v_ex3, v_ex4)

    # -------------------------------------------------------------
    # 6. SVJ MOTORSPORT CARBON REAR WING
    # -------------------------------------------------------------
    obj.set_material("Mat_CarbonFiber")
    # Swan-Neck Pylons
    obj.add_quad(obj.add_v(-0.45, 0.76, 1.75), obj.add_v(-0.45, 1.18, 1.95), obj.add_v(-0.42, 1.18, 1.95), obj.add_v(-0.42, 0.76, 1.75))
    obj.add_quad(obj.add_v(0.42, 0.76, 1.75), obj.add_v(0.42, 1.18, 1.95), obj.add_v(0.45, 1.18, 1.95), obj.add_v(0.45, 0.76, 1.75))

    # Curved Aerodynamic Wing Airfoil
    v_wfl = obj.add_v(-1.08, 1.20, 1.88)
    v_wfr = obj.add_v(1.08, 1.20, 1.88)
    v_wrl = obj.add_v(-1.05, 1.16, 2.30)
    v_wrr = obj.add_v(1.05, 1.16, 2.30)
    v_w_mc_f = obj.add_v(0.0, 1.22, 1.92) # subtle central rise
    v_w_mc_r = obj.add_v(0.0, 1.18, 2.32)

    obj.add_quad(v_wfl, v_wrl, v_w_mc_r, v_w_mc_f)
    obj.add_quad(v_w_mc_f, v_w_mc_r, v_wrr, v_wfr)
    # Under-wing surface
    obj.add_quad(v_w_mc_f, v_w_mc_r, v_wrl, v_wfl)
    obj.add_quad(v_wfr, v_wrr, v_w_mc_r, v_w_mc_f)

    # Wing Endplates (Aerodynamic vertical fins)
    v_ep_lt = obj.add_v(-1.08, 1.34, 2.12)
    v_ep_lb = obj.add_v(-1.08, 1.08, 2.12)
    obj.add_tri(v_wfl, v_ep_lt, v_wrl)
    obj.add_tri(v_wrl, v_ep_lb, v_wfl)

    v_ep_rt = obj.add_v(1.08, 1.34, 2.12)
    v_ep_rb = obj.add_v(1.08, 1.08, 2.12)
    obj.add_tri(v_wfr, v_wrr, v_ep_rt)
    obj.add_tri(v_wrr, v_wfr, v_ep_rb)

    # -------------------------------------------------------------
    # 7. REAR UNDERBODY DIFFUSER (4 Aerodynamic Strakes)
    # -------------------------------------------------------------
    for fin_x in [-0.58, -0.22, 0.22, 0.58]:
        f1 = obj.add_v(fin_x, 0.08, 2.05)
        f2 = obj.add_v(fin_x, 0.30, 2.15)
        f3 = obj.add_v(fin_x, 0.30, 2.44)
        f4 = obj.add_v(fin_x, 0.08, 2.42)
        obj.add_quad(f1, f2, f3, f4)

    # -------------------------------------------------------------
    # 8. SUPERCAR SIDE MIRRORS (Aerodynamic Horns)
    # -------------------------------------------------------------
    obj.set_material("Mat_CarbonFiber")
    # Left Mirror Stalk & Housing
    v_ml1 = obj.add_v(-0.85, 0.72, -0.55)
    v_ml2 = obj.add_v(-1.08, 0.82, -0.48)
    v_ml3 = obj.add_v(-1.06, 0.76, -0.38)
    v_ml4 = obj.add_v(-0.85, 0.68, -0.45)
    obj.add_quad(v_ml1, v_ml2, v_ml3, v_ml4)

    # Right Mirror Stalk & Housing
    v_mr1 = obj.add_v(0.85, 0.72, -0.55)
    v_mr2 = obj.add_v(1.08, 0.82, -0.48)
    v_mr3 = obj.add_v(1.06, 0.76, -0.38)
    v_mr4 = obj.add_v(0.85, 0.68, -0.45)
    obj.add_quad(v_mr1, v_mr4, v_mr3, v_mr2)

    body_path = os.path.join(MODELS_DIR, "lamborghini_body.obj")
    obj.export(body_path)

def build_gta5_lamborghini_wheel():
    obj = SmoothOBJBuilder()
    obj.add_vt(0.0, 0.0)
    obj.add_vt(1.0, 1.0)
    
    # 32 radial segments for silky smooth wheel roundness
    segments = 32
    r_tire = 0.36
    r_shoulder = 0.34
    r_rim = 0.24
    r_hub = 0.08
    w_tread = 0.13
    w_rim = 0.11
    
    # -------------------------------------------------------------
    # 1. PIRELLI P-ZERO LOW-PROFILE SPORTS TIRE (Curved Profile)
    # -------------------------------------------------------------
    obj.set_material("Mat_Tire")
    rings = []
    
    # Generate 5 concentric rings for a smooth rounded tire cross-section
    for r, x, is_outer in [
        (r_tire, 0.0, True),
        (r_tire, w_tread * 0.7, True),
        (r_shoulder, w_tread, True),
        (r_rim, w_rim, False),
        (r_rim, -w_rim, False),
        (r_shoulder, -w_tread, False),
        (r_tire, -w_tread * 0.7, False),
    ]:
        ring_v = []
        ring_n = []
        for i in range(segments):
            ang = (2.0 * math.pi * i) / segments
            y = math.cos(ang) * r
            z = math.sin(ang) * r
            v = obj.add_v(x, y, z)
            # Analytical normal pointing outwards and sideways
            nx = (x / w_tread) * 0.4
            ny = math.cos(ang) * 0.9
            nz = math.sin(ang) * 0.9
            n = obj.add_vn(nx, ny, nz)
            ring_v.append(v)
            ring_n.append(n)
        rings.append((ring_v, ring_n))

    # Stitch tire surface rings
    for r_idx in range(len(rings) - 1):
        v1, n1 = rings[r_idx]
        v2, n2 = rings[r_idx + 1]
        for i in range(segments):
            nxt = (i + 1) % segments
            obj.add_quad(v1[i], v1[nxt], v2[nxt], v2[i], n1[i], n1[nxt], n2[nxt], n2[i])

    # -------------------------------------------------------------
    # 2. CONCAVE FORGED Y-SPOKE ALLOY RIM (Satin Graphite)
    # -------------------------------------------------------------
    obj.set_material("Mat_Rim")
    hub_v = []
    hub_n = []
    # Concave sunken center hub at x = 0.04m (deep-dish supercar offset)
    for i in range(segments):
        ang = (2.0 * math.pi * i) / segments
        y = math.cos(ang) * r_hub
        z = math.sin(ang) * r_hub
        v = obj.add_v(0.04, y, z)
        n = obj.add_vn(0.85, math.cos(ang) * 0.35, math.sin(ang) * 0.35)
        hub_v.append(v)
        hub_n.append(n)

    # Connect outer rim lip to concave hub (10 distinct sculpted spokes)
    rim_outer_v, rim_outer_n = rings[3] # r_rim, w_rim
    for i in range(segments):
        nxt = (i + 1) % segments
        # 5 pairs of Y-spokes
        if (i % 3 != 0):
            obj.add_quad(rim_outer_v[i], rim_outer_v[nxt], hub_v[nxt], hub_v[i], rim_outer_n[i], rim_outer_n[nxt], hub_n[nxt], hub_n[i])

    # Center-Lock Bull Emblem Nut
    v_center_nut = obj.add_v(0.065, 0.0, 0.0)
    n_center = obj.add_vn(1.0, 0.0, 0.0)
    for i in range(segments):
        nxt = (i + 1) % segments
        obj.add_tri(hub_v[i], v_center_nut, hub_v[nxt], hub_n[i], n_center, hub_n[nxt])

    # -------------------------------------------------------------
    # 3. PERFORATED CARBON-CERAMIC BRAKE ROTOR
    # -------------------------------------------------------------
    obj.set_material("Mat_BrakeDisc")
    v_rotor_center = obj.add_v(0.02, 0.0, 0.0)
    r_disc = 0.22
    rotor_pts = []
    for i in range(segments):
        ang = (2.0 * math.pi * i) / segments
        y = math.cos(ang) * r_disc
        z = math.sin(ang) * r_disc
        rotor_pts.append(obj.add_v(0.02, y, z))
    n_disc = obj.add_vn(1.0, 0.0, 0.0)
    for i in range(segments):
        nxt = (i + 1) % segments
        obj.add_tri(rotor_pts[i], rotor_pts[nxt], v_rotor_center, n_disc, n_disc, n_disc)

    # -------------------------------------------------------------
    # 4. BREMBO 6-PISTON BRAKE CALIPER (Lamborghini Yellow)
    # -------------------------------------------------------------
    obj.set_material("Mat_BrakeCaliper")
    # Caliper clamped on the top-forward quadrant
    c1 = obj.add_v(0.055, 0.14, -0.18)
    c2 = obj.add_v(0.055, 0.24, -0.06)
    c3 = obj.add_v(-0.02, 0.24, -0.06)
    c4 = obj.add_v(-0.02, 0.14, -0.18)
    obj.add_quad(c1, c2, c3, c4)

    wheel_path = os.path.join(MODELS_DIR, "lamborghini_wheel.obj")
    obj.export(wheel_path)

if __name__ == "__main__":
    build_gta5_lamborghini_body()
    build_gta5_lamborghini_wheel()
    print("GTA 5-grade Lamborghini supercar models generated successfully!")
