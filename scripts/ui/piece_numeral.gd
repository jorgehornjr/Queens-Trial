class_name PieceNumeral
extends Node3D
## Screen-space glyphs anchored above the piece, independent of 3D mipmaps/lighting.
const FONT = preload("res://assets/fonts/jupiter_pro.otf")
const FONT_SIZE := 48
var text := ""
var modulate := Color.WHITE
var suppressed := false
var label: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	label = Label.new()
	label.name = "SharpNumeral"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_color_override("font_color", Color(1.0,0.97,0.90))
	label.add_theme_color_override("font_outline_color", Color(0.035,0.016,0.012,0.95))
	layer.add_child(label)
	_process(0.0)

func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	label.visible = not suppressed and is_visible_in_tree() and camera != null and not camera.is_position_behind(global_position)
	if not label.visible: return
	var factor := get_viewport().get_visible_rect().size.y / 1080.0
	label.text = text
	label.modulate = modulate
	var font_size := maxi(22,roundi(FONT_SIZE*factor))
	if label.get_theme_font_size("font_size") != font_size: label.add_theme_font_size_override("font_size",font_size)
	var outline := maxi(1,roundi(2.0*factor))
	if label.get_theme_constant("outline_size") != outline: label.add_theme_constant_override("outline_size",outline)
	label.size = Vector2(130,64) * factor
	label.position = (camera.unproject_position(global_position) - label.size * 0.5 - Vector2(0,8)*factor).round()
