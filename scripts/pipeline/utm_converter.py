#!/usr/bin/env python3
"""
Mumbai Drive - UTM Zone 43N (EPSG:32643) Coordinate Converter
Converts WGS-84 Latitude/Longitude to UTM Zone 43N metric coordinates.
Supports pyproj if installed, with a verified Snyder Transverse Mercator fallback.
"""

import math

# Reference Origin for Mumbai Drive: Marine Drive / Nariman Point
DEFAULT_ORIGIN_LAT = 18.9437
DEFAULT_ORIGIN_LON = 72.8232

# WGS 84 Ellipsoid Constants
WGS84_A = 6378137.0          # Semi-major axis (meters)
WGS84_F = 1.0 / 298.257223563 # Flattening
WGS84_B = WGS84_A * (1.0 - WGS84_F)
WGS84_E2 = 2.0 * WGS84_F - WGS84_F * WGS84_F # First eccentricity squared
WGS84_EB2 = WGS84_E2 / (1.0 - WGS84_E2)     # Second eccentricity squared

# UTM Zone 43N Constants (Central Meridian = 75° E)
UTM_ZONE_43_CM_DEG = 75.0
UTM_K0 = 0.9996
UTM_FALSE_EASTING = 500000.0
UTM_FALSE_NORTHING = 0.0

# Try importing pyproj
_HAS_PYPROJ = False
_PYPROJ_TRANSFORMER = None
_PYPROJ_INVERSE = None

try:
    import pyproj
    _PYPROJ_TRANSFORMER = pyproj.Transformer.from_crs("EPSG:4326", "EPSG:32643", always_xy=True)
    _PYPROJ_INVERSE = pyproj.Transformer.from_crs("EPSG:32643", "EPSG:4326", always_xy=True)
    _HAS_PYPROJ = True
except Exception:
    _HAS_PYPROJ = False


def wgs84_to_utm43n_snyder(lat_deg: float, lon_deg: float) -> tuple[float, float]:
    """
    Standard Snyder Transverse Mercator forward projection for UTM Zone 43N (WGS84).
    Returns (easting, northing) in meters. Accurate to millimeters.
    """
    phi = math.radians(lat_deg)
    lam = math.radians(lon_deg)
    lam0 = math.radians(UTM_ZONE_43_CM_DEG)
    dlam = lam - lam0

    sin_phi = math.sin(phi)
    cos_phi = math.cos(phi)
    tan_phi = math.tan(phi)

    n_val = WGS84_A / math.sqrt(1.0 - WGS84_E2 * sin_phi * sin_phi)
    t = tan_phi * tan_phi
    c = WGS84_EB2 * cos_phi * cos_phi
    a = dlam * cos_phi

    # Meridional distance M
    e2 = WGS84_E2
    m = WGS84_A * (
        (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * e2 * e2 * e2 / 256.0) * phi
        - (3.0 * e2 / 8.0 + 3.0 * e2 * e2 / 32.0 + 45.0 * e2 * e2 * e2 / 1024.0) * math.sin(2.0 * phi)
        + (15.0 * e2 * e2 / 256.0 + 45.0 * e2 * e2 * e2 / 1024.0) * math.sin(4.0 * phi)
        - (35.0 * e2 * e2 * e2 / 3072.0) * math.sin(6.0 * phi)
    )

    a2 = a * a
    a3 = a2 * a
    a4 = a2 * a2
    a5 = a4 * a
    a6 = a4 * a2

    easting = UTM_FALSE_EASTING + UTM_K0 * n_val * (
        a
        + (1.0 - t + c) * a3 / 6.0
        + (5.0 - 18.0 * t + t * t + 72.0 * c - 58.0 * WGS84_EB2) * a5 / 120.0
    )

    northing = UTM_FALSE_NORTHING + UTM_K0 * (
        m
        + n_val * tan_phi * (
            a2 / 2.0
            + (5.0 - t + 9.0 * c + 4.0 * c * c) * a4 / 24.0
            + (61.0 - 58.0 * t + t * t + 600.0 * c - 330.0 * WGS84_EB2) * a6 / 720.0
        )
    )

    return (easting, northing)


def utm43n_to_wgs84_snyder(easting: float, northing: float) -> tuple[float, float]:
    """
    Inverse Transverse Mercator projection from UTM Zone 43N to WGS84 (lat_deg, lon_deg).
    """
    lam0 = math.radians(UTM_ZONE_43_CM_DEG)
    x = easting - UTM_FALSE_EASTING
    y = northing - UTM_FALSE_NORTHING

    e2 = WGS84_E2
    e1 = (1.0 - math.sqrt(1.0 - e2)) / (1.0 + math.sqrt(1.0 - e2))
    mu = y / (WGS84_A * (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * e2 * e2 * e2 / 256.0))

    phi1 = mu + (
        (3.0 * e1 / 2.0 - 27.0 * e1 * e1 * e1 / 32.0) * math.sin(2.0 * mu)
        + (21.0 * e1 * e1 / 16.0 - 55.0 * e1 * e1 * e1 * e1 / 32.0) * math.sin(4.0 * mu)
        + (151.0 * e1 * e1 * e1 / 96.0) * math.sin(6.0 * mu)
        + (1097.0 * e1 * e1 * e1 * e1 / 512.0) * math.sin(8.0 * mu)
    )

    sin_phi1 = math.sin(phi1)
    cos_phi1 = math.cos(phi1)
    tan_phi1 = math.tan(phi1)

    c1 = WGS84_EB2 * cos_phi1 * cos_phi1
    t1 = tan_phi1 * tan_phi1
    n1 = WGS84_A / math.sqrt(1.0 - e2 * sin_phi1 * sin_phi1)
    r1 = WGS84_A * (1.0 - e2) / math.pow(1.0 - e2 * sin_phi1 * sin_phi1, 1.5)
    d = x / (n1 * UTM_K0)

    d2 = d * d
    d3 = d2 * d
    d4 = d2 * d2
    d5 = d4 * d
    d6 = d4 * d2

    lat = phi1 - (n1 * tan_phi1 / r1) * (
        d2 / 2.0
        - (5.0 + 3.0 * t1 + 10.0 * c1 - 4.0 * c1 * c1 - 9.0 * WGS84_EB2) * d4 / 24.0
        + (61.0 + 90.0 * t1 + 298.0 * c1 + 45.0 * t1 * t1 - 252.0 * WGS84_EB2 - 3.0 * c1 * c1) * d6 / 720.0
    )

    lon = lam0 + (
        d
        - (1.0 + 2.0 * t1 + c1) * d3 / 6.0
        + (5.0 - 2.0 * c1 + 28.0 * t1 - 3.0 * c1 * c1 + 8.0 * WGS84_EB2 + 24.0 * t1 * t1) * d5 / 120.0
    ) / cos_phi1

    return (math.degrees(lat), math.degrees(lon))


def latlon_to_utm(lat: float, lon: float) -> tuple[float, float]:
    """Converts (lat, lon) to UTM 43N (easting, northing)."""
    if _HAS_PYPROJ and _PYPROJ_TRANSFORMER:
        x, y = _PYPROJ_TRANSFORMER.transform(lon, lat)
        return (float(x), float(y))
    return wgs84_to_utm43n_snyder(lat, lon)


def utm_to_latlon(easting: float, northing: float) -> tuple[float, float]:
    """Converts UTM 43N (easting, northing) to (lat, lon)."""
    if _HAS_PYPROJ and _PYPROJ_INVERSE:
        lon, lat = _PYPROJ_INVERSE.transform(easting, northing)
        return (float(lat), float(lon))
    return utm43n_to_wgs84_snyder(easting, northing)


class MumbaiWorldProjection:
    """
    Handles translation between WGS-84 GPS coordinates and local Godot 3D game coordinates.
    Godot 3D Coordinate System:
      +X : East (Easting offset)
      +Y : Up (Elevation)
      -Z : North (Northing offset) -> Z = -(northing - origin_northing)
    """
    def __init__(self, origin_lat: float = DEFAULT_ORIGIN_LAT, origin_lon: float = DEFAULT_ORIGIN_LON):
        self.origin_lat = origin_lat
        self.origin_lon = origin_lon
        self.origin_easting, self.origin_northing = latlon_to_utm(origin_lat, origin_lon)

    def geo_to_godot(self, lat: float, lon: float, elevation: float = 0.0) -> tuple[float, float, float]:
        """Converts (lat, lon, elevation) to Godot 3D Vector3 (x, y, z) in meters."""
        easting, northing = latlon_to_utm(lat, lon)
        x = easting - self.origin_easting
        z = -(northing - self.origin_northing)
        return (round(x, 3), round(elevation, 3), round(z, 3))

    def godot_to_geo(self, x: float, z: float) -> tuple[float, float]:
        """Converts Godot 3D (x, z) in meters back to (lat, lon)."""
        easting = x + self.origin_easting
        northing = (-z) + self.origin_northing
        return utm_to_latlon(easting, northing)


if __name__ == "__main__":
    print(f"UTM 43N Engine ready (Using pyproj: {_HAS_PYPROJ})")
    proj = MumbaiWorldProjection(DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON)
    print(f"Origin Marine Drive ({DEFAULT_ORIGIN_LAT}, {DEFAULT_ORIGIN_LON}):")
    print(f"  UTM 43N: Easting={proj.origin_easting:.2f} m, Northing={proj.origin_northing:.2f} m")
    gx, gy, gz = proj.geo_to_godot(DEFAULT_ORIGIN_LAT, DEFAULT_ORIGIN_LON)
    print(f"  Godot local 3D: ({gx}, {gy}, {gz})")
    
    # Test nearby landmark: Gateway of India (18.9220 N, 72.8347 E)
    gw_x, gw_y, gw_z = proj.geo_to_godot(18.9220, 72.8347)
    print(f"Gateway of India (18.9220 N, 72.8347 E):")
    print(f"  Godot local 3D: X={gw_x:.1f} m (East), Z={gw_z:.1f} m (South)")
    dist = math.sqrt(gw_x * gw_x + gw_z * gw_z)
    print(f"  Distance from Marine Drive origin: {dist:.1f} meters (~{dist/1000.0:.2f} km)")

