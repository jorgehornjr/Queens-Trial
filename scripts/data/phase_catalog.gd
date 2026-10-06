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

		var should_be_timed := phase_number >= 7
		var is_timed := String(phase.get("resolution", "")) == "timer"
		if should_be_timed != is_timed:
			errors.append("Modo de resolução incorreto na fase %d." % phase_number)
		if phase_number == 6:
			if String(phase.get("resolution", "")) != "balance" or float(phase.get("seconds_per_edict", 0)) != 5.0:
				errors.append("A fase 6 deve usar a balança com cinco segundos de decisão.")
			var rounds: Array = phase.get("balance_rounds", [])
			if rounds.is_empty():
				errors.append("A balança precisa de pelo menos uma rodada.")
			for pair in rounds:
				if not pair is Array or pair.size() != 2:
					errors.append("Cada rodada da balança precisa de duas cartas.")
					continue
				if pair[0] == pair[1] or float(pair[0]) != int(pair[0]) or float(pair[1]) != int(pair[1]) or int(pair[0]) not in range(1, 5) or int(pair[1]) not in range(1, 5):
					errors.append("As cartas da balança devem ter pesos diferentes entre 1 e 4.")
			if float(phase.get("tilt_degrees", 0.0)) <= 0.0 or float(phase.get("tilt_degrees", 0.0)) > 30.0 or not is_equal_approx(float(phase.get("slide_tiles", 0.0)), 3.0):
				errors.append("A balança exige inclinação parcial e deslizamento de três casas.")

		var should_be_procedural := phase_number == 7 or phase_number == 9
		var is_procedural := String(phase.get("configuration", "")) == "procedural"
		if should_be_procedural != is_procedural:
			errors.append("Configuração fixa/procedural incorreta na fase %d." % phase_number)
		errors.append_array(validate_piece_borders(phase))

	return errors


static func validate_piece_borders(phase: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var occupied_sides := {}
	for wave in phase.get("piece_waves", []):
		for definition in wave:
			var side := String(definition.get("side", ""))
			if side not in ["left", "right", "top", "bottom"]:
				errors.append("Borda inválida na fase %s." % phase.get("number", "?"))
			elif occupied_sides.has(side):
				errors.append("A fase %s deve ter no máximo uma peça por borda (%s)." % [phase.get("number", "?"), side])
			occupied_sides[side] = true
	return errors
