import sqlite3
import time
from utm_converter import MumbaiWorldProjection, DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON
from test_parser import parse_gpkg_geom

proj = MumbaiWorldProjection(DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON)
conn = sqlite3.connect('data/geojson/planet_72.726_18.908_de78b929.gpkg')
cur = conn.cursor()

t0 = time.time()
rows = cur.execute("""
    SELECT osm_id, name, highway, other_tags, geom 
    FROM lines 
    WHERE highway IN ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'residential')
    LIMIT 2000
""").fetchall()

parsed_count = 0
for r in rows:
    geom = parse_gpkg_geom(r[4])
    if geom and geom["type"] == "LineString":
        pts = [proj.geo_to_godot(lat, lon) for lon, lat in geom["coordinates"]]
        parsed_count += 1

elapsed = time.time() - t0
print(f"Processed {parsed_count} roads in {elapsed:.3f}s ({parsed_count/elapsed:.0f} roads/sec)")
conn.close()
