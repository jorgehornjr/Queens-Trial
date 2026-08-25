class_name Board3D
extends Node3D

signal board_built

const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")

@export_category("Geometry")
@export_range(0.5, 5.0, 0.1) var tile_size := 1.8
@export var safe_spot := Vector2i(4, 0)

@export_category("Palette")
@export var light_tile_color := Color("c9d4ee")
@export var dark_tile_color := Color("5f6d9a")
@export var queen_color := Color("d8ad55")
@export var safe_spot_color := Color("56d6a5")

@onready var tiles_root: Node3D = $Tiles
@onready var markers_root: Node3D = $Markers

var state


func _ready() -> void:
	state = BoardStateModel.new()
	if not state.set_safe_spot(safe_spot):
		push_warning("Safe spot inválido; usando a casa padrão.")
		safe_spot = state.safe_spot
	build_visuals()


func build_visuals() -> void:
	_clear_children(tiles_root)
	_clear_children(markers_root)

	for row in range(Constants.BOARD_SIZE):
		for column in range(Constants.BOARD_SIZE):
			_create_tile(Vector2i(column, row))
	_create_queen_marker()
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


func _create_tile(cell: Vector2i) -> void:
	var tile := MeshInstance3D.new()
	tile.name = "Tile_%d_%d" % [cell.x, cell.y]

	var mesh := BoxMesh.new()
	mesh.size = Vector3(tile_size * 0.94, 0.18, tile_size * 0.94)
	tile.mesh = mesh
	tile.position = grid_to_world(cell) + Vector3(0.0, -0.09, 0.0)
	var color := light_tile_color if (cell.x + cell.y) % 2 == 0 else dark_tile_color
	tile.material_override = _make_material(color)
	tiles_root.add_child(tile)


func _create_queen_marker() -> void:
	var queen := MeshInstance3D.new()
	queen.name = "QueenMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = tile_size * 0.24
	mesh.bottom_radius = tile_size * 0.38
	mesh.height = 1.45
	mesh.radial_segments = 32
	queen.mesh = mesh
	queen.position = grid_to_world(Constants.QUEEN_CELL) + Vector3(0.0, 0.72, 0.0)
	queen.material_override = _make_material(queen_color, 0.35)
	markers_root.add_child(queen)


func _create_safe_spot_marker() -> void:
	var marker := MeshInstance3D.new()
	marker.name = "SafeSpotMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = tile_size * 0.30
	mesh.bottom_radius = tile_size * 0.30
	mesh.height = 0.06
	mesh.radial_segments = 32
	marker.mesh = mesh
	marker.position = grid_to_world(state.safe_spot) + Vector3(0.0, 0.13, 0.0)
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
