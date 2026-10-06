class_name QueenBalance
extends Node3D

const MODEL_PATH := "res://assets/models/props/balance/balance.glb"
const DISSOLVE = preload("res://shaders/ritual_dissolve.gdshader")
const WORLD_SCALE := 0.15

var reveal := 0.0:
	set(value):
		reveal = value
		for material in _materials:
			material.set_shader_parameter("reveal", value)
var weight_angle := 0.0:
	set(value):
		weight_angle = value
		if is_instance_valid(_beam):
			_beam.rotation.z = value
			_left_pan.rotation.z = -value
			_right_pan.rotation.z = -value

var _orb: Node3D
var _beam: Node3D
var _left_pan: Node3D
var _right_pan: Node3D
var _materials: Array[ShaderMaterial] = []
var _weight_tween: Tween


func _ready() -> void:
	top_level = true
	var model := (load(MODEL_PATH) as PackedScene).instantiate() as Node3D
	add_child(model)
	_beam = model.find_child("Beam", true, false) as Node3D
	_left_pan = model.find_child("LeftPan", true, false) as Node3D
	_right_pan = model.find_child("RightPan", true, false) as Node3D
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 64
		for surface in range(mesh.mesh.get_surface_count()):
			var source := mesh.get_active_material(surface) as StandardMaterial3D
			var material := ShaderMaterial.new()
			material.shader = DISSOLVE
			if source != null:
				material.set_shader_parameter("base_color", source.albedo_texture)
				material.set_shader_parameter("orm_map", source.roughness_texture)
				material.set_shader_parameter("normal_map", source.normal_texture)
				material.set_shader_parameter("tint", source.albedo_color)
			material.set_shader_parameter("reveal", reveal)
			mesh.set_surface_override_material(surface, material)
			_materials.append(material)
	hide()


func configure(orb: Node3D) -> void:
	_orb = orb
	_process(0.0)


func _process(_delta: float) -> void:
	if is_instance_valid(_orb):
		global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * WORLD_SCALE), _orb.global_position - Vector3.UP * 6.0)


func set_weights(left: int, right: int) -> void:
	if _weight_tween != null:
		_weight_tween.kill()
	var angle := deg_to_rad(5.0 + absf(float(right - left)) * 3.0)
	var target := angle if left > right else -angle
	_weight_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weight_tween.tween_property(self, "weight_angle", target, 0.85)


func reset_weights() -> void:
	if _weight_tween != null:
		_weight_tween.kill()
	weight_angle = 0.0
