extends SceneTree

const Trial = preload("res://scripts/gameplay/balance_trial_controller.gd")
var failures := PackedStringArray()


func _initialize() -> void:
	# Cloth and render-driven mist must be observed at their real cadence.
	Engine.time_scale = 1.0
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var player := main.get_node("World/Player") as GridPlayer
	var board := main.get_node("World/Board") as Board3D
	var queen := main.get_node("World/Seraph") as Node3D
	var audio := main.get_node("GameAudio") as GameAudio
	var mist := board.get_node("LevitationMist")
	manager.start_phase(6)
	_expect(trial.stage == Trial.Stage.TRANSITION and not player.input_enabled, "A transformação deve preceder a decisão.")
	var book := (main.get_node("HUD") as GameHUD).tutorial_book
	await _until(func(): return book.state == TutorialBook.State.READING)
	book.request_close()
	await _until(func(): return not book.visible)
	if not await _until(func(): return trial.stage == Trial.Stage.DECISION):
		return _finish(main)
	_expect(not board._safe_spot_marker.visible, "A fase seis não deve ter safe spot.")
	_expect(mist.get_node("NebulaVolume").visible and mist.get_node("VolumetricMist").visible and mist.get_node_or_null("EdgeMist") == null, "A balança deve usar a névoa original, sem o efeito azul substituto.")
	_expect(mist._follow_tilt and mist.top_level, "Na fase seis a nuvem deve acompanhar a plataforma com movimento independente.")
	_expect(not main.get_node("HUD").announcement.visible and not main.get_node("HUD").result_panel.visible, "A prova deve começar sem textos de feedback.")
	_expect(not main.get_node("World/BoardCamera").horizontal_orbit_enabled, "A câmera frontal deve preservar a correspondência das cartas laterais.")
	_expect(main.get_node("PhaseLoopController")._piece_root == null, "A balança não deve criar inimigos das fases comuns.")
	_expect(queen.balance.visible and not queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb").visible, "A balança deve substituir o globo após a dissolução.")
	_expect(trial.trial_hud.left_card.texture == BalanceHUD.CARDS[3] and trial.trial_hud.right_card.texture == BalanceHUD.CARDS[0], "As duas cartas precisam corresponder aos pesos da primeira rodada.")
	var animation := player.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_expect(animation.has_animation("left_slide") and animation.has_animation("right_slide"), "As duas reações próprias do sacerdote precisam estar no rig.")
	# Pause both the countdown and weight cue while the pause overlay is open.
	paused = true
	var before := trial.remaining
	for frame in range(12):
		await process_frame
	_expect(is_equal_approx(before, trial.remaining), "Pausar deve congelar os cinco segundos.")
	paused = false
	for round_number in range(3):
		if not await _until(func(): return trial.stage == Trial.Stage.DECISION and trial.round_index == round_number):
			break
		var safe_x := 0 if trial.heavy_direction > 0 else 4
		while player.current_cell.x != safe_x:
			player._try_move(Vector2i.LEFT if safe_x < player.current_cell.x else Vector2i.RIGHT)
			if not await _until(func(): return not player.movement_locked):
				break
		if not await _until(func(): return trial.stage == Trial.Stage.TILTING):
			break
		_expect(player.platform_sliding and not player.input_enabled, "A resolução deve bloquear input e iniciar deslizamento.")
		_expect(trial.stardust.flow_direction == trial.heavy_direction, "O pó estelar deve seguir a mesma direção do deslizamento.")
		_expect(trial.stardust.screen_dust.flow_direction == trial.heavy_direction and not trial.stardust.screen_dust._motes.is_empty(), "A poeira da tela deve começar junto ao piso, na mesma direção.")
		var wind: AudioStream = GameAudio.SOUNDS[&"balance_slide_right" if trial.heavy_direction > 0 else &"balance_slide_left"]
		var wind_playing := false
		for voice in audio._voices:
			if voice.stream == wind and voice.playing:
				wind_playing = true
		_expect(wind_playing, "O vento direcional deve começar junto ao deslizamento.")
		_expect(animation.current_animation == ("right_slide" if trial.heavy_direction > 0 else "left_slide"), "A tentativa de apoio deve acompanhar o lado pesado.")
		if not await _until(func(): return trial.stage == Trial.Stage.RECOVERING):
			break
		_expect(signf(board.rotation.z) == -trial.heavy_direction, "O lado pesado deve ficar mais baixo.")
		_expect(signf(mist.global_rotation.z) == signf(board.rotation.z) and absf(mist.global_rotation.z) < absf(board.rotation.z) * 0.65, "A nuvem deve seguir a inclinação de forma parcial e suave.")
		_expect(signf(queen.balance.weight_angle) == -trial.heavy_direction, "Balança e tabuleiro devem indicar o mesmo lado pesado.")
		_expect(player.global_position.is_equal_approx(board.to_global(player.platform_local_position)), "O jogador deve tocar a plataforma inclinada.")
		_expect(trial.stardust.strength > 0.9, "O efeito dourado deve estar ativo ao terminar o deslizamento.")
		_expect(trial.stardust.screen_dust.visible and is_equal_approx(trial.stardust.screen_dust.strength, trial.stardust.strength), "Piso e tela devem compartilhar a intensidade e dissipação.")
	if await _until(func(): return trial.stage == Trial.Stage.COMPLETE):
		_expect(is_zero_approx(board.rotation.z) and not player.platform_sliding, "A conclusão deve deixar o tabuleiro nivelado.")
		_expect(not main.get_node("HUD").announcement.visible, "Concluir a balança não deve mostrar anúncio escrito.")
	await _until(func(): return not main.get_node("HUD").announcement.visible)
	# Center is unsafe: the physical slide must carry it over the low edge.
	manager.restart_phase()
	await _until(func(): return trial.stage == Trial.Stage.DECISION)
	await _until(func(): return trial.stage == Trial.Stage.FALLING)
	_expect(absf(player.platform_local_position.x) > board.tile_size * 2.5, "Falhar exige atravessar a borda pelo deslizamento.")
	_expect(not main.get_node("HUD").result_panel.visible, "Cair não deve mostrar texto de falha.")
	await _until(func(): return trial.stage == Trial.Stage.DECISION)
	_expect(player.current_cell == player.starting_cell and not player.platform_sliding and is_zero_approx(board.rotation.z), "A falha deve reiniciar jogador, física, rodada e inclinação.")
	# Stop a partially completed keypress at the deadline, then restart mid-tilt.
	trial.remaining = 0.16
	player._try_move(Vector2i.LEFT)
	await _until(func(): return trial.stage == Trial.Stage.TILTING)
	_expect(player.platform_local_position.x > -board.tile_size and player.platform_local_position.x < 0, "O prazo deve preservar a posição real do passo incompleto.")
	manager.restart_phase()
	await _until(func(): return trial.stage == Trial.Stage.DECISION)
	_expect(trial.round_index == 0 and is_zero_approx(board.rotation.z), "R durante a inclinação não deve deixar callbacks antigos ativos.")
	_expect(trial.stardust.flow_direction == 0 and is_zero_approx(trial.stardust.strength), "Reiniciar deve apagar o fluxo de partículas anterior.")
	_expect(not trial.stardust.screen_dust.visible and trial.stardust.screen_dust._motes.is_empty(), "Reiniciar deve apagar também as partículas da tela.")
	# Interrupt the ritual too; later phases should restore the existing globe.
	manager.start_phase(5)
	await _until(func(): return queen.balance.reveal < 0.6)
	manager.start_phase(6)
	await _until(func(): return trial.stage == Trial.Stage.DECISION)
	_expect(queen.balance.visible and queen.balance.reveal > 0.99, "Reverter uma dissolução precisa recuperar a balança inteira.")
	manager.start_phase(7)
	await _until(func(): return not queen.balance.visible)
	var orb := queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb") as Node3D
	_expect(orb.visible and is_equal_approx(orb.ritual_reveal, 1.0) and not trial.trial_hud.visible, "Ao sair da fase seis, o globo e a composição anterior devem retornar.")
	_expect(mist.get_node("NebulaVolume").visible and mist.get_node("VolumetricMist").visible and not mist._follow_tilt and not mist.top_level and mist.transform.is_equal_approx(mist._rest_transform), "Sair da balança deve restaurar a posição e comportamento original da névoa.")
	_finish(main)


func _until(predicate: Callable, seconds := 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if predicate.call():
			return true
		await process_frame
	failures.append("Tempo esgotado esperando estado da balança.")
	return false


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish(main: Node) -> void:
	paused = false
	main.get_node("Music").stop()
	await create_timer(0.05).timeout
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	for failure in failures:
		printerr("FALHA: " + failure)
	if failures.is_empty():
		print("OK: balança, três rodadas, deslizamento, queda, pausa, reinício e retorno do globo.")
	quit(0 if failures.is_empty() else 1)
