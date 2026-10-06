extends Node2D
## Pequenas regras de tinta fixa, desenhadas sobre o papel.

const INK := Color(0.54, 0.35, 0.17, 0.55)


func _draw() -> void:
	for bounds in [Vector2(584, 752), Vector2(848, 1016)]:
		draw_polyline(PackedVector2Array([
			Vector2(bounds.x, 408), Vector2((bounds.x + bounds.y) * 0.5, 407.5), Vector2(bounds.y, 408),
		]), INK, 1.0, true)
	var points := PackedVector2Array()
	for index in range(8):
		var angle := index * PI / 4.0
		var radius := 10.0 if index % 2 == 0 else 2.2
		points.append(Vector2(800, 408) + Vector2(sin(angle), cos(angle)) * radius)
	draw_colored_polygon(points, INK)
