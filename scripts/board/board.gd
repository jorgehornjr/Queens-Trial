class_name Board3D
extends Node3D

signal board_built

const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")
const FloorStarShader = preload("res://shaders/sanctuary_symbol.gdshader")
const SANCTUARY_SYMBOL = preload("res://assets/textures/guidance/sanctuary_reference.png")
const GLOW_PERIOD := 2.8
const StarredGuideModel = preload("res://scripts/gameplay/starred_guide.gd")

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
var _safe_spot_ink: ShaderMaterial
var _tutorial_guide: StarredGuide
var _tutorial_generation := 0
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
	var glow := 0.5 + 0.5 * cos(_presentation_time * TAU / GLOW_PERIOD)
	if _safe_spot_ink != null:
		_safe_spot_ink.set_shader_parameter("energy", lerpf(0.55, 3.3, glow))
		_safe_spot_ink.set_shader_parameter("glow_strength", lerpf(0.20, 1.0, glow))
	if is_instance_valid(_safe_spot_light):
		_safe_spot_light.light_energy = lerpf(0.05, 0.95, glow)


func build_visuals() -> void:
	clear_tutorial_path()
	_clear_children(markers_root)
	_safe_spot_marker = null
	_safe_spot_light = null
	_safe_spot_ink = null
	board_built.emit()


func set_safe_spot_cell(cell: Vector2i) -> bool:
	if state == null or not state.set_safe_spot(cell):
		return false
	safe_spot = cell
	show_safe_spot(cell)
	return true


func set_safe_spot_visible(enabled: bool) -> void:
	if is_instance_valid(_safe_spot_marker):
		_safe_spot_marker.visible = enabled
	if is_instance_valid(_safe_spot_light):
		_safe_spot_light.visible = enabled


func show_safe_spot(cell: Vector2i) -> void:
	if is_instance_valid(_safe_spot_marker):
		_safe_spot_marker.queue_free()
	var marker := MeshInstance3D.new()
	marker.name = "SafeSpot"
	marker.position = grid_to_world(cell) + Vector3(0.0, 0.16, 0.0)
	var floor := PlaneMesh.new()
	floor.size = Vector2(1.0, float(SANCTUARY_SYMBOL.get_height()) / SANCTUARY_SYMBOL.get_width()) * tile_size * 0.98
	marker.mesh = floor
	marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ink := ShaderMaterial.new()
	ink.shader = FloorStarShader
	ink.set_shader_parameter("glyph", SANCTUARY_SYMBOL)
	_safe_spot_ink = ink
	ink.set_shader_parameter("reveal", 0.0)
	marker.material_override = ink
	markers_root.add_child(marker)
	var appear := marker.create_tween()
	appear.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	appear.tween_method(func(value: float): ink.set_shader_parameter("reveal", value), 0.0, 1.0, 0.65)
	_safe_spot_light = OmniLight3D.new()
	_safe_spot_light.name = "StarFloorLight"
	_safe_spot_light.position.y = 0.26
	_safe_spot_light.light_color = Color(1.0, 0.76, 0.35)
	_safe_spot_light.light_energy = 0.72
	_safe_spot_light.light_volumetric_fog_energy = 0.0
	_safe_spot_light.omni_range = tile_size * 0.65
	_safe_spot_light.shadow_enabled = false
	marker.add_child(_safe_spot_light)
	_safe_spot_marker = marker


func show_tutorial_path(cells: Array, origin_cell := Vector2i(-1, -1)) -> bool:
	clear_tutorial_path()
	var run_id := _tutorial_generation
	var waypoints := PackedVector3Array()
	if state != null and state.is_inside(origin_cell):
		waypoints.append(grid_to_world(origin_cell))
	for value in cells:
		if not value is Array or value.size() != 2: continue
		var cell := Vector2i(int(value[0]), int(value[1]))
		if state == null or not state.is_inside(cell): continue
		var point := grid_to_world(cell)
		if waypoints.is_empty() or not point.is_equal_approx(waypoints[-1]):
			waypoints.append(point)
	if waypoints.size() < 2: return true
	var guide := StarredGuideModel.new() as StarredGuide
	guide.name = "StarredTutorialPath"
	guide.position.y = 0.18
	markers_root.add_child(guide)
	guide.configure(waypoints, tile_size)
	_tutorial_guide = guide
	guide.play()
	var completed: bool = await guide.finished
	return completed and run_id == _tutorial_generation


func clear_tutorial_path() -> void:
	_tutorial_generation += 1
	if is_instance_valid(_tutorial_guide):
		_tutorial_guide.cancel()
		_tutorial_guide.hide()
		_tutorial_guide.queue_free()
	_tutorial_guide = null


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
