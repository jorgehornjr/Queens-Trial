extends Node2D


const INDIGO := Color(0.15, 0.29, 0.42, 0.78)


func _draw() -> void:
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
