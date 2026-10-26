class_name RomanConstellationField
extends Node2D


const DATA_PATH := "res://data/astronomy/constellations.json"
const FONT: Font = preload("res://assets/fonts/Alegreya-Variable.ttf")
const BUILD_SECONDS := 2.4
const BREATH_SECONDS := 6.0
const AREAS := [
	Rect2(35, 38, 150, 94), Rect2(210, 65, 150, 105),
	Rect2(1560, 50, 150, 100), Rect2(1735, 58, 150, 100),
	Rect2(40, 192, 155, 103), Rect2(223, 209, 150, 100),
	Rect2(1547, 207, 150, 100), Rect2(1735, 190, 150, 105),
	Rect2(12, 355, 98, 95), Rect2(1810, 355, 98, 95),
	Rect2(12, 500, 98, 95), Rect2(1810, 500, 98, 95),
	Rect2(12, 650, 98, 95), Rect2(1810, 650, 98, 95),
	Rect2(40, 808, 150, 105), Rect2(220, 886, 150, 105),
	Rect2(1550, 886, 150, 105), Rect2(1735, 808, 150, 105),
	Rect2(80, 969, 160, 93), Rect2(1680, 969, 160, 93),
]
var charts: Array = []
var positions: Array[PackedVector2Array] = []
var births: Array[float] = []
var age := 0.0
var _star_glow: GradientTexture2D

func _ready() -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.12, 0.32, 0.6, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.72), Color(1, 1, 1, 0.28), Color(1, 1, 1, 0.045), Color(1, 1, 1, 0)])
	_star_glow = GradientTexture2D.new()
	_star_glow.gradient = gradient
	_star_glow.width = 128
	_star_glow.height = 128
	_star_glow.fill = GradientTexture2D.FILL_RADIAL
	_star_glow.fill_from = Vector2(0.5, 0.5)
	_star_glow.fill_to = Vector2(1.0, 0.5)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	charts = data.get("constellations", [])
	for index in range(charts.size()):
		var area: Rect2 = AREAS[index]
		var coordinates := PackedVector2Array()
		for point in charts[index].points: coordinates.append(Vector2(float(point[0]), float(point[1])))
		var bounds := Rect2(coordinates[0], Vector2.ZERO)
		for point in coordinates: bounds = bounds.expand(point)
		var available := area.size - Vector2(18, 28)
		var factor := minf(available.x / maxf(bounds.size.x, 0.01), available.y / maxf(bounds.size.y, 0.01))
		var center := area.position + Vector2(area.size.x * 0.5, (area.size.y - 24) * 0.5)
		for point_index in range(coordinates.size()): coordinates[point_index] = (coordinates[point_index] - bounds.get_center()) * factor + center
		positions.append(coordinates)
		births.append(INF)

func reset(complete: bool) -> void:
	age = 0.0
	for index in range(births.size()): births[index] = -BUILD_SECONDS if complete else INF
	queue_redraw()

func reveal_to(count: int) -> void:
	for index in range(mini(count, births.size())):
		if is_inf(births[index]): births[index] = age

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	age += delta
	queue_redraw()

func _draw() -> void:
	for index in range(charts.size()):
		if is_inf(births[index]): continue
		var chart: Dictionary = charts[index]
		var points := positions[index]
		var color := Color(String(chart.color))
		var reveal := clampf((age - births[index]) / BUILD_SECONDS, 0.0, 1.0)
		var segments: Array = chart.segments
		var arrivals: Array[float] = []
		arrivals.resize(points.size())
		arrivals.fill(INF)
		var total := 0.0
		for edge in segments: total += points[int(edge[0])].distance_to(points[int(edge[1])])
		var traveled := 0.0
		for edge in segments:
			var first := int(edge[0])
			var last := int(edge[1])
			var length := points[first].distance_to(points[last])
			arrivals[first] = minf(arrivals[first], traveled / maxf(total, 0.01))
			arrivals[last] = minf(arrivals[last], (traveled + length) / maxf(total, 0.01))
			var amount := clampf((reveal * total - traveled) / maxf(length, 0.01), 0.0, 1.0)
			if amount > 0.0:
				var endpoint := points[first].lerp(points[last], amount)
				draw_line(points[first], endpoint, Color(color, 0.055), 6.0, true)
				draw_line(points[first], endpoint, Color(color, 0.20), 2.7, true)
				draw_line(points[first], endpoint, Color(color, 0.72), 1.0, true)
			traveled += length
		for star in range(points.size()):
			var lit := smoothstep(arrivals[star] - 0.08, arrivals[star], reveal)
			if lit <= 0.0: continue
			var breath := 0.5 + 0.5 * sin(age * TAU / BREATH_SECONDS + index * 1.17 + star * 0.48)
			var glow := lerpf(0.24, 1.0, breath)
			var radius := lerpf(10.0, 21.0, breath)
			draw_texture_rect(_star_glow, Rect2(points[star] - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, Color(color, lit * glow * 0.62))
			var core := color.lerp(Color.WHITE, 0.3 + breath * 0.45)
			draw_circle(points[star], lerpf(1.5, 2.7, breath), Color(core, lit * lerpf(0.55, 1.0, breath)))
			var ray := lerpf(3.2, 6.8, breath)
			var ray_color := Color(color, lit * glow * 0.7)
			draw_line(points[star] - Vector2(ray, 0), points[star] + Vector2(ray, 0), ray_color, 0.8, true)
			draw_line(points[star] - Vector2(0, ray), points[star] + Vector2(0, ray), ray_color, 0.8, true)
		var label_alpha := smoothstep(0.65, 1.0, reveal) * 0.57
		var label: String = chart.name
		var width := FONT.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		var area: Rect2 = AREAS[index]
		draw_string(FONT, Vector2(area.get_center().x - width * 0.5, area.end.y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(color, label_alpha))
