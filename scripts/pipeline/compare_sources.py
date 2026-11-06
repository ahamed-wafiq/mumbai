import json
import os
import sqlite3

geojson_files = {
    "boundary": "data/geojson/mumbai_boundary.geojson",
    "roads": "data/geojson/mumbai_roads.geojson",
    "buildings": "data/geojson/mumbai_buildings.geojson",
    "environment": "data/geojson/mumbai_environment.geojson"
}

print("=== GEOJSON FILES ANALYSIS ===")
for key, path in geojson_files.items():
    size = os.path.getsize(path)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    features = data.get("features", [])
    crs = data.get("crs", {}).get("properties", {}).get("name", "EPSG:4326 (default)")
    geom_types = set(f.get("geometry", {}).get("type") for f in features)
    
    # Calculate bounds
    min_x, min_y = float('inf'), float('inf')
    max_x, max_y = float('-inf'), float('-inf')
    
    def extract_coords(geom):
        if not geom: return
        coords = geom.get("coordinates", [])
        
        def recurse(c):
            global min_x, min_y, max_x, max_y
            if isinstance(c, (list, tuple)):
                if len(c) >= 2 and isinstance(c[0], (int, float)) and isinstance(c[1], (int, float)):
                    bounds[0] = min(bounds[0], c[0])
                    bounds[1] = max(bounds[1], c[0])
                    bounds[2] = min(bounds[2], c[1])
                    bounds[3] = max(bounds[3], c[1])
                else:
                    for sub in c:
                        recurse(sub)
        recurse(coords)

    bounds = [float('inf'), float('-inf'), float('inf'), float('-inf')]
    for f in features:
        extract_coords(f.get("geometry"))

    sample_props = list(features[0].get("properties", {}).keys()) if features else []
    print(f"\n[{key.upper()}] File: {path}")
    print(f"  Size: {size:,} bytes ({size/1024:.1f} KB)")
    print(f"  Feature Count: {len(features):,}")
    print(f"  CRS: {crs}")
    print(f"  Geom Types: {geom_types}")
    print(f"  Bounding Box: ({bounds[0]:.4f}, {bounds[2]:.4f}) to ({bounds[1]:.4f}, {bounds[3]:.4f})")
    print(f"  Property keys ({len(sample_props)}): {sample_props[:10]}")

print("\n=== COMPARING WITH GPKG ===")
gpkg_path = "data/geojson/planet_72.726_18.908_de78b929.gpkg"
conn = sqlite3.connect(gpkg_path)
cur = conn.cursor()

# Get all column names for multipolygons
mp_cols = [c[1] for c in cur.execute("PRAGMA table_info('multipolygons')").fetchall()]
print(f"Multipolygon columns: {mp_cols}")

line_cols = [c[1] for c in cur.execute("PRAGMA table_info('lines')").fetchall()]
print(f"Lines columns: {line_cols}")

# Check road features in lines
road_lines = cur.execute("SELECT COUNT(*) FROM lines WHERE highway IS NOT NULL").fetchone()[0]
railway_lines = cur.execute("SELECT COUNT(*) FROM lines WHERE railway IS NOT NULL").fetchone()[0]
waterway_lines = cur.execute("SELECT COUNT(*) FROM lines WHERE waterway IS NOT NULL").fetchone()[0]

# Check building features in multipolygons
building_polys = cur.execute("SELECT COUNT(*) FROM multipolygons WHERE building IS NOT NULL AND building != 'no'").fetchone()[0]
has_natural = "natural" in mp_cols
water_query = "SELECT COUNT(*) FROM multipolygons WHERE \"natural\" = 'water' OR \"water\" IS NOT NULL" if has_natural else "SELECT 0"
water_polys = cur.execute(water_query).fetchone()[0]
boundary_polys = cur.execute("SELECT COUNT(*) FROM multipolygons WHERE boundary = 'administrative'").fetchone()[0]

print(f"\nGPKG Feature Breakdown:")
print(f"  Roads (highway IS NOT NULL): {road_lines:,}")
print(f"  Railways (railway IS NOT NULL): {railway_lines:,}")
print(f"  Waterway lines: {waterway_lines:,}")
print(f"  Buildings (building IS NOT NULL): {building_polys:,}")
print(f"  Water body polygons: {water_polys:,}")
print(f"  Administrative boundary polygons: {boundary_polys:,}")

conn.close()
