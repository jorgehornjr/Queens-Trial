extends Node3D

const CHARACTER_LAYER := 64
const INSTRUMENT_SHADER = preload("res://shaders/astraia_instrument.gdshader")
const BASE_COLOR = preload("res://assets/models/props/astraia/textures/Instru_Low_01_Instruments_BaseColor.jpeg")
const METALLIC = preload("res://assets/models/props/astraia/textures/Instru_Low_01_Instruments_Metallic.jpeg")
const NORMAL = preload("res://assets/models/props/astraia/textures/Instru_Low_01_Instruments_Normal.jpeg")
const ROUGHNESS = preload("res://assets/models/props/astraia/textures/Instru_Low_01_Instruments_Roughness.jpeg")
const OPACITY = preload("res://assets/models/props/astraia/textures/Instruments_Opacity.jpg")


func _ready() -> void:
	var material := ShaderMaterial.new()
	material.shader = INSTRUMENT_SHADER
	material.set_shader_parameter("base_color", BASE_COLOR)
	material.set_shader_parameter("metallic_map", METALLIC)
	material.set_shader_parameter("roughness_map", ROUGHNESS)
	material.set_shader_parameter("normal_map", NORMAL)
	material.set_shader_parameter("opacity_map", OPACITY)
	for mesh: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		mesh.layers = CHARACTER_LAYER
		for surface in range(mesh.mesh.get_surface_count()):
			mesh.set_surface_override_material(surface, material)
	var player := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if player != null and player.has_animation("orbit"):
		var animation := player.get_animation("orbit")
		animation.loop_mode = Animation.LOOP_LINEAR
		player.play("orbit")
