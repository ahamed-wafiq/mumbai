import sqlite3
import json
import os

gpkg_path = "data/geojson/planet_72.726_18.908_de78b929.gpkg"

print(f"Inspecting: {gpkg_path}")
print(f"File size: {os.path.getsize(gpkg_path):,} bytes ({os.path.getsize(gpkg_path)/(1024*1024):.2f} MB)")

conn = sqlite3.connect(gpkg_path)
cur = conn.cursor()

# 1. Check gpkg metadata tables
print("\n--- GPKG CONTENTS ---")
contents = cur.execute("SELECT table_name, data_type, identifier, srs_id, min_x, min_y, max_x, max_y FROM gpkg_contents").fetchall()
for row in contents:
    tbl, dtype, ident, srs, min_x, min_y, max_x, max_y = row
    count = cur.execute(f"SELECT COUNT(*) FROM '{tbl}'").fetchone()[0]
    print(f"Layer: {tbl} | Type: {dtype} | SRS: {srs} | Features: {count:,} | BBox: ({min_x}, {min_y}) to ({max_x}, {max_y})")

print("\n--- GPKG GEOMETRY COLUMNS ---")
geom_cols = cur.execute("SELECT table_name, column_name, geometry_type_name, srs_id, z, m FROM gpkg_geometry_columns").fetchall()
for row in geom_cols:
    print(row)

print("\n--- GPKG SPATIAL REF SYS ---")
srs_rows = cur.execute("SELECT srs_name, srs_id, organization, organization_coordsys_id, definition FROM gpkg_spatial_ref_sys").fetchall()
for row in srs_rows:
    print(f"SRS: {row[0]} (ID: {row[1]}, Org: {row[2]}:{row[3]})")

print("\n--- COLUMNS PER LAYER ---")
for row in contents:
    tbl = row[0]
    cols = cur.execute(f"PRAGMA table_info('{tbl}')").fetchall()
    col_names = [c[1] for c in cols]
    print(f"Layer '{tbl}' columns ({len(col_names)}): {', '.join(col_names[:15])}{'...' if len(col_names) > 15 else ''}")
    sample = cur.execute(f"SELECT * FROM '{tbl}' LIMIT 1").fetchone()
    if sample:
        # Show first 5 non-geometry values
        sample_dict = {cols[i][1]: sample[i] for i in range(min(len(cols), 8)) if cols[i][1] != 'geom'}
        print(f"  Sample: {sample_dict}")

conn.close()

