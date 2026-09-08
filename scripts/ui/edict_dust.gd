extends Node2D
## Rasterize the current font once; every moving grain samples that exact glyph mask.
const EROSION = preload("res://shaders/edict_erosion.gdshader")
const STARDUST = preload("res://shaders/edict_stardust.gdshader")
const DURATION := 2.25

var _ink: ShaderMaterial
var _grains: ShaderMaterial

func prepare(source: Label) -> void:
	position = source.position
	var canvas_size := Vector2i(source.size)
	var viewport := SubViewport.new()
	viewport.name = "GlyphMask"
	viewport.size = canvas_size
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var glyphs := Label.new()
	glyphs.text = source.text
	glyphs.horizontal_alignment = source.horizontal_alignment
	glyphs.vertical_alignment = source.vertical_alignment
	glyphs.size = source.size
	var font := source.get_theme_font("font")
	var font_size := source.get_theme_font_size("font_size")
	glyphs.add_theme_font_override("font", font)
	glyphs.add_theme_font_size_override("font_size", font_size)
	glyphs.add_theme_color_override("font_color", source.get_theme_color("font_color"))
	glyphs.add_theme_constant_override("outline_size", 0)
	viewport.add_child(glyphs)
	var width := font.get_string_size(source.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var bounds := Vector2((source.size.x - width) * 0.5, (source.size.x + width) * 0.5) / source.size.x
	_ink = ShaderMaterial.new()
	_ink.shader = EROSION
	_grains = ShaderMaterial.new()
	_grains.shader = STARDUST
	for shader_material in [_ink, _grains]:
		shader_material.set_shader_parameter("mask_size", source.size)
		shader_material.set_shader_parameter("text_bounds", bounds)
	_grains.set_shader_parameter("glyph_mask", viewport.get_texture())
	var ink := TextureRect.new()
	ink.name = "ErodingGlyphs"
	ink.size = source.size
	ink.texture = viewport.get_texture()
	ink.material = _ink
	ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ink)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(2.8, 2.8)
	multimesh.mesh = quad
	var spacing := 1.7
	var columns := ceili((width + 12.0) / spacing)
	var rows := ceili(source.size.y / spacing)
	multimesh.instance_count = columns * rows
	var rng := RandomNumberGenerator.new()
	rng.seed = 78219
	for index in range(multimesh.instance_count):
		var row := floorf(float(index) / float(columns))
		var point := Vector2((source.size.x - width) * 0.5 - 6.0 + float(index % columns) * spacing, row * spacing)
		point += Vector2(rng.randf(), rng.randf()) * spacing
		multimesh.set_instance_transform_2d(index, Transform2D(0.0, point))
		multimesh.set_instance_custom_data(index, Color(point.x / source.size.x, point.y / source.size.y, rng.randf(), rng.randf()))
	# Explicit bounds include the wind plume outside the original text rectangle.
	multimesh.custom_aabb = AABB(Vector3(-20, -200, -1), Vector3(source.size.x + 620, source.size.y + 400, 2))
	var dust := MultiMeshInstance2D.new()
	dust.name = "GlyphGrains"
	dust.multimesh = multimesh
	dust.texture = viewport.get_texture()
	dust.material = _grains
	add_child(dust)
	set_elapsed(-1.0)
	visible = false

func set_elapsed(value: float) -> void:
	_ink.set_shader_parameter("elapsed", value)
	_grains.set_shader_parameter("elapsed", value)
