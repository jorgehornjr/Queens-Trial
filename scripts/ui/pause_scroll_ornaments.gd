extends Control

const INK := Color(0.31, 0.16, 0.10, 0.83)
const GOLD := Color(0.54, 0.35, 0.16, 0.84)


func _draw() -> void:
	_draw_divider(260.0, 236.0)
	_draw_divider(616.0, 205.0)
	for side in [-1.0, 1.0]:
		var center := Vector2(450.0 + side * 305.0, 336.0)
		draw_arc(center, 17.0, -PI * 0.82, PI * 0.82, 28, INK, 1.4, true)
		draw_arc(center, 10.0, -PI * 0.82, PI * 0.82, 22, GOLD, 1.1, true)
		draw_circle(center, 3.0, INK)
		draw_line(center + Vector2(0.0, -27.0), center + Vector2(0.0, 27.0), INK, 1.1, true)
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(0.0, -34.0),
			center + Vector2(4.0, -27.0),
			center + Vector2(0.0, -20.0),
			center + Vector2(-4.0, -27.0),
		]), GOLD)


func _draw_divider(y: float, half_width: float) -> void:
	var center := Vector2(450.0, y)
	draw_line(Vector2(450.0 - half_width, y), center + Vector2(-22.0, 0.0), GOLD, 1.6, true)
	draw_line(center + Vector2(22.0, 0.0), Vector2(450.0 + half_width, y), GOLD, 1.6, true)
	for side in [-1.0, 1.0]:
		var x: float = 450.0 + side * half_width
		draw_circle(Vector2(x, y), 2.7, INK)
		draw_circle(Vector2(450.0 + side * 28.0, y), 2.0, INK)
	draw_arc(center, 16.0, 0.0, TAU, 36, INK, 1.2, true)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -15.0),
		center + Vector2(7.0, 0.0),
		center + Vector2(0.0, 15.0),
		center + Vector2(-7.0, 0.0),
	]), INK)
	draw_circle(center, 2.2, GOLD)
