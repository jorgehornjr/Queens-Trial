class_name SavageHUD
extends CanvasLayer

const FONT = preload("res://assets/fonts/jupiter_pro.otf")
const IVORY := Color(1.0, 0.91, 0.78)
const RUBY := Color(1.0, 0.34, 0.22)
var canvas: Control
var timer: Label
var banner: Label
var _banner_tween: Tween

func _ready() -> void:
	layer = 3
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.size = Vector2(1920,1080)
	timer = _label("Countdown", Vector2(1740,76), Vector2(144,88), 66, true)
	banner = _label("SavageBanner", Vector2(0,400), Vector2(1920,200), 154)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	banner.text = "Chaotic"
	banner.modulate.a = 0.0
	banner.show()
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.45)
	_banner_tween.tween_interval(1.0)
	_banner_tween.tween_property(banner, "modulate:a", 0.0, 0.8)
	_banner_tween.tween_callback(banner.hide)

func update_timer(seconds: float, _preparing: bool, _wave: int) -> void:
	timer.show()
	timer.text = "%02d" % ceili(maxf(seconds,0.0))
	timer.modulate = RUBY if seconds <= 3.0 else Color.WHITE

func resolving() -> void:
	timer.text = ""

func cancel() -> void:
	if _banner_tween != null and _banner_tween.is_valid(): _banner_tween.kill()
	canvas.hide()
	banner.hide()
