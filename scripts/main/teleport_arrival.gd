class_name TeleportArrival
extends Node3D
## Opaque vertical rift: the leading foot emerges by crossing its plane.

const LIFE := 9.2
const VOID_SHADER := preload("res://shaders/priest_portal_void.gdshader")
const AURA_SHADER := preload("res://shaders/priest_portal_aura.gdshader")
const TURBULENCE := preload("res://assets/textures/effects/priest_rift_noise.png")
const WISP_COUNT := 56
var _core: MeshInstance3D
var _aura: MeshInstance3D
var _wisps: MultiMeshInstance3D
var _core_material: ShaderMaterial
var _aura_material: ShaderMaterial
var _light: OmniLight3D
var _elapsed := LIFE
var _active := false
var aperture := 0.0

func _ready() -> void:
	visible = false
	set_process(false)
	_build_effect()

func burst() -> void:
	_elapsed = 0.0
	_active = true
	visible = true
	set_process(true)
	_update_effect()

func set_age(age: float) -> void:
	set_process(false)
	_elapsed = maxf(0.0, age)
	if _elapsed >= LIFE:
		stop()
		return
	_update_effect()

func stop() -> void:
	_active = false
	aperture = 0.0
	visible = false
	set_process(false)
	if _light != null: _light.light_energy = 0.0

func _process(delta: float) -> void:
	if not _active: return
	_elapsed += delta
	if _elapsed >= LIFE: stop()
	else: _update_effect()

func _build_effect() -> void:
	_core = MeshInstance3D.new()
	_core.name = "OpaqueRift"
	var core_mesh := QuadMesh.new()
	core_mesh.size = Vector2(4.2, 6.2)
	_core.mesh = core_mesh
	_core.position.y = 2.72
	_core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_core_material = ShaderMaterial.new()
	_core_material.shader = VOID_SHADER
	_core_material.set_shader_parameter("turbulence",TURBULENCE)
	_core.material_override = _core_material
	add_child(_core)
	_aura = MeshInstance3D.new()
	_aura.name = "VioletBoundary"
	var aura_mesh := QuadMesh.new()
	aura_mesh.size = Vector2(5.35, 7.9)
	_aura.mesh = aura_mesh
	_aura.position = Vector3(0, 2.72, -0.025)
	_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_aura_material = ShaderMaterial.new()
	_aura_material.shader = AURA_SHADER
	_aura_material.set_shader_parameter("turbulence",TURBULENCE)
	_aura.material_override = _aura_material
	add_child(_aura)
	_wisps = MultiMeshInstance3D.new()
	_wisps.name = "OrbitingEmbers"
	var particles := MultiMesh.new()
	particles.transform_format = MultiMesh.TRANSFORM_3D
	particles.use_colors = true
	var sphere := SphereMesh.new()
	sphere.radius = 0.018
	sphere.height = 0.036
	sphere.radial_segments = 6
	sphere.rings = 3
	particles.mesh = sphere
	particles.instance_count = WISP_COUNT
	_wisps.multimesh = particles
	_wisps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = Color(0.28, 0.05, 0.43)
	material.emission_energy_multiplier = 1.8
	_wisps.material_override = material
	add_child(_wisps)
	_light = OmniLight3D.new()
	_light.name = "RiftLight"
	_light.position = Vector3(0, 2.8, -0.5)
	_light.light_color = Color(0.48, 0.15, 0.8)
	_light.omni_range = 10.0
	_light.light_energy = 0.0
	add_child(_light)

func _update_effect() -> void:
	var opening := smoothstep(0.0, 1.35, _elapsed)
	var closing := 1.0 - smoothstep(6.9, LIFE, _elapsed)
	aperture = opening * closing
	var scale_x := maxf(0.001, aperture * (0.92 + 0.015 * sin(_elapsed * 2.3)))
	var scale_y := maxf(0.001, smoothstep(0.0, 0.7, _elapsed) * closing)
	_core.scale = Vector3(scale_x, scale_y, 1.0)
	_aura.scale = _core.scale
	_core_material.set_shader_parameter("age", _elapsed)
	_core_material.set_shader_parameter("intensity", aperture)
	_aura_material.set_shader_parameter("age", _elapsed)
	_aura_material.set_shader_parameter("strength", aperture)
	_light.light_energy = 1.35 * aperture
	for i in range(WISP_COUNT):
		var angle := float(i) / WISP_COUNT * TAU + _elapsed * (0.3 + float(i % 4) * 0.06)
		var flutter := sin(_elapsed * 2.6 + i * 1.71) * 0.06
		var radius := 1.0 + flutter
		var point := Vector3(cos(angle) * 1.74 * scale_x * radius, 2.72 + sin(angle) * 2.75 * scale_y * radius, -0.08 + 0.06 * cos(angle * 3.0))
		var tangent := Vector3(-sin(angle), cos(angle), 0).normalized()
		var basis := Basis.looking_at(Vector3.FORWARD, tangent).scaled(Vector3(1.0, 2.0 + 1.8 * flutter, 1.0) * aperture)
		_wisps.multimesh.set_instance_transform(i, Transform3D(basis, point))
		_wisps.multimesh.set_instance_color(i, Color(0.48, 0.11, 0.66, aperture * (0.25 + 0.55 * sin(angle + i) * sin(angle + i))))
