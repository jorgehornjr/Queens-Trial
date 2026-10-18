class_name QueenBalance
extends Node3D

signal malfunction_finished(completed: bool)

const MODEL := preload("res://assets/models/props/balance/balance.glb")
const DISSOLVE = preload("res://shaders/ritual_dissolve.gdshader")
const WORLD_SCALE := 0.15
const QUESTION_FONT = preload("res://assets/fonts/jupiter_pro.otf")
const MALFUNCTION_DURATION := 1.65
const QUESTION_COLOR := Color(1.0, 0.97, 0.87)

var reveal := 0.0:
	set(value):
		reveal = value
		for material in _materials:
			material.set_shader_parameter("reveal", value)
var weight_angle := 0.0:
	set(value):
		weight_angle = 0.0 if broken else value
		_apply_pose()

var _orb: Node3D
var _beam: Node3D
var _left_pan: Node3D
var _right_pan: Node3D
var _materials: Array[ShaderMaterial] = []
var _weight_tween: Tween
var question_mark: Label3D
var broken := false
var malfunction_running := false
var _damage_tween: Tween
var _damage_progress := 0.0
var _beam_rest := Transform3D.IDENTITY
var _left_rest := Transform3D.IDENTITY
var _right_rest := Transform3D.IDENTITY


func _ready() -> void:
	top_level = true
	var model := MODEL.instantiate() as Node3D
	add_child(model)
	_beam = model.find_child("Beam", true, false) as Node3D
	_left_pan = model.find_child("LeftPan", true, false) as Node3D
	_right_pan = model.find_child("RightPan", true, false) as Node3D
	_beam_rest = _beam.transform
	_left_rest = _left_pan.transform
	_right_rest = _right_pan.transform
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
	question_mark = Label3D.new()
	question_mark.name = "UnknownWeight"
	question_mark.text = "?"
	question_mark.font = QUESTION_FONT
	question_mark.font_size = 192
	question_mark.pixel_size = 0.064
	question_mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	question_mark.no_depth_test = true
	question_mark.outline_size = 10
	question_mark.outline_modulate = Color(0.02, 0.025, 0.045, 0.95)
	question_mark.modulate = QUESTION_COLOR
	question_mark.top_level = true
	add_child(question_mark)
	question_mark.hide()
	hide()


func configure(orb: Node3D) -> void:
	_orb = orb
	_process(0.0)


func _process(_delta: float) -> void:
	if is_instance_valid(_orb):
		global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * WORLD_SCALE), _orb.global_position - Vector3.UP * 6.0)
		if broken: _apply_pose()
		if is_instance_valid(question_mark):
			question_mark.global_position = _beam.global_position + Vector3(0, -6.0, 3.0)


func set_weights(left: int, right: int, concealed := false) -> void:
	if concealed:
		_start_malfunction()
		return
	if broken or malfunction_running: reset_weights()
	question_mark.hide()
	if _weight_tween != null:
		_weight_tween.kill()
	var angle := deg_to_rad(clampf(5.0 + absf(float(right - left)) * 1.2, 6.0, 14.0))
	var target := angle if left > right else -angle
	_weight_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_weight_tween.tween_property(self, "weight_angle", target, 0.85)


func reset_weights() -> void:
	if _weight_tween != null:
		_weight_tween.kill()
		_weight_tween = null
	if _damage_tween != null and _damage_tween.is_valid(): _damage_tween.kill()
	_damage_tween = null
	var interrupted := malfunction_running
	malfunction_running = false
	broken = false
	_damage_progress = 0.0
	weight_angle = 0.0
	if is_instance_valid(question_mark):
		question_mark.hide()
		question_mark.scale = Vector3.ONE
		question_mark.modulate = QUESTION_COLOR
	if interrupted: malfunction_finished.emit(false)

func _apply_pose() -> void:
	if not is_instance_valid(_beam): return
	# Restore whole transforms, including translations, before applying any pose.
	_beam.transform = _beam_rest
	_left_pan.transform = _left_rest
	_right_pan.transform = _right_rest
	if broken:
		# Both assemblies loosen and drop together. No roll or unequal heights.
		var shudder := sin(_damage_progress * TAU * 8.0) * 0.65 * (1.0 - smoothstep(0.0, 0.4, _damage_progress))
		_beam.position.y += shudder
		var release := smoothstep(0.22, 0.78, _damage_progress)
		var drop := release * 22.0 + sin(release * PI) * 2.0
		_left_pan.position.y -= drop
		_right_pan.position.y -= drop
		_left_pan.position.x -= release * 6.0
		_right_pan.position.x += release * 6.0
	else:
		_beam.basis = _beam_rest.basis * Basis(Vector3.BACK, weight_angle)
		_left_pan.basis = _left_rest.basis * Basis(Vector3.BACK, -weight_angle)
		_right_pan.basis = _right_rest.basis * Basis(Vector3.BACK, -weight_angle)

func _start_malfunction() -> void:
	reset_weights()
	broken = true
	malfunction_running = true
	_set_damage_progress(0.0)
	_damage_tween = create_tween()
	_damage_tween.tween_method(_set_damage_progress, 0.0, 1.0, MALFUNCTION_DURATION)
	_damage_tween.tween_callback(_finish_malfunction)

func _set_damage_progress(amount: float) -> void:
	_damage_progress = amount
	_apply_pose()
	var reveal_mark := smoothstep(0.32, 0.82, amount)
	question_mark.visible = reveal_mark > 0.001
	question_mark.modulate = Color(QUESTION_COLOR, reveal_mark)
	question_mark.scale = Vector3.ONE * lerpf(1.18, 1.0, reveal_mark)

func _finish_malfunction() -> void:
	_set_damage_progress(1.0)
	malfunction_running = false
	malfunction_finished.emit(true)
