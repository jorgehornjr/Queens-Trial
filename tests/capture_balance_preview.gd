extends SceneTree
## Rendered QA capture; does not change the campaign or saved initial phase.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var player := main.get_node("World/Player") as GridPlayer
	(main.get_node("HUD") as GameHUD).tutorial_book.seen_chapters[6] = true
	# Fixed QA seed only: gameplay calls randomize() and draws anew each round.
	trial._weight_rng.seed = 142026
	manager.start_phase(6)
	await create_timer(0.55).timeout
	await _capture("globe_dissolve")
	await create_timer(1.15).timeout
	await _capture("scales_materialize")
	for round_number in range(3):
		if round_number == 2:
			await _until(func(): return trial.stage == BalanceTrialController.Stage.MALFUNCTION)
			await _capture_malfunction()
		await _until(func(): return trial.stage == BalanceTrialController.Stage.DECISION and trial.round_index == round_number)
		await create_timer(1.0).timeout
		await _capture(["balance_decision", "balance_second_round", "balance_hidden_round"][round_number])
		print("QA_ROUND: ", round_number + 1, " weights ", trial.left_weight, " / ", trial.right_weight, " angle ", trial._queen.balance.weight_angle)
		if round_number == 2: break
		var safe_x := 0 if trial.heavy_direction > 0 else 4
		while player.current_cell.x != safe_x:
			player._try_move(Vector2i.LEFT if safe_x < player.current_cell.x else Vector2i.RIGHT)
			await _until(func(): return not player.movement_locked)
		await _until(func(): return trial.stage == BalanceTrialController.Stage.TILTING)
		if round_number == 0:
			await create_timer(0.90).timeout
			await _capture("balance_tilt")
	var menu := main.get_node("PauseOverlay") as PauseOverlay
	menu._set_paused(true)
	await create_timer(0.9).timeout
	await _capture("pause_phase_selector")
	menu.phase_selector.show_popup()
	await create_timer(0.2).timeout
	await _capture("pause_phase_options")
	menu.phase_selector.get_popup().hide()
	await menu._close_sheet()
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()

func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("QA_TIMEOUT: balance state did not arrive")
	quit(1)

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/qa")
	var path := "res://.godot/qa/%s.png" % filename
	root.get_texture().get_image().save_png(path)
	print("QA: " + ProjectSettings.globalize_path(path))
	if filename == "balance_hidden_round":
		DirAccess.make_dir_recursive_absolute("res://docs/previews/balance")
		root.get_texture().get_image().save_png("res://docs/previews/balance/round_3_unknown.png")

func _capture_malfunction() -> void:
	var folder := "res://docs/previews/balance/malfunction/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var frames: Array[Image] = []
	var clock_start := Time.get_ticks_msec()
	var elapsed := 0.0
	var next_capture := 0.0
	while elapsed < QueenBalance.MALFUNCTION_DURATION + 0.7:
		await RenderingServer.frame_post_draw
		elapsed = (Time.get_ticks_msec() - clock_start) / 1000.0
		if elapsed >= next_capture:
			frames.append(root.get_texture().get_image())
			next_capture = elapsed + 1.0 / 24.0
	for index in range(frames.size()): frames[index].save_png(folder + "%03d.png" % index)
	var report := FileAccess.open(folder + "timing.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"frames": frames.size(), "duration": elapsed, "fps": frames.size() / elapsed}))
	report.close()
	print("QA_MALFUNCTION: ", frames.size(), " frames in ", elapsed)
