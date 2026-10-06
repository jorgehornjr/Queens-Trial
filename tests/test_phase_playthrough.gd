extends SceneTree

const EditoMachine = preload("res://scripts/gameplay/edito_state_machine.gd")
const Constants = preload("res://scripts/core/game_constants.gd")
const CARD_BACK = preload("res://assets/cards/back.png")

var failures := PackedStringArray()

const ROUTES := {
	1: [[Vector2i.LEFT, Vector2i.LEFT, Vector2i.UP, Vector2i.UP]],
	2: [[Vector2i.LEFT, Vector2i.LEFT], [Vector2i.RIGHT, Vector2i.RIGHT, Vector2i.RIGHT]],
	3: [[Vector2i.DOWN, Vector2i.DOWN], [Vector2i.LEFT, Vector2i.LEFT, Vector2i.UP, Vector2i.UP]],
	4: [[Vector2i.DOWN, Vector2i.DOWN], [Vector2i.LEFT, Vector2i.LEFT, Vector2i.UP, Vector2i.UP]],
	5: [[Vector2i.LEFT, Vector2i.DOWN, Vector2i.DOWN], [Vector2i.LEFT, Vector2i.UP, Vector2i.UP, Vector2i.UP]],
}


func _initialize() -> void:
	Engine.time_scale = 10.0
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.set("opening_cutscene_enabled", false)
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var controller := main.get_node("PhaseLoopController") as PhaseLoopController
	var player := main.get_node("World/Player") as GridPlayer
	var hud := main.get_node("HUD") as GameHUD
	var presentation := hud.card_presentation
	manager.start_phase(1)

	for phase_number in range(1, 6):
		if not await _wait_until(func(): return hud.tutorial_book.state == TutorialBook.State.READING):
			failures.append("O capítulo da fase %d não abriu." % phase_number)
			break
		hud.tutorial_book.request_close()
		var expected_card_count: int = 1 if phase_number == 1 else 2
		if not await _wait_until(func():
			return manager.current_phase == phase_number and presentation._cards.size() == expected_card_count and not presentation._cards[0].disabled
		):
			failures.append("As cartas da fase %d não ficaram prontas para clique." % phase_number)
			break
		if expected_card_count == 2 and presentation._cards[0].position.x >= presentation._cards[1].position.x:
			failures.append("As duas cartas devem aparecer lado a lado.")
		for card in presentation._cards:
			if card.texture_normal != CARD_BACK:
				failures.append("Cada carta deve começar pelo verso.")
			card.pressed.emit()
		if not await _wait_until(func(): return manager.current_phase == phase_number and player.input_enabled):
			failures.append("A fase %d não liberou o jogador." % phase_number)
			break
		if presentation.visible or hud.get_node_or_null("RoundEdicts") != null:
			failures.append("Os valores não devem permanecer na HUD após a queima.")
		var phase_routes: Array = ROUTES[phase_number]
		var sides := {}
		var expected_piece_count := 0
		for definitions in controller._current_phase_data.get("piece_waves", []):
			for definition in definitions:
				expected_piece_count += 1
				if sides.has(definition.side):
					failures.append("Não pode haver duas peças na mesma borda, mesmo em ondas diferentes.")
				sides[definition.side] = true
		if phase_number >= 4 and sides.size() != 4:
			failures.append("As fases com quatro peças devem utilizar as quatro bordas.")
		if controller._piece_root.get_child_count() != expected_piece_count:
			failures.append("Todas as peças declaradas devem existir no tabuleiro.")
		for wave in controller._waves:
			if wave.size() == 2 and wave[0].move_value == wave[1].move_value:
				failures.append("A fase %d deve ter valores independentes por peça." % phase_number)
			for piece in wave:
				if piece.edge_steps != piece.move_value:
					failures.append("A peça deve deslocar o mesmo valor na borda e para dentro.")
				if piece.get_node("RomanNumeral").text != str(Constants.to_roman(piece.move_value)):
					failures.append("Numeral da peça não corresponde ao deslocamento.")
		for edict_index in range(phase_routes.size()):
			for direction in phase_routes[edict_index]:
				player._try_move(direction)
				if not await _wait_until(func(): return not player.movement_locked):
					failures.append("Movimento travou na fase %d." % phase_number)
					break
			if edict_index < phase_routes.size() - 1:
				if not await _wait_until(func():
					return controller._edito_machine.indice_edito_atual == edict_index + 1 and player.input_enabled
				):
					failures.append("O próximo édito não abriu na fase %d." % phase_number)
		if not await _wait_until(func(): return controller._edito_machine.estado_atual == EditoMachine.Estado.FINALIZADO):
			failures.append("A fase %d não concluiu." % phase_number)
		if hud.announcement_label.text != "FASE CONCLUÍDA" or not hud.announcement.visible or hud.result_panel.visible:
			failures.append("A conclusão deve usar o anúncio de poeira, sem painel.")
		if phase_number < 5:
			if not await _wait_until(func(): return manager.current_phase == phase_number + 1):
				failures.append("A fase %d não avançou após a rota válida." % phase_number)
		else:
			if not await _wait_until(func(): return not hud.announcement.visible):
				failures.append("A última fase deve terminar a animação de conclusão.")
			if not await _wait_until(func(): return manager.current_phase == 6):
				failures.append("A conclusão da fase cinco deve abrir a fase da balança.")

	if manager.current_phase == 6:
		await _wait_until(func(): return hud.tutorial_book.state == TutorialBook.State.READING)
		hud.tutorial_book.request_close()
		await _wait_until(func(): return main.get_node("BalanceTrialController").stage == BalanceTrialController.Stage.DECISION)
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("OK: fases 1 a 5 concluídas com movimento, pares e ataques reais.")
		quit(0)
		return
	for failure in failures:
		printerr("FALHA: " + failure)
	quit(1)


func _wait_until(predicate: Callable, limit := 900) -> bool:
	for _frame in range(limit):
		if predicate.call():
			return true
		await process_frame
	return false
