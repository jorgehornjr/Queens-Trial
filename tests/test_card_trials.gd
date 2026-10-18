extends SceneTree

const State = preload("res://scripts/gameplay/card_trial_state.gd")
var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for seed_value in range(80):
		var model := State.new()
		model.begin(7, seed_value)
		for round in range(2):
			_expect(model.deck.size() == 20 and model.anchor_index in range(1, 5), "O deck completo e a carta fixa interior devem existir em ambas as ordens.")
			_expect(not model.remove(model.anchor_index) and not model.place(model.anchor_index, 1), "A carta fixa não pode ser retirada ou substituída.")
			var answer := _ordered_answer(model)
			for index in range(6):
				if index != model.anchor_index: model.place(index, answer[index])
			_expect(model.check().correct, "Toda sequência estrita e válida deve ser aceita, sem solução escondida.")
			if round == 0: _expect(model.next_round() and not model.ascending, "A segunda rodada deve ser decrescente.")
	root.size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var trial := main.get_node("CardTrialController") as CardTrialController
	var space := main.get_node("World/CelestialSpace") as CelestialSpace
	space.set_effect_time(180.0)
	var flow_speed := space.nebula_motion_speed
	var flow_strength := space.nebula_motion_strength
	manager.start_phase(7, 3107)
	_expect(trial.space_transition.duration >= 4.5, "A passagem deve ter um ritmo mais lento que a versão anterior.")
	await _until(func(): return trial.space_transition.progress > 0.3)
	_expect(is_equal_approx(space.nebula_motion_speed, flow_speed) and is_equal_approx(space.nebula_motion_strength, flow_strength), "A transição não pode alterar a velocidade ou deformação da nébula, sobretudo com um relógio acumulado longo.")
	await _until(func(): return trial.table.visible)
	await create_timer(0.4).timeout
	_expect(trial.active and trial.table.visible and not main.get_node("World/Player").visible and not main.get_node("World/Player").input_enabled, "A fase sete deve ser uma mesa de cartas sem jogador ou movimento.")
	_expect(not main.get_node("World/Board")._safe_spot_marker.visible, "Não deve haver safe spot nas provas de cartas.")
	_expect(trial.table.hand.order.size() == 19 and trial.state.anchor_value not in trial.table.hand.order, "A carta fixa deve sair da mão, sem fantasma.")
	_expect(trial.table.input_shield.material == null and trial.table.input_shield.color.a == 0.0, "O fundo deve permanecer nítido, sem shader de blur.")
	_expect(not main.get_node("World/Board").visible and not main.get_node("World/Seraph").visible and not main.get_node("World/CelestialSpace/SolarSystem").visible and not main.get_node("World/CelestialSpace/DistantEarth").visible, "A passagem deve recolher tabuleiro, rainha, planetas e satélites.")
	_expect(root.get_camera_3d() == trial.space_transition.camera and main.get_node("World/CelestialSpace/WorldEnvironment").environment.background_mode == Environment.BG_SKY, "A mesa deve preservar o panorama VFX na própria câmera.")
	var hud := main.get_node("HUD") as GameHUD
	_expect(not hud.tutorial_book.visible and space._effect_time > 180.0, "A fase sete deve preservar o relógio VFX contínuo e dispensar abertura automática do livro.")
	hud._consult_book()
	for frame in range(3): await process_frame
	_expect(not paused and not hud.tutorial_book.visible and not hud.book_button.visible, "As provas de cartas não devem oferecer livro nem consulta por N.")
	hud.tutorial_book.cancel()
	hud._release_reading()
	await process_frame
	_expect(not paused and trial.active, "A tentativa de consulta deve preservar a mesa de cartas.")
	var answer := _ordered_answer(trial.state)
	var index := 0 if trial.state.anchor_index != 0 else 1
	var value: int = answer[index]
	var card_index := trial.table.hand.order.find(value)
	var hand_point := trial.table.hand.card_point(value)
	await _move(hand_point)
	await create_timer(0.25).timeout
	_expect(trial.table.hand._cards[card_index].position.y < 50.0, "O hover deve levantar a carta e revelar sua frente.")
	var destination := trial.table.slots[index].get_global_rect().get_center()
	await _drag(hand_point, destination)
	_expect(trial.state.slots[index] == value, "Arrastar uma carta da mão deve preencher o slot real.")
	_expect(trial.table.hand.order.size() == 18 and value not in trial.table.hand.order and trial.table.hand.get_child_count() == 18, "A mão deve perder o nó da carta colocada e fechar o espaço.")
	_expect(trial.table.hand._start_x > CardTrialHand.STEP * 0.5, "Com duas cartas fora, a mão deve ocupar uma faixa menor e centralizada.")
	var other_index := 1 if trial.state.anchor_index != 1 else 2
	await _drag(destination, trial.table.slots[other_index].get_global_rect().get_center())
	_expect(trial.state.slots[index] == 0 and trial.state.slots[other_index] == value, "Arrastar uma carta colocada deve mover a carta, sem removê-la no início do gesto.")
	await _drag(trial.table.slots[other_index].get_global_rect().get_center(), hand_point)
	_expect(trial.state.slots[other_index] == 0, "Soltar sobre a mão deve devolver a carta ao deck.")
	_expect(trial.table.hand.order.size() == 19 and value in trial.table.hand.order, "Devolver deve restaurar a carta na ordem embaralhada original.")
	await create_timer(0.3).timeout
	# A cancelled native drag must restore the removed hand card.
	hand_point = trial.table.hand.card_point(value)
	await _move(hand_point)
	await _drag(hand_point, Vector2(25, 25))
	_expect(value in trial.table.hand.order and trial.table.hand.order.size() == 19, "Cancelar o arrastar deve devolver a carta sem perdê-la ou duplicá-la.")
	for i in range(6):
		if i != trial.state.anchor_index: trial._drop(i, answer[i])
	await _click(trial.table.submit.get_global_rect().get_center())
	_expect(trial.state.solved and trial.table.continue_button.visible, "Confirmar a ordem deve resolver a rodada pelo botão da interface.")
	await _click(trial.table.continue_button.get_global_rect().get_center())
	_expect(trial.state.round_index == 1 and not trial.state.ascending, "Continuar deve carregar a ordem decrescente.")
	answer = _ordered_answer(trial.state)
	for i in range(6):
		if i != trial.state.anchor_index: trial._drop(i, answer[i])
	trial._submit()
	trial._continue()
	await create_timer(0.8).timeout
	_expect(manager.current_phase == 8 and trial.table.hand.visible, "Concluir a fase sete deve abrir a associação da fase oito, sem tela de término antecipada.")
	_expect(trial.state.kind == State.Kind.MATCH and trial.state.targets == [14, 18, 19], "A fase oito deve começar com os espaços 14, 18 e 19.")
	card_index = trial.table.hand.order.find(14)
	hand_point = trial.table.hand.card_point(14)
	await _move(hand_point)
	await _drag(hand_point, trial.table.slots[0].get_global_rect().get_center())
	_expect(trial.state.slots[0] == 14, "A associação também deve aceitar um arrastar real sobre o alvo em Jupiter Pro.")
	for i in range(3): trial._drop(i, trial.state.targets[i])
	trial._drop(0, 4)
	trial._submit()
	_expect(not trial.state.solved, "Uma carta incorreta não deve resolver a associação.")
	_expect(hud.result_panel.visible and trial._feedback_pending, "A resposta incorreta deve abrir uma correção central antes da revisão.")
	var wrong_slots := trial.state.slots.duplicate()
	trial._drop(0, 14)
	_expect(trial.state.slots == wrong_slots, "O aviso deve impedir mudanças nas cartas que estão atrás dele.")
	await _until(func(): return not hud.failure_feedback.action.disabled)
	hud.failure_feedback.acknowledge()
	_expect(trial.state.slots == wrong_slots and not trial._feedback_pending, "Continuar deve preservar as cartas para o aluno ajustar.")
	for i in range(3): trial._drop(i, trial.state.targets[i])
	await _click(trial.table.submit.get_global_rect().get_center())
	await _click(trial.table.continue_button.get_global_rect().get_center())
	_expect(trial.state.kind == State.Kind.FALSE_DECREE and not trial.table.hand.visible, "A segunda parte deve apresentar as três opções do decreto falso.")
	var false_slot := trial.table.slots[trial.state.false_index]
	await _move(false_slot.get_global_rect().get_center())
	await process_frame
	_expect(float(false_slot._art.material.get_shader_parameter("false_mark")) == 1.0, "O hover do decreto deve mostrar um X vermelho sobre a carta.")
	await _click(false_slot.get_global_rect().get_center())
	_expect(trial.state.solved, "Selecionar a única correspondência falsa deve resolver a rodada.")
	trial._continue()
	await create_timer(0.8).timeout
	_expect(manager.current_phase == 8 and trial.table.title.text == "Provas concluídas", "A última fase jogável deve terminar sem abrir os espaços reservados nove e dez.")
	manager.start_phase(3)
	await process_frame
	_expect(not trial.table.visible and main.get_node("World/Player").visible, "Voltar a uma fase de tabuleiro deve devolver o personagem e ocultar a mesa.")
	_expect(main.get_node("World/Board").visible and main.get_node("World/CelestialSpace/SolarSystem").visible and root.get_camera_3d() == main.get_node("World/BoardCamera").camera, "Sair da mesa deve restaurar cenário e câmera.")
	manager.start_phase(7)
	await process_frame
	await process_frame
	_expect(trial.space_transition.transitioning and not trial.table.visible, "As cartas devem aguardar a passagem pelo ambiente.")
	paused = true
	var stopped_progress := trial.space_transition.progress
	await create_timer(0.08, true, false, true).timeout
	_expect(is_equal_approx(stopped_progress, trial.space_transition.progress), "Pausar durante a passagem deve congelar câmera e nuvem estelar.")
	paused = false
	manager.start_phase(3)
	await create_timer(trial.space_transition.duration + 0.4).timeout
	_expect(not trial.table.visible and not trial.space_transition.in_space and main.get_node("World/Board").visible, "Interromper a passagem não pode esconder o cenário ou reabrir a mesa por callback antigo.")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: ", failure)
	print("CARD_TRIAL_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _ordered_answer(model: CardTrialState) -> Array[int]:
	var values: Array[int] = []
	for i in range(6): values.append(model.anchor_value + (i - model.anchor_index) * (1 if model.ascending else -1))
	return values

func _move(point: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.global_position = point
	root.push_input(event, true)
	await process_frame

func _button(point: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = point
	event.global_position = point
	root.push_input(event, true)
	await process_frame

func _click(point: Vector2) -> void:
	await _move(point)
	await _button(point, true)
	await _button(point, false)

func _drag(start: Vector2, destination: Vector2) -> void:
	await _button(start, true)
	for i in range(1, 9):
		var event := InputEventMouseMotion.new()
		event.position = start.lerp(destination, float(i) / 8.0)
		event.global_position = event.position
		event.button_mask = MOUSE_BUTTON_MASK_LEFT
		event.relative = (destination - start) / 8.0
		root.push_input(event, true)
		await process_frame
	await _button(destination, false)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)

func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	failures.append("Tempo esgotado aguardando a mesa.")
