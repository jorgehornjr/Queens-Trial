extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	Engine.time_scale = 6.0
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var hud := main.get_node("HUD") as GameHUD
	var book := hud.tutorial_book
	var player := main.get_node("World/Player") as GridPlayer
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	manager.start_phase(1)
	await _until(func(): return book.state == TutorialBook.State.READING)
	_expect(book.current_chapter == 1 and not player.input_enabled and hud.card_presentation._cards.is_empty(), "Ler a fase um deve bloquear jogo e cartas.")
	_expect("torre" not in book.body_label.text.to_lower() and "bispo" not in book.body_label.text.to_lower() and "safe" not in book.body_label.text.to_lower(), "O primeiro capítulo não deve antecipar peças ou safe spot.")
	_expect(book.reveal_progress < 0.2, "A página deve começar com tinta e pintura ainda se revelando.")
	await _until(func(): return book.reveal_progress > 0.99)
	await _click(book.volume.get_global_transform_with_canvas() * Vector2(1250, 600))
	_expect(book._displayed_chapter == 1 and book.visible, "Clicar à direita não deve fechar nem liberar a próxima fase bloqueada.")
	await _click(book.volume.get_global_transform_with_canvas() * Vector2(270, 600))
	await _until(func(): return book.state == TutorialBook.State.READING and book.table_visible)
	_expect(book.visible and book.table_visible and book.numeral_table.get_node("Number3/Roman").text == "IV" and book.numeral_table.get_node("Number3/Arabic").text == "4", "A consulta deve ensinar IV = 4 sem dispensar o livro.")
	_expect(book.chapter_label.text == "CONSULTA" and not book.body_label.visible,
		"A consulta deve conter somente título e tabela, sem explicações impressas.")
	for index in range(20):
		var number := book.numeral_table.get_node("Number%d" % index) as Control
		_expect(number.get_node("Roman").text == TutorialBook.Chapters.ROMANS[index] and number.get_node("Arabic").text == str(index + 1), "A tabela deve corresponder ao número %d." % [index + 1])
		if index < 10:
			var opposite := book.numeral_table.get_node("Number%d" % [index + 10]) as Control
			_expect(is_equal_approx(number.get_global_rect().position.y, opposite.get_global_rect().position.y), "Os números %d e %d devem estar nivelados entre as páginas." % [index + 1, index + 11])
	_expect(book.cover.get_node_or_null("CoverTitle") == null, "A capa aprovada não deve conter título sobre a arte.")
	book.turn_page(1)
	await _until(func(): return book.state == TutorialBook.State.READING and not book.table_visible)
	book.request_close()
	await _until(func(): return not book.visible and hud.card_presentation._cards.size() == 1 and not hud.card_presentation._cards[0].disabled)
	_expect(book.seen_chapters.has(1) and book.last_chapter == 1, "Somente o capítulo fechado deve ser guardado como lido.")
	hud.card_presentation._cards[0].pressed.emit()
	await _until(func(): return player.input_enabled)
	var origin := player.current_cell
	await process_frame
	_expect(hud.book_button.visible, "O ícone do manual deve aparecer durante a gameplay.")
	await _click(hud.book_button.get_global_rect().get_center())
	await _until(func(): return book.state == TutorialBook.State.READING)
	_expect(paused and book.consultation, "Consultar durante o jogo deve pausar a prova e permitir ler.")
	_expect(book._displayed_chapter == 1, "O ícone deve reabrir o tutorial da fase atual.")
	book.turn_page(-1)
	await _until(func(): return book.state == TutorialBook.State.READING and book.table_visible)
	await create_timer(0.15, true, false, true).timeout
	_expect(player.current_cell == origin and book.table_visible, "Consultar números não deve consumir passos.")
	book.request_close()
	await _until(func(): return not paused and not book.visible)
	_expect(player.input_enabled and player.current_cell == origin, "Fechar a consulta deve retomar a mesma prova.")
	manager.start_phase(2)
	await _until(func(): return book.state == TutorialBook.State.TURNING)
	_expect(book.chapter_label.text == "FASE I", "Reabrir deve mostrar a página anterior antes de folhear.")
	# Change phase in mid-turn: the cancelled chapter must remain unread.
	manager.start_phase(3)
	await _until(func(): return book.state == TutorialBook.State.READING and book.current_chapter == 3)
	_expect(not book.seen_chapters.has(2) and book.needs_chapter(2), "Um capítulo interrompido não pode ser perdido.")
	_expect("linha reta" in book.body_label.text and "bispo" not in book.body_label.text.to_lower(), "O capítulo das torres deve explicar somente seu alcance.")
	_expect("número acima de cada torre" in book.body_label.text and "mesma na linha e na coluna" in book.body_label.text, "O numeral da torre deve explicar o mesmo deslocamento nas duas direções.")
	book.request_close()
	await _until(func(): return not book.visible and hud.card_presentation._cards.size() == 2)
	manager.restart_phase()
	await create_timer(0.3).timeout
	_expect(not book.visible, "Reiniciar um capítulo lido não deve repetir a apresentação.")
	manager.start_phase(6)
	await _until(func(): return book.state == TutorialBook.State.READING and trial.stage == BalanceTrialController.Stage.DECISION)
	var remaining := trial.remaining
	for step in range(6):
		book.turn_page(-1)
		await _until(func(): return book.state == TutorialBook.State.READING)
	_expect(book._displayed_chapter == 0 and book.table_visible, "A fase seis deve exigir folhear os seis capítulos para chegar à consulta inicial.")
	await create_timer(1.0).timeout
	_expect(is_equal_approx(trial.remaining, remaining) and not player.input_enabled and not trial.trial_hud.visible, "Ler a balança deve congelar o relógio e impedir movimentos.")
	_expect("lado leve" not in book.body_label.text.to_lower() and "coluna" not in book.body_label.text.to_lower(), "A balança não deve revelar a posição vencedora.")
	await _click(Vector2(20, 20))
	await _until(func(): return not book.visible)
	_expect(player.input_enabled and trial.trial_hud.visible and trial.process_mode != Node.PROCESS_MODE_DISABLED, "Fechar o livro deve liberar os cinco segundos da balança.")
	manager.restart_phase()
	await create_timer(0.15).timeout
	_expect(not book.visible, "Reiniciar a balança também deve respeitar o capítulo já lido.")
	trial.set_physics_process(false)
	for number in range(1, 7):
		book._set_chapter(number)
		for frame in range(12): await process_frame
		_expect(book.body_label.get_content_height() <= book.body_label.size.y, "O texto da fase %d deve caber integralmente antes do rodapé." % number)
		_expect(book.body_label.text == TutorialBook.Chapters.chapter(number).body, "A capitular não deve consumir ou alterar o texto da fase %d." % number)
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	for failure in failures: printerr("FALHA: " + failure)
	if failures.is_empty(): print("OK: livro, capítulos, consulta, pausa, cancelamento, reinício e relógio da balança.")
	quit(0 if failures.is_empty() else 1)


func _until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return true
		await process_frame
	failures.append("Tempo esgotado esperando o livro ou a prova.")
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _click(position: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.global_position = position
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
