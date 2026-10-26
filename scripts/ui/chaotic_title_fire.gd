extends Node2D


const DURATION := 5.5
const SIZE := Vector2i(1440, 800)
const FLAME = preload("res://shaders/chaotic_title_combustion.gdshader")
const BLOOM = preload("res://shaders/chaotic_title_bloom.gdshader")
const HEAT = preload("res://shaders/chaotic_title_heat.gdshader")
const FIELDS: Texture2D = preload("res://assets/effects/chaotic_title/title_fields.exr")
const NOISE: Texture2D = preload("res://assets/effects/chaotic_title/turbulence.exr")
var _surface: ShaderMaterial
var _heat: ShaderMaterial
var elapsed := 0.0


func prepare(fields: Texture2D = FIELDS) -> void:
	var viewport := SubViewport.new()
	viewport.name = "Combustion"
	viewport.size = SIZE
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	_surface = ShaderMaterial.new()
	_surface.shader = FLAME
	_surface.set_shader_parameter("title_fields", fields)
	_surface.set_shader_parameter("turbulence", NOISE)
	var fire := ColorRect.new()
	fire.name = "BurningLetters"
	fire.size = SIZE
	fire.material = _surface
	fire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport.add_child(fire)
	_heat = ShaderMaterial.new()
	_heat.shader = HEAT
	var heat := ColorRect.new()
	heat.name = "HeatPressure"
	heat.position = Vector2(-240, -70)
	heat.size = Vector2(1920, 1080)
	heat.material = _heat
	heat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(heat)
	var bloom := ShaderMaterial.new()
	bloom.shader = BLOOM
	bloom.set_shader_parameter("combustion", viewport.get_texture())
	var result := ColorRect.new()
	result.name = "IncandescentTitle"
	result.size = SIZE
	result.material = bloom
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(result)
	visibility_changed.connect(func():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	)
	set_elapsed(0.0)
	hide()


func set_elapsed(value: float) -> void:
	elapsed = value
	_surface.set_shader_parameter("elapsed", value)
	_heat.set_shader_parameter("elapsed", value)
