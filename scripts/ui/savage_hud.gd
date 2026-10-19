class_name SavageHUD
extends CanvasLayer

signal banner_finished
signal countdown_warning(second: int)
const FireTitle = preload("res://scripts/ui/chaotic_title_fire.gd")
const FONT = preload("res://assets/fonts/jupiter_pro.otf")
const IVORY := Color(1.0, 0.91, 0.78)
const RUBY := Color(1.0, 0.34, 0.22)
var canvas: Control
var timer: Label
var _banner_tween: Tween
var fire_title: Node2D
var _presenting := false
var _last_warning_second := 0

func _ready() -> void:
	layer = 3
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.size = Vector2(1920,1080)
	timer = _label("Countdown", Vector2(1740,142), Vector2(144,88), 66, true)
	fire_title = FireTitle.new()
	fire_title.name = "ChaoticFireTitle"
	fire_title.position = Vector2(240, 70)
	canvas.add_child(fire_title)
	fire_title.prepare()
	canvas.hide()
	get_viewport().size_changed.connect(_fit)
	_fit()

func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var factor := minf(view.x/1920.0, view.y/1080.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (view - Vector2(1920,1080)*factor)*0.5

func _label(node_name: String, origin: Vector2, size_value: Vector2, font_size: int, right: bool = false) -> Label:
	var label := Label.new()
	label.name = node_name
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = origin
	label.size = size_value
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", IVORY)
	label.add_theme_color_override("font_shadow_color", Color(0.08,0.01,0.01,0.8))
	label.add_theme_constant_override("shadow_offset_y", 3)
	canvas.add_child(label)
	if right:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return label

func present(_number: int, _values: Array) -> void:
	cancel()
	canvas.show()
	timer.hide()
	_presenting = true
	fire_title.show()
	fire_title.set_elapsed(0.0)
	_banner_tween = create_tween()
	_banner_tween.tween_method(fire_title.set_elapsed, 0.0, FireTitle.DURATION, FireTitle.DURATION)
	_banner_tween.tween_callback(_finish_banner)

func _finish_banner() -> void:
	fire_title.hide()
	_presenting = false
	banner_finished.emit()

func update_timer(seconds: float, preparing: bool, _wave: int) -> void:
	if not preparing:
		timer.hide()
		return
	timer.show()
	var whole_seconds := ceili(maxf(seconds, 0.0))
	timer.text = "%02d" % whole_seconds
	timer.modulate = RUBY if seconds <= 3.0 else Color.WHITE
	if whole_seconds > 3:
		_last_warning_second = 0
	elif whole_seconds >= 1 and whole_seconds != _last_warning_second:
		_last_warning_second = whole_seconds
		countdown_warning.emit(whole_seconds)

func resolving() -> void:
	timer.text = ""
	timer.hide()

func cancel() -> void:
	_last_warning_second = 0
	if _banner_tween != null and _banner_tween.is_valid(): _banner_tween.kill()
	canvas.hide()
	fire_title.hide()
	if _presenting:
		_presenting = false
		banner_finished.emit()
