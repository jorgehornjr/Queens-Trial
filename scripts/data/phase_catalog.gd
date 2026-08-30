class_name PhaseCatalog
extends RefCounted

const DATA_PATH := "res://data/phases/campaign.json"


static func load_campaign(path: String = DATA_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Catálogo de fases não encontrado: %s" % path)
		return {}

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Catálogo de fases inválido: %s" % path)
		return {}
	return parsed


static func find_phase(campaign: Dictionary, phase_number: int) -> Dictionary:
	var phases: Array = campaign.get("phases", [])
	for entry in phases:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var phase: Dictionary = entry
		if int(phase.get("number", -1)) == phase_number:
			return phase.duplicate(true)
	return {}


static func validate_campaign(campaign: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var phases: Array = campaign.get("phases", [])
	if phases.size() != 10:
		errors.append("A campanha deve conter exatamente 10 fases.")

	for phase_number in range(1, 11):
		var phase := find_phase(campaign, phase_number)
		if phase.is_empty():
			errors.append("Fase %d ausente." % phase_number)
			continue

		var should_be_timed := phase_number >= 6
		var is_timed := String(phase.get("resolution", "")) == "timer"
		if should_be_timed != is_timed:
			errors.append("Modo de resolução incorreto na fase %d." % phase_number)

		var should_be_procedural := phase_number == 7 or phase_number == 9
		var is_procedural := String(phase.get("configuration", "")) == "procedural"
		if should_be_procedural != is_procedural:
			errors.append("Configuração fixa/procedural incorreta na fase %d." % phase_number)

	return errors
