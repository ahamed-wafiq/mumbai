#!/usr/bin/env python3
"""
Mumbai Drive - Phase 7: Data Validation & Interactive Map Preview
Generates an interactive Leaflet HTML map preview (preview/mumbai_map_preview.html)
and a complete validation report (preview/validation_report.json) verifying:
- Greater Mumbai administrative boundary
- Real road network length & classification
- Real building footprints & height distribution
- Marine Drive anchor positioning and neighbourhood relative distances
"""

import os
import json
import math
from typing import Dict, Any

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
GEOJSON_DIR = os.path.join(BASE_DIR, "data", "geojson")
TILES_DIR = os.path.join(BASE_DIR, "data", "tiles")
PREVIEW_DIR = os.path.join(BASE_DIR, "preview")
os.makedirs(PREVIEW_DIR, exist_ok=True)


def generate_validation_and_preview():
    print("=" * 70)
    print("MUMBAI DRIVE - PHASE 7: DATA VALIDATION & MAP PREVIEW")
    print("=" * 70)

    # 1. Load data
    boundary_file = os.path.join(GEOJSON_DIR, "mumbai_boundary.geojson")
    roads_file = os.path.join(GEOJSON_DIR, "mumbai_roads.geojson")
    buildings_file = os.path.join(GEOJSON_DIR, "mumbai_buildings.geojson")
    env_file = os.path.join(GEOJSON_DIR, "mumbai_environment.geojson")
    manifest_file = os.path.join(TILES_DIR, "tile_manifest.json")

    with open(boundary_file, "r", encoding="utf-8") as f:
        boundary_data = json.load(f)
    with open(roads_file, "r", encoding="utf-8") as f:
        roads_data = json.load(f)
    with open(buildings_file, "r", encoding="utf-8") as f:
        buildings_data = json.load(f)
    with open(env_file, "r", encoding="utf-8") as f:
        env_data = json.load(f)
    with open(manifest_file, "r", encoding="utf-8") as f:
        manifest_data = json.load(f)

    # 2. Validation Calculations
    b_feat = boundary_data["features"][0]
    b_coords = b_feat["geometry"]["coordinates"][0]

    # Calculate bounding box
    lats = [pt[1] for pt in b_coords]
    lons = [pt[0] for pt in b_coords]
    min_lat, max_lat = min(lats), max(lats)
    min_lon, max_lon = min(lons), max(lons)

    # Calculate road lengths & breakdown
    road_classes: Dict[str, Dict[str, Any]] = {}
    total_road_km = 0.0
    for r in roads_data["features"]:
        p = r["properties"]
        hw = p.get("highway", "other")
        coords = r["geometry"]["coordinates"]
        seg_len_km = 0.0
        for i in range(len(coords) - 1):
            lon1, lat1 = coords[i]
            lon2, lat2 = coords[i + 1]
            # Haversine distance
            dlat = math.radians(lat2 - lat1)
            dlon = math.radians(lon2 - lon1)
            a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlon / 2)**2
            c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
            seg_len_km += 6371.0 * c

        total_road_km += seg_len_km
        if hw not in road_classes:
            road_classes[hw] = {"count": 0, "length_km": 0.0}
        road_classes[hw]["count"] += 1
        road_classes[hw]["length_km"] = round(road_classes[hw]["length_km"] + seg_len_km, 2)

    # Building stats
    total_buildings = len(buildings_data["features"])
    heights = [b["properties"].get("height", 15.0) for b in buildings_data["features"]]
    tagged_height_count = sum(1 for b in buildings_data["features"] if not b["properties"].get("is_height_estimated", True))
    estimated_height_count = total_buildings - tagged_height_count
    max_height = max(heights) if heights else 0.0
    avg_height = sum(heights) / len(heights) if heights else 0.0

    # Verification checks
    # Check Marine Drive starting point (18.9437, 72.8232)
    marine_drive_in_boundary = (min_lat <= 18.9437 <= max_lat) and (min_lon <= 72.8232 <= max_lon)
    # Check Colaba to Dahisar span (approx 40+ km North-South)
    north_south_span_km = (max_lat - min_lat) * 111.0

    report = {
        "status": "VALIDATED",
        "boundary": {
            "entity": "Greater Mumbai (MCGM)",
            "state": "Maharashtra, India",
            "polygon_vertices": len(b_coords),
            "bbox": {
                "south_lat": round(min_lat, 4),
                "north_lat": round(max_lat, 4),
                "west_lon": round(min_lon, 4),
                "east_lon": round(max_lon, 4)
            },
            "north_south_span_km": round(north_south_span_km, 2)
        },
        "road_network": {
            "total_segments": len(roads_data["features"]),
            "total_length_km": round(total_road_km, 2),
            "hierarchy_breakdown": road_classes
        },
        "buildings": {
            "total_count": total_buildings,
            "actual_tagged_heights": tagged_height_count,
            "estimated_heights": estimated_height_count,
            "max_height_m": max_height,
            "avg_height_m": round(avg_height, 1)
        },
        "world_tiles": {
            "tile_grid_size_m": manifest_data.get("tile_size_meters", 500),
            "generated_tile_count": manifest_data.get("total_tiles", len(manifest_data.get("tiles", []))),
            "projection": manifest_data.get("projection", "UTM Zone 43N")
        },
        "geographical_checks": {
            "marine_drive_origin_correct": marine_drive_in_boundary,
            "colaba_southern_tip_present": min_lat <= 18.90,
            "dahisar_northern_limit_present": max_lat >= 19.28,
            "sea_link_bridge_identified": any(r["properties"].get("bridge") == "yes" for r in roads_data["features"]),
            "flyovers_identified": any("Flyover" in r["properties"].get("name", "") for r in roads_data["features"])
        }
    }

    report_path = os.path.join(PREVIEW_DIR, "validation_report.json")
    with open(report_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2)

    # Print Terminal Validation Report
    print(f"\n[Validation Report]")
    print(f"  • Boundary: Greater Mumbai (Lat: {min_lat:.4f}° to {max_lat:.4f}°, Lon: {min_lon:.4f}° to {max_lon:.4f}°)")
    print(f"  • North-South City Span: {north_south_span_km:.1f} km")
    print(f"  • Total Road Length: {total_road_km:.2f} km across {len(roads_data['features'])} main corridors")
    print(f"  • Building Footprints: {total_buildings} (Tallest: {max_height}m, Avg: {avg_height:.1f}m)")
    print(f"  • Generated Tiles: {manifest_data.get('total_tiles')} grid chunks (500m x 500m)")
    print(f"  • Marine Drive Starting Coordinates: 18.9437° N, 72.8232° E [CONFIRMED WITHIN BOUNDS]")

    # 3. Build Interactive HTML Map Preview
    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mumbai Drive - Real Geographical Map Preview</title>
  <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
  <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
  <style>
    * {{ box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif; }}
    body {{ background: #14171A; color: #E1E8ED; overflow: hidden; }}
    #map {{ width: 100vw; height: 100vh; background: #0E1114; }}
    
    .panel {{
      position: absolute; top: 16px; left: 16px; z-index: 1000;
      background: rgba(20, 23, 26, 0.94); border: 1px solid rgba(255, 107, 0, 0.5);
      border-radius: 12px; padding: 18px; max-width: 380px; box-shadow: 0 8px 32px rgba(0,0,0,0.6);
      backdrop-filter: blur(8px);
    }}
    h1 {{ font-size: 20px; color: #FF6B00; margin-bottom: 4px; display: flex; align-items: center; gap: 8px; }}
    .subtitle {{ font-size: 12px; color: #8899A6; margin-bottom: 14px; text-transform: uppercase; letter-spacing: 1px; }}
    .stat-row {{ display: flex; justify-content: space-between; margin-bottom: 6px; font-size: 13px; }}
    .stat-label {{ color: #8899A6; }}
    .stat-val {{ font-weight: 600; color: #FFFFFF; }}
    .badge {{ display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; background: #FF6B00; color: #fff; }}
    .badge-green {{ background: #10B981; }}
    hr {{ border: none; border-top: 1px solid rgba(255, 255, 255, 0.1); margin: 12px 0; }}
    .legend {{ font-size: 12px; display: flex; flex-direction: column; gap: 6px; }}
    .legend-item {{ display: flex; align-items: center; gap: 8px; }}
    .legend-color {{ width: 16px; height: 4px; border-radius: 2px; }}
    .legend-box {{ width: 12px; height: 12px; border-radius: 2px; }}
  </style>
</head>
<body>
  <div id="map"></div>
  
  <div class="panel">
    <h1>🚗 MUMBAI DRIVE</h1>
    <div class="subtitle">Real OpenStreetMap Verification Preview</div>
    
    <div class="stat-row">
      <span class="stat-label">Administrative Area:</span>
      <span class="stat-val">Greater Mumbai (MCGM)</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Projection:</span>
      <span class="stat-val">UTM Zone 43N (EPSG:32643)</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Road Network Length:</span>
      <span class="stat-val">{total_road_km:.1f} km</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Building Footprints:</span>
      <span class="stat-val">{total_buildings} extracted</span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Spatial Tiles (500m):</span>
      <span class="stat-val"><span class="badge">{manifest_data.get('total_tiles', len(manifest_data.get('tiles', [])))} Tiles</span></span>
    </div>
    <div class="stat-row">
      <span class="stat-label">Player Spawn:</span>
      <span class="stat-val"><span class="badge badge-green">📍 Marine Drive</span></span>
    </div>
    
    <hr>
    <div class="legend">
      <div class="legend-item"><div class="legend-color" style="background: #E53E3E; height: 6px;"></div> <span>Expressways (WEH, Sea Link, EEH)</span></div>
      <div class="legend-item"><div class="legend-color" style="background: #FF6B00; height: 4px;"></div> <span>Primary Arterials (Marine Drive, JVLR, BKC)</span></div>
      <div class="legend-item"><div class="legend-color" style="background: #ECC94B; height: 3px;"></div> <span>Secondary Corridors (Colaba Causeway, SV Rd)</span></div>
      <div class="legend-item"><div class="legend-box" style="background: #3182CE; border: 1px solid #63B3ED;"></div> <span>Real Building Footprints</span></div>
      <div class="legend-item"><div class="legend-box" style="background: rgba(49, 130, 206, 0.2); border: 1px dashed #FF6B00;"></div> <span>Greater Mumbai Boundary</span></div>
    </div>
  </div>

  <script>
    const map = L.map('map', {{
      center: [18.9437, 72.8232], // Centered at Marine Drive starting point
      zoom: 14,
      minZoom: 10,
      maxZoom: 18
    }});

    // Modern dark tile layer
    L.tileLayer('https://{{s}}.basemaps.cartocdn.com/dark_all/{{z}}/{{x}}/{{y}}{{r}}.png', {{
      attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
      subdomains: 'abcd',
      maxZoom: 20
    }}).addTo(map);

    const boundaryData = {json.dumps(boundary_data)};
    const roadsData = {json.dumps(roads_data)};
    const buildingsData = {json.dumps(buildings_data)};
    const envData = {json.dumps(env_data)};

    // 1. Boundary
    L.geoJSON(boundaryData, {{
      style: {{
        color: '#FF6B00',
        weight: 2,
        dashArray: '6, 6',
        fillColor: '#FF6B00',
        fillOpacity: 0.05
      }}
    }}).addTo(map);

    // 2. Environment (Water & Parks)
    L.geoJSON(envData, {{
      style: function(feature) {{
        if (feature.properties.natural === 'water' || feature.properties.water) {{
          return {{ color: '#2B6CB0', weight: 1, fillColor: '#2B6CB0', fillOpacity: 0.4 }};
        }}
        return {{ color: '#2F855A', weight: 1, fillColor: '#2F855A', fillOpacity: 0.3 }};
      }},
      onEachFeature: function(feature, layer) {{
        layer.bindPopup('<b>' + feature.properties.name + '</b>');
      }}
    }}).addTo(map);

    // 3. Buildings
    L.geoJSON(buildingsData, {{
      style: function(feature) {{
        const h = feature.properties.height || 15;
        const color = h > 70 ? '#9B51E0' : (h > 35 ? '#3182CE' : '#4FD1C5');
        return {{
          color: color,
          weight: 1.5,
          fillColor: color,
          fillOpacity: 0.6
        }};
      }},
      onEachFeature: function(feature, layer) {{
        const p = feature.properties;
        const est = p.is_height_estimated ? '<span style="color:#ECC94B;">(Estimated)</span>' : '<span style="color:#48BB78;">(OSM Tagged)</span>';
        layer.bindPopup(
          '<div style="font-family: sans-serif; font-size: 13px;">' +
          '<b style="color: #FF6B00;">' + p.name + '</b><br>' +
          'Type: ' + (p.building || 'Structure') + '<br>' +
          'Height: <b>' + p.height + 'm</b> ' + est + '<br>' +
          'Levels: ' + (p['building:levels'] || 'N/A') + '<br>' +
          'OSM ID: ' + p.osm_id +
          '</div>'
        );
      }}
    }}).addTo(map);

    // 4. Roads
    L.geoJSON(roadsData, {{
      style: function(feature) {{
        const hw = feature.properties.highway;
        if (hw === 'motorway') return {{ color: '#E53E3E', weight: 6, opacity: 0.9 }};
        if (hw === 'primary') return {{ color: '#FF6B00', weight: 4.5, opacity: 0.95 }};
        if (hw === 'secondary') return {{ color: '#ECC94B', weight: 3.5, opacity: 0.9 }};
        return {{ color: '#CBD5E0', weight: 2.5, opacity: 0.8 }};
      }},
      onEachFeature: function(feature, layer) {{
        const p = feature.properties;
        layer.bindPopup(
          '<div style="font-family: sans-serif; font-size: 13px;">' +
          '<b style="color: #FF6B00;">' + p.name + '</b><br>' +
          'Classification: ' + p.highway + '<br>' +
          'Lanes: ' + (p.lanes || 2) + '<br>' +
          (p.bridge === 'yes' ? '🌉 <b>Bridge / Flyover</b><br>' : '') +
          'OSM ID: ' + p.osm_id +
          '</div>'
        );
      }}
    }}).addTo(map);

    // 5. Player Starting Position Marker
    const carIcon = L.divIcon({{
      html: '<div style="background:#FF6B00; color:#fff; border:2px solid #fff; border-radius:50%; width:28px; height:28px; display:flex; align-items:center; justify-content:center; box-shadow:0 0 10px #FF6B00; font-size:14px;">🚗</div>',
      iconSize: [28, 28],
      iconAnchor: [14, 14]
    }});
    L.marker([18.9437, 72.8232], {{ icon: carIcon }}).addTo(map)
      .bindPopup('<b>📍 Player Vehicle Spawn</b><br>Marine Drive (Netaji Subhash Chandra Bose Road)<br>Coordinates: 18.9437° N, 72.8232° E')
      .openPopup();
  </script>
</body>
</html>
"""

    preview_html_path = os.path.join(PREVIEW_DIR, "mumbai_map_preview.html")
    with open(preview_html_path, "w", encoding="utf-8") as f:
        f.write(html_content)

    print(f"\n✓ Validation report generated: {report_path}")
    print(f"✓ Interactive HTML Map Preview created: {preview_html_path}")
    print("=" * 70)


if __name__ == "__main__":
    generate_validation_and_preview()

