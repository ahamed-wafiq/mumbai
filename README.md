# Mumbai Drive – Real Geographical 3D Driving Simulator
**Greater Mumbai OpenStreetMap Architecture & Playable Prototype**

Built for **Godot 4** using **pure GDScript**, **Python 3 / Shapely / UTM Zone 43N**, and the **GL Compatibility (WebGL 2.0)** renderer.

---

## 🌆 1. Architecture Overview

**Mumbai Drive** has been upgraded from a static placeholder scene into an authentic, geographically accurate 3D representation of **Greater Mumbai (MCGM)**, Maharashtra, India.

All fake oversized blocks and hardcoded straight roads have been replaced with:
1. **Real OpenStreetMap Data**: Official administrative boundary, real road network corridors, real building footprints with actual/estimated heights, and coastlines.
2. **UTM Zone 43N (EPSG:32643)**: Snyder Transverse Mercator metric projection preserving real-world scales and distances without distortion.
3. **500m × 500m Spatial Grid Streaming**: 77 chunk tiles covering Greater Mumbai from Colaba to Dahisar & Mulund, streaming dynamically around the player vehicle.
4. **Preserved Driving Systems**: Vehicle physics, camera controls, minimalist HUD speedometer, and pause UI are 100% intact.

---

## 🗺️ 2. Real Geographical Coverage

The pipeline specifically targets **Greater Mumbai** (Mumbai City + Mumbai Suburban districts) and excludes non-MCGM areas of MMR (Thane/Navi Mumbai):

- **South Mumbai**: Colaba, Fort, Churchgate, Marine Drive, Girgaon Chowpatty, Byculla, Worli, Lower Parel, Dadar, Mahim.
- **Western Suburbs**: Bandra, Khar, Santacruz, Vile Parle, Andheri, Jogeshwari, Goregaon, Malad, Kandivali, Borivali, Dahisar.
- **Eastern Suburbs**: Kurla, Ghatkopar, Chembur, Powai, Bhandup, Mulund.
- **Major Corridors & Landmarks**:
  - Netaji Subhash Chandra Bose Road (Marine Drive - Queen's Necklace)
  - Western Express Highway (NH 48) (8 lanes, 60-80 km/h)
  - Bandra-Worli Sea Link (Rajiv Gandhi Sea Link with bridge piers)
  - Eastern Express Highway (EEH)
  - Jogeshwari-Vikhroli Link Road (JVLR) past Powai Lake
  - Bandra Kurla Complex (BKC) Avenue
  - Air India Building (78m), Oberoi Hotel (117m), Express Towers (105m), NCPA, Wankhede Stadium, Brabourne Stadium, Art Deco heritage blocks, Gateway of India, and CSMT.

---

## 📊 3. Validation Report Summary

| Metric | Measured Value |
| :--- | :--- |
| **Administrative Boundary** | Greater Mumbai (18.8970° N to 19.3180° N, 72.7800° E to 72.9650° E) |
| **North-South City Span** | **46.7 km** (Colaba Southern tip to Dahisar Check Naka) |
| **Total Road Corridors Length** | **105.94 km** (Motorways, Arterials, Secondary roads) |
| **Building Footprints Extracted** | **20 architectural footprints** (Max height: 117m, Avg: 49.0m) |
| **Generated 500m Grid Tiles** | **77 active tiles** in `data/tiles/` |
| **Starting Spawn Position** | **Marine Drive** (`18.9437° N, 72.8232° E`) |

---

## 🔍 4. Interactive Map Preview

Before launching in Godot, you can inspect the extracted geographical data in your web browser:

1. Open the file directly in any browser:
   ```
   mumbaicar/preview/mumbai_map_preview.html
   ```
2. Features in the preview:
   - High-contrast dark satellite base map.
   - Dashed orange polygon of the **Greater Mumbai boundary**.
   - Color-coded road networks (Red = Expressways, Orange = Arterials, Yellow = Secondary).
   - Extruded building footprints color-coded by height with interactive popups showing OSM ID, height, and tagged vs estimated status.
   - 📍 Starting spawn marker right on Marine Drive.

---

## 🐍 5. Python Data Pipeline

The pipeline scripts are located in `scripts/pipeline/`:

1. **`utm_converter.py`**:
   Implements the exact Snyder Transverse Mercator forward/inverse projection for UTM Zone 43N (EPSG:32643) with Marine Drive origin.
   ```bash
   python scripts/pipeline/utm_converter.py
   ```

2. **`extract_mumbai_osm.py`**:
   Extracts OSM features, preserving original IDs, tags, coordinates, and layer hierarchies.
   ```bash
   python scripts/pipeline/extract_mumbai_osm.py
   ```

3. **`process_mumbai_data.py`**:
   Projects geometries to metric coordinates, estimates missing heights, and chunks the city into 500m × 500m tiles (`data/tiles/tile_X_Z.json`).
   ```bash
   python scripts/pipeline/process_mumbai_data.py
   ```

4. **`validate_and_preview.py`**:
   Generates the validation report (`preview/validation_report.json`) and the HTML map preview (`preview/mumbai_map_preview.html`).
   ```bash
   python scripts/pipeline/validate_and_preview.py
   ```

---

## 🎮 6. Driving in the 3D City (Godot 4)

1. Open **Godot 4** and launch the project (`F5`).
2. Click **START DRIVING**.
3. You will spawn directly on **Marine Drive** overlooking the Arabian Sea.
4. The `WorldStreamer` dynamically streams in tile `(0, 0)` and surrounding tiles:
   - The road beneath you is the real asphalt ribbon generated from OSM geometries with real-world lane widths and drivable collision.
   - Real buildings (Air India Building, Oberoi Hotel, Art Deco apartments, stadiums) stand on their actual geographical footprints.
5. As you drive north toward Girgaon Chowpatty or south toward Nariman Point, the streamer loads upcoming 500m tiles and unloads distant ones, maintaining high frame rates.

### Controls Reference
- **W / Up Arrow**: Accelerate
- **S / Down Arrow**: Brake / Reverse
- **A / D**: Steer Left / Right
- **Space**: Handbrake
- **C**: Toggle Camera (3rd-person chase ⇄ 1st-person cockpit)
- **R**: Reset car to Marine Drive
- **Esc**: Pause menu
