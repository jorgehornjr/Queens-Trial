class_name BalanceStardust
extends Node3D

const SHADER = preload("res://shaders/balance_stardust.gdshader")
const FLOOR_SHADER = preload("res://shaders/balance_floor_flow.gdshader")
var flow_direction := 0
var screen_dust: BalanceScreenDust
var strength := 0.0:
	set(value):
		strength = value
		if screen_dust != null:
			screen_dust.strength = value
		if _material != null:
			_material.set_shader_parameter("strength",value)
		if _floor_material != null:
			_floor_material.set_shader_parameter("strength",value)
var _particles: GPUParticles3D
var _process_material: ParticleProcessMaterial
var _material: ShaderMaterial
var _floor_material: ShaderMaterial
var _effect_time := 0.0


func _ready() -> void:
	_particles = GPUParticles3D.new()
	_particles.name = "GoldenFloorDust"
	_particles.amount = 1250
	_particles.lifetime = 1.35
	_particles.preprocess = 0.0
	_particles.local_coords = true
	_particles.emitting = false
	_particles.randomness = 0.65
	_particles.visibility_aabb = AABB(Vector3(-22,-1,-22),Vector3(44,5,44))
	_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_process_material = ParticleProcessMaterial.new()
	_process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_process_material.emission_box_extents = Vector3(18.2,0.10,18.2)
	_process_material.direction = Vector3.RIGHT
	_process_material.spread = 3.0
	_process_material.initial_velocity_min = 14.0
	_process_material.initial_velocity_max = 27.0
	_process_material.gravity = Vector3.ZERO
	_process_material.scale_min = 0.45
	_process_material.scale_max = 1.6
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0,0.12,0.68,1.0])
	gradient.colors = PackedColorArray([Color(1,1,1,0),Color(1,1,1,1),Color(1,1,1,0.7),Color(1,1,1,0)])
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	_process_material.color_ramp = ramp
	_particles.process_material = _process_material
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("strength",0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.36,0.36)
	quad.material = _material
	_particles.draw_pass_1 = quad
	_particles.position.y = 0.32
	add_child(_particles)
	var floor_flow := MeshInstance3D.new()
	floor_flow.name = "FloorShimmer"
	floor_flow.position.y = 0.18
	floor_flow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var plane := PlaneMesh.new()
	plane.size = Vector2(37.8,37.8)
	floor_flow.mesh = plane
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = FLOOR_SHADER
	_floor_material.set_shader_parameter("strength",0.0)
	floor_flow.material_override = _floor_material
	add_child(floor_flow)
	_process(0.0)


func _process(delta: float) -> void:
	_material.set_shader_parameter("world_to_board",global_transform.affine_inverse())
	_effect_time += delta
	_floor_material.set_shader_parameter("effect_time",_effect_time)


func start(direction: int) -> void:
	flow_direction = direction
	if screen_dust != null:
		screen_dust.start(direction)
	_effect_time = 0.0
	_floor_material.set_shader_parameter("flow_direction",float(direction))
	_process_material.direction = Vector3(float(direction),0,0)
	_particles.restart()
	_particles.emitting = true


func fade() -> void:
	if screen_dust != null:
		screen_dust.fade()
	_particles.emitting = false


func clear() -> void:
	if screen_dust != null:
		screen_dust.clear()
	flow_direction = 0
	strength = 0.0
	_particles.emitting = false
	_particles.restart()
	_particles.emitting = false
