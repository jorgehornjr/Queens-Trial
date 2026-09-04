class_name Board3D
extends Node3D

signal board_built

const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")

@export_category("Geometry")
@export_range(1.0, 12.0, 0.1) var tile_size := 7.6
@export var safe_spot := Vector2i(4, 0)

@export_category("Staging Preview")
@export var show_preview_pieces := true

@onready var board_visual: Node3D = $BoardVisual
@onready var spawn_points_root: Node3D = $SpawnPoints
@onready var preview_pieces_root: Node3D = $PreviewPieces
@onready var markers_root: Node3D = $Markers

var state
func _ready() -> void:
	state = BoardStateModel.new()
	if board_visual == null:
		push_error("O modelo 3D definitivo do tabuleiro não foi carregado.")
	preview_pieces_root.visible = show_preview_pieces
	if not state.set_safe_spot(safe_spot):
		push_warning("Safe spot inválido; usando a casa padrão.")
		safe_spot = state.safe_spot
	build_visuals()


func build_visuals() -> void:
	_clear_children(markers_root)
	board_built.emit()


func grid_to_world(cell: Vector2i) -> Vector3:
	var half_extent := float(Constants.BOARD_SIZE - 1) * tile_size * 0.5
	return Vector3(
		float(cell.x) * tile_size - half_extent,
		0.0,
		float(cell.y) * tile_size - half_extent
	)


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
