import sqlite3
import struct

def parse_gpkg_geom(blob):
    if not blob or len(blob) < 8:
        return None
    magic = blob[:2]
    if magic != b'GP':
        return None
    flags = blob[3]
    envelope_indicator = (flags & 0b00001110) >> 1
    envelope_sizes = {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}
    env_size = envelope_sizes.get(envelope_indicator, 0)
    wkb_offset = 8 + env_size
    return parse_wkb(blob[wkb_offset:])

def parse_wkb(wkb):
    if len(wkb) < 5:
        return None
    endian = '<' if wkb[0] == 1 else '>'
    geom_type = struct.unpack(endian + 'I', wkb[1:5])[0]
    # Handle ISO / EWKB flags (e.g. SRID or 3D/Z/M)
    geom_base_type = geom_type % 1000
    is_3d = (geom_type >= 1000 and geom_type < 2000) or bool(geom_type & 0x80000000)
    coord_dim = 3 if is_3d else 2
    offset = 5
    
    if geom_base_type == 1: # Point
        vals = struct.unpack(endian + ('d' * coord_dim), wkb[offset:offset + coord_dim*8])
        return {"type": "Point", "coordinates": list(vals[:2])}
        
    elif geom_base_type == 2: # LineString
        num_pts = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
        offset += 4
        fmt = endian + ('d' * (num_pts * coord_dim))
        coords_flat = struct.unpack(fmt, wkb[offset:offset + num_pts * coord_dim * 8])
        pts = [[coords_flat[i*coord_dim], coords_flat[i*coord_dim+1]] for i in range(num_pts)]
        return {"type": "LineString", "coordinates": pts}
        
    elif geom_base_type == 3: # Polygon
        num_rings = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
        offset += 4
        rings = []
        for _ in range(num_rings):
            num_pts = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
            offset += 4
            fmt = endian + ('d' * (num_pts * coord_dim))
            coords_flat = struct.unpack(fmt, wkb[offset:offset + num_pts * coord_dim * 8])
            offset += num_pts * coord_dim * 8
            pts = [[coords_flat[i*coord_dim], coords_flat[i*coord_dim+1]] for i in range(num_pts)]
            rings.append(pts)
        return {"type": "Polygon", "coordinates": rings}
        
    elif geom_base_type == 6: # MultiPolygon
        num_polys = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
        offset += 4
        polys = []
        for _ in range(num_polys):
            # sub-polygon has its own 5-byte header
            poly_endian = '<' if wkb[offset] == 1 else '>'
            poly_type = struct.unpack(poly_endian + 'I', wkb[offset+1:offset+5])[0]
            sub_dim = 3 if (poly_type >= 1000 or bool(poly_type & 0x80000000)) else 2
            offset += 5
            num_rings = struct.unpack(poly_endian + 'I', wkb[offset:offset+4])[0]
            offset += 4
            rings = []
            for _ in range(num_rings):
                num_pts = struct.unpack(poly_endian + 'I', wkb[offset:offset+4])[0]
                offset += 4
                fmt = poly_endian + ('d' * (num_pts * sub_dim))
                coords_flat = struct.unpack(fmt, wkb[offset:offset + num_pts * sub_dim * 8])
                offset += num_pts * sub_dim * 8
                pts = [[coords_flat[i*sub_dim], coords_flat[i*sub_dim+1]] for i in range(num_pts)]
                rings.append(pts)
            polys.append(rings)
        return {"type": "MultiPolygon", "coordinates": polys}
        
    return None

conn = sqlite3.connect('data/geojson/planet_72.726_18.908_de78b929.gpkg')
cur = conn.cursor()

# Test LineString
row = cur.execute("SELECT name, highway, geom FROM lines WHERE highway IS NOT NULL LIMIT 1").fetchone()
geom = parse_gpkg_geom(row[2])
print("Sample road:", row[0], row[1], geom["type"], "Points:", len(geom["coordinates"]), geom["coordinates"][0])

# Test Polygon
row = cur.execute("SELECT name, building, geom FROM multipolygons WHERE building IS NOT NULL LIMIT 1").fetchone()
geom = parse_gpkg_geom(row[2])
print("Sample building:", row[0], row[1], geom["type"], "Rings/Polys:", len(geom["coordinates"]))

conn.close()
