class_name PhaseManager
extends Node

signal phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int)
signal phase_restarted(phase_number: int, phase_seed: int)
signal campaign_completed

const Catalog = preload("res://scripts/data/phase_catalog.gd")

@export_range(1, 10) var initial_phase := 1
@export var auto_start := true

var campaign: Dictionary = {}
var current_phase := 0
var current_phase_data: Dictionary = {}
var current_seed := 0


func _ready() -> void:
	campaign = Catalog.load_campaign()
	var validation_errors := Catalog.validate_campaign(campaign)
	if not validation_errors.is_empty():
		for error in validation_errors:
			push_error(error)
		return
	if auto_start:
		call_deferred("start_phase", initial_phase)


func start_phase(phase_number: int, seed_override: int = -1) -> void:
	var phase_data := Catalog.find_phase(campaign, phase_number)
	if phase_data.is_empty():
		push_error("Fase fora da campanha: %d" % phase_number)
		return

	current_phase = phase_number
	current_phase_data = phase_data
	if String(phase_data.get("configuration", "fixed")) == "procedural":
		current_seed = seed_override if seed_override >= 0 else randi()
	else:
		current_seed = 0

	phase_started.emit(current_phase, current_phase_data.duplicate(true), current_seed)


func restart_phase() -> void:
	if current_phase == 0:
		return
	var preserved_seed := current_seed
	start_phase(current_phase, preserved_seed)
	phase_restarted.emit(current_phase, preserved_seed)


func advance_phase() -> void:
	if current_phase >= 10:
		campaign_completed.emit()
		return
	start_phase(current_phase + 1)
