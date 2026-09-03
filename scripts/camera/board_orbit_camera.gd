class_name BoardOrbitCamera
extends Node3D

@export var board_path := NodePath("../Board")
@export_range(20.0, 55.0, 1.0) var elevation_degrees := 32.0
@export_range(0.05, 0.6, 0.01) var orbit_sensitivity := 0.22
@export_range(1.0, 2.5, 0.05) var max_zoom_ratio := 1.7
@export_range(1.0, 2.5, 0.01) var zoom_ratio := 1.08
@export var yaw_degrees := 0.0
@export var start_in_presentation := true
@export_range(10.0, 25.0, 1.0) var presentation_elevation_degrees := 18.0
@export_range(0.2, 4.0, 0.1) var transition_seconds := 1.8

@onready var camera: Camera3D = $Camera3D
var framing_points := PackedVector3Array()
var minimum_distance := 1.0
var _board: Node3D
var _yaw := 0.0
var _distance := 1.0
var _dragging := false
var _mouse_before_drag := Vector2.ZERO
var _previous_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _active_elevation := 32.0
var _mode_transition: Tween
var gameplay_mode := false


func _ready() -> void:
	process_priority = 50
	_board = get_node_or_null(board_path) as Node3D
	if _board == null:
		push_error("BoardOrbitCamera precisa de um tabuleiro válido.")
		set_process(false)
		return
	_collect_framing_points(_board)
	_yaw = deg_to_rad(yaw_degrees)
	gameplay_mode = not start_in_presentation
	_active_elevation = elevation_degrees if gameplay_mode else presentation_elevation_degrees
	update_framing(0.0, true)


func enter_gameplay(instant := false) -> void:
	if gameplay_mode:
		return
	gameplay_mode = true
	if _mode_transition != null:
		_mode_transition.kill()
	if instant:
		_active_elevation = elevation_degrees
		update_framing(0.0, true)
		return
	_mode_transition = create_tween()
	_mode_transition.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_mode_transition.tween_property(self, "_active_elevation", elevation_degrees, transition_seconds)


func _process(delta: float) -> void:
	update_framing(delta)


func update_framing(delta: float, snap := false) -> void:
	if not is_instance_valid(_board):
		return
	zoom_ratio = clampf(zoom_ratio, 1.0, max_zoom_ratio)
	var weight := 1.0 if snap else 1.0 - exp(-12.0 * delta)
	_yaw = lerp_angle(_yaw, deg_to_rad(yaw_degrees), weight)
	global_position = _board.global_position
	camera.global_basis = Basis.from_euler(Vector3(deg_to_rad(-_active_elevation), _yaw, 0.0))
	minimum_distance = fit_distance(camera.global_basis)
	# Distância mínima evita cortes durante interpolação e redimensionamento.
	_distance = maxf(minimum_distance, lerpf(_distance, minimum_distance * zoom_ratio, weight))
	camera.global_position = global_position + camera.global_basis.z * _distance


func fit_distance(view_basis: Basis) -> float:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(viewport_size.y, 1.0)
	var vertical_tangent := tan(deg_to_rad(camera.fov * 0.5))
	var horizontal_tangent := vertical_tangent * aspect
	var distance := 1.0
	for world_point in framing_points:
		var p := view_basis.inverse() * (world_point - global_position)
		distance = maxf(distance, p.z + absf(p.x) / (horizontal_tangent * 0.90))
		# Margem inferior de enquadramento em todos os ângulos da órbita.
		var vertical_margin := 0.78 if p.y >= 0.0 else 0.72
		distance = maxf(distance, p.z + absf(p.y) / (vertical_tangent * vertical_margin))
	return distance + 1.0


func _collect_framing_points(node: Node) -> void:
	if node.is_in_group("presentation_only"):
		return
	if node is MeshInstance3D and node.is_visible_in_tree():
		var bounds: AABB = node.get_aabb().grow(1.0)
		for index in 8:
			framing_points.append(node.global_transform * bounds.get_endpoint(index))
	for child in node.get_children():
		_collect_framing_points(child)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_mouse_before_drag = get_viewport().get_mouse_position()
			_previous_mouse_mode = Input.mouse_mode
			_dragging = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var direction := -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
			zoom_ratio = clampf(zoom_ratio * pow(1.10, direction * maxf(event.factor, 1.0)), 1.0, max_zoom_ratio)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		# Órbita horizontal com inclinação e centro fixos.
		yaw_degrees = wrapf(yaw_degrees - event.relative.x * orbit_sensitivity, -180.0, 180.0)
		get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	# Libera o mouse mesmo quando a interface consome o evento.
	if _dragging and ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed)
			or (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed)):
		_end_orbit()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_end_orbit()


func _exit_tree() -> void:
	_end_orbit()


func _end_orbit() -> void:
	if not _dragging:
		return
	_dragging = false
	Input.mouse_mode = _previous_mouse_mode
	if is_inside_tree() and _previous_mouse_mode == Input.MOUSE_MODE_VISIBLE:
		get_viewport().warp_mouse(_mouse_before_drag)
