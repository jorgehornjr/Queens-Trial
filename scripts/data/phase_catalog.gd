class_name PhaseCatalog
extends RefCounted

const DATA_PATH := "res://data/phases/campaign.json"
const Routes = preload("res://scripts/data/vanilla_board_generator.gd")


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
	if phases.size() != 12:
		errors.append("A campanha deve conter exatamente 12 fases.")
	var heavy_weights := {}
	var light_weights := {}
	var left_weights := {}
	var right_weights := {}

	for phase_number in range(1, 13):
		var phase := find_phase(campaign, phase_number)
		if phase.is_empty():
			errors.append("Fase %d ausente." % phase_number)
			continue

		var expected := "moves" if phase_number <= 7 else ("balance" if phase_number <= 10 else ("card_order" if phase_number == 11 else "card_match"))
		if String(phase.get("resolution", "")) != expected:
			errors.append("Modo de resolução incorreto na fase %d." % phase_number)
		var chapter := phase_number if phase_number <= 5 else (6 if phase_number == 8 else 0)
		if int(phase.get("tutorial_chapter", 0)) != chapter:
			errors.append("Tutorial incorreto na fase %d." % phase_number)
		if expected == "moves":
			if float(phase.get("seconds_per_edict", -1)) != 0.0:
				errors.append("Os éditos Vanilla não têm cronômetro.")
			if int(phase.get("edict_count", 0)) != (1 if phase_number == 1 else 2):
				errors.append("Quantidade de éditos incorreta na fase %d." % phase_number)
			if Routes.solution(phase).is_empty():
				errors.append("A fase %d não possui rota entre os ataques e o refúgio." % phase_number)
		if expected == "balance":
			if float(phase.get("seconds_per_edict", 0)) != 5.0:
				errors.append("Cada balança deve ter cinco segundos de decisão.")
			if phase.get("balance_round_count", 0) != 3:
				errors.append("A balança precisa de três rodadas.")
			var rounds: Array = phase.get("balance_rounds", [])
			if rounds.size() != 3: errors.append("Cada balança exige três pares fixos.")
			for index in range(rounds.size()):
				var round_data: Dictionary = rounds[index]
				var left := int(round_data.get("left", 0))
				var right := int(round_data.get("right", 0))
				if left not in range(9, 21) or right not in range(9, 21) or absi(left - right) < 2:
					errors.append("Pesos fixos da balança inválidos ou próximos demais.")
				var heavy := maxi(left, right)
				var light := mini(left, right)
				if heavy_weights.has(heavy) or light_weights.has(light): errors.append("Um peso repetiu seu papel na balança.")
				if left_weights.has(left) or right_weights.has(right): errors.append("Um peso repetiu o mesmo lado da balança.")
				heavy_weights[heavy] = true
				light_weights[light] = true
				left_weights[left] = true
				right_weights[right] = true
				var expected_concealed := index >= (2 if phase_number == 8 else 1)
				if bool(round_data.get("concealed", false)) != expected_concealed: errors.append("Indicação de peso incorreta na balança.")
			if float(phase.get("tilt_degrees", 0.0)) <= 0.0 or float(phase.get("tilt_degrees", 0.0)) > 30.0 or not is_equal_approx(float(phase.get("slide_tiles", 0.0)), 3.0):
				errors.append("A balança exige inclinação parcial e deslizamento de três casas.")

		if expected == "card_order" and int(phase.get("rounds", 0)) != 4:
			errors.append("A ordenação exige duas rodadas de cada ordem.")
		if expected == "card_match" and int(phase.get("rounds", 0)) != 3:
			errors.append("A associação deve terminar com dois decretos falsos.")
		var should_be_procedural := expected in ["card_order", "card_match"]
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
