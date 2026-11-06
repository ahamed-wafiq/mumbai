import json
import os
import math

print("=== VERIFYING BUILDING TILES AND MESH PROPERTIES ===")

# Test tile (0, 0)
tile_file = "data/tiles/tile_0_0.json"
with open(tile_file, "r", encoding="utf-8") as f:
    t0 = json.load(f)

blds = t0.get("buildings", [])
print(f"Tile (0, 0) Buildings: {len(blds)}")
print(f"Tile Bounds: {t0.get('bounds')}")

valid_count = 0
min_height = 999.0
max_height = -999.0
min_y = 999.0

for b in blds:
    footprint = b.get("footprint", [])
    h = b.get("height", 0.0)
    min_height = min(min_height, h)
    max_height = max(max_height, h)
    
    if len(footprint) >= 3:
        valid_count += 1
        for pt in footprint:
            min_y = min(min_y, pt[1])

print(f"Valid Footprints: {valid_count} of {len(blds)}")
print(f"Building Heights: Min={min_height}m, Max={max_height}m")
print(f"Minimum Ground Y: {min_y}m (Ground level is >= 0m)")

print("\n--- SAMPLE BUILDINGS IN TILE (0, 0) ---")
for i, b in enumerate(blds[:5]):
    fp = b.get("footprint", [])
    cx = sum(p[0] for p in fp) / len(fp)
    cz = sum(p[2] for p in fp) / len(fp)
    print(f"[{i+1}] {b.get('name')}: Type={b.get('type')}, Height={b.get('height')}m, Centroid=({cx:.1f}, {cz:.1f}), Vertices={len(fp)}")

# Also test GeoJSON landmarks
gj_file = "data/geojson/mumbai_buildings.geojson"
with open(gj_file, "r", encoding="utf-8") as f:
    gj = json.load(f)

print(f"\nGeoJSON Landmarks: {len(gj.get('features', []))} features")
for i, f in enumerate(gj.get("features", [])[:5]):
    props = f.get("properties", {})
    print(f"[{i+1}] Landmark: {props.get('name')} | Height: {props.get('height')}m | Levels: {props.get('building:levels')}")

