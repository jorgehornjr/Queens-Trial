extends Node2D


const GOLD := Color(0.70, 0.58, 0.36)
const SILVER := Color(0.80, 0.87, 0.94)
var anchors := [Vector2(520, 40), Vector2(220, 153), Vector2(820, 153)]
var chaotic_available := true
var emphasis := Vector3(1, 0, 0)
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _ellipse(center: Vector2, radii: Vector2, first: float, last: float, color: Color, width := 1.0) -> void:
	var points := PackedVector2Array()
	for index in range(121):
		var angle := lerpf(first, last, float(index) / 120.0)
		points.append(center + Vector2(cos(angle), sin(angle)) * radii)
	draw_polyline(points, color, width, true)


func _star(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(16):
		var angle := float(index) * TAU / 16.0
		var length := radius if index % 4 == 0 else (radius * 0.48 if index % 2 == 0 else radius * 0.12)
		points.append(center + Vector2(sin(angle), cos(angle)) * length)
	draw_colored_polygon(points, color)


func _draw() -> void:
	var center := Vector2(520, 425)
	_ellipse(center, Vector2(434, 385), PI + 0.4, TAU - 0.4, Color(GOLD, 0.61), 1.35)
	_ellipse(center, Vector2(444, 395), PI + 0.48, PI * 1.42, Color(SILVER, 0.17))
	_ellipse(center, Vector2(444, 395), PI * 1.58, TAU - 0.48, Color(SILVER, 0.17))
	for index in range(41):
		var angle := lerpf(PI + 0.48, TAU - 0.48, float(index) / 40.0)
		var direction := Vector2(cos(angle), sin(angle))
		var outer := center + direction * Vector2(456, 407)
		var inner := center + direction * Vector2(451 if index % 5 else 443, 402 if index % 5 else 394)
		draw_line(inner, outer, Color(GOLD, 0.32 if index % 5 else 0.64), 1.0, true)

	for direction in [-1.0, 1.0]:
		var hinge := Vector2(520 + direction * 71, 286)
		draw_line(hinge, Vector2(520 + direction * 320, 286), Color(GOLD, 0.37), 1.0, true)
		_star(Vector2(520 + direction * 335, 286), 5, Color(SILVER, 0.7))
		draw_circle(Vector2(520 + direction * 365, 286), 1.5, Color(GOLD, 0.56))
	_ellipse(Vector2(520, 286), Vector2(31, 7), 0, TAU, Color(GOLD, 0.38))
	draw_arc(Vector2(520, 286), 19, -PI * 0.75, PI * 0.25, 40, Color(SILVER, 0.52), 1.0, true)
	draw_arc(Vector2(520, 286), 15, PI * 0.25, PI * 1.25, 40, Color(GOLD, 0.6), 1.0, true)
	for index in range(3):
		if index == 1 and not chaotic_available: continue
		var point: Vector2 = anchors[index]
		var focus: float = emphasis[index]
		var radius := lerpf(4.5, 10.0, focus)
		for halo in range(4, 0, -1):
			draw_circle(point, radius + halo * 2.7, Color(GOLD, 0.016 * focus))
		_star(point, radius, Color(SILVER.lerp(Color(1.0, 0.86, 0.55), focus), 0.48 + focus * 0.52))
		var underline := point + Vector2(0, 113 if index == 0 else 103)
		var length := 35.0 + 54.0 * focus
		draw_line(underline - Vector2(length, 0), underline + Vector2(length, 0), Color(GOLD, 0.22 + focus * 0.53), 1.0, true)
		_star(underline, 2.4 + focus, Color(GOLD, 0.45 + focus * 0.5))
		if focus > 0.02:
			var orbiting := point + Vector2(cos(_time * 0.55) * 13, sin(_time * 0.55) * 4)
			draw_circle(orbiting, 1.15, Color(1.0, 0.89, 0.64, focus * 0.64))
