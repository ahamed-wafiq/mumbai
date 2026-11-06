import sqlite3

conn = sqlite3.connect('data/geojson/planet_72.726_18.908_de78b929.gpkg')
cur = conn.cursor()

# Check road count in Mumbai bounds
# Using envelope or attributes
mumbai_roads = cur.execute("""
    SELECT COUNT(*) FROM lines 
    WHERE highway IS NOT NULL
""").fetchone()[0]

mumbai_drivable = cur.execute("""
    SELECT COUNT(*) FROM lines 
    WHERE highway IN ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'service')
""").fetchone()[0]

mumbai_blds = cur.execute("""
    SELECT COUNT(*) FROM multipolygons 
    WHERE building IS NOT NULL AND building != 'no'
""").fetchone()[0]

print(f"Total highway lines in GPKG: {mumbai_roads:,}")
print(f"Drivable road lines: {mumbai_drivable:,}")
print(f"Buildings in GPKG: {mumbai_blds:,}")

conn.close()
