extends Control

const FONT: Font = preload("res://assets/fonts/WhiteDreamPERSONALUSEONLY-Regular.otf")
const COMPOSITE: Shader = preload("res://shaders/ending_calligraphy.gdshader")
const SIZE := Vector2i(1024, 640)
const FONT_SIZE := 420
const WRITE_SECONDS := 5.0

var title: Label
var progress := 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		if is_instance_valid(_result): (_result.material as ShaderMaterial).set_shader_parameter("write_progress", progress)
		if is_instance_valid(_pen):
			_pen.queue_redraw()
			_mask.render_target_update_mode = SubViewport.UPDATE_ONCE
var _ink: SubViewport
var _mask: SubViewport
var _pen: Node2D
var _result: TextureRect
var _strokes: Array[Dictionary] = []
var _length := 0.0
var _letter_start := 0.0


class Pen extends Node2D:
	var writing: Control
	func _draw() -> void:
		writing.draw_ink(self)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ink = _viewport("Lettering")
	title = Label.new()
	title.name = "FimCalligraphy"
	title.text = "Fim"
	title.size = SIZE
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", FONT_SIZE)
	title.add_theme_color_override("font_color", Color.WHITE)
	_ink.add_child(title)
	_mask = _viewport("PenMask")
	_prepare_strokes()
	_pen = Pen.new()
	_pen.writing = self
	_mask.add_child(_pen)
	_result = TextureRect.new()
	_result.texture = _ink.get_texture()
	_result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result.material = ShaderMaterial.new()
	(_result.material as ShaderMaterial).shader = COMPOSITE
	(_result.material as ShaderMaterial).set_shader_parameter("ink_mask", _mask.get_texture())
	(_result.material as ShaderMaterial).set_shader_parameter("write_progress", progress)
	(_result.material as ShaderMaterial).set_shader_parameter("letter_start", _letter_start)
	add_child(_result)
	get_viewport().size_changed.connect(_fit)
	_fit()


func _viewport(node_name: String) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.name = node_name
	viewport.size = SIZE
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	return viewport


func _fit() -> void:
	var view := get_viewport_rect().size
	var factor := minf(view.x / 1920.0, view.y / 1080.0) * 340.0 / FONT_SIZE
	_result.size = Vector2(SIZE) * factor
	_result.position = (view - _result.size) * 0.5


func draw_ink(canvas: Node2D) -> void:
	if progress >= 1.0:
		canvas.draw_rect(Rect2(Vector2.ZERO, Vector2(SIZE)), Color.WHITE)
		return
	var remaining := progress * _length
	for stroke in _strokes:
		if remaining <= 0.0: return
		var points: PackedVector2Array = stroke.points
		var visible_points := PackedVector2Array([points[0]])
		for index in range(1, points.size()):
			if remaining <= 0.0: break
			var length := points[index - 1].distance_to(points[index])
			var cost := length * float(stroke.pace)
			var end := points[index - 1].lerp(points[index], minf(remaining / maxf(cost, 0.001), 1.0))
			visible_points.append(end)
			remaining -= cost
		if visible_points.size() > 1:
			canvas.draw_polyline(visible_points, Color.WHITE, stroke.width, true)
			canvas.draw_circle(visible_points[0], float(stroke.width) * 0.5, Color.WHITE)
			canvas.draw_circle(visible_points[-1], float(stroke.width) * 0.5, Color.WHITE)


func _stroke(points: PackedVector2Array, width: float, pace := 1.0) -> void:
	var curve := Curve2D.new()
	curve.bake_interval = 3.0
	for index in range(points.size()):
		var previous := points[maxi(0, index - 1)]
		var next := points[mini(points.size() - 1, index + 1)]
		var handle := (next - previous) / 6.0
		curve.add_point(points[index], -handle, handle)
	var baked := curve.get_baked_points()
	for index in range(1, baked.size()): _length += baked[index - 1].distance_to(baked[index]) * pace
	_strokes.append({"points": baked, "width": width, "pace": pace})


func _prepare_strokes() -> void:
	# Traçados da fonte White Dream no espaço fixo da composição; a tela só escala o resultado.
	_stroke(PackedVector2Array([
		Vector2(350, 231), Vector2(340, 273), Vector2(309, 301),
		Vector2(270, 307), Vector2(230, 289), Vector2(211, 254),
		Vector2(218, 196), Vector2(253, 149), Vector2(308, 113),
		Vector2(380, 86), Vector2(460, 72), Vector2(558, 69),
		Vector2(657, 73), Vector2(730, 77),
	]), 74.0)
	_stroke(PackedVector2Array([
		Vector2(660, 80), Vector2(610, 122), Vector2(567, 181),
		Vector2(532, 250), Vector2(503, 321), Vector2(476, 394),
		Vector2(441, 464), Vector2(400, 520), Vector2(351, 558),
		Vector2(297, 581), Vector2(229, 590), Vector2(177, 573),
		Vector2(143, 543), Vector2(134, 493), Vector2(155, 456),
		Vector2(191, 435),
	]), 86.0, 1.08)
	_stroke(PackedVector2Array([
		Vector2(290, 367), Vector2(420, 360), Vector2(542, 364),
	]), 38.0, 0.8)
	_letter_start = _length
	_stroke(PackedVector2Array([
		Vector2(617, 226), Vector2(604, 266), Vector2(589, 314),
		Vector2(576, 365), Vector2(581, 403), Vector2(606, 411),
		Vector2(637, 380),
	]), 62.0)
	_stroke(PackedVector2Array([
		Vector2(696, 225), Vector2(688, 271), Vector2(670, 327),
		Vector2(650, 406), Vector2(679, 320), Vector2(716, 256),
		Vector2(744, 229), Vector2(772, 228), Vector2(783, 246),
		Vector2(774, 284), Vector2(754, 343), Vector2(739, 410),
		Vector2(766, 331), Vector2(803, 267), Vector2(829, 234),
		Vector2(853, 227), Vector2(867, 243), Vector2(861, 283),
		Vector2(842, 340), Vector2(829, 391), Vector2(841, 414),
		Vector2(865, 406), Vector2(885, 380), Vector2(908, 331),
	]), 72.0, 1.1)
	_stroke(PackedVector2Array([
		Vector2(642, 130), Vector2(635, 168),
	]), 64.0, 4.0)
	_letter_start /= _length
