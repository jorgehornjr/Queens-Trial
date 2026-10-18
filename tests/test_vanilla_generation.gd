extends SceneTree

const Generator = preload("res://scripts/data/vanilla_board_generator.gd")
const Catalog = preload("res://scripts/data/phase_catalog.gd")
const Machine = preload("res://scripts/gameplay/edito_state_machine.gd")
var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var campaign := Catalog.load_campaign()
	var starts := {}
	var pairs := {}
	var seen_values := {}
	var generated := 0
	var worst_usec := 0
	for sample in range(128):
		var history: Array = []
		for number in range(1, 6):
			var template := Catalog.find_phase(campaign, number)
			var before := Time.get_ticks_usec()
			var data := Generator.generate(template, sample * 17 + number, history)
			worst_usec = maxi(worst_usec, Time.get_ticks_usec() - before)
			_expect(not data.is_empty(), "Toda semente deve produzir uma fase solucionável.")
			if data.is_empty(): continue
			_expect(data == Generator.generate(template, sample * 17 + number, history), "A mesma semente e histórico devem reproduzir o tabuleiro.")
			_expect(data.resolution == "moves" and float(data.seconds_per_edict) == 0.0, "Vanilla 1–5 deve continuar sem cronômetro.")
			_expect(data.piece_waves == template.piece_waves, "A geração deve preservar as peças de cada lição.")
			for value in data.edict_values: seen_values[int(value)] = true
			starts[str(data.starting_cell)] = true
			if not history.is_empty():
				_expect(data.starting_cell != history[-1].starting_cell, "Fases consecutivas devem variar a casa inicial.")
				_expect(data.edict_values != history[-1].edict_values, "Fases consecutivas não devem repetir a sequência de éditos.")
			if number > 1:
				var unordered: Array = data.edict_values.duplicate()
				unordered.sort()
				for previous: Dictionary in history:
					var old: Array = previous.edict_values.duplicate()
					old.sort()
					_expect(unordered != old, "As quatro fases de dois éditos devem preferir combinações novas.")
				pairs[str(data.edict_values)] = true
			_verify_solution(data)
			history.append(data)
			generated += 1
	_expect(starts.size() >= 20 and pairs.size() == 12 and seen_values.size() == 4, "O sorteio deve variar as casas e alcançar todas as ordens de I–IV.")
	var exhausted: Array = []
	var sequences := {}
	for sample in range(12):
		var data := Generator.generate(Catalog.find_phase(campaign, 2), sample + 710, exhausted)
		var values: Array = data.edict_values
		_expect(not sequences.has(str(values)), "Antes de esgotar as 12 ordens, uma combinação repetida deve vir invertida.")
		sequences[str(values)] = true
		for previous: Dictionary in exhausted:
			if values.has(previous.edict_values[0]) and values.has(previous.edict_values[1]):
				_expect(values[0] == previous.edict_values[1], "Reutilizar o par deve inverter a ordem anterior.")
		exhausted.append(data)
	var manager := PhaseManager.new()
	manager.auto_start = false
	manager.save_progress = false
	manager.campaign = campaign
	manager.start_phase(4, 2077)
	var puzzle := manager.current_phase_data.duplicate(true)
	manager.restart_phase()
	_expect(manager.current_seed == 2077 and manager.current_phase_data == puzzle, "Reiniciar deve manter o mesmo desafio e sua semente.")
	manager.free()
	for failure in failures: printerr("FALHA: " + failure)
	print("Vanilla: %d fases; %d casas iniciais; %d sequências; geração máxima %.2f ms." % [generated, starts.size(), pairs.size(), float(worst_usec) / 1000.0])
	quit(0 if failures.is_empty() else 1)

func _verify_solution(data: Dictionary) -> void:
	var routes := Generator.solution(data)
	_expect(routes.size() == data.edict_values.size(), "Cada édito deve ter uma rota completa.")
	if routes.is_empty(): return
	var machine := Machine.new()
	root.add_child(machine)
	var success := [false]
	machine.sucesso.connect(func(): success[0] = true)
	var edicts: Array = []
	for index in range(data.edict_values.size()): edicts.append({"valor": int(data.edict_values[index]), "par": str(index)})
	var cell := Vector2i(int(data.starting_cell[0]), int(data.starting_cell[1]))
	_expect(machine.configurar_fase(edicts, cell), "A máquina de éditos deve aceitar I–IV.")
	var geometry := Generator.wave_geometry(data)
	var occupied: Array = []
	for index in range(routes.size()):
		_expect(routes[index].size() == int(data.edict_values[index]), "A solução deve usar exatamente os passos do édito.")
		for next: Vector2i in routes[index]:
			_expect(next not in occupied and absi(next.x - cell.x) + absi(next.y - cell.y) == 1, "A rota deve respeitar ocupação e movimentos adjacentes.")
			machine.registrar_movimento(next - cell)
			cell = next
		machine.avancar_primeira_peca()
		machine.avancar_segunda_peca()
		machine.avancar_ataque()
		machine.julgar(geometry[index].attacked, Vector2i(int(data.safe_spot[0]), int(data.safe_spot[1])))
		occupied.append_array(geometry[index].occupied)
	_expect(success[0], "A solução gerada deve passar pelo julgamento real e terminar no refúgio.")
	if routes.size() == 1:
		_expect(data.tutorial_path.size() == int(data.edict_values[0]), "As estrelas devem acompanhar o édito sorteado.")
	machine.free()

func _expect(condition: bool, message: String) -> void:
	if not condition and message not in failures: failures.append(message)
