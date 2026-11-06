import json
import sqlite3
import os
from utm_converter import MumbaiWorldProjection, DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON

print("=== 1. INSPECT GEOJSON BUILDINGS ===")
geojson_path = "data/geojson/mumbai_buildings.geojson"
with open(geojson_path, "r", encoding="utf-8") as f:
    gj = json.load(f)

feats = gj.get("features", [])
print(f"File: {geojson_path}")
print(f"Feature count: {len(feats)}")
print(f"CRS: {gj.get('crs', 'Default EPSG:4326')}")

# Bounds check
min_lon, max_lon = 180.0, -180.0
min_lat, max_lat = 90.0, -90.0
valid_polys = 0

for f in feats:
    coords = f.get("geometry", {}).get("coordinates", [])
    if coords and len(coords[0]) >= 3:
        valid_polys += 1
        for lon, lat in coords[0]:
            min_lon = min(min_lon, lon)
            max_lon = max(max_lon, lon)
            min_lat = min(min_lat, lat)
            max_lat = max(max_lat, lat)

print(f"Valid polygons: {valid_polys}")
print(f"Lon bounds: {min_lon:.5f} to {max_lon:.5f}")
print(f"Lat bounds: {min_lat:.5f} to {max_lat:.5f}")

print("\n=== 2. INSPECT GPKG BUILDINGS ===")
gpkg_path = "data/geojson/planet_72.726_18.908_de78b929.gpkg"
conn = sqlite3.connect(gpkg_path)
cur = conn.cursor()

count_bld = cur.execute("SELECT COUNT(*) FROM multipolygons WHERE building IS NOT NULL AND building != 'no'").fetchone()[0]
print(f"GPKG multipolygons building count: {count_bld:,}")
srs = cur.execute("SELECT srs_id, srs_name FROM gpkg_spatial_ref_sys WHERE srs_id = 4326").fetchone()
print(f"GPKG CRS: {srs}")

print("\n=== 3. CHECK COORDINATE CONVERSION & PRINT SAMPLES ===")
proj = MumbaiWorldProjection(DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON)
print(f"World Origin: Marine Drive (Lat: {DEFAULT_ORIGIN_LAT}, Lon: {DEFAULT_ORIGIN_LON})")
print(f"UTM 43N: Easting={proj.origin_easting:.2f} m, Northing={proj.origin_northing:.2f} m")

print("\nSample GeoJSON buildings projected to Godot local 3D (X=East, Y=Up, Z=-North):")
for i, f in enumerate(feats[:4]):
    name = f.get("properties", {}).get("name")
    coords = f.get("geometry", {}).get("coordinates", [[]])[0]
    lon, lat = coords[0]
    gx, gy, gz = proj.geo_to_godot(lat, lon, 0.0)
    print(f"[{i+1}] {name}:")
    print(f"    WGS84: ({lat:.5f}° N, {lon:.5f}° E)")
    print(f"    Godot Vector3: ({gx:.1f}, {gy:.1f}, {gz:.1f})")

conn.close()

