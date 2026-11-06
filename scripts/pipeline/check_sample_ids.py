import sqlite3
import json

conn = sqlite3.connect('data/geojson/planet_72.726_18.908_de78b929.gpkg')
cur = conn.cursor()

ids_to_check = ['7933618', '48219412', '1029481', '5011001']
for tbl in ['points', 'lines', 'multilinestrings', 'multipolygons']:
    placeholders = ','.join('?' for _ in ids_to_check)
    found = cur.execute(f"SELECT osm_id, name FROM {tbl} WHERE osm_id IN ({placeholders})", ids_to_check).fetchall()
    if found:
        print(f"Found in {tbl}:", found)
print("Done checking.")
conn.close()
