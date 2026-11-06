import sqlite3
import struct

conn = sqlite3.connect('data/geojson/planet_72.726_18.908_de78b929.gpkg')
cur = conn.cursor()

sample = cur.execute("SELECT geom FROM lines WHERE highway IS NOT NULL LIMIT 1").fetchone()
blob = sample[0]
print(f"Blob length: {len(blob)} bytes")
print(f"Header: {blob[:8]}")
magic = blob[:2]
version = blob[2]
flags = blob[3]
srs_id = struct.unpack('<i', blob[4:8])[0]
print(f"Magic: {magic}, Version: {version}, Flags: {bin(flags)}, SRS ID: {srs_id}")

envelope_indicator = (flags & 0b00001110) >> 1
envelope_sizes = {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}
env_size = envelope_sizes.get(envelope_indicator, 0)
wkb_offset = 8 + env_size
print(f"Envelope size: {env_size}, WKB offset: {wkb_offset}")

# Let's inspect WKB header
wkb = blob[wkb_offset:]
endian = wkb[0]
geom_type = struct.unpack('<I', wkb[1:5])[0] if endian == 1 else struct.unpack('>I', wkb[1:5])[0]
print(f"WKB Endian: {endian}, Geom Type: {geom_type} (2 = LineString)")

conn.close()
