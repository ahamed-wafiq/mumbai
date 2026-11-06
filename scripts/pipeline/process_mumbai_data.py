#!/usr/bin/env python3
"""
Mumbai Drive - Geographical Data Processing & World Tile Generator (Phase 3, 4, 5)
Converts raw OSM GeoJSON data to UTM Zone 43N (EPSG:32643) metric coordinates,
segments Greater Mumbai into 500m x 500m spatial grid tiles,
and outputs optimized Godot-ready tile JSON files.
"""

import os
import json
import math
from typing import Dict, List, Any, Tuple
from shapely.geometry import shape, Polygon, LineString, Point
from shapely.validation import make_valid
from utm_converter import MumbaiWorldProjection, DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEOJSON_DIR = os.path.join(BASE_DIR, "data", "geojson")
TILES_DIR = os.path.join(BASE_DIR, "data", "tiles")
os.makedirs(TILES_DIR, exist_ok=True)

# Configurable tile dimension in game world meters (500m x 500m)
TILE_SIZE_METERS = 500.0

# Road width mapping based on OSM highway classification (in meters)
ROAD_WIDTH_MAP = {
    "motorway": 24.0,       # 8-lane expressway (e.g. WEH, Sea Link)
    "trunk": 20.0,          # 6-lane trunk
    "primary": 16.0,        # 4 to 6-lane main arterial (e.g. Marine Drive)
    "secondary": 12.0,      # 4-lane secondary
    "tertiary": 9.0,        # 2 to 3-lane collector
    "residential": 7.0,     # 2-lane local street
    "service": 4.5,
    "default": 10.0
}


def get_tile_index(x: float, z: float) -> Tuple[int, int]:
    """Returns the grid tile coordinates (gx, gz) for a given world position (x, z)."""
    gx = int(math.floor(x / TILE_SIZE_METERS))
    gz = int(math.floor(z / TILE_SIZE_METERS))
    return (gx, gz)


def process_mumbai_dataset():
    print("=" * 70)
    print("MUMBAI DRIVE - PHASE 3, 4 & 5: DATA PROCESSING & TILE GENERATION")
    print("=" * 70)

    proj = MumbaiWorldProjection(DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON)
    print(f"World Origin: Marine Drive (Lat: {DEFAULT_ORIGIN_LAT}, Lon: {DEFAULT_ORIGIN_LON})")
    print(f"UTM 43N Projection Origin: Easting={proj.origin_easting:.2f} m, Northing={proj.origin_northing:.2f} m")
    print(f"Tile Grid Resolution: {TILE_SIZE_METERS}m x {TILE_SIZE_METERS}m")

    # 1. Load GeoJSON files
    roads_file = os.path.join(GEOJSON_DIR, "mumbai_roads.geojson")
    buildings_file = os.path.join(GEOJSON_DIR, "mumbai_buildings.geojson")
    boundary_file = os.path.join(GEOJSON_DIR, "mumbai_boundary.geojson")
    env_file = os.path.join(GEOJSON_DIR, "mumbai_environment.geojson")

    with open(roads_file, "r", encoding="utf-8") as f:
        roads_raw = json.load(f)
    with open(buildings_file, "r", encoding="utf-8") as f:
        buildings_raw = json.load(f)
    with open(boundary_file, "r", encoding="utf-8") as f:
        boundary_raw = json.load(f)
    with open(env_file, "r", encoding="utf-8") as f:
        env_raw = json.load(f)

    # 2. Process Roads into Projected 3D Points
    processed_roads = []
    total_road_length_m = 0.0

    print("\n[1/4] Projecting Road Networks to UTM 43N...")
    for feat in roads_raw.get("features", []):
        props = feat.get("properties", {})
        coords = feat.get("geometry", {}).get("coordinates", [])
        if len(coords) < 2:
            continue

        hw_type = props.get("highway", "default")
        width = float(props.get("width", ROAD_WIDTH_MAP.get(hw_type, ROAD_WIDTH_MAP["default"])))
        lanes = int(props.get("lanes", max(2, int(width / 3.5))))

        points_3d = []
        seg_length = 0.0
        for i, pt in enumerate(coords):
            lon, lat = pt[0], pt[1]
            elev = float(pt[2]) if len(pt) > 2 else 0.0
            # If bridge/flyover, give elevated Y
            if props.get("bridge") == "yes":
                elev = 6.0
            x, y, z = proj.geo_to_godot(lat, lon, elev)
            points_3d.append([x, y, z])
            if i > 0:
                dx = x - points_3d[i - 1][0]
                dy = y - points_3d[i - 1][1]
                dz = z - points_3d[i - 1][2]
                seg_length += math.sqrt(dx * dx + dy * dy + dz * dz)

        total_road_length_m += seg_length
        processed_roads.append({
            "osm_id": props.get("osm_id"),
            "name": props.get("name", "Unnamed Road"),
            "highway": hw_type,
            "width": width,
            "lanes": lanes,
            "oneway": props.get("oneway", "no") == "yes",
            "bridge": props.get("bridge") == "yes",
            "tunnel": props.get("tunnel") == "yes",
            "points": points_3d,
            "length_m": round(seg_length, 1)
        })

    print(f"  ✓ Processed {len(processed_roads)} road lines (Total: {total_road_length_m / 1000.0:.2f} km)")

    # 3. Process Buildings into Projected 3D Footprints
    print("\n[2/4] Projecting Building Footprints & Estimating Heights...")
    processed_buildings = []
    for feat in buildings_raw.get("features", []):
        props = feat.get("properties", {})
        geom = feat.get("geometry", {})
        if geom.get("type") != "Polygon":
            continue

        raw_rings = geom.get("coordinates", [])
        if not raw_rings or len(raw_rings[0]) < 3:
            continue

        outer_ring = raw_rings[0]
        pts_3d = []
        sum_x, sum_z = 0.0, 0.0
        for pt in outer_ring:
            lon, lat = pt[0], pt[1]
            x, y, z = proj.geo_to_godot(lat, lon, 0.0)
            pts_3d.append([x, y, z])
            sum_x += x
            sum_z += z

        count = len(pts_3d)
        center_x = sum_x / count
        center_z = sum_z / count

        height = float(props.get("height", 15.0))
        levels = int(props.get("building:levels", max(1, int(height / 3.5))))
        is_estimated = bool(props.get("is_height_estimated", False))

        processed_buildings.append({
            "osm_id": props.get("osm_id"),
            "name": props.get("name", f"Building_{props.get('osm_id')}"),
            "building_type": props.get("building", "yes"),
            "height": height,
            "levels": levels,
            "is_height_estimated": is_estimated,
            "center": [round(center_x, 2), 0.0, round(center_z, 2)],
            "polygon": pts_3d
        })

    print(f"  ✓ Processed {len(processed_buildings)} building footprints")

    # 4. Process Environment (Water & Parks)
    print("\n[3/4] Projecting Environment (Water & Parks)...")
    processed_env = []
    for feat in env_raw.get("features", []):
        props = feat.get("properties", {})
        geom = feat.get("geometry", {})
        if geom.get("type") != "Polygon":
            continue
        rings = geom.get("coordinates", [])
        if not rings or len(rings[0]) < 3:
            continue

        pts_3d = []
        for pt in rings[0]:
            lon, lat = pt[0], pt[1]
            x, y, z = proj.geo_to_godot(lat, lon, 0.0)
            pts_3d.append([x, y, z])

        processed_env.append({
            "osm_id": props.get("osm_id"),
            "name": props.get("name", "Environment Feature"),
            "type": props.get("natural") or props.get("leisure") or "water",
            "polygon": pts_3d
        })
    print(f"  ✓ Processed {len(processed_env)} environmental polygons")

    # 5. Distribute into 500m x 500m Spatial Grid Tiles
    print("\n[4/4] Generating 500m x 500m Spatial Grid Tiles...")
    tiles_dict: Dict[Tuple[int, int], Dict[str, Any]] = {}

    def ensure_tile(gx: int, gz: int) -> Dict[str, Any]:
        key = (gx, gz)
        if key not in tiles_dict:
            cx = (float(gx) + 0.5) * TILE_SIZE_METERS
            cz = (float(gz) + 0.5) * TILE_SIZE_METERS
            tiles_dict[key] = {
                "tile_coord": [gx, gz],
                "world_bounds": {
                    "min_x": gx * TILE_SIZE_METERS,
                    "max_x": (gx + 1) * TILE_SIZE_METERS,
                    "min_z": gz * TILE_SIZE_METERS,
                    "max_z": (gz + 1) * TILE_SIZE_METERS
                },
                "world_center": [cx, 0.0, cz],
                "roads": [],
                "buildings": [],
                "environment": []
            }
        return tiles_dict[key]

    # Assign roads to tiles they intersect
    for r in processed_roads:
        assigned_tiles = set()
        for p in r["points"]:
            t_coord = get_tile_index(p[0], p[2])
            assigned_tiles.add(t_coord)
        for t_coord in assigned_tiles:
            tile_data = ensure_tile(t_coord[0], t_coord[1])
            tile_data["roads"].append(r)

    # Assign buildings to tiles based on center position
    for b in processed_buildings:
        cx, cz = b["center"][0], b["center"][2]
        t_coord = get_tile_index(cx, cz)
        tile_data = ensure_tile(t_coord[0], t_coord[1])
        tile_data["buildings"].append(b)

    # Assign environment to tiles
    for e in processed_env:
        assigned_tiles = set()
        for p in e["polygon"]:
            t_coord = get_tile_index(p[0], p[2])
            assigned_tiles.add(t_coord)
        for t_coord in assigned_tiles:
            tile_data = ensure_tile(t_coord[0], t_coord[1])
            tile_data["environment"].append(e)

    # Save individual tile files
    manifest_tiles = []
    for (gx, gz), tile_content in tiles_dict.items():
        filename = f"tile_{gx}_{gz}.json"
        filepath = os.path.join(TILES_DIR, filename)
        with open(filepath, "w", encoding="utf-8") as f:
            json.dump(tile_content, f, indent=2)

        manifest_tiles.append({
            "coord": [gx, gz],
            "file": f"res://data/tiles/{filename}",
            "center": tile_content["world_center"],
            "bounds": tile_content["world_bounds"],
            "road_count": len(tile_content["roads"]),
            "building_count": len(tile_content["buildings"]),
            "env_count": len(tile_content["environment"])
        })

    # Save master tile manifest
    manifest = {
        "project": "Mumbai Drive",
        "origin_name": "Marine Drive / Nariman Point",
        "origin_lat": DEFAULT_ORIGIN_LAT,
        "origin_lon": DEFAULT_ORIGIN_LON,
        "projection": "UTM Zone 43N (EPSG:32643)",
        "tile_size_meters": TILE_SIZE_METERS,
        "total_tiles": len(manifest_tiles),
        "total_roads": len(processed_roads),
        "total_road_km": round(total_road_length_m / 1000.0, 2),
        "total_buildings": len(processed_buildings),
        "tiles": manifest_tiles
    }

    manifest_path = os.path.join(TILES_DIR, "tile_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)

    print(f"  ✓ Generated {len(manifest_tiles)} spatial tiles in data/tiles/")
    print(f"  ✓ Master tile manifest written to {manifest_path}")
    print("\n✓ Phase 3, 4 & 5 processing completed successfully!")


if __name__ == "__main__":
    process_mumbai_dataset()

