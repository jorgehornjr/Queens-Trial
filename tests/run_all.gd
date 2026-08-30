extends SceneTree
const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")
const Catalog = preload("res://scripts/data/phase_catalog.gd")
const PhaseManagerModel = preload("res://scripts/gameplay/fase_manager.gd")
var failures := PackedStringArray()
func _initialize() -> void:
	_test_board_state()
	_test_attack_geometry()
	_test_campaign_catalog()
	_test_fase1_dados_completos()
	_test_input_map()
	_test_procedural_seed_is_preserved()
	if failures.is_empty():
		print("OK: scaffold validado (grade, ataques e campanha).")
		quit(0)
		return
	for failure in failures:
		printerr("FALHA: %s" % failure)
	quit(1)
func _test_board_state() -> void:
	var state = BoardStateModel.new()
	_expect(state.is_inside(Vector2i(0, 0)), "A origem deve pertencer à grade.")
	_expect(state.is_inside(Vector2i(4, 4)), "A última casa deve pertencer à grade.")
	_expect(not state.is_inside(Vector2i(5, 4)), "Coluna 5 deve ficar fora da grade 5 x 5.")
	_expect(not state.can_player_enter(Constants.QUEEN_CELL), "A casa da Rainha deve ser bloqueada.")
	_expect(state.manhattan_distance(Vector2i(0, 0), Vector2i(3, 2)) == 5, "A distância deve ser Manhattan.")
	_expect(not state.set_safe_spot(Constants.QUEEN_CELL), "A casa central não pode ser safe spot.")
func _test_attack_geometry() -> void:
	var state = BoardStateModel.new()
	var rook_cells: Array[Vector2i] = state.rook_attack_cells(Vector2i(2, 0))
	_expect(rook_cells.size() == 8, "A Torre deve atacar oito casas em uma grade 5 x 5.")
	_expect(rook_cells.has(Vector2i(2, 4)), "A Torre deve atacar através da Rainha.")
	var bishop_cells: Array[Vector2i] = state.bishop_attack_cells(Vector2i(0, 0))
	_expect(bishop_cells.size() == 4, "O Bispo no canto deve atacar quatro casas.")
	_expect(bishop_cells.has(Vector2i(3, 3)), "O Bispo deve atacar através da Rainha.")
func _test_campaign_catalog() -> void:
	var campaign := Catalog.load_campaign()
	var catalog_errors := Catalog.validate_campaign(campaign)
	_expect(catalog_errors.is_empty(), "O catálogo deve reproduzir a progressão consolidada.")
	_expect(Catalog.find_phase(campaign, 1).get("edict_count") == 1, "A fase 1 deve usar um único édito.")
	_expect(Catalog.find_phase(campaign, 6).get("seconds_per_edict") == 15, "A fase 6 deve introduzir 15 segundos por édito.")
	_expect(Catalog.find_phase(campaign, 7).get("configuration") == "procedural", "A fase 7 deve ser procedural.")
	_expect(Catalog.find_phase(campaign, 9).get("configuration") == "procedural", "A fase 9 deve ser procedural.")
func _test_fase1_dados_completos() -> void:
	# Caso feliz: a fase 1 carrega com todos os dados esperados,
	# batendo com a especificação consolidada do jogo.
	var campaign := Catalog.load_campaign()
	var fase1 := Catalog.find_phase(campaign, 1)

	_expect(not fase1.is_empty(), "A fase 1 deve existir no catálogo.")
	_expect(int(fase1.get("number", -1)) == 1, "O número da fase 1 deve ser 1.")
	_expect(String(fase1.get("resolution", "")) == "moves", "A fase 1 deve usar resolução por movimentos, não por tempo.")
	_expect(int(fase1.get("edict_count", -1)) == 1, "A fase 1 deve ter exatamente um édito.")
	_expect(int(fase1.get("seconds_per_edict", -1)) == 0, "A fase 1 não deve ter limite de tempo por édito.")
	_expect((fase1.get("first_pair", null) as Array).is_empty(), "A fase 1 não deve ter peças no primeiro par (ainda é tutorial).")
	_expect((fase1.get("second_pair", null) as Array).is_empty(), "A fase 1 não deve ter peças no segundo par.")
	_expect(String(fase1.get("pair_order", "")) == "horizontal_first", "A ordem dos pares da fase 1 deve ser horizontal_first.")
	_expect(String(fase1.get("configuration", "")) == "fixed", "A fase 1 deve ser configuração fixa, não procedural.")

	# Caso de falha: um caminho de catálogo inexistente não deve
	# retornar um valor padrão disfarçado (sem fallback).
	var catalogo_invalido := Catalog.load_campaign("res://data/phases/arquivo_que_nao_existe.json")
	_expect(catalogo_invalido.is_empty(), "Um caminho de catálogo inválido deve retornar vazio, nunca um valor padrão disfarçado.")
func _test_input_map() -> void:
	for action in ["move_up", "move_left", "move_down", "move_right", "restart_phase"]:
		_expect(InputMap.has_action(action), "A ação de entrada '%s' deve existir." % action)
func _test_procedural_seed_is_preserved() -> void:
	var manager = PhaseManagerModel.new()
	manager.auto_start = false
	manager.campaign = Catalog.load_campaign()
	manager.start_phase(7, 240826)
	manager.restart_phase()
	_expect(manager.current_seed == 240826, "Reiniciar uma fase procedural deve preservar a semente.")
	manager.free()
func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
