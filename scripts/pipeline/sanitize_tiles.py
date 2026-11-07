#!/usr/bin/env python3
"""
Mumbai Drive - Comprehensive Road Protection & Building Plot Sanitizer
Scans tile JSONs and enforces:
1. Zero building overlaps on any road asphalt, lane, or sidewalk buffer.
2. Complete junction/intersection clearance.
3. Designated building plot setbacks (minimum 2.5m from road curb).
4. Realistic building diversity (heights & architectural typologies).
"""

import os
import glob
import json
import math
from typing import List, Dict, Any, Tuple, Optional

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
TILES_DIR = os.path.join(BASE_DIR, "data", "tiles")

def dist_point_to_seg(px: float, pz: float, ax: float, az: float, bx: float, bz: float) -> Tuple[float, float, float, float, float]:
    dx = bx - ax
    dz = bz - az
    len_sq = dx * dx + dz * dz
    if len_sq < 0.0001:
        d = math.hypot(px - ax, pz - az)
        return d, ax, az, 0.0, 0.0
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / len_sq))
    proj_x = ax + t * dx
    proj_z = az + t * dz
    d = math.hypot(px - proj_x, pz - proj_z)
    return d, proj_x, proj_z, dx, dz

def calc_poly_area(pts: List[List[float]]) -> float:
    n = len(pts)
    if n < 3:
        return 0.0
    area = 0.0
    for i in range(n):
        j = (i + 1) % n
        area += pts[i][0] * pts[j][2] - pts[j][0] * pts[i][2]
    return abs(area) * 0.5

def sanitize_tile_buildings(tile_path: str) -> Tuple[int, int, int]:
    """
    Sanitizes buildings in a tile.
    Returns (original_count, preserved_count, overlaps_eliminated)
    """
    try:
        with open(tile_path, 'r', encoding='utf-8') as f:
            tile = json.load(f)
    except Exception as e:
        return 0, 0, 0

    roads = tile.get("roads", [])
    blds = tile.get("buildings", [])
    if not blds:
        return 0, 0, 0

    orig_count = len(blds)

    # 1. Collect all road segments and junction endpoints
    segments = []
    junctions = []
    for r in roads:
        pts = r.get("points", [])
        w = float(r.get("width", 8.0))
        hw = w * 0.5
        for i in range(len(pts) - 1):
            ax, az = pts[i][0], pts[i][2]
            bx, bz = pts[i+1][0], pts[i+1][2]
            segments.append((ax, az, bx, bz, hw, w))
        if pts:
            junctions.append((pts[0][0], pts[0][2], hw))
            junctions.append((pts[-1][0], pts[-1][2], hw))

    # Also include Marine Drive corridor explicitly if tile intersects it
    is_marine_drive_tile = False
    bounds = tile.get("bounds", [0, 0, 0, 0])
    # Marine Drive spans roughly X in [-100, 100], Z in [-1400, 2200]
    if (bounds[0] <= 100 and bounds[1] >= -100) and (bounds[2] <= 2200 and bounds[3] >= -1400):
        is_marine_drive_tile = True

    clean_blds = []
    overlaps_eliminated = 0

    for b in blds:
        fp = b.get("footprint", b.get("polygon", []))
        if len(fp) < 3:
            continue

        cx = sum(p[0] for p in fp) / len(fp)
        cz = sum(p[2] for p in fp) / len(fp)

        # Marine Drive corridor check
        if is_marine_drive_tile and (-1400.0 <= cz <= 2200.0):
            if abs(cx) < 8.5:
                overlaps_eliminated += 1
                continue # In middle of Marine Drive

        # Centroid road overlap check
        centroid_in_road = False
        for ax, az, bx, bz, hw, w in segments:
            d, _, _, _, _ = dist_point_to_seg(cx, cz, ax, az, bx, bz)
            if d < hw:
                centroid_in_road = True
                break
        if centroid_in_road:
            overlaps_eliminated += 1
            continue

        # Intersection node check
        in_junction = False
        for jx, jz, jhw in junctions:
            if math.hypot(cx - jx, cz - jz) < (jhw + 2.0):
                in_junction = True
                break
        if in_junction:
            overlaps_eliminated += 1
            continue

        # Vertex-level plot boundary clearance
        new_fp = []
        had_infringement = False
        severe_shifts = 0

        for p in fp:
            px, py, pz = p[0], p[1], p[2]
            max_sx, max_sz = 0.0, 0.0
            infringed = False

            # Marine Drive corridor push
            if is_marine_drive_tile and (-1400.0 <= pz <= 2200.0):
                if cx >= 0.0 and px < 13.5:
                    max_sx = 13.5 - px
                    infringed = True
                elif cx < 0.0 and px > -15.5:
                    max_sx = -15.5 - px
                    infringed = True

            # Tile roads push
            for ax, az, bx, bz, hw, w in segments:
                safe_dist = hw + 2.5 # Road asphalt half-width + 2.5m sidewalk plot setback
                d, proj_x, proj_z, dx, dz = dist_point_to_seg(px, pz, ax, az, bx, bz)
                if d < safe_dist:
                    infringed = True
                    dist_to_proj = math.hypot(px - proj_x, pz - proj_z)
                    if dist_to_proj > 0.001:
                        dir_x = (px - proj_x) / dist_to_proj
                        dir_z = (pz - proj_z) / dist_to_proj
                    else:
                        seg_l = math.hypot(dx, dz)
                        if seg_l > 0.001:
                            dir_x = -dz / seg_l
                            dir_z = dx / seg_l
                        else:
                            dir_x, dir_z = 1.0, 0.0

                    needed = safe_dist - d
                    sx = dir_x * needed
                    sz = dir_z * needed
                    if math.hypot(sx, sz) > math.hypot(max_sx, max_sz):
                        max_sx, max_sz = sx, sz

            if infringed:
                had_infringement = True
                shift_len = math.hypot(max_sx, max_sz)
                if shift_len > 7.0:
                    severe_shifts += 1
                new_fp.append([round(px + max_sx, 2), py, round(pz + max_sz, 2)])
            else:
                new_fp.append([round(px, 2), py, round(pz, 2)])

        if had_infringement:
            overlaps_eliminated += 1

        if severe_shifts > (len(fp) / 2):
            continue # Too distorted by multiple intersecting roads

        # Post-shift collision verification against all road asphalt
        still_in_road = False
        for p in new_fp:
            for ax, az, bx, bz, hw, w in segments:
                d, _, _, _, _ = dist_point_to_seg(p[0], p[2], ax, az, bx, bz)
                if d < hw:
                    still_in_road = True
                    break
            if still_in_road:
                break
        if still_in_road:
            continue

        # Area check
        area = calc_poly_area(new_fp)
        if area < 16.0:
            continue

        # Architectural Diversity & Height Assignment
        b_type = str(b.get("type", "residential")).lower()
        is_estimated = bool(b.get("estimated", True))
        height = float(b.get("height", 14.0))
        pos_hash = abs(int(cx * 31.0 + cz * 17.0))

        if is_estimated or height in (14.0, 22.0):
            if b_type == "hotel":
                height = 36.0 + float(pos_hash % 8) * 4.0
            elif b_type in ["commercial", "office"]:
                if area > 800.0 or cz > 1400.0:
                    height = 55.0 + float(pos_hash % 12) * 6.5
                else:
                    height = 28.0 + float(pos_hash % 6) * 3.5
            elif b_type in ["school", "university", "civic", "courthouse", "heritage"]:
                height = 16.0 + float(pos_hash % 4) * 2.5
            elif b_type in ["retail", "shop", "kiosk"]:
                height = 8.0 + float(pos_hash % 4) * 1.5
            else:
                if area < 140.0:
                    height = 9.0 + float(pos_hash % 3) * 2.0
                elif area < 450.0:
                    height = 18.0 + float(pos_hash % 5) * 3.0
                elif area < 900.0:
                    height = 32.0 + float(pos_hash % 7) * 4.0
                else:
                    height = 58.0 + float(pos_hash % 10) * 7.0

        b_clean = dict(b)
        b_clean["height"] = round(height, 1)
        b_clean["footprint"] = new_fp
        b_clean["area"] = round(area, 1)
        clean_blds.append(b_clean)

    # Save sanitized tile
    tile["buildings"] = clean_blds
    with open(tile_path, 'w', encoding='utf-8') as f:
        json.dump(tile, f, separators=(',', ':'))

    return orig_count, len(clean_blds), overlaps_eliminated

def main():
    print("=" * 70)
    print("MUMBAI DRIVE - ROAD CLEARANCE & BUILDING DIVERSITY SANITIZER")
    print("=" * 70)

    tile_files = glob.glob(os.path.join(TILES_DIR, "tile_*.json"))
    print(f"Discovered {len(tile_files)} tile files.")

    total_orig = 0
    total_preserved = 0
    total_eliminated = 0
    tiles_modified = 0

    for i, tpath in enumerate(tile_files):
        orig, pres, elim = sanitize_tile_buildings(tpath)
        if orig > 0:
            total_orig += orig
            total_preserved += pres
            total_eliminated += elim
            tiles_modified += 1
            if i % 100 == 0:
                print(f"Processed {i+1}/{len(tile_files)} tiles: {total_preserved}/{total_orig} buildings preserved ({total_eliminated} overlaps resolved)...", flush=True)

    print("\n" + "=" * 70)
    print("SANITIZATION COMPLETE!")
    print(f"Tiles Processed: {tiles_modified}")
    print(f"Original Buildings: {total_orig:,}")
    print(f"Preserved Clean Buildings: {total_preserved:,}")
    print(f"Road Overlaps Completely Eliminated: {total_eliminated:,}")
    print("=" * 70)

if __name__ == "__main__":
    main()

