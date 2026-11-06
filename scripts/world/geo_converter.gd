class_name GeoConverter
extends RefCounted

## Mumbai Drive - UTM Zone 43N (EPSG:32643) Geographical Projection Utility
## Converts OpenStreetMap WGS-84 coordinates (Latitude, Longitude in degrees)
## into local 3D game engine positions (X, Y, Z in meters) using the exact
## Snyder Transverse Mercator forward and inverse projection.

# Reference Origin for Mumbai Drive: Marine Drive / Nariman Point
const DEFAULT_ORIGIN_LAT: float = 18.9437
const DEFAULT_ORIGIN_LON: float = 72.8232

# WGS 84 Ellipsoid Constants
const WGS84_A: float = 6378137.0          # Semi-major axis in meters
const WGS84_F: float = 1.0 / 298.257223563 # Flattening
const WGS84_E2: float = 0.00669437999014  # First eccentricity squared
const WGS84_EB2: float = 0.00673949674228 # Second eccentricity squared

# UTM Zone 43N Constants (Central Meridian = 75° E)
const UTM_CM_DEG: float = 75.0
const UTM_K0: float = 0.9996
const UTM_FALSE_EASTING: float = 500000.0
const UTM_FALSE_NORTHING: float = 0.0

var origin_lat: float
var origin_lon: float
var origin_easting: float
var origin_northing: float

func _init(p_origin_lat: float = DEFAULT_ORIGIN_LAT, p_origin_lon: float = DEFAULT_ORIGIN_LON) -> void:
	set_origin(p_origin_lat, p_origin_lon)

## Sets the geographic anchor point for the local game world (0, 0, 0)
func set_origin(p_lat: float, p_lon: float) -> void:
	origin_lat = p_lat
	origin_lon = p_lon
	var utm := latlon_to_utm43n(origin_lat, origin_lon)
	origin_easting = utm.x
	origin_northing = utm.y

## Converts GPS (lat, lon) to UTM Zone 43N (easting, northing) in meters
static func latlon_to_utm43n(lat_deg: float, lon_deg: float) -> Vector2:
	var phi := deg_to_rad(lat_deg)
	var lam := deg_to_rad(lon_deg)
	var lam0 := deg_to_rad(UTM_CM_DEG)
	var dlam := lam - lam0

	var sin_phi := sin(phi)
	var cos_phi := cos(phi)
	var tan_phi := tan(phi)

	var n_val := WGS84_A / sqrt(1.0 - WGS84_E2 * sin_phi * sin_phi)
	var t := tan_phi * tan_phi
	var c := WGS84_EB2 * cos_phi * cos_phi
	var a := dlam * cos_phi

	# Meridional distance M
	var e2 := WGS84_E2
	var m := WGS84_A * (
		(1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * e2 * e2 * e2 / 256.0) * phi
		- (3.0 * e2 / 8.0 + 3.0 * e2 * e2 / 32.0 + 45.0 * e2 * e2 * e2 / 1024.0) * sin(2.0 * phi)
		+ (15.0 * e2 * e2 / 256.0 + 45.0 * e2 * e2 * e2 / 1024.0) * sin(4.0 * phi)
		- (35.0 * e2 * e2 * e2 / 3072.0) * sin(6.0 * phi)
	)

	var a2 := a * a
	var a3 := a2 * a
	var a4 := a2 * a2
	var a5 := a4 * a
	var a6 := a4 * a2

	var easting := UTM_FALSE_EASTING + UTM_K0 * n_val * (
		a
		+ (1.0 - t + c) * a3 / 6.0
		+ (5.0 - 18.0 * t + t * t + 72.0 * c - 58.0 * WGS84_EB2) * a5 / 120.0
	)

	var northing := UTM_FALSE_NORTHING + UTM_K0 * (
		m
		+ n_val * tan_phi * (
			a2 / 2.0
			+ (5.0 - t + 9.0 * c + 4.0 * c * c) * a4 / 24.0
			+ (61.0 - 58.0 * t + t * t + 600.0 * c - 330.0 * WGS84_EB2) * a6 / 720.0
		)
	)

	return Vector2(easting, northing)

## Converts UTM Zone 43N (easting, northing) back to GPS (lat_deg, lon_deg)
static func utm43n_to_latlon(easting: float, northing: float) -> Vector2:
	var lam0 := deg_to_rad(UTM_CM_DEG)
	var x := easting - UTM_FALSE_EASTING
	var y := northing - UTM_FALSE_NORTHING

	var e2 := WGS84_E2
	var e1 := (1.0 - sqrt(1.0 - e2)) / (1.0 + sqrt(1.0 - e2))
	var mu := y / (WGS84_A * (1.0 - e2 / 4.0 - 3.0 * e2 * e2 / 64.0 - 5.0 * e2 * e2 * e2 / 256.0))

	var phi1 := mu + (
		(3.0 * e1 / 2.0 - 27.0 * e1 * e1 * e1 / 32.0) * sin(2.0 * mu)
		+ (21.0 * e1 * e1 / 16.0 - 55.0 * e1 * e1 * e1 * e1 / 32.0) * sin(4.0 * mu)
		+ (151.0 * e1 * e1 * e1 / 96.0) * sin(6.0 * mu)
		+ (1097.0 * e1 * e1 * e1 * e1 / 512.0) * sin(8.0 * mu)
	)

	var sin_phi1 := sin(phi1)
	var cos_phi1 := cos(phi1)
	var tan_phi1 := tan(phi1)

	var c1 := WGS84_EB2 * cos_phi1 * cos_phi1
	var t1 := tan_phi1 * tan_phi1
	var n1 := WGS84_A / sqrt(1.0 - e2 * sin_phi1 * sin_phi1)
	var r1 := WGS84_A * (1.0 - e2) / pow(1.0 - e2 * sin_phi1 * sin_phi1, 1.5)
	var d := x / (n1 * UTM_K0)

	var d2 := d * d
	var d3 := d2 * d
	var d4 := d2 * d2
	var d5 := d4 * d
	var d6 := d4 * d2

	var lat := phi1 - (n1 * tan_phi1 / r1) * (
		d2 / 2.0
		- (5.0 + 3.0 * t1 + 10.0 * c1 - 4.0 * c1 * c1 - 9.0 * WGS84_EB2) * d4 / 24.0
		+ (61.0 + 90.0 * t1 + 298.0 * c1 + 45.0 * t1 * t1 - 252.0 * WGS84_EB2 - 3.0 * c1 * c1) * d6 / 720.0
	)

	var lon := lam0 + (
		d
		- (1.0 + 2.0 * t1 + c1) * d3 / 6.0
		+ (5.0 - 2.0 * c1 + 28.0 * t1 - 3.0 * c1 * c1 + 8.0 * WGS84_EB2 + 24.0 * t1 * t1) * d5 / 120.0
	) / cos_phi1

	return Vector2(rad_to_deg(lat), rad_to_deg(lon))

## Converts GPS (lat, lon) to Local 3D World Vector3 (X, Y, Z) in meters.
## In Godot 3D:
## +X points East
## +Y points Up
## -Z points North
func geo_to_world(lat: float, lon: float, elevation: float = 0.0) -> Vector3:
	var utm := latlon_to_utm43n(lat, lon)
	var x := utm.x - origin_easting
	var z := -(utm.y - origin_northing)
	return Vector3(x, elevation, z)

## Converts local 3D world coordinates (X, Y, Z) back to GPS (lat, lon)
func world_to_geo(world_pos: Vector3) -> Vector2:
	var easting := world_pos.x + origin_easting
	var northing := (-world_pos.z) + origin_northing
	return utm43n_to_latlon(easting, northing)

## Parses a GeoJSON coordinate pair [lon, lat] or [lon, lat, elev]
func parse_geojson_point(coords: Array) -> Vector3:
	var lon: float = float(coords[0])
	var lat: float = float(coords[1])
	var elev: float = float(coords[2]) if coords.size() > 2 else 0.0
	return geo_to_world(lat, lon, elev)
