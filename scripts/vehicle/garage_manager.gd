class_name GarageManager
extends RefCounted

## GarageManager - Central Vehicle Registry & Selection System
## Stores specifications, mesh references, and handles switching between supercars.

const CARS: Array[Dictionary] = [
	{
		"id": "lamborghini",
		"name": "Lamborghini Aventador SVJ",
		"tagline": "6.5L V12 Naturally Aspirated Supercar",
		"mesh_path": "res://assets/models/lamborghini_body.obj",
		"color_name": "Giallo Auge Pearl Yellow",
		"top_speed": 350.0,
		"acceleration": 36.0,
		"braking": 48.0,
		"grip": 35.0,
		"rot_y": PI,
		"badge_color": Color(1.0, 0.85, 0.1) # Yellow
	},
	{
		"id": "ferrari",
		"name": "Ferrari SF90 Stradale",
		"tagline": "4.0L V8 Twin-Turbo Hybrid Hypercar",
		"mesh_path": "res://assets/models/ferrari_body.obj",
		"color_name": "Rosso Corsa Red",
		"top_speed": 340.0,
		"acceleration": 38.0,
		"braking": 46.0,
		"grip": 34.0,
		"rot_y": PI,
		"badge_color": Color(0.95, 0.15, 0.15) # Red
	},
	{
		"id": "porsche",
		"name": "Porsche 911 GT3 RS",
		"tagline": "4.0L Flat-6 Precision Track Weapon",
		"mesh_path": "res://assets/models/porsche_body.obj",
		"color_name": "Miami Blue Aero Spec",
		"top_speed": 320.0,
		"acceleration": 34.0,
		"braking": 50.0,
		"grip": 38.0,
		"rot_y": PI,
		"badge_color": Color(0.1, 0.65, 1.0) # Blue
	},
	{
		"id": "mclaren",
		"name": "McLaren 570S Spider",
		"tagline": "Carbon Monocell Lightweight Hypercar",
		"mesh_path": "res://assets/models/mclaren_body.obj",
		"color_name": "Papaya Orange",
		"top_speed": 330.0,
		"acceleration": 35.0,
		"braking": 45.0,
		"grip": 33.0,
		"rot_y": PI,
		"badge_color": Color(1.0, 0.45, 0.0) # Orange
	}
]

static var selected_car_index: int = 0

static func get_selected_car() -> Dictionary:
	return CARS[selected_car_index % CARS.size()]

static func set_selected_car(index: int) -> void:
	selected_car_index = posmod(index, CARS.size())

static func next_car() -> Dictionary:
	selected_car_index = (selected_car_index + 1) % CARS.size()
	return get_selected_car()

static func prev_car() -> Dictionary:
	selected_car_index = posmod(selected_car_index - 1, CARS.size())
	return get_selected_car()

