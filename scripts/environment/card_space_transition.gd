class_name CardSpaceTransition
extends Node

signal finished(completed: bool)
const PASSAGE = preload("res://shaders/card_space_passage.gdshader")
@export_range(2.0, 10.0, 0.1) var duration := 4.8
var in_space := false
var transitioning := false
var progress := 0.0
var camera: Camera3D
var _veil: ColorRect
var _material: ShaderMaterial
var _motion: Tween
var _visibility: Dictionary = {}
var _from: Transform3D
var _from_fov := 60.0
var _rig: BoardOrbitCamera
var _space: CelestialSpace
var _saved_camera: Camera3D
var _hidden := false

func _ready() -> void:
	var main := get_parent().get_parent()
	_rig = main.get_node("World/BoardCamera")
	_space = main.get_node("World/CelestialSpace")
	camera = Camera3D.new()
	camera.name = "CardSpaceCamera"
	camera.far = _rig.camera.far
	add_child(camera)
	var layer := CanvasLayer.new()
	layer.layer = 0
	add_child(layer)
	_veil = ColorRect.new()
	_veil.name = "PassingNebula"
	_material = ShaderMaterial.new()
	_material.shader = PASSAGE
	_veil.material = _material
	_veil.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_veil)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.hide()

func enter_space() -> bool:
	if transitioning:
		camera.make_current()
		return await finished
	if in_space:
		camera.make_current()
		return true
	in_space = true
	transitioning = true
	_hidden = false
	_visibility.clear()
	for node in _rig.get_parent().get_children():
		if node is Node3D and node not in [_rig, _space]: _visibility[node] = node.visible
	for node in _space.get_children():
		if node is Node3D and node not in [_space.world_environment, _space.star_field]: _visibility[node] = node.visible
	_saved_camera = get_viewport().get_camera_3d()
	_from = _rig.camera.global_transform
	_from_fov = _rig.camera.fov
	camera.global_transform = _from
	camera.fov = _from_fov
	camera.make_current()
	_veil.show()
	_step(0.0)
	_motion = create_tween()
	_motion.tween_method(_step, 0.0, 1.0, duration)
	_motion.tween_callback(_complete)
	return await finished

func _step(amount: float) -> void:
	progress = amount
	_material.set_shader_parameter("progress", amount)
	var view := get_viewport().get_visible_rect().size
	_material.set_shader_parameter("aspect", view.x / maxf(view.y, 1.0))
	var travel := smoothstep(0.03, 0.94, amount)
	camera.global_position = _from.origin + Vector3.UP * travel * 16.0 + _from.basis.z * travel * 22.0
	camera.global_basis = _from.basis.slerp(Basis.from_euler(Vector3(0.12, 0, 0)), travel)
	camera.fov = lerpf(_from_fov, 64.0, travel)
	# Preserva o relógio do céu para evitar inversões no fluxo durante a transição.

	if amount >= 0.5 and not _hidden:
		_hidden = true
		for node: Node3D in _visibility: node.hide()
		_space.set_background_only(true)

func _complete() -> void:
	_step(1.0)
	_veil.hide()
	transitioning = false
	finished.emit(true)

func leave_space() -> void:
	if not in_space: return
	_space.set_background_only(false)
	if _motion != null and _motion.is_valid(): _motion.kill()
	for node: Node3D in _visibility:
		if is_instance_valid(node): node.visible = _visibility[node]
	_visibility.clear()
	if is_instance_valid(_saved_camera): _saved_camera.make_current()
	else: _rig.camera.make_current()
	camera.current = false
	_veil.hide()
	in_space = false
	var interrupted := transitioning
	transitioning = false
	if interrupted: finished.emit(false)

func _exit_tree() -> void:
	if _motion != null and _motion.is_valid(): _motion.kill()
