# pyright: reportMissingImports=false
"""
Blender 5.2 Supercar Post-Processor: Authentic Lamborghini Aventador
1. Auto-launches inside Blender if invoked from standard Python (VS Code / terminal).
2. Automatically verifies / downloads authentic CAD model if missing into a .gdignored folder.
3. Normalizes coordinate bounds (centered at X=0, Y=0, tires on Z=0 ground).
4. Configures high-end PBR materials (Giallo Auge pearl paint, carbon fiber, LED emissions, tinted glass).
5. Exports both GLB (lamborghini_car.glb without Draco) and OBJ (lamborghini_body.obj + .mtl) for Godot 4.
"""

import os
import sys
import subprocess
import shutil
import urllib.request
import importlib

def find_blender():
    """Finds the Blender executable on Windows, Linux, or macOS."""
    if os.environ.get("BLENDER_PATH") and os.path.isfile(os.environ["BLENDER_PATH"]):
        return os.environ["BLENDER_PATH"]
    which_b = shutil.which("blender")
    if which_b:
        return which_b
    candidates = [
        r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.3\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.2\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.1\blender.exe",
        r"C:\Program Files\Blender Foundation\Blender 4.0\blender.exe",
    ]
    for c in candidates:
        if os.path.isfile(c):
            return c
    return None

# If running outside Blender (e.g. from VS Code or standard python), re-launch inside Blender
if "bpy" not in sys.modules:
    try:
        importlib.import_module("bpy")
    except ImportError:
        blender_exe = find_blender()
        if not blender_exe:
            print("ERROR: Blender executable not found. Please install Blender 4.x or 5.x or set BLENDER_PATH.")
            sys.exit(1)
        print(f"[Auto-Launcher] Launching script via Blender ({blender_exe})...")
        res = subprocess.run([blender_exe, "--background", "--python", os.path.abspath(__file__)])
        sys.exit(res.returncode)

# Dynamically import Blender modules to eliminate IDE static linter missing-import errors
bpy = sys.modules.get("bpy") or importlib.import_module("bpy")  # type: ignore
_mathutils = sys.modules.get("mathutils") or importlib.import_module("mathutils")  # type: ignore
Vector = getattr(_mathutils, "Vector")  # type: ignore

AVENTADOR_SOURCE_URL = "https://raw.githubusercontent.com/supercar3d/supercar_3D_asssets/main/basic/lamborghini/aventador/aventador.glb"

def get_project_root():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(script_dir, "..", ".."))

def ensure_source_model(project_root):
    # Store raw downloaded source models outside Godot's import scanner
    raw_dir = os.path.join(project_root, "data", "source", "supercars")
    os.makedirs(raw_dir, exist_ok=True)
    
    # Write .gdignore to prevent Godot from trying to import raw Draco models
    gdignore_path = os.path.join(raw_dir, ".gdignore")
    if not os.path.exists(gdignore_path):
        with open(gdignore_path, "w") as f:
            f.write("# Godot: ignore raw source assets\n")
            
    source_path = os.path.join(raw_dir, "aventador_real.glb")
    if not os.path.exists(source_path) or os.path.getsize(source_path) < 1000000:
        print(f"Downloading authentic Lamborghini Aventador model from:\n{AVENTADOR_SOURCE_URL} ...")
        urllib.request.urlretrieve(AVENTADOR_SOURCE_URL, source_path)
        print(f"Downloaded: {source_path} ({os.path.getsize(source_path):,} bytes)")
    return source_path

def clean_mtl_file(mtl_path):
    """Strips legacy 'Ka' ambient light lines to silence Godot 4 PBR import warnings."""
    if not os.path.exists(mtl_path):
        return
    with open(mtl_path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    clean_lines = [l for l in lines if not l.strip().startswith("Ka ")]
    with open(mtl_path, "w", encoding="utf-8") as f:
        f.writelines(clean_lines)
    print(f"Cleaned MTL file: {mtl_path}")

def process_aventador():
    project_root = get_project_root()
    source_glb = ensure_source_model(project_root)
    
    models_dir = os.path.join(project_root, "assets", "models")
    os.makedirs(models_dir, exist_ok=True)
    
    out_glb = os.path.join(models_dir, "lamborghini_car.glb")
    out_obj = os.path.join(models_dir, "lamborghini_body.obj")
    out_mtl = os.path.join(models_dir, "lamborghini_body.mtl")
    
    # Remove any old raw Draco file from assets/models if it exists
    old_raw = os.path.join(models_dir, "aventador_real.glb")
    if os.path.exists(old_raw):
        try:
            os.remove(old_raw)
        except:
            pass
    old_import = os.path.join(models_dir, "aventador_real.glb.import")
    if os.path.exists(old_import):
        try:
            os.remove(old_import)
        except:
            pass
            
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
                
    # Apply decimation to optimize polycount for real-time integrated GPUs (Intel UHD)
    # Reduces massive 430k polygons down to crisp, responsive ~45k triangles
    total_poly_before = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == 'MESH')
    print(f"Total polygons before optimization: {total_poly_before}")
    
    for obj in bpy.data.objects:
        if obj.type == 'MESH' and len(obj.data.polygons) > 100:
            bpy.context.view_layer.objects.active = obj
            mod = obj.modifiers.new(name="Decimate", type='DECIMATE')
            # 0.10 decimation drops the Aventador to ~42,000 polygons (GTA 5 standard)
            mod.ratio = 0.10
            try:
                bpy.ops.object.modifier_apply(modifier="Decimate")
            except Exception as e:
                print(f"Decimate warning for {obj.name}: {e}")
                
    total_poly_after = sum(len(o.data.polygons) for o in bpy.data.objects if o.type == 'MESH')
    print(f"Total polygons after optimization: {total_poly_after}")

    # Select all objects for export
    for obj in bpy.data.objects:
        obj.select_set(True)
        
    print(f"Exporting standard GLB (no Draco) to: {out_glb}")
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
    
    # Strip legacy Ka lines from the MTL file
    clean_mtl_file(out_mtl)
    
    # Remove any loose image dumps so Godot's asset importer doesn't get overwhelmed
    for f in os.listdir(models_dir):
        if "_Image_" in f and (f.endswith(".png") or f.endswith(".jpg") or f.endswith(".import")):
            try:
                os.remove(os.path.join(models_dir, f))
            except Exception:
                pass
    
    print("SUCCESS: Blender Lamborghini processing complete!")
    return True

if __name__ == '__main__':
    process_aventador()
