extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var preview := (load("res://scenes/previews/fallen_priest_phase_six_preview.tscn") as PackedScene).instantiate()
	preview.character_scene = load("res://scenes/player/fallen_priest_animated_model.tscn") as PackedScene
	root.add_child(preview)
	await process_frame
	await process_frame
	var main: Node = preview.main
	var player := main.get_node("World/Player") as GridPlayer
	var model := player.get_node("Model")
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var book := (main.get_node("HUD") as GameHUD).tutorial_book
	await _until(func(): return book.state == TutorialBook.State.READING)
	book.request_close()
	await _until(func(): return not book.visible)
	_expect(main.get_node("PhaseManager").current_phase == 6, "A prévia deve abrir diretamente na fase seis.")
	_expect(not main.opening_cutscene._running, "A abertura deve ser pulada.")
	_expect(model.skeleton.get_bone_count() == 139, "O rig deve incluir corpo e 117 pontos da capa.")
	_expect(model.cape.points.size() == 117, "A capa deve ter a malha física completa.")
	for clip in ["left_slide", "right_slide", "left_fall", "right_fall", "left_recover", "right_recover", "walk", "breathing_idle", "intro_arrival", "standing_death"]:
		_expect(model.animation_player.has_animation(clip), "Animação ausente: " + clip)
	if await _until(func(): return trial.stage == BalanceTrialController.Stage.DECISION):
		player._try_move(Vector2i.LEFT)
		_expect(model.animation_player.current_animation == "walk", "Movimento pela grade deve usar o ciclo próprio de caminhada.")
		await _until(func(): return not player.movement_locked)
	var cloth_before: PackedVector3Array = model.cape.points.duplicate()
	paused = true
	for frame in range(12): await process_frame
	_expect(model.cape.points == cloth_before, "Pausar deve congelar a simulação da capa.")
	paused = false
	preview._toggle_camera()
	var left_delta := Vector3.ZERO
	for direction in [-1, 1]:
		preview.repeat_test(direction)
		_expect(preview._inspection_camera.current, "Repetir a queda deve preservar a câmera de inspeção selecionada.")
		if not await _until(func(): return trial.stage == BalanceTrialController.Stage.TILTING): break
		_expect(model.animation_player.current_animation == ("left_slide" if direction < 0 else "right_slide"), "O corpo deve reagir ao lado pesado.")
		var start: Vector3 = model.skeleton.to_local(model.cape.points[112])
		for frame in range(45): await physics_frame
		var end: Vector3 = model.skeleton.to_local(model.cape.points[112])
		var motion := end - start
		print("CAPE_DIAGNOSTIC: direction=", direction, " motion=", motion, " stretch=", model.cape.max_stretch_ratio(), " solver_usec=", model.cape.last_step_usec)
		_expect(motion.length() > 0.025, "A barra da capa deve mover-se em relação ao personagem.")
		if direction < 0: left_delta = motion
		else: _expect(absf(left_delta.x - motion.x) > 0.05, "As duas direções devem gerar reações distintas na capa.")
		_expect(model.cape.max_stretch_ratio() < 1.35, "A capa deve preservar comprimento durante o deslizamento.")
		if not await _until(func(): return trial.stage == BalanceTrialController.Stage.FALLING): break
		_expect(model.airborne and not model.cape.floor_enabled, "A capa deve liberar o piso ao sair da borda.")
		_expect(model.animation_player.current_animation == ("left_fall" if direction < 0 else "right_fall"), "A queda deve ter pose própria.")
		for frame in range(35): await physics_frame
		print("AIR_DIAGNOSTIC: direction=", direction, " stretch=", model.cape.max_stretch_ratio())
		_expect(model.cape.max_stretch_ratio() < 1.35, "A capa deve preservar comprimento também no ar.")
		for point in model.cape.points:
			_expect(point.is_finite(), "A simulação não pode gerar coordenadas inválidas.")
	main.get_node("PhaseManager").restart_phase()
	await process_frame
	await physics_frame
	_expect(not model.airborne and model.cape.floor_enabled, "Reiniciar deve limpar a queda e restaurar o piso.")
	# Survive all rounds with the same model and check the recovery transition.
	preview.repeat_test(0)
	for round_number in range(3):
		if not await _until(func(): return trial.stage == BalanceTrialController.Stage.DECISION and trial.round_index == round_number): break
		var safe_x := 0 if trial.heavy_direction > 0 else 4
		player.current_cell = Vector2i(safe_x, 4)
		player.position = main.get_node("World/Board").grid_to_world(player.current_cell) + Vector3.UP * player.surface_offset
		model.reset_platform_motion()
		trial.remaining = 0.1
		if not await _until(func(): return trial.stage == BalanceTrialController.Stage.RECOVERING): break
		_expect(model.animation_player.current_animation == "breathing_idle", "Sobreviver deve mesclar o Strafe do Mixamo de volta ao Idle.")
	if await _until(func(): return trial.stage == BalanceTrialController.Stage.COMPLETE):
		_expect(not player.platform_sliding and model.animation_player.current_animation == "breathing_idle", "Concluir deve restaurar a respiração e o controle do corpo.")
		await create_timer(0.45).timeout
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	await create_timer(0.12, true, false, true).timeout
	preview.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: " + failure)
	print("PRIEST_TEST_FAILURES: ", failures.size())
	var file := FileAccess.open("res://.godot/qa/priest_validation_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures": failures, "passed": failures.is_empty(), "scenarios": ["rig_and_weights", "walk", "pause", "left_slide_and_fall", "right_slide_and_fall", "restart", "three_round_recovery"]}, "\t"))
	file.close()
	quit(0 if failures.is_empty() else 1)

func _until(predicate: Callable) -> bool:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return true
		await process_frame
	failures.append("Tempo esgotado esperando o estado da fase 6.")
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
