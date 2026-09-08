class_name Board3D
extends Node3D

signal board_built

const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")
const SquareAura = preload("res://scripts/gameplay/square_aura.gd")

@export_category("Geometry")
@export_range(1.0, 12.0, 0.1) var tile_size := 7.6
@export var safe_spot := Vector2i(4, 0)
## Center between the playable inset and the outer frame, measured from the mesh.
var _frame_inner := Vector2(19.225, 19.225)
var _frame_outer := Vector2(24.0, 24.0)

@export_category("Staging Preview")
@export var show_preview_pieces := true

@onready var board_visual: Node3D = $BoardVisual
@onready var spawn_points_root: Node3D = $SpawnPoints
@onready var preview_pieces_root: Node3D = $PreviewPieces
@onready var markers_root: Node3D = $Markers

var state
var _safe_spot_marker: Node3D
var _safe_spot_light: OmniLight3D
var _tutorial_markers: Array[Node3D] = []
var _tutorial_tweens: Array[Tween] = []
var _presentation_time := 0.0


func _ready() -> void:
	state = BoardStateModel.new()
	if board_visual == null:
		push_error("O modelo 3D definitivo do tabuleiro não foi carregado.")
	preview_pieces_root.visible = show_preview_pieces
	_measure_frame()
	if not state.set_safe_spot(safe_spot):
		push_warning("Safe spot inválido; usando a casa padrão.")
		safe_spot = state.safe_spot
	build_visuals()
	show_safe_spot(safe_spot)


func _process(delta: float) -> void:
	_presentation_time += delta
	if is_instance_valid(_safe_spot_light):
		_safe_spot_light.light_energy = 1.15 + sin(_presentation_time * 2.25) * 0.32


func build_visuals() -> void:
	_clear_children(markers_root)
	_safe_spot_marker = null
	_safe_spot_light = null
	_tutorial_markers.clear()
	board_built.emit()


func set_safe_spot_cell(cell: Vector2i) -> bool:
	if state == null or not state.set_safe_spot(cell):
		return false
	safe_spot = cell
	show_safe_spot(cell)
	return true


func show_safe_spot(cell: Vector2i) -> void:
	if is_instance_valid(_safe_spot_marker):
		_safe_spot_marker.queue_free()
	# Keep the semantic marker as a MeshInstance3D for scene/test discoverability;
	# the actual layered VFX lives in its children.
	var marker := MeshInstance3D.new()
	marker.name = "SafeSpot"
	marker.position = grid_to_world(cell) + Vector3(0.0, 0.16, 0.0)
	markers_root.add_child(marker)
	var seal := SquareAura.new()
	seal.name = "SanctuaryAura"
	seal.reveal = 0.0
	seal.configure(tile_size * 1.04, Color(0.12, 1.0, 0.40, 0.92), 2.25, 0.0, true)
	marker.add_child(seal)
	var appear := create_tween()
	appear.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	appear.tween_property(seal, "reveal", 1.0, 0.85)

	_safe_spot_light = OmniLight3D.new()
	_safe_spot_light.name = "CelestialGlow"
	_safe_spot_light.position.y = 0.55
	_safe_spot_light.light_color = Color(0.10, 1.0, 0.32)
	_safe_spot_light.omni_range = tile_size * 0.82
	_safe_spot_light.shadow_enabled = false
	marker.add_child(_safe_spot_light)
	_safe_spot_marker = marker


func show_tutorial_path(cells: Array) -> void:
	clear_tutorial_path()
	var delay := 0.0
	for value in cells:
		if not value is Array or value.size() != 2:
			continue
		var cell := Vector2i(int(value[0]), int(value[1]))
		if state == null or not state.is_inside(cell):
			continue
		var marker := SquareAura.new()
		marker.name = "Tutorial_%d_%d" % [cell.x, cell.y]
		marker.position = grid_to_world(cell) + Vector3(0.0, 0.17, 0.0)
		marker.reveal = 0.0
		markers_root.add_child(marker)
		var path_index := _tutorial_markers.size()
		var color := Color(0.10, 0.48, 1.0, 0.90)
		if cell == safe_spot:
			color = Color(0.12, 1.0, 0.40, 0.75)
		marker.configure(tile_size * 1.04, color, 1.55, float(path_index) * 0.72, cell != safe_spot)
		_tutorial_markers.append(marker)
		var tween := create_tween()
		_tutorial_tweens.append(tween)
		tween.tween_interval(delay)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(marker, "reveal", 1.0, 0.68)
		delay += 0.95


func clear_tutorial_path() -> void:
	for tween in _tutorial_tweens:
		tween.kill()
	_tutorial_tweens.clear()
	for marker in _tutorial_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_tutorial_markers.clear()


func grid_to_world(cell: Vector2i) -> Vector3:
	var half_extent := float(Constants.BOARD_SIZE - 1) * tile_size * 0.5
	return Vector3(
		float(cell.x) * tile_size - half_extent,
		0.0,
		float(cell.y) * tile_size - half_extent
	)


func edge_to_world(side: String, slot: int) -> Vector3:
	var half_extent := float(Constants.BOARD_SIZE - 1) * tile_size * 0.5
	var edge_center := (_frame_inner + _frame_outer) * 0.5
	var tangent := float(slot) * tile_size - half_extent
	match side:
		"left": return Vector3(-edge_center.x, 0.0, tangent)
		"right": return Vector3(edge_center.x, 0.0, tangent)
		"top": return Vector3(tangent, 0.0, -edge_center.y)
		_: return Vector3(tangent, 0.0, edge_center.y)


func _measure_frame() -> void:
	for part_name in ["Estrutura_01", "Estrutura_02"]:
		var part := board_visual.find_child(part_name, true, false) as MeshInstance3D
		if part == null:
			continue
		var bounds := (global_transform.affine_inverse() * part.global_transform) * part.get_aabb()
		var extent := Vector2(maxf(absf(bounds.position.x), absf(bounds.end.x)), maxf(absf(bounds.position.z), absf(bounds.end.z)))
		if part_name == "Estrutura_01":
			_frame_outer = extent
		else:
			_frame_inner = extent


func world_to_grid(world_position: Vector3) -> Vector2i:
	var half_extent := float(Constants.BOARD_SIZE - 1) * tile_size * 0.5
	return Vector2i(
		roundi((world_position.x + half_extent) / tile_size),
		roundi((world_position.z + half_extent) / tile_size)
	)


func can_player_enter(cell: Vector2i) -> bool:
	return state != null and state.can_player_enter(cell)


func manhattan_distance(origin: Vector2i, destination: Vector2i) -> int:
	return state.manhattan_distance(origin, destination)


func get_spawn_marker(corner_name: StringName) -> Marker3D:
	var points_root := spawn_points_root
	if points_root == null:
		points_root = get_node_or_null("SpawnPoints") as Node3D
	if points_root == null:
		return null
	return points_root.get_node_or_null(NodePath(String(corner_name))) as Marker3D


func get_spawn_transform(corner_name: StringName) -> Transform3D:
	var marker := get_spawn_marker(corner_name)
	if marker == null:
		push_warning("Ponto de spawn externo desconhecido: %s" % corner_name)
		return global_transform
	return marker.global_transform


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()
