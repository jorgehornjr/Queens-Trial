class_name PhaseManager
extends Node

signal phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int)
signal phase_restarted(phase_number: int, phase_seed: int)
signal campaign_completed
signal savage_completed

const Catalog = preload("res://scripts/data/phase_catalog.gd")
const LAST_PLAYABLE_PHASE := 12
const Savage = preload("res://scripts/data/savage_catalog.gd")
const Progress = preload("res://scripts/data/campaign_progress.gd")

const SAVAGE_TEST_ACCESS := false

static func can_start_phase(number: int) -> bool:
	return number in range(1, LAST_PLAYABLE_PHASE + 1) or (Savage.contains(number) and (SAVAGE_TEST_ACCESS or Progress.savage_unlocked()))

@export_range(1, 12) var initial_phase := 1
@export var auto_start := true
@export var save_progress := true

var campaign: Dictionary = {}
var current_phase := 0
var current_phase_data: Dictionary = {}
var current_seed := 0
var _opening_board: Dictionary = {}
var _opening_seed := 0
var campaign_finished := false


func _ready() -> void:
	campaign = Catalog.load_campaign()
	var validation_errors := Catalog.validate_campaign(campaign)
	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error(error)
		return
	if auto_start:
		call_deferred("start_phase", initial_phase)


func prepare_opening_board() -> Dictionary:
	var first := Catalog.find_phase(campaign, initial_phase)
	if String(first.get("resolution", "")) != "moves": return {}
	_opening_seed = 0
	_opening_board = first.duplicate(true)
	return _opening_board.duplicate(true)


func start_phase(phase_number: int, seed_override: int = -1) -> void:
	if Savage.contains(phase_number) and not can_start_phase(phase_number): return
	var phase_data := Savage.find(phase_number) if Savage.contains(phase_number) else Catalog.find_phase(campaign, phase_number)
	if phase_data.is_empty():
		push_error("Fase fora da campanha: %d" % phase_number)
		return
	campaign_finished = false

	if String(phase_data.get("configuration", "fixed")) == "procedural":
		current_seed = seed_override if seed_override >= 0 else randi()
	else:
		current_seed = 0
	if String(phase_data.get("resolution", "")) == "moves":
		if not _opening_board.is_empty() and int(_opening_board.number) == phase_number and seed_override < 0:
			phase_data = _opening_board
			current_seed = _opening_seed
	current_phase = phase_number
	current_phase_data = phase_data
	_opening_board = {}

	phase_started.emit(current_phase, current_phase_data.duplicate(true), current_seed)


func restart_phase() -> void:
	if current_phase == 0 or campaign_finished:
		return
	var preserved_seed := current_seed

	phase_started.emit(current_phase, current_phase_data.duplicate(true), preserved_seed)
	phase_restarted.emit(current_phase, preserved_seed)


func advance_phase() -> void:
	if current_phase == 0 or campaign_finished: return
	if Savage.contains(current_phase):
		if current_phase == Savage.LAST:
			campaign_finished = true
			savage_completed.emit()
		else: start_phase(current_phase + 1)
		return
	if save_progress: Progress.record_completion(current_phase)
	if current_phase >= LAST_PLAYABLE_PHASE:
		campaign_finished = true
		campaign_completed.emit()
		return
	start_phase(current_phase + 1)
