extends SceneTree
## Aspecto real do menu ampliado, da estrela no piso e do caminho da fase 1.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(65.0, true).timeout.connect(func():
		printerr("QA: captura excedeu o tempo máximo")
		quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD") as GameHUD
	var board := main.get_node("World/Board") as Board3D
	var player := main.get_node("World/Player") as GridPlayer
	hud.tutorial_book.seen_chapters[1] = true
	main.start_test_phase(1)
	await _until(func(): return hud.card_presentation._cards.size() == 1 and not hud.card_presentation._cards[0].disabled)
	hud.card_presentation._cards[0].pressed.emit()
	await _until(func(): return is_instance_valid(board._tutorial_guide) and board._tutorial_guide.playing)
	await create_timer(1.9).timeout
	await _capture("stars_revealing")
	await _until(func(): return player.input_enabled)
	await _capture("starred_route")
	board.set_process(false)
	board._presentation_time = 0.0
	board._process(0.0)
	await create_timer(0.15).timeout
	await _capture("sanctuary_bright")
	board._process(Board3D.GLOW_PERIOD * 0.5)
	await create_timer(0.15).timeout
	await _capture("sanctuary_dim")
	board.set_process(true)
	var menu := main.get_node("PauseOverlay") as PauseOverlay
	menu._set_paused(true)
	await create_timer(0.55, true).timeout
	await _capture("pause_nearly_fullscreen")
	menu.phase_selector.show_popup()
	await process_frame
	await process_frame
	await _capture("pause_text_controls")
	menu.phase_selector.get_popup().hide()
	menu._set_paused(false)
	await _until(func(): return not paused)
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()


func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("QA: espera excedida")
	quit(1)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := "res://docs/previews/starred_guidance/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := folder + name + ".png"
	root.get_texture().get_image().save_png(path)
	print("QA: " + ProjectSettings.globalize_path(path))
