class_name MinimapManager
extends Control

## MinimapManager for Mumbai Drive
## Draws a 2D GPS navigation minimap displaying the player's vehicle, heading,
## and surrounding road network vectors.

@export var player_target: Node3D
@export var minimap_radius_meters: float = 250.0 # Visible world radius around car
@export var road_color: Color = Color(0.35, 0.4, 0.46, 0.8)
@export var player_color: Color = Color(1.0, 0.45, 0.0) # Mumbai Orange
@export var background_color: Color = Color(0.08, 0.09, 0.11, 0.85)

var _road_segments: Array[PackedVector2Array] = []

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)

func register_road_segment(points_world: PackedVector3Array) -> void:
	var pts2d := PackedVector2Array()
	for p in points_world:
		pts2d.append(Vector2(p.x, p.z))
	_road_segments.append(pts2d)
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(player_target):
		queue_redraw()

func _draw() -> void:
	var map_size := size
	var center := map_size * 0.5
	var radius := minf(center.x, center.y) - 4.0
	
	# Draw circular GPS radar background
	draw_circle(center, radius, background_color)
	draw_arc(center, radius, 0.0, TAU, 32, Color(0.25, 0.28, 0.35, 0.8), 2.0)
	
	if not is_instance_valid(player_target):
		return
		
	var player_pos_3d := player_target.global_position
	var player_pos_2d := Vector2(player_pos_3d.x, player_pos_3d.z)
	var scale_factor := radius / minimap_radius_meters
	
	# Draw roads relative to player position
	for segment in _road_segments:
		if segment.size() < 2:
			continue
		for i in range(segment.size() - 1):
			var p1 := center + (segment[i] - player_pos_2d) * scale_factor
			var p2 := center + (segment[i + 1] - player_pos_2d) * scale_factor
			# Simple clip to radar radius
			if p1.distance_to(center) <= radius and p2.distance_to(center) <= radius:
				draw_line(p1, p2, road_color, 3.0)
				
	# Draw player vehicle indicator (directional triangle pointing along car's forward vector)
	var car_forward := -player_target.global_transform.basis.z
	var angle := atan2(car_forward.x, -car_forward.z)
	
	var triangle_size := 8.0
	var tip := center + Vector2(sin(angle), -cos(angle)) * triangle_size
	var left := center + Vector2(sin(angle + 2.5), -cos(angle + 2.5)) * (triangle_size * 0.7)
	var right := center + Vector2(sin(angle - 2.5), -cos(angle - 2.5)) * (triangle_size * 0.7)
	
	draw_colored_polygon(PackedVector2Array([tip, left, right]), player_color)

