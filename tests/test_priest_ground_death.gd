extends SceneTree

var failures := PackedStringArray()
var finished := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	preload("res://tests/fixtures/priest_model.gd").replace(main.get_node("World/Player"))
	root.add_child(main)
	await process_frame
	main.start_test_phase(6)
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var book := (main.get_node("HUD") as GameHUD).tutorial_book
	while book.state != TutorialBook.State.READING: await process_frame
	book.request_close()
	while book.visible: await process_frame
	while trial.stage != BalanceTrialController.Stage.DECISION: await process_frame
	trial.set_physics_process(false)
	var player := main.get_node("World/Player") as GridPlayer
	var model := player.get_node("Model")
	var skeleton: Skeleton3D = model.skeleton
	var floor_y := player.global_position.y - player.surface_offset
	var start_head := _bone_world(skeleton, "Head").y
	var start_cell := player.current_cell
	var start_position := player.global_position
	_finish_death(player)
	var started := Time.get_ticks_msec()
	await create_timer(0.8).timeout
	_expect(model.animation_player.current_animation == "standing_death" and player.movement_locked and not player.input_enabled, "A morte deve usar o clipe próprio e bloquear o movimento.")
	_expect(_bone_world(skeleton, "Head").y < start_head - 0.15, "A reação de morte do Mixamo deve começar a baixar o corpo.")
	var deadline := Time.get_ticks_msec() + 6000
	while not finished and Time.get_ticks_msec() < deadline: await process_frame
	_expect(finished and Time.get_ticks_msec() - started >= 3600, "A morte deve aguardar os 3,67 segundos do clipe completo do Mixamo.")
	for bone_name in ["Pelvis", "Chest", "Head", "Hand_L", "Hand_R"]:
		var point := _bone_world(skeleton, bone_name)
		print("DEATH_CONTACT: ", bone_name, " height=", point.y-floor_y)
		_expect(point.y-floor_y < 0.8 and point.y-floor_y > -0.2, "A pose final deve acomodar " + bone_name + " junto ao piso.")
	_expect(player.current_cell == start_cell and player.global_position.is_equal_approx(start_position), "A morte não deve deslocar a célula lógica nem a raiz do jogador.")
	for point in model.cape.points: _expect(point.is_finite(), "A capa deve manter coordenadas finitas durante a morte.")
	_expect(model.cape.max_stretch_ratio() < 1.35, "A capa deve conservar o comprimento sobre o corpo caído.")
	main.get_node("PhaseManager").restart_phase()
	await process_frame
	await physics_frame
	_expect(model.animation_player.current_animation == "breathing_idle" and not player.movement_locked and not model.airborne, "Reiniciar deve recuperar a pose em pé e limpar o estado da morte.")
	while trial.stage != BalanceTrialController.Stage.DECISION: await process_frame
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	await create_timer(0.12, true, false, true).timeout
	main.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: ", failure)
	print("PRIEST_DEATH_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _finish_death(player: GridPlayer) -> void:
	await player.play_death_animation()
	finished = true

func _bone_world(skeleton: Skeleton3D, bone_name: String) -> Vector3:
	return skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
