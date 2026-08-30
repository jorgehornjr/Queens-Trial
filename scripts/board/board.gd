class_name Board3D
extends Node3D

signal board_built

const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")

@export_category("Geometry")
@export_range(1.0, 12.0, 0.1) var tile_size := 5.6
@export var safe_spot := Vector2i(4, 0)

@export_category("Dynamic Markers")
@export var safe_spot_color := Color("56d6a5")

@onready var board_visual: Node3D = $BoardVisual
@onready var markers_root: Node3D = $Markers

var state


func _ready() -> void:
	state = BoardStateModel.new()
	if board_visual == null:
		push_error("O modelo 3D definitivo do tabuleiro não foi carregado.")
	if not state.set_safe_spot(safe_spot):
		push_warning("Safe spot inválido; usando a casa padrão.")
		safe_spot = state.safe_spot
	build_visuals()


func build_visuals() -> void:
	_clear_children(markers_root)
	_create_safe_spot_marker()
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


func _create_safe_spot_marker() -> void:
	var marker := MeshInstance3D.new()
	marker.name = "SafeSpotMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = tile_size * 0.28
	mesh.bottom_radius = tile_size * 0.28
	mesh.height = 0.08
	mesh.radial_segments = 48
	marker.mesh = mesh
	marker.position = grid_to_world(state.safe_spot) + Vector3(0.0, 0.07, 0.0)
	marker.material_override = _make_material(safe_spot_color, 1.15)
	markers_root.add_child(marker)


func _make_material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.08
	material.roughness = 0.42
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material


func _clear_children(parent: Node) -> void:
	for child in parent.get_children():
		child.free()
