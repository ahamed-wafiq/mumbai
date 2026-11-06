#!/usr/bin/env python3
"""
Mumbai Drive - Complete Greater Mumbai Tile Generator (BBBike GeoPackage Source)
Extracts and projects real OSM road networks, building footprints, waterways,
railways, and green spaces from the authoritative GeoPackage into 500m x 500m
streamable spatial grid tiles (UTM Zone 43N).
"""

import os
import json
import math
import sqlite3
import struct
import re
from typing import Dict, List, Any, Tuple, Optional
from utm_converter import MumbaiWorldProjection, DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = os.path.join(BASE_DIR, "data")
TILES_DIR = os.path.join(DATA_DIR, "tiles")
os.makedirs(TILES_DIR, exist_ok=True)

GPKG_PATH = os.path.join(DATA_DIR, "geojson", "planet_72.726_18.908_de78b929.gpkg")

# Spatial Grid Resolution
TILE_SIZE_METERS = 500.0

# Greater Mumbai Strict Geographic Bounds (WGS84)
# Bounds strictly encompass Brihanmumbai (Colaba to Dahisar/Borivali, Worli to Mulund)
MUMBAI_BOUNDS = {
    "min_lat": 18.890,
    "max_lat": 19.325,
    "min_lon": 72.770,
    "max_lon": 72.995
}

# Road Classification Mapping
ROAD_WIDTH_MAP = {
    "motorway": 24.0,       # 8-lane expressway (e.g. Bandra-Worli Sea Link, Eastern Freeway)
    "trunk": 20.0,          # 6-lane highway (e.g. Western Express Highway, EEH)
    "primary": 16.0,        # 4 to 6-lane arterial (e.g. Marine Drive, SV Road, LBS Marg)
    "secondary": 12.0,      # 4-lane secondary (e.g. Linking Road, Veer Nariman Rd)
    "tertiary": 9.0,        # 2-3 lane collector (e.g. local connector avenues)
    "residential": 7.5,     # 2-lane neighbourhood road
    "unclassified": 7.0,
    "service": 5.0,
    "default": 8.0
}

# Building Height Estimation Standards
BUILDING_HEIGHT_MAP = {
    "commercial": 28.0,
    "office": 32.0,
    "hotel": 36.0,
    "apartments": 22.0,
    "residential": 18.0,
    "hospital": 20.0,
    "university": 16.0,
    "school": 14.0,
    "retail": 10.0,
    "industrial": 12.0,
    "public": 18.0,
    "default": 14.0
}

# HStore Regex Parser
HSTORE_PATTERN = re.compile(r'"((?:[^"\\]|\\.)*)"=>"((?:[^"\\]|\\.)*)"')

def parse_hstore(hstore_str: Optional[str]) -> Dict[str, str]:
    if not hstore_str:
        return {}
    res = {}
    for m in HSTORE_PATTERN.finditer(hstore_str):
        k = m.group(1).replace(r'\"', '"').replace(r'\\', '\\')
        v = m.group(2).replace(r'\"', '"').replace(r'\\', '\\')
        res[k] = v
    return res

# OGC GeoPackage Geometry Parser
def parse_gpkg_geom(blob: bytes) -> Optional[Dict[str, Any]]:
    if not blob or len(blob) < 8 or blob[:2] != b'GP':
        return None
    flags = blob[3]
    env_ind = (flags & 0b00001110) >> 1
    env_sizes = {0: 0, 1: 32, 2: 48, 3: 48, 4: 64}
    offset = 8 + env_sizes.get(env_ind, 0)
    wkb = blob[offset:]
    return parse_wkb(wkb)

def parse_wkb(wkb: bytes) -> Optional[Dict[str, Any]]:
    if len(wkb) < 5:
        return None
    endian = '<' if wkb[0] == 1 else '>'
    geom_type = struct.unpack(endian + 'I', wkb[1:5])[0]
    base_type = geom_type % 1000
    is_3d = (geom_type >= 1000 and geom_type < 2000) or bool(geom_type & 0x80000000)
    dim = 3 if is_3d else 2
    offset = 5
    
    if base_type == 2: # LineString
        num_pts = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
        offset += 4
        fmt = endian + ('d' * (num_pts * dim))
        flat = struct.unpack(fmt, wkb[offset:offset + num_pts * dim * 8])
        pts = [[flat[i*dim], flat[i*dim+1]] for i in range(num_pts)]
        return {"type": "LineString", "coordinates": pts}
        
    elif base_type == 3: # Polygon
        num_rings = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
        offset += 4
        rings = []
        for _ in range(num_rings):
            num_pts = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
            offset += 4
            fmt = endian + ('d' * (num_pts * dim))
            flat = struct.unpack(fmt, wkb[offset:offset + num_pts * dim * 8])
            offset += num_pts * dim * 8
            pts = [[flat[i*dim], flat[i*dim+1]] for i in range(num_pts)]
            rings.append(pts)
        return {"type": "Polygon", "coordinates": rings}
        
    elif base_type == 6: # MultiPolygon
        num_polys = struct.unpack(endian + 'I', wkb[offset:offset+4])[0]
        offset += 4
        polys = []
        for _ in range(num_polys):
            sub_endian = '<' if wkb[offset] == 1 else '>'
            sub_type = struct.unpack(sub_endian + 'I', wkb[offset+1:offset+5])[0]
            sub_dim = 3 if (sub_type >= 1000 or bool(sub_type & 0x80000000)) else 2
            offset += 5
            num_rings = struct.unpack(sub_endian + 'I', wkb[offset:offset+4])[0]
            offset += 4
            rings = []
            for _ in range(num_rings):
                num_pts = struct.unpack(sub_endian + 'I', wkb[offset:offset+4])[0]
                offset += 4
                fmt = sub_endian + ('d' * (num_pts * sub_dim))
                flat = struct.unpack(fmt, wkb[offset:offset + num_pts * sub_dim * 8])
                offset += num_pts * sub_dim * 8
                pts = [[flat[i*sub_dim], flat[i*sub_dim+1]] for i in range(num_pts)]
                rings.append(pts)
            polys.append(rings)
        return {"type": "MultiPolygon", "coordinates": polys}
        
    return None

def is_point_in_bounds(lon: float, lat: float) -> bool:
    return (MUMBAI_BOUNDS["min_lon"] <= lon <= MUMBAI_BOUNDS["max_lon"] and
            MUMBAI_BOUNDS["min_lat"] <= lat <= MUMBAI_BOUNDS["max_lat"])

def get_grid_coords(x: float, z: float) -> Tuple[int, int]:
    return (int(math.floor(x / TILE_SIZE_METERS)), int(math.floor(z / TILE_SIZE_METERS)))

def run_tile_generation():
    print("=" * 70)
    print("MUMBAI DRIVE - GENERATING GREATER MUMBAI WORLD TILES (GPKG SOURCE)")
    print("=" * 70)
    
    proj = MumbaiWorldProjection(DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON)
    print(f"Origin (Marine Drive): Lat={DEFAULT_ORIGIN_LAT}, Lon={DEFAULT_ORIGIN_LON}")
    print(f"UTM 43N: Easting={proj.origin_easting:.2f} m, Northing={proj.origin_northing:.2f} m")
    
    conn = sqlite3.connect(GPKG_PATH)
    cur = conn.cursor()
    
    tiles: Dict[str, Dict[str, Any]] = {}
    
    def get_tile(gx: int, gz: int) -> Dict[str, Any]:
        key = f"{gx}_{gz}"
        if key not in tiles:
            min_x = gx * TILE_SIZE_METERS
            max_x = min_x + TILE_SIZE_METERS
            min_z = gz * TILE_SIZE_METERS
            max_z = min_z + TILE_SIZE_METERS
            tiles[key] = {
                "grid_x": gx,
                "grid_z": gz,
                "bounds": [round(min_x, 1), round(max_x, 1), round(min_z, 1), round(max_z, 1)],
                "roads": [],
                "buildings": [],
                "environment": []
            }
        return tiles[key]
    
    # -------------------------------------------------------------
    # 1. PROCESS ROADS FROM GPKG
    # -------------------------------------------------------------
    print("\n[1/3] Extracting & Projecting Road Network from GeoPackage...")
    cur.execute("""
        SELECT osm_id, name, highway, other_tags, geom 
        FROM lines 
        WHERE highway IN ('motorway', 'trunk', 'primary', 'secondary', 'tertiary', 'residential', 'unclassified', 'service')
    """)
    
    total_roads = 0
    total_road_length_m = 0.0
    
    while True:
        rows = cur.fetchmany(5000)
        if not rows:
            break
            
        for osm_id, name, highway, other_tags, geom_blob in rows:
            geom = parse_gpkg_geom(geom_blob)
            if not geom or geom["type"] != "LineString":
                continue
                
            coords = geom["coordinates"]
            if len(coords) < 2:
                continue
                
            # Quick bounds test on midpoint
            mid_lon, mid_lat = coords[len(coords) // 2]
            if not is_point_in_bounds(mid_lon, mid_lat):
                continue
                
            tags = parse_hstore(other_tags)
            is_bridge = (tags.get("bridge") == "yes") or (tags.get("layer") in ("1", "2"))
            is_tunnel = (tags.get("tunnel") == "yes") or (tags.get("layer") in ("-1", "-2"))
            elev = 6.0 if is_bridge else (-4.0 if is_tunnel else 0.0)
            
            width = float(tags.get("width", ROAD_WIDTH_MAP.get(highway, ROAD_WIDTH_MAP["default"])))
            lanes = int(tags.get("lanes", max(2, int(width / 3.5))))
            oneway = (tags.get("oneway") == "yes")
            
            # Project 3D points
            pts_3d = []
            for lon, lat in coords:
                x, y, z = proj.geo_to_godot(lat, lon, elev)
                pts_3d.append([x, y, z])
                
            # Calculate segment length
            for k in range(len(pts_3d) - 1):
                dx = pts_3d[k+1][0] - pts_3d[k][0]
                dz = pts_3d[k+1][2] - pts_3d[k][2]
                total_road_length_m += math.sqrt(dx*dx + dz*dz)
                
            road_record = {
                "id": str(osm_id),
                "name": name if name else f"{highway.capitalize()} Road",
                "highway": highway,
                "width": round(width, 1),
                "lanes": lanes,
                "oneway": oneway,
                "bridge": is_bridge,
                "tunnel": is_tunnel,
                "points": pts_3d
            }
            
            # Assign road to intersected tiles
            assigned_tiles = set()
            for pt in pts_3d:
                gx, gz = get_grid_coords(pt[0], pt[2])
                assigned_tiles.add((gx, gz))
                
            for gx, gz in assigned_tiles:
                t = get_tile(gx, gz)
                t["roads"].append(road_record)
                
            total_roads += 1
            
    print(f"Processed {total_roads:,} roads spanning {total_road_length_m/1000.0:,.1f} km of roadways.")
    
    # -------------------------------------------------------------
    # 2. PROCESS BUILDINGS FROM GPKG
    # -------------------------------------------------------------
    print("\n[2/3] Extracting & Projecting Building Footprints from GeoPackage...")
    cur.execute("""
        SELECT osm_id, name, building, other_tags, geom 
        FROM multipolygons 
        WHERE building IS NOT NULL AND building != 'no'
    """)
    
    total_buildings = 0
    
    while True:
        rows = cur.fetchmany(5000)
        if not rows:
            break
            
        for osm_id, name, bld_type, other_tags, geom_blob in rows:
            geom = parse_gpkg_geom(geom_blob)
            if not geom:
                continue
                
            # Extract exterior ring
            exterior_ring = None
            if geom["type"] == "Polygon" and geom["coordinates"]:
                exterior_ring = geom["coordinates"][0]
            elif geom["type"] == "MultiPolygon" and geom["coordinates"] and geom["coordinates"][0]:
                exterior_ring = geom["coordinates"][0][0]
                
            if not exterior_ring or len(exterior_ring) < 3:
                continue
                
            # Bounds check
            c_lon, c_lat = exterior_ring[0]
            if not is_point_in_bounds(c_lon, c_lat):
                continue
                
            tags = parse_hstore(other_tags)
            
            # Determine Height
            is_estimated = True
            height = None
            if "height" in tags:
                try:
                    clean_h = tags["height"].replace("m", "").replace("M", "").strip()
                    height = float(clean_h)
                    is_estimated = False
                except ValueError:
                    pass
                    
            if height is None and "building:levels" in tags:
                try:
                    lvls = float(tags["building:levels"])
                    height = lvls * 3.2
                    is_estimated = False
                except ValueError:
                    pass
                    
            if height is None:
                height = BUILDING_HEIGHT_MAP.get(bld_type, BUILDING_HEIGHT_MAP["default"])
                
            # Downsample / simplify footprint if too dense to optimize WebGL / memory
            step = 1 if len(exterior_ring) <= 12 else (len(exterior_ring) // 8)
            simplified_pts = []
            sum_x, sum_z = 0.0, 0.0
            
            for idx in range(0, len(exterior_ring), step):
                lon, lat = exterior_ring[idx]
                x, y, z = proj.geo_to_godot(lat, lon, 0.0)
                simplified_pts.append([x, y, z])
                sum_x += x
                sum_z += z
                
            if len(simplified_pts) < 3:
                continue
                
            centroid_x = sum_x / len(simplified_pts)
            centroid_z = sum_z / len(simplified_pts)
            
            bld_record = {
                "id": str(osm_id),
                "name": name if name else f"{bld_type.capitalize()} Building",
                "type": bld_type,
                "height": round(height, 1),
                "estimated": is_estimated,
                "footprint": simplified_pts
            }
            
            # Assign building to its centroid tile
            gx, gz = get_grid_coords(centroid_x, centroid_z)
            t = get_tile(gx, gz)
            t["buildings"].append(bld_record)
            
            total_buildings += 1
            
    print(f"Processed {total_buildings:,} 3D architectural building footprints.")
    
    # -------------------------------------------------------------
    # 3. PROCESS ENVIRONMENT (WATER & PARKS)
    # -------------------------------------------------------------
    print("\n[3/3] Extracting Coastlines, Water Bodies & Green Spaces...")
    cur.execute("""
        SELECT osm_id, name, natural, leisure, landuse, geom 
        FROM multipolygons 
        WHERE "natural" IN ('water', 'wood', 'scrub', 'beach') 
           OR leisure IN ('park', 'garden', 'pitch', 'nature_reserve')
           OR landuse IN ('reservoir', 'basin', 'recreation_ground')
    """)
    
    total_env = 0
    while True:
        rows = cur.fetchmany(2000)
        if not rows:
            break
        for osm_id, name, natural, leisure, landuse, geom_blob in rows:
            geom = parse_gpkg_geom(geom_blob)
            if not geom:
                continue
            ring = None
            if geom["type"] == "Polygon" and geom["coordinates"]:
                ring = geom["coordinates"][0]
            elif geom["type"] == "MultiPolygon" and geom["coordinates"] and geom["coordinates"][0]:
                ring = geom["coordinates"][0][0]
            if not ring or len(ring) < 3:
                continue
            if not is_point_in_bounds(ring[0][0], ring[0][1]):
                continue
                
            env_type = "water" if (natural == 'water' or landuse in ('reservoir', 'basin')) else "park"
            step = max(1, len(ring) // 16)
            pts_3d = []
            sum_x, sum_z = 0.0, 0.0
            for idx in range(0, len(ring), step):
                lon, lat = ring[idx]
                x, y, z = proj.geo_to_godot(lat, lon, -0.2 if env_type == "water" else 0.05)
                pts_3d.append([x, y, z])
                sum_x += x
                sum_z += z
                
            env_record = {
                "id": str(osm_id),
                "name": name if name else env_type.capitalize(),
                "type": env_type,
                "polygon": pts_3d
            }
            
            gx, gz = get_grid_coords(sum_x / len(pts_3d), sum_z / len(pts_3d))
            t = get_tile(gx, gz)
            t["environment"].append(env_record)
            total_env += 1
            
    print(f"Processed {total_env:,} environmental polygons (water & parks).")
    conn.close()
    
    # -------------------------------------------------------------
    # 4. SAVE TILES & GENERATE MASTER INDEX
    # -------------------------------------------------------------
    print("\n[4/4] Writing Out Spatial Grid Tiles...")
    tile_index: Dict[str, Any] = {
        "format": "mumbai_spatial_tile_index_v2",
        "origin": {
            "lat": DEFAULT_ORIGIN_LAT,
            "lon": DEFAULT_ORIGIN_LON,
            "description": "Marine Drive • Nariman Point"
        },
        "tile_size_meters": TILE_SIZE_METERS,
        "total_active_tiles": 0,
        "tiles": {}
    }
    
    manifest_records = []
    saved_tile_count = 0
    
    for key, tile_data in tiles.items():
        # Only save tiles that contain active features
        if not tile_data["roads"] and not tile_data["buildings"] and not tile_data["environment"]:
            continue
            
        tile_filename = f"tile_{tile_data['grid_x']}_{tile_data['grid_z']}.json"
        tile_path = os.path.join(TILES_DIR, tile_filename)
        
        with open(tile_path, "w", encoding="utf-8") as f:
            json.dump(tile_data, f, separators=(',', ':')) # Compact output
            
        tile_index["tiles"][key] = {
            "file": tile_filename,
            "grid_x": tile_data["grid_x"],
            "grid_z": tile_data["grid_z"],
            "bounds": tile_data["bounds"],
            "roads_count": len(tile_data["roads"]),
            "buildings_count": len(tile_data["buildings"]),
            "environment_count": len(tile_data["environment"])
        }
        
        manifest_records.append({
            "key": key,
            "file": tile_filename,
            "roads": len(tile_data["roads"]),
            "buildings": len(tile_data["buildings"]),
            "environment": len(tile_data["environment"])
        })
        saved_tile_count += 1
        
    tile_index["total_active_tiles"] = saved_tile_count
    
    # Save tile_index.json
    index_path = os.path.join(TILES_DIR, "tile_index.json")
    with open(index_path, "w", encoding="utf-8") as f:
        json.dump(tile_index, f, indent=2)
        
    # Save tile_manifest.json
    manifest_path = os.path.join(TILES_DIR, "tile_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump({
            "version": "2.0.0",
            "source": "BBBike OpenStreetMap GeoPackage (planet_72.726_18.908_de78b929.gpkg)",
            "city": "Greater Mumbai, Maharashtra, India",
            "total_tiles": saved_tile_count,
            "total_roads": total_roads,
            "total_buildings": total_buildings,
            "total_environment": total_env,
            "tiles": manifest_records
        }, f, indent=2)
        
    print(f"\n=======================================================")
    print(f"GREATER MUMBAI MAP GENERATION COMPLETE:")
    print(f"  • Total Active Tiles Created: {saved_tile_count:,}")
    print(f"  • Total Road Segments: {total_roads:,}")
    print(f"  • Total 3D Buildings: {total_buildings:,}")
    print(f"  • Total Environmental Polygons: {total_env:,}")
    print(f"  • Master Index: {index_path}")
    print(f"  • Manifest: {manifest_path}")
    print(f"=======================================================")

if __name__ == "__main__":
    run_tile_generation()

