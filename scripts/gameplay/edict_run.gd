class_name EdictRun
extends RefCounted

signal edict_started(index: int, value: int)
signal steps_changed(taken: int, required: int)
signal movement_finished
signal failed(reasons: Array)
signal completed

enum Status { IDLE, WALKING, AWAITING_JUDGMENT, FINISHED }

var status := Status.IDLE
var index := 0
var origin := Vector2i.ZERO
var cell := Vector2i.ZERO
var steps_taken := 0
var required_steps := 0
var _values := PackedInt32Array()
var _grid := BoardState.new()


func start(values: Array, starting_cell: Vector2i) -> bool:
	var parsed := PackedInt32Array()
	for raw: Variant in values:
		if typeof(raw) not in [TYPE_INT, TYPE_FLOAT]: return false
		var value := int(raw)
		if value < 1 or value > 4 or float(raw) != value or value in parsed: return false
		parsed.append(value)
	if parsed.size() not in [1, 2] or not _grid.is_inside(starting_cell): return false
	_values = parsed
	index = 0
	cell = starting_cell
	_begin_edict()
	return true


func cancel() -> void:
	status = Status.IDLE
	_values.clear()


func move_to(destination: Vector2i) -> bool:
	if status != Status.WALKING or not _grid.is_inside(destination): return false
	if _grid.manhattan_distance(cell, destination) != 1: return false
	cell = destination
	steps_taken += 1
	steps_changed.emit(steps_taken, required_steps)
	if steps_taken == required_steps:
		status = Status.AWAITING_JUDGMENT
		movement_finished.emit()
	return true


func resolve(attacked_cells: Array, refuge: Vector2i) -> void:
	if status != Status.AWAITING_JUDGMENT: return
	var reasons: Array = []
	var distance := _grid.manhattan_distance(origin, cell)
	if distance != required_steps: reasons.append(_distance_feedback(distance))
	if cell in attacked_cells: reasons.append("Uma peça atacou a casa onde você parou.")
	var last := index + 1 == _values.size()
	if reasons.is_empty() and last and cell != refuge:
		reasons.append("Você cumpriu os éditos, mas terminou fora da casa iluminada.")
	if not reasons.is_empty():
		status = Status.FINISHED
		failed.emit(reasons)
	elif last:
		status = Status.FINISHED
		completed.emit()
	else:
		index += 1
		_begin_edict()


func _begin_edict() -> void:
	origin = cell
	steps_taken = 0
	required_steps = _values[index]
	status = Status.WALKING
	edict_started.emit(index, required_steps)


func _distance_feedback(distance: int) -> String:
	var position := "Você voltou ao ponto de partida."
	if distance > 0:
		position = "Você terminou a %d %s do ponto de partida." % [distance, "casa" if distance == 1 else "casas"]
	return "A carta %s pedia uma distância de %d %s.\n%s" % [
		GameConstants.to_roman(required_steps), required_steps,
		"casa" if required_steps == 1 else "casas", position,
	]
