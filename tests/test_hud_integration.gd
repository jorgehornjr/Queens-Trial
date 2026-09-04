extends SceneTree

const HudScene = preload("res://scenes/ui/hud.tscn")
const EditoMachine = preload("res://scripts/gameplay/edito_state_machine.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	await _test_connection_before_ready()
	await _test_main_scene()
	if failures.is_empty():
		print("OK: HUD validada (cena, inicialização, ordens, falha, reinício e avanço).")
		quit(0)
	else:
		for failure in failures:
			printerr("FALHA: " + failure)
		quit(1)


func _test_connection_before_ready() -> void:
	var machine := EditoMachine.new()
	root.add_child(machine)
	var hud := HudScene.instantiate() as GameHUD
	# Reproduz a ordem em que o controller encontra a HUD antes do _ready.
	hud.connect_to_edito_machine(machine)
	root.add_child(hud)
	_expect(hud.edito_order_1_label != null and hud.status_label != null,
		"A cena deve conter os textos referenciados pelo script.")
	_expect(hud._edito_machine == machine, "A conexão deve terminar quando a HUD ficar pronta.")
	machine.configurar_fase([
		{"valor": 2, "par": "first_pair"},
		{"valor": 3, "par": "second_pair"},
	], Vector2i(0, 4))
	_expect(hud.edito_order_1_label.text == "1ª ordem  •  II  •  em andamento",
		"A primeira ordem deve mostrar seu numeral e estado.")
	_expect(hud.edito_order_2_label.text == "2ª ordem  •  III  •  pendente",
		"A segunda ordem deve aguardar a primeira.")
	hud.free()
	machine.free()
	await process_frame


func _test_main_scene() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	_expect(scene != null, "A cena principal deve carregar com a HUD.")
	if scene == null:
		return
	var main := scene.instantiate()
	root.add_child(main)
	await _settle()
	var hud := main.get_node("HUD") as GameHUD
	var controller := main.get_node_or_null("PhaseLoopController") as PhaseLoopController
	_expect(controller != null, "O controlador dos éditos deve estar na cena principal.")
	if controller == null:
		main.free()
		return
	var manager := main.get_node("PhaseManager") as PhaseManager
	var player := main.get_node("World/Player") as GridPlayer
	player.move_duration = 0.01
	player.turn_duration = 0.01
	_expect(manager.current_phase == 0, "A apresentação deve continuar aguardando Enter.")
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	main._unhandled_input(enter)
	await _settle()
	_expect(manager.current_phase == 1 and controller._edito_machine.editos.size() == 1,
		"Enter deve iniciar a fase e configurar a primeira ordem.")
	_expect(hud.state_label.text == "Estado  •  Aguardando movimento",
		"A HUD deve acompanhar a máquina de estados ao iniciar.")
	_expect(hud.goal_label.text == "Destino  •  coluna 1  •  linha 3",
		"A HUD deve informar o destino configurado para a fase.")
	player.move_duration = 0.05
	player._try_move(Vector2i.UP)
	var restart := InputEventKey.new()
	restart.physical_keycode = KEY_R
	restart.pressed = true
	player._unhandled_input(restart)
	await create_timer(0.1).timeout
	await _settle()
	var board := main.get_node("World/Board") as Board3D
	var start_position := board.grid_to_world(player.starting_cell) + Vector3.UP * player.surface_offset
	_expect(player.position.is_equal_approx(start_position),
		"Reiniciar durante a animação deve cancelar o movimento e manter a posição inicial.")
	_expect(controller._edito_machine.passos_dados == 0,
		"Uma animação cancelada pelo reinício não deve consumir um passo.")
	player.move_duration = 0.01

	var initial_editos: Array = controller._edito_machine.editos.duplicate(true)
	await _move(player, Vector2i.UP)
	await _move(player, Vector2i.DOWN)
	_expect(manager.current_phase == 1 and player.current_cell == player.starting_cell,
		"Falhar no édito deve reiniciar a fase e reposicionar o jogador.")
	_expect(controller._edito_machine.estado_atual == EditoMachine.Estado.AGUARDANDO_MOVIMENTO,
		"A máquina deve aceitar novos movimentos após falhar e reiniciar.")
	_expect(hud.state_label.text == "Estado  •  Aguardando movimento",
		"Estados antigos não devem sobrescrever o estado da fase reiniciada.")
	_expect(controller._edito_machine.editos == initial_editos,
		"Reiniciar deve preservar os valores da fase fixa.")

	# Usa os dados reais da campanha, sem substituir éditos ou destino.
	await _move(player, Vector2i.UP)
	await _move(player, Vector2i.UP)
	_expect(manager.current_phase == 2, "Cumprir o édito no safe spot deve avançar a fase.")
	_expect(controller._edito_machine.estado_atual == EditoMachine.Estado.AGUARDANDO_MOVIMENTO,
		"A fase seguinte deve começar aceitando movimentos.")
	_expect(controller._edito_machine.editos.size() == 2,
		"A fase 2 deve configurar suas duas ordens.")
	await _move(player, Vector2i.RIGHT)
	await _move(player, Vector2i.RIGHT)
	_expect(hud.edito_order_1_label.text == "1ª ordem  •  II  •  concluído",
		"A primeira ordem deve aparecer concluída após o julgamento.")
	_expect(hud.edito_order_2_label.text == "2ª ordem  •  III  •  em andamento",
		"A segunda ordem deve passar a ser a ordem ativa.")
	_expect(hud.state_label.text == "Estado  •  Aguardando movimento",
		"A HUD deve mostrar o estado atual após a resolução das peças.")

	manager.restart_phase()
	await _settle()
	_expect(controller._edito_machine.indice_edito_atual == 0,
		"Reiniciar durante a segunda ordem deve voltar para a primeira.")
	_expect(controller._edito_machine.passos_dados == 0,
		"Reposicionar o jogador não deve contar como movimento do édito.")
	for direction in [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.UP, Vector2i.UP]:
		await _move(player, direction)
	_expect(manager.current_phase == 3, "Os dados reais da fase 2 devem permitir sua conclusão.")
	for phase_number in [3, 4]:
		for direction in [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.LEFT, Vector2i.UP, Vector2i.UP]:
			await _move(player, direction)
		_expect(manager.current_phase == phase_number + 1,
			"A fase %d deve ter uma solução que sobreviva aos ataques das Torres." % phase_number)
	main.free()
	await _settle()


func _move(player: GridPlayer, direction: Vector2i) -> void:
	player._try_move(direction)
	await create_timer(0.05).timeout
	await _settle()


func _settle() -> void:
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
