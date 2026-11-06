import json
import math

with open('data/tiles/tile_0_0.json', 'r', encoding='utf-8') as f:
    t0 = json.load(f)

roads = t0.get('roads', [])
blds = t0.get('buildings', [])

def dist_point_to_segment(px, pz, ax, az, bx, bz):
    dx = bx - ax
    dz = bz - az
    len_sq = dx*dx + dz*dz
    if len_sq == 0:
        return math.hypot(px - ax, pz - az)
    t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / len_sq))
    proj_x = ax + t * dx
    proj_z = az + t * dz
    return math.hypot(px - proj_x, pz - proj_z)

overlapping_blds = []
for b in blds:
    fp = b.get('footprint', [])
    min_dist_to_road = 9999.0
    violating_road = None
    violating_half_w = 0.0
    
    for r in roads:
        pts = r.get('points', [])
        half_w = float(r.get('width', 8.0)) * 0.5
        for p in fp:
            px, pz = p[0], p[2]
            for i in range(len(pts) - 1):
                d = dist_point_to_segment(px, pz, pts[i][0], pts[i][2], pts[i+1][0], pts[i+1][2])
                if d < half_w:
                    if d < min_dist_to_road:
                        min_dist_to_road = d
                        violating_road = r.get('name')
                        violating_half_w = half_w
                        
    if violating_road:
        overlapping_blds.append({
            'name': b.get('name'),
            'road': violating_road,
            'dist': round(min_dist_to_road, 2),
            'road_half_width': violating_half_w
        })

print(f"Total buildings in tile_0_0: {len(blds)}")
print(f"Buildings overlapping roads: {len(overlapping_blds)}")
for ob in overlapping_blds[:10]:
    print(ob)
