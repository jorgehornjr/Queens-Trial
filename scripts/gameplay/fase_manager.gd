class_name PhaseManager
extends Node

signal phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int)
signal phase_restarted(phase_number: int, phase_seed: int)
signal campaign_completed
signal savage_completed

const Catalog = preload("res://scripts/data/phase_catalog.gd")
const Savage = preload("res://scripts/data/savage_catalog.gd")
const Progress = preload("res://scripts/data/campaign_progress.gd")
const LAST_PLAYABLE_PHASE := 12
const SAVAGE_TEST_ACCESS := false

@export_range(1, 12) var initial_phase := 1
@export var auto_start := true
@export var save_progress := true

var campaign: Dictionary = {}
var current_phase := 0
var current_phase_data: Dictionary = {}
var current_seed := 0
var campaign_finished := false
var _opening_board: Dictionary = {}


static func can_start_phase(number: int) -> bool:
	if Savage.contains(number): return SAVAGE_TEST_ACCESS or Progress.savage_unlocked()
	return number >= 1 and number <= LAST_PLAYABLE_PHASE


func _ready() -> void:
	campaign = Catalog.load_campaign()
	var errors := Catalog.validate_campaign(campaign)
	for message: String in errors: push_error(message)
	if errors.is_empty() and auto_start: start_phase.call_deferred(initial_phase)


func prepare_opening_board() -> Dictionary:
	var definition := Catalog.find_phase(campaign, initial_phase)
	_opening_board = definition.duplicate(true) if definition.get("resolution") == "moves" else {}
	return _opening_board.duplicate(true)


func start_phase(number: int, seed_override := -1) -> void:
	if Savage.contains(number) and not can_start_phase(number): return
	var definition := _definition(number)
	if definition.is_empty():
		push_error("Fase fora da campanha: %d" % number)
	else:
		var seed_value := 0
		if definition.get("configuration", "fixed") == "procedural":
			seed_value = randi() if seed_override < 0 else seed_override
		if seed_override < 0 and int(_opening_board.get("number", 0)) == number:
			definition = _opening_board.duplicate(true)
			seed_value = 0
		_opening_board.clear()
		campaign_finished = false
		current_phase = number
		current_phase_data = definition
		current_seed = seed_value
		_publish_phase()


func restart_phase() -> void:
	if current_phase > 0 and not campaign_finished:
		_publish_phase()
		phase_restarted.emit(current_phase, current_seed)


func advance_phase() -> void:
	if current_phase <= 0 or campaign_finished: return
	var chaotic := Savage.contains(current_phase)
	if save_progress and not chaotic: Progress.record_completion(current_phase)
	var last := Savage.LAST if chaotic else LAST_PLAYABLE_PHASE
	if current_phase < last:
		start_phase(current_phase + 1)
	else:
		campaign_finished = true
		if chaotic: savage_completed.emit()
		else: campaign_completed.emit()


func _definition(number: int) -> Dictionary:
	return Savage.find(number) if Savage.contains(number) else Catalog.find_phase(campaign, number)


func _publish_phase() -> void:
	phase_started.emit(current_phase, current_phase_data.duplicate(true), current_seed)
