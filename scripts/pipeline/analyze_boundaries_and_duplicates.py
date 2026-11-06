import sqlite3
import json
import os

gpkg_path = "data/geojson/planet_72.726_18.908_de78b929.gpkg"
conn = sqlite3.connect(gpkg_path)
cur = conn.cursor()

print("--- BOUNDARIES IN GPKG ---")
rows = cur.execute("""
    SELECT osm_id, name, admin_level, boundary, place, type 
    FROM multipolygons 
    WHERE boundary = 'administrative' OR name LIKE '%Mumbai%' OR name LIKE '%Bombay%'
""").fetchall()

for r in rows:
    print(r)

print("\n--- CHECKING DUPLICATES WITH GEOJSON ---")
geojson_files = {
    "boundary": "data/geojson/mumbai_boundary.geojson",
    "roads": "data/geojson/mumbai_roads.geojson",
    "buildings": "data/geojson/mumbai_buildings.geojson",
    "environment": "data/geojson/mumbai_environment.geojson"
}

geojson_osm_ids = {}
for category, path in geojson_files.items():
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    ids = set()
    for feat in data.get("features", []):
        props = feat.get("properties", {})
        oid = str(props.get("osm_id", ""))
        if oid:
            ids.add(oid)
    geojson_osm_ids[category] = ids
    print(f"GeoJSON {category}: {len(ids)} OSM IDs loaded.")

# Check how many of these exist in GPKG
gpkg_road_ids = set(str(r[0]) for r in cur.execute("SELECT osm_id FROM lines WHERE osm_id IS NOT NULL").fetchall())
gpkg_poly_ids = set(str(r[0]) for r in cur.execute("SELECT osm_id FROM multipolygons WHERE osm_id IS NOT NULL").fetchall())
gpkg_point_ids = set(str(r[0]) for r in cur.execute("SELECT osm_id FROM points WHERE osm_id IS NOT NULL").fetchall())

all_gpkg_ids = gpkg_road_ids | gpkg_poly_ids | gpkg_point_ids

for category, ids in geojson_osm_ids.items():
    common = ids & all_gpkg_ids
    print(f"GeoJSON {category}: {len(common)} of {len(ids)} exist in GPKG. IDs in both: {list(common)[:5]}")

conn.close()
