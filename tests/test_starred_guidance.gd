extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	Engine.time_scale = 8.0
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD") as GameHUD
	var board := main.get_node("World/Board") as Board3D
	var player := main.get_node("World/Player") as GridPlayer
	var controller := main.get_node("PhaseLoopController") as PhaseLoopController
	var menu := main.get_node("PauseOverlay") as PauseOverlay
	hud.tutorial_book.seen_chapters[1] = true
	main.start_test_phase(1)
	await _flip_first_card(hud)
	await _until(func(): return is_instance_valid(board._tutorial_guide) and board._tutorial_guide.playing)
	var guide := board._tutorial_guide
	var origin := player.current_cell
	_expect(not player.input_enabled and controller._edito_machine.passos_dados == 0, "A orientação deve bloquear movimentos sem consumir os quatro passos.")
	player._try_move(Vector2i.LEFT)
	_expect(player.current_cell == origin and controller._edito_machine.passos_dados == 0, "Uma tecla durante as estrelas não deve deslocar o viajante nem gastar passos.")
	_expect(guide.points[-1].is_equal_approx(board.grid_to_world(board.safe_spot)), "A curva deve terminar no centro do refúgio real.")
	menu._set_paused(true)
	var progress := guide.reveal
	for frame in range(20): await process_frame
	_expect(is_equal_approx(progress, guide.reveal) and not player.input_enabled, "O ESC deve congelar o caminho estrelado.")
	menu._set_paused(false)
	await _until(func(): return not paused)
	await _until(func(): return player.input_enabled)
	_expect(not guide.playing and guide.reveal > 0.999, "O movimento só deve ser liberado depois da última estrela.")
	for direction in [Vector2i.LEFT, Vector2i.LEFT, Vector2i.UP, Vector2i.UP]:
		player._try_move(direction)
		await _until(func(): return not player.movement_locked)
	_expect(player.current_cell == board.safe_spot, "A orientação deve preservar a rota de quatro movimentos.")
	# Reiniciar durante a revelação e trocar de fase deve cancelar o bloqueio antigo.
	main.start_test_phase(1)
	await _flip_first_card(hud)
	await _until(func(): return is_instance_valid(board._tutorial_guide) and board._tutorial_guide.playing)
	main.start_test_phase(2)
	await _until(func(): return hud.tutorial_book.state == TutorialBook.State.READING)
	await create_timer(StarredGuide.DURATION + 0.5).timeout
	_expect(main.phase_manager.current_phase == 2 and not player.input_enabled and not is_instance_valid(board._tutorial_guide), "O fim de uma curva cancelada não deve liberar a fase seguinte durante seu livro.")
	hud.tutorial_book.request_close()
	await _until(func(): return hud.card_presentation._cards.size() == 2 and not hud.card_presentation._cards[0].disabled)
	for card in hud.card_presentation._cards: card.pressed.emit()
	await _until(func(): return player.input_enabled)
	_expect(not is_instance_valid(board._tutorial_guide), "A fase dois deve seguir sem repetir a orientação da fase um.")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	for failure in failures: printerr("FALHA: " + failure)
	if failures.is_empty(): print("OK: estrelas, bloqueio de passos, pausa, rota e cancelamento ao trocar de fase.")
	quit(0 if failures.is_empty() else 1)


func _flip_first_card(hud: GameHUD) -> void:
	await _until(func(): return hud.card_presentation._cards.size() == 1 and not hud.card_presentation._cards[0].disabled)
	hud.card_presentation._cards[0].pressed.emit()


func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 14000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	failures.append("Tempo esgotado aguardando a orientação ou a apresentação.")


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
