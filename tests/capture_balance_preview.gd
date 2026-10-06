extends SceneTree
## Rendered QA capture; does not change the campaign or saved initial phase.

func _initialize() -> void:
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
	(main.get_node("HUD") as GameHUD).tutorial_book.seen_chapters[6] = true
	manager.start_phase(6)
	await create_timer(0.55).timeout
	await _capture("globe_dissolve")
	await create_timer(1.15).timeout
	await _capture("scales_materialize")
	while trial.stage != BalanceTrialController.Stage.DECISION:
		await process_frame
	await create_timer(1.2).timeout
	await _capture("balance_decision")
	player._try_move(Vector2i.RIGHT)
	while player.movement_locked:
		await process_frame
	player._try_move(Vector2i.RIGHT)
	while trial.stage != BalanceTrialController.Stage.TILTING:
		await process_frame
	await create_timer(0.95).timeout
	await _capture("balance_tilt")
	while trial.stage != BalanceTrialController.Stage.DECISION:
		await process_frame
	await create_timer(1.0).timeout
	await _capture("balance_right_heavy")
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
	await create_timer(0.05).timeout
	main.queue_free()
	await process_frame
	quit()


func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/qa")
	var path := "res://.godot/qa/%s.png" % filename
	root.get_texture().get_image().save_png(path)
	print("QA: " + ProjectSettings.globalize_path(path))
