extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	Engine.time_scale = 8.0
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	var menu := main.get_node("PauseOverlay") as PauseOverlay
	var manager := main.get_node("PhaseManager") as PhaseManager
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var cutscene := main.get_node("OpeningCutscene") as OpeningCutscene
	_expect(menu.content.get_node_or_null("RestartButton") == null and menu.content.get_node_or_null("PhaseSelectorLabel") == null and menu.content.get_node_or_null("ControlsLabel") == null and menu.main_menu_button.text == "Menu principal", "A pausa deve conter Continuar, seletor com Ir e Menu principal, sem os textos removidos.")
	_expect(cutscene._running and manager.current_phase == 0, "O teste deve começar durante a abertura.")
	_expect(menu.phase_selector.item_count == 13 and menu.phase_selector.get_item_id(8) == 101 and menu.phase_selector.get_item_id(12) == 105 and menu.phase_selector.get_item_text(8) == "Chaotic I" and menu.phase_selector.get_item_text(12) == "Chaotic V", "O seletor deve oferecer oito fases e cinco desafios Chaotic para teste.")
	await _jump(menu, 6)
	_expect(manager.current_phase == 6 and not paused and not menu.screen.visible, "Ir deve fechar o ESC e iniciar a fase escolhida.")
	_expect(not cutscene._running and not cutscene.teleport.visible and not cutscene.teleport_sound.playing, "Pular a abertura deve encerrar câmera, teleporte e áudio da intro.")
	_expect(root.get_camera_3d() == main.get_node("World/BoardCamera").camera and main.get_node("World/Player").visible and main.get_node("World/Seraph").visible, "O salto deve entregar a câmera de jogo e revelar os personagens.")
	_expect(main.get_node("Music").stream == main.GAME_MUSIC and not main.get_node("Music").stream_paused, "A trilha de gameplay deve tocar após o salto.")
	await _until(func(): return trial.stage == BalanceTrialController.Stage.TILTING)
	await process_frame
	menu._set_paused(true)
	var mote_x := trial.stardust.screen_dust._motes[0].x
	var timer := trial._elapsed
	for frame in range(15):
		await process_frame
	_expect(is_equal_approx(mote_x, trial.stardust.screen_dust._motes[0].x) and is_equal_approx(timer, trial._elapsed), "O ESC deve congelar física e poeira da tela.")
	menu.phase_selector.select(2)
	_expect(manager.current_phase == 6, "Escolher uma opção só deve trocar de fase ao pressionar Ir.")
	menu.phase_button.pressed.emit()
	await _until(func(): return not menu.screen.visible)
	await process_frame
	_expect(manager.current_phase == 3 and is_zero_approx(main.get_node("World/Board").rotation.z), "Trocar durante a inclinação deve nivelar o tabuleiro e carregar a fase três.")
	_expect(not trial.stardust.screen_dust.visible and trial.stardust.screen_dust._motes.is_empty(), "Sair da fase seis deve apagar a poeira da tela imediatamente.")
	await _jump(menu, 5)
	await _jump(menu, 1)
	await _jump(menu, 2)
	await _jump(menu, 4)
	_expect(manager.current_phase == 4 and main.get_node("PhaseLoopController")._piece_root != null, "As fases comuns devem carregar suas próprias peças após saltos rápidos.")
	await _jump(menu, 6)
	await _until(func(): return trial.stage == BalanceTrialController.Stage.DECISION)
	await _jump(menu, 6)
	_expect(trial.round_index == 0 and not main.get_node("World/Player").platform_sliding, "Selecionar a fase atual deve iniciar um teste novo.")
	# Interrupt into the card table, then return, and let old callbacks expire.
	await _jump(menu, 7)
	await _until(func(): return main.get_node("CardTrialController").table.visible)
	_expect(main.get_node("CardTrialController").table.visible and not main.get_node("World/Player").visible, "O seletor deve abrir a fase sete sem personagem.")
	await _jump(menu, 8)
	_expect(main.get_node("CardTrialController").state.kind == CardTrialState.Kind.MATCH, "A fase oito deve começar pela associação.")
	await _jump(menu, 6)
	await create_timer(OpeningCutscene.TOTAL_LENGTH + 1.0).timeout
	_expect(manager.current_phase in [6, 7] and not cutscene.top_bar.visible and not cutscene.bottom_bar.visible, "Callbacks antigos da abertura não devem sobrescrever a fase selecionada.")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	await create_timer(0.12, true, false, true).timeout
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	for failure in failures:
		printerr("FALHA: " + failure)
	if failures.is_empty():
		print("OK: ESC, oito fases, mesa de cartas, salto da abertura, pausa e reinício.")
	quit(0 if failures.is_empty() else 1)


func _jump(menu: PauseOverlay, number: int) -> void:
	menu._set_paused(true)
	menu.phase_selector.select(number - 1)
	menu.phase_button.pressed.emit()
	await _until(func(): return not menu.screen.visible)
	await process_frame
	await process_frame
	var book := (menu.get_parent().get_node("HUD") as GameHUD).tutorial_book
	if book.needs_chapter(number):
		await _until(func(): return book.state == TutorialBook.State.READING)
		book.request_close()
		await _until(func(): return not book.visible)


func _until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await process_frame
	failures.append("Tempo esgotado esperando a troca de fase.")
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
