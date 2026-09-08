class_name EnemyPieceController
extends Node3D

signal movement_finished(piece: EnemyPieceController)

const Constants = preload("res://scripts/core/game_constants.gd")
const ROOK_SCENE = preload("res://scenes/pieces/rook.tscn")
const BISHOP_SCENE = preload("res://scenes/pieces/bishop.tscn")
const DIRECTION_SHADER = preload("res://shaders/direction_neon.gdshader")
const CELESTIAL_FONT = preload("res://assets/fonts/jupiter_pro.otf")
const ARROW_STRIP_SIZE := Vector2(2.4, 6.7)
const ARROW_NEAR_GAP := 5.5
const QUEEN_GOLD := Color(0.82, 0.58, 0.21, 1.0)

var piece_type: StringName
var destination_cell := Vector2i.ZERO
var wave_index := 0
var move_value := 0
var edge_steps := 0
var entry_lane := 0

var _board: Board3D
var _edge_target := Vector3.ZERO
var _final_target := Vector3.ZERO
var _roman_label: Label3D
var _arrows: Array[MeshInstance3D] = []
var _active := false
var _pulse_time := 0.0
var _visual: Node3D


func configure(board: Board3D, definition: Dictionary, value: int, index: int) -> bool:
	_board = board
	wave_index = index
	piece_type = StringName(definition.get("type", "rook"))
	var side := String(definition.get("side", ""))
	var edge_slot := int(definition.get("edge_slot", -1))
	var edge_direction := int(definition.get("edge_direction", 0))
	move_value = int(definition.get("move_value", value))
	if move_value < 1 or move_value >= Constants.BOARD_SIZE:
		return false
	if side not in ["left", "right", "top", "bottom"] or edge_slot < 0 or edge_slot >= Constants.BOARD_SIZE or edge_direction not in [-1, 1]:
		return false
	entry_lane = edge_slot + edge_direction * move_value
	if entry_lane < 0 or entry_lane >= Constants.BOARD_SIZE:
		return false
	edge_steps = absi(entry_lane - edge_slot)

	destination_cell = _destination_cell(side, entry_lane, move_value)
	position = board.edge_to_world(side, edge_slot) + Vector3(0.0, 0.18, 0.0)
	_edge_target = board.edge_to_world(side, entry_lane) + Vector3(0.0, 0.18, 0.0)
	_final_target = board.grid_to_world(destination_cell) + Vector3(0.0, 0.18, 0.0)

	var scene: PackedScene = BISHOP_SCENE if piece_type == Constants.PIECE_BISHOP else ROOK_SCENE
	_visual = scene.instantiate() as Node3D
	add_child(_visual)
	_visual.rotation.y = _rotation_for_inward(side)
	_create_roman_label(Constants.to_roman(move_value))
	_create_edge_arrows()
	set_wave_active(false)
	return true


func _process(delta: float) -> void:
	if not _active:
		return
	_pulse_time += delta
	if _roman_label != null:
		var glow := 0.86 + sin(_pulse_time * 2.8) * 0.14
		_roman_label.modulate = Color(1.0, 1.0, 1.0, glow)


func set_wave_active(active: bool) -> void:
	_active = active
	if _roman_label != null:
		_roman_label.modulate = Color(1.0, 1.0, 1.0, 1.0 if active else 0.34)
	for arrow in _arrows:
		arrow.visible = active


func play_resolution() -> void:
	set_wave_active(false)
	var animator := _visual.find_child("Visual", true, false) if _visual != null else null
	if animator != null and animator.has_method("play_move"):
		animator.play_move(1.45)

	if position.distance_to(_edge_target) > 0.05:
		var edge_tween := create_tween()
		edge_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		edge_tween.tween_property(self, "position", _edge_target, 0.62)
		await edge_tween.finished
		await get_tree().create_timer(0.10).timeout

	var entry_tween := create_tween()
	entry_tween.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	entry_tween.tween_property(self, "position", _final_target + Vector3(0.0, 0.26, 0.0), 0.92)
	entry_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	entry_tween.tween_property(self, "position", _final_target, 0.24)
	await entry_tween.finished
	movement_finished.emit(self)


func _create_roman_label(text_value: String) -> void:
	_roman_label = Label3D.new()
	_roman_label.name = "RomanNumeral"
	_roman_label.text = text_value
	_roman_label.position = Vector3(0.0, 7.2, 0.0)
	_roman_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_roman_label.no_depth_test = true
	_roman_label.font = CELESTIAL_FONT
	_roman_label.font_size = 124
	_roman_label.outline_size = 0
	_roman_label.modulate = Color.WHITE
	_roman_label.fixed_size = false
	_roman_label.pixel_size = 0.009
	add_child(_roman_label)


func _create_edge_arrows() -> void:
	var world_delta := _edge_target - position
	var flat_direction := Vector3(world_delta.x, 0.0, world_delta.z).normalized()
	var length := Vector3(world_delta.x, 0.0, world_delta.z).length()
	if length < 0.2:
		return
	var arrow := MeshInstance3D.new()
	arrow.name = "DirectionEtching"
	var mesh := PlaneMesh.new()
	mesh.orientation = PlaneMesh.FACE_Y
	# This is a direction cue, not a ruler for the total move distance.
	# Keep both its footprint and its clearance from the piece identical.
	mesh.size = ARROW_STRIP_SIZE
	var material := ShaderMaterial.new()
	material.shader = DIRECTION_SHADER
	material.set_shader_parameter("neon_color", QUEEN_GOLD)
	material.set_shader_parameter("phase", float(wave_index) * 0.41)
	mesh.material = material
	arrow.mesh = mesh
	# The painted trim sits above the frame's structural mesh; clear that trim.
	arrow.position = flat_direction * (ARROW_NEAR_GAP + ARROW_STRIP_SIZE.y * 0.5) + Vector3(0.0, 0.035, 0.0)
	arrow.rotation.y = atan2(flat_direction.x, flat_direction.z)
	arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(arrow)
	_arrows.append(arrow)


func _outside_cell(side: String, slot: int) -> Vector2i:
	match side:
		"left": return Vector2i(-1, slot)
		"right": return Vector2i(5, slot)
		"top": return Vector2i(slot, -1)
		_: return Vector2i(slot, 5)


func _destination_cell(side: String, lane: int, value: int) -> Vector2i:
	match side:
		"left": return Vector2i(value - 1, lane)
		"right": return Vector2i(5 - value, lane)
		"top": return Vector2i(lane, value - 1)
		_: return Vector2i(lane, 5 - value)


func _rotation_for_inward(side: String) -> float:
	match side:
		"left": return -PI * 0.5
		"right": return PI * 0.5
		"top": return PI
		_: return 0.0
