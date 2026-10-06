extends Node2D
## Pequenos traços de tinta ao redor da capitular e no cabeçalho da consulta.

var consultation_header := false
const GOLD := Color(0.66, 0.43, 0.17, 0.8)
const INDIGO := Color(0.15, 0.29, 0.42, 0.78)


func _draw() -> void:
	if consultation_header:
		_draw_header()
	else:
		for star in [Vector3(-12, 8, 5), Vector3(24, -10, 4), Vector3(69, -6, 3), Vector3(98, 23, 4), Vector3(106, 68, 3), Vector3(91, 118, 4), Vector3(45, 135, 4), Vector3(-10, 112, 3), Vector3(-18, 67, 5)]:
			_star(Vector2(star.x, star.y), star.z, INDIGO)
		for dot in [Vector2(-6, 35), Vector2(9, -5), Vector2(83, 3), Vector2(110, 91), Vector2(17, 126)]:
			draw_circle(dot, 1.1, INDIGO)


func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(8):
		var angle := float(index) * PI / 4.0
		var length := radius if index % 2 == 0 else radius * 0.21
		points.append(center + Vector2(sin(angle), cos(angle)) * length)
	draw_colored_polygon(points, color)


func _draw_header() -> void:
	for orbit in [Vector3(215, 68, -0.17), Vector3(174, 43, -0.17)]:
		var points := PackedVector2Array()
		for index in range(81):
			var angle := float(index) / 80.0 * TAU
			var p := Vector2(cos(angle) * orbit.x, sin(angle) * orbit.y).rotated(orbit.z)
			points.append(Vector2(282, 140) + p)
		draw_polyline(points, Color(GOLD, 0.44), 1.0, true)
	for star in [Vector3(78, 132, 10), Vector3(198, 94, 5), Vector3(446, 82, 14), Vector3(365, 173, 6), Vector3(157, 207, 5), Vector3(478, 212, 4), Vector3(103, 235, 4)]:
		_star(Vector2(star.x, star.y), star.z, GOLD)
	draw_circle(Vector2(281, 152), 12, Color(0.68, 0.46, 0.19, 0.27))
	draw_arc(Vector2(281, 152), 12, 0, TAU, 24, GOLD, 1, true)
