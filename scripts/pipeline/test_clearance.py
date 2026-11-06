import math

def push_building_away_from_roads(footprint, roads, clearance_margin=1.8):
    """
    Pushes building footprint vertices that infringe on road corridors
    outward past (road_half_width + clearance_margin).
    If > 60% of vertices are within road, returns None (skip building).
    """
    def dist_point_to_seg(px, pz, ax, az, bx, bz):
        dx = bx - ax
        dz = bz - az
        len_sq = dx*dx + dz*dz
        if len_sq == 0:
            return math.hypot(px - ax, pz - az), ax, az, 0.0, 0.0
        t = max(0.0, min(1.0, ((px - ax) * dx + (pz - az) * dz) / len_sq))
        proj_x = ax + t * dx
        proj_z = az + t * dz
        dist = math.hypot(px - proj_x, pz - proj_z)
        return dist, proj_x, proj_z, dx, dz

    new_footprint = []
    severely_overlapping_pts = 0
    
    for pt in footprint:
        px, py, pz = pt[0], pt[1], pt[2]
        max_push_x, max_push_z = 0.0, 0.0
        is_infringing = False
        
        for r in roads:
            half_w = float(r.get('width', 8.0)) * 0.5
            safe_dist = half_w + clearance_margin
            pts = r.get('points', [])
            
            for i in range(len(pts) - 1):
                dist, proj_x, proj_z, dx, dz = dist_point_to_seg(
                    px, pz, pts[i][0], pts[i][2], pts[i+1][0], pts[i+1][2]
                )
                if dist < safe_dist:
                    is_infringing = True
                    # Direction from road center to building point
                    dist_to_proj = math.hypot(px - proj_x, pz - proj_z)
                    if dist_to_proj > 0.001:
                        dir_x = (px - proj_x) / dist_to_proj
                        dir_z = (pz - proj_z) / dist_to_proj
                    else:
                        # If point is exactly on centerline, push perpendicular to road
                        seg_len = math.hypot(dx, dz)
                        if seg_len > 0.001:
                            dir_x = -dz / seg_len
                            dir_z = dx / seg_len
                        else:
                            dir_x, dir_z = 1.0, 0.0
                    
                    needed_push = safe_dist - dist
                    push_x = dir_x * needed_push
                    push_z = dir_z * needed_push
                    
                    if math.hypot(push_x, push_z) > math.hypot(max_push_x, max_push_z):
                        max_push_x = push_x
                        max_push_z = push_z
                        
        if is_infringing:
            severely_overlapping_pts += 1
            new_footprint.append([px + max_push_x, py, pz + max_push_z])
        else:
            new_footprint.append([px, py, pz])
            
    # If the vast majority of points are on the road, building is in the middle of a street
    if severely_overlapping_pts / float(max(1, len(footprint))) > 0.65:
        return None
        
    return new_footprint

# Test with Meghdoot on Marine Drive
sample_fp = [
    [7.6, 0.0, -10.2],
    [49.0, 0.0, -10.2],
    [49.0, 0.0, 37.0],
    [7.6, 0.0, 37.0],
    [7.6, 0.0, -10.2]
]
sample_road = [{
    'name': 'Marine Drive',
    'width': 18.0, # half width = 9.0m
    'points': [[1.0, 0.05, 50.0], [0.0, 0.05, 0.0], [-15.0, 0.05, -150.0]]
}]

adjusted = push_building_away_from_roads(sample_fp, sample_road, clearance_margin=2.0)
print("Original X min:", min(p[0] for p in sample_fp))
print("Adjusted X min:", min(p[0] for p in adjusted))
print("Safe road boundary: X > 11.0m (Road half_width 9.0 + clearance 2.0 = 11.0m)")
print("Adjusted footprint safe:", all(p[0] >= 11.0 for p in adjusted if p[2] >= 0.0))
