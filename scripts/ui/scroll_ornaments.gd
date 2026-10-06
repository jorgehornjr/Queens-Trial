extends Control

const INK := Color(0.16, 0.09, 0.07, 0.91)
const WINE := Color(0.29, 0.075, 0.07, 0.95)
const GOLD := Color(0.57, 0.35, 0.16, 0.83)
const PALE := Color(0.54, 0.36, 0.21, 0.50)


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	_draw_rule(843.0, 156.0, 285.0)
	_draw_rule(843.0, 812.0, 230.0)
	for index in 6:
		var column := 0 if index < 3 else 1
		var row := index % 3
		var center := Vector2(410.0 if column == 0 else 923.0, 453.0 + row * 137.0)
		_draw_symbol(index, center)
		var divider_x := 470.0 if column == 0 else 986.0
		var divider_y := 404.0 + row * 137.0
		draw_line(Vector2(divider_x, divider_y), Vector2(divider_x, divider_y + 91.0), INK, 1.25, true)
		_diamond(Vector2(divider_x, divider_y + 45.5), 5.0, WINE)


func _draw_rule(center_x: float, y: float, half_width: float) -> void:
	draw_line(Vector2(center_x - half_width, y), Vector2(center_x - 31.0, y), PALE, 1.35, true)
	draw_line(Vector2(center_x + 31.0, y), Vector2(center_x + half_width, y), PALE, 1.35, true)
	_dot(Vector2(center_x - half_width, y), 1.6, INK)
	_dot(Vector2(center_x + half_width, y), 1.6, INK)
	_ellipse(Vector2(center_x, y), 21.0, 12.0, GOLD, 1.15)
	_ellipse(Vector2(center_x, y), 7.5, 25.0, INK, 1.35)
	_diamond(Vector2(center_x, y), 7.0, INK)
	_dot(Vector2(center_x, y), 3.2, GOLD)
	for side in [-1.0, 1.0]:
		_diamond(Vector2(center_x + side * 36.0, y), 2.7, GOLD)


func _draw_symbol(index: int, center: Vector2) -> void:
	match index:
		0:
			_draw_crescent(center)
		1:
			_draw_eye(center)
		2:
			_draw_orb(center)
		3:
			_draw_atom(center)
		4:
			_draw_planet(center)
		5:
			_draw_compass(center)


func _draw_crescent(c: Vector2) -> void:
	_ellipse(c, 33.0, 39.0, INK, 1.65)
	_ellipse(c + Vector2(9.0, -1.0), 25.0, 35.0, PALE, 1.0)
	draw_line(c + Vector2(0, -53), c + Vector2(0, 53), INK, 1.6, true)
	_ellipse(c + Vector2(-9, 0), 17.0, 29.0, INK, 4.0, 0.47 * PI, 1.53 * PI)
	_ellipse(c + Vector2(-3, 0), 17.0, 28.0, GOLD, 1.1, 0.50 * PI, 1.50 * PI)
	_dot(c, 7.0, INK)
	_dot(c, 3.4, GOLD)
	for offset in [-51.0, 51.0]:
		_dot(c + Vector2(0, offset), 3.0, WINE)


func _draw_eye(c: Vector2) -> void:
	_ellipse(c, 39.0, 39.0, PALE, 1.1)
	_ellipse(c, 29.0, 27.0, INK, 1.2)
	var points := PackedVector2Array([c + Vector2(-52, 0), c + Vector2(-26, -13), c, c + Vector2(26, -13), c + Vector2(52, 0), c + Vector2(26, 13), c, c + Vector2(-26, 13), c + Vector2(-52, 0)])
	draw_polyline(points, INK, 2.0, true)
	_dot(c, 15.0, INK)
	_ellipse(c, 16.0, 16.0, GOLD, 1.3)
	_dot(c + Vector2(-4, -5), 3.0, GOLD)
	for offset in [-52.0, 52.0]:
		_diamond(c + Vector2(0, offset), 3.3, WINE)


func _draw_orb(c: Vector2) -> void:
	draw_line(c + Vector2(0, -51), c + Vector2(0, 52), INK, 1.4, true)
	_ellipse(c, 28.0, 41.0, INK, 1.6)
	_ellipse(c, 19.0, 32.0, GOLD, 1.0)
	_ellipse(c, 36.0, 13.0, PALE, 1.0, -0.63, 0.63)
	_dot(c, 14.0, INK)
	_dot(c + Vector2(-4.0, -5.0), 3.3, GOLD)
	for offset in [-52.0, 52.0]:
		_dot(c + Vector2(0, offset), 3.3, WINE)
	_dot(c + Vector2(-39, 0), 2.4, INK)
	_dot(c + Vector2(39, 0), 2.4, INK)


func _draw_atom(c: Vector2) -> void:
	draw_line(c + Vector2(0, -55), c + Vector2(0, 55), INK, 1.4, true)
	for angle in [-0.58, 0.58, PI * 0.5]:
		_ellipse(c, 43.0, 19.0, INK, 1.35, 0.0, TAU, angle)
	_ellipse(c, 27.0, 39.0, PALE, 1.0)
	_dot(c, 6.0, WINE)
	for point in [Vector2(31, -26), Vector2(-32, 22), Vector2(30, 28)]:
		_dot(c + point, 4.3, INK)
	for offset in [-55.0, 55.0]:
		_dot(c + Vector2(0, offset), 3.1, WINE)


func _draw_planet(c: Vector2) -> void:
	_ellipse(c, 29.0, 35.0, INK, 1.65)
	_ellipse(c, 40.0, 24.0, GOLD, 1.0, -0.75, 0.67, -0.35)
	_ellipse(c, 41.0, 25.0, PALE, 1.0, 2.38, 3.72, -0.35)
	draw_line(c + Vector2(0, -50), c + Vector2(0, 50), PALE, 1.0, true)
	_dot(c, 16.0, INK)
	_ellipse(c, 16.5, 16.5, GOLD, 1.2)
	_dot(c + Vector2(-4, -5), 3.4, GOLD)
	for offset in [-51.0, 51.0]:
		_dot(c + Vector2(0, offset), 5.0, WINE)
	_dot(c + Vector2(-44, 13), 3.4, WINE)


func _draw_compass(c: Vector2) -> void:
	_ellipse(c, 31.0, 31.0, GOLD, 1.1)
	for angle_index in 16:
		var angle := float(angle_index) * TAU / 16.0
		var start_radius := 38.0 if angle_index % 2 == 0 else 42.0
		var end_radius := 53.0 if angle_index % 4 == 0 else 48.0
		var direction := Vector2(cos(angle), sin(angle))
		draw_line(c + direction * start_radius, c + direction * end_radius, INK, 1.3, true)
	var eye := PackedVector2Array([c + Vector2(-49, 0), c + Vector2(0, -20), c + Vector2(49, 0), c + Vector2(0, 20), c + Vector2(-49, 0)])
	draw_polyline(eye, INK, 1.8, true)
	_dot(c, 17.0, INK)
	_ellipse(c, 17.0, 17.0, GOLD, 1.3)
	_dot(c + Vector2(-4, -5), 3.4, GOLD)
	for offset in [-56.0, 56.0]:
		_dot(c + Vector2(0, offset), 2.8, WINE)


func _ellipse(c: Vector2, radius_x: float, radius_y: float, color: Color, width: float, start: float = 0.0, end: float = TAU, rotation: float = 0.0) -> void:
	var points := PackedVector2Array()
	for index in 65:
		var angle := lerpf(start, end, float(index) / 64.0)
		points.append(c + Vector2(cos(angle) * radius_x, sin(angle) * radius_y).rotated(rotation))
	draw_polyline(points, color, width, true)


func _dot(c: Vector2, radius: float, color: Color) -> void:
	draw_circle(c, radius, color, true, -1.0, true)


func _diamond(c: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([c + Vector2(0, -radius), c + Vector2(radius * 0.74, 0), c + Vector2(0, radius), c + Vector2(-radius * 0.74, 0)])
	draw_colored_polygon(points, color)
