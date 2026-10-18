extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	Engine.time_scale = 8.0
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD") as GameHUD
	var book := hud.tutorial_book
	var manager := main.get_node("PhaseManager") as PhaseManager
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var player := main.get_node("World/Player") as GridPlayer
	var queen: Node = main.get_node("World/Seraph")
	var orb: Node3D = queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb")
	manager.start_phase(6)
	await _until(func(): return queen.balance.reveal > 0.05)
	_expect(not book.visible and trial.stage == BalanceTrialController.Stage.TRANSITION, "O globo e a balança devem se transformar sem o livro por cima.")
	_expect(not player.input_enabled and not trial.trial_hud.visible, "A apresentação não deve liberar jogador nem cartas antes do tutorial.")
	paused = true
	var reveal: float = queen.balance.reveal
	for frame in range(12): await process_frame
	_expect(is_equal_approx(queen.balance.reveal, reveal) and not book.visible, "Pausar deve congelar a transformação e adiar o livro.")
	paused = false
	await _until(func(): return book.visible)
	_expect(queen.balance.reveal > 0.999 and not orb.visible, "O livro só deve chegar depois de a balança estar completa e o globo sumir.")
	_expect(trial.stage == BalanceTrialController.Stage.TRANSITION and trial.remaining == 5.0, "Ler não pode gastar o prazo da prova.")
	await _until(func(): return book.state == TutorialBook.State.READING)
	book.request_close()
	await _until(func(): return trial.stage == BalanceTrialController.Stage.DECISION)
	_expect(player.input_enabled and trial.remaining > 4.5 and trial.trial_hud.visible, "Cartas e cinco segundos devem começar depois do fechamento do livro.")
	# Changing phase during a second ritual must cancel the old tutorial callback.
	book.seen_chapters.erase(6)
	book.seen_chapters[3] = true
	manager.start_phase(3)
	await _until(func(): return queen.balance.reveal < 0.2)
	manager.start_phase(6)
	await _until(func(): return queen.balance.reveal > 0.3)
	manager.start_phase(3)
	await create_timer(4.0).timeout
	_expect(manager.current_phase == 3 and not book.visible and trial.stage == BalanceTrialController.Stage.INACTIVE, "Trocar de fase deve impedir que o livro da balança reapareça depois.")
	hud.card_presentation.cancel()
	player.set_input_enabled(false)
	var feedback := hud.failure_feedback
	var result: Array = []
	_observe(hud, ["A carta IV pedia uma distância de 4 casas.\nVocê terminou a 2 casas do ponto de partida.", "Uma peça atacou a casa onde você parou."], result)
	_press_enter()
	await process_frame
	_expect(result.is_empty() and feedback.screen.visible, "O Enter da resposta não pode dispensar a correção que acabou de aparecer.")
	await _until(func(): return not feedback.action.disabled)
	_press_enter(true)
	await process_frame
	_expect(result.is_empty(), "Segurar Enter não pode fechar o aviso por repetição da tecla.")
	for resolution in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		for frame in range(4): await process_frame
		var card := feedback.panel.get_global_rect()
		var viewport := root.get_visible_rect()
		_expect(card.get_center().distance_to(viewport.get_center()) < 2.0, "A correção deve estar centralizada em 720p e 1080p.")
		_expect(viewport.encloses(card) and card.encloses(feedback.action.get_global_rect()), "Texto e botão devem caber na tela.")
	_expect(feedback.body.get_theme_font_size("font_size") >= 38 and "Voltar" in feedback.hint.text, "O erro deve ter letras grandes e explicar por que voltar não resolve a distância.")
	await create_timer(12.0).timeout
	_expect(feedback.screen.visible and result.is_empty(), "A explicação deve permanecer até o aluno decidir continuar.")
	paused = true
	_press_enter()
	await process_frame
	_expect(result.is_empty() and feedback.screen.visible, "Enter durante a pausa não pode confirmar o aviso que está atrás dela.")
	paused = false
	_press_enter()
	await process_frame
	_expect(result == [true], "Confirmar deve concluir a apresentação uma única vez.")
	result.clear()
	_observe(hud, ["Você terminou fora da casa iluminada."], result)
	await _until(func(): return not feedback.action.disabled)
	manager.start_phase(2)
	_expect(result == [false] and not feedback.screen.visible, "Trocar de fase deve cancelar o aviso, sem reiniciar a fase antiga.")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	for failure in failures: printerr("FALHA: " + failure)
	if failures.is_empty(): print("OK: transformação antes do livro, pausa, relógio, correção central, leitura livre e cancelamento.")
	quit(0 if failures.is_empty() else 1)

func _observe(hud: GameHUD, reasons: Array, results: Array) -> void:
	results.append(await hud.show_failure(reasons))

func _press_enter(echo := false) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ENTER
	event.physical_keycode = KEY_ENTER
	event.pressed = true
	event.echo = echo
	Input.parse_input_event(event)
	var release := event.duplicate() as InputEventKey
	release.pressed = false
	Input.parse_input_event(release)

func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	failures.append("Tempo esgotado aguardando a apresentação.")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
