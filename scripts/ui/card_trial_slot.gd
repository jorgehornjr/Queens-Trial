class_name CardTrialSlot
extends Control

signal dropped(index: int, value: int)
signal clicked(index: int)
const Assets = preload("res://scripts/ui/roman_card_assets.gd")
const FONT = preload("res://assets/fonts/jupiter_pro.otf")
var index := 0
var value := 0
var claim := 0
var locked := false
var false_decree := false
var revision := 0
var _hovered := false
var _pressed_here := false
var _art: TextureRect
var _number: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_art = TextureRect.new()
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_SCALE
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	_number = _label(58)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))
	refresh()

func _label(font_size: int) -> Label:
	var text := Label.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_override("font", FONT)
	text.add_theme_font_size_override("font_size", font_size)
	text.add_theme_color_override("font_color", Color(0.94, 0.87, 0.72))
	add_child(text)
	return text

func refresh() -> void:
	if _art == null: return
	_art.size = size
	_art.texture = Assets.front(value)
	_art.material = Assets.card_material(value)
	if false_decree: (_art.material as ShaderMaterial).set_shader_parameter("false_mark", 1.0 if _hovered else 0.0)
	_art.visible = value > 0
	_number.text = str(claim) if claim > 0 else ""
	_number.position = Vector2(0, -77 if value > 0 else size.y * 0.36)
	_number.size = Vector2(size.x, 74)
	queue_redraw()

func _draw() -> void:
	var edge := Color(0.73, 0.57, 0.32, 0.80 if _hovered else 0.45)
	if locked: edge = Color(0.95, 0.76, 0.40, 0.9)
	if value == 0:
		var paper := StyleBoxFlat.new()
		paper.bg_color = Color(0.025, 0.03, 0.06, 0.35)
		paper.draw(get_canvas_item(), Rect2(Vector2.ZERO, size))
	for corner in [Vector2.ZERO, Vector2(size.x, 0), Vector2(0, size.y), size]:
		var dx := 1.0 if corner.x == 0 else -1.0
		var dy := 1.0 if corner.y == 0 else -1.0
		draw_line(corner + Vector2(dx * 5, dy * 28), corner + Vector2(dx * 5, dy * 5), edge, 1.7, true)
		draw_line(corner + Vector2(dx * 5, dy * 5), corner + Vector2(dx * 28, dy * 5), edge, 1.7, true)

func _hover(active: bool) -> void:
	_hovered = active
	if false_decree: (_art.material as ShaderMaterial).set_shader_parameter("false_mark", 1.0 if active else 0.0)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressed_here = true
		else:
			if _pressed_here and Rect2(Vector2.ZERO, size).has_point(event.position): clicked.emit(index)
			_pressed_here = false
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		clicked.emit(index)
		accept_event()

func _get_drag_data(_point: Vector2) -> Variant:
	if value == 0 or locked or false_decree: return null
	_pressed_here = false
	var preview := TextureRect.new()
	preview.texture = Assets.front(value)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.size = size
	preview.position = -size * 0.5
	preview.material = Assets.card_material(value)
	set_drag_preview(preview)
	return {"roman_card": value, "revision": revision}

func _can_drop_data(_point: Vector2, data: Variant) -> bool:
	return not locked and not false_decree and data is Dictionary and data.get("revision", -1) == revision and int(data.get("roman_card", 0)) in range(1, 21)

func _drop_data(_point: Vector2, data: Variant) -> void:
	dropped.emit(index, int(data.roman_card))
