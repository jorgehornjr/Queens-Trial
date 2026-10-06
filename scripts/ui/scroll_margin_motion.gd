class_name ScrollMarginMotion
extends Control

const ORBITS := [
	{"a": Vector2(469, 173), "b": Vector2(397, 225), "c": Vector2(300, 326), "d": Vector2(365, 414), "speed": 0.105, "offset": 0.11},
	{"a": Vector2(339, 440), "b": Vector2(306, 504), "c": Vector2(322, 625), "d": Vector2(391, 724), "speed": 0.083, "offset": 0.58},
	{"a": Vector2(1115, 128), "b": Vector2(1225, 183), "c": Vector2(1327, 285), "d": Vector2(1302, 397), "speed": 0.095, "offset": 0.34},
	{"a": Vector2(1365, 478), "b": Vector2(1313, 568), "c": Vector2(1260, 673), "d": Vector2(1381, 783), "speed": 0.078, "offset": 0.79},
]

var _elapsed := 0.0


func _ready() -> void:
	visible = false
	mouse_filter = MOUSE_FILTER_IGNORE
	set_process(false)


func begin_motion() -> void:
	_elapsed = 0.0
	visible = true
	set_process(true)


func end_motion() -> void:
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_elapsed += delta
	queue_redraw()


func _draw() -> void:
	for index in ORBITS.size():
		var orbit: Dictionary = ORBITS[index]
		var travel := fposmod(_elapsed * float(orbit["speed"]) + float(orbit["offset"]), 1.0)
		var point := _bezier(orbit["a"], orbit["b"], orbit["c"], orbit["d"], travel)
		var presence := pow(sin(travel * PI), 1.5) * (0.78 + 0.12 * sin(_elapsed * 1.4 + float(index)))
		draw_circle(point, 12.0, Color(0.78, 0.29, 0.10, 0.07 * presence))
		draw_circle(point, 6.0, Color(0.85, 0.40, 0.15, 0.20 * presence))
		draw_circle(point, 2.5, Color(0.95, 0.71, 0.39, 0.75 * presence))


func _bezier(a: Vector2, b: Vector2, c: Vector2, d: Vector2, t: float) -> Vector2:
	var inverse := 1.0 - t
	return a * pow(inverse, 3.0) + b * 3.0 * pow(inverse, 2.0) * t + c * 3.0 * inverse * pow(t, 2.0) + d * pow(t, 3.0)
