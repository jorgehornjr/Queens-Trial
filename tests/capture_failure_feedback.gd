extends SceneTree
## Real rendered previews for the correction and unobstructed balance arrival.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	create_timer(55.0, true).timeout.connect(func(): quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD") as GameHUD
	hud.tutorial_book.seen_chapters[3] = true
	main.phase_manager.start_phase(3, 171026)
	await create_timer(0.5).timeout
	hud.card_presentation.cancel()
	await process_frame
	await process_frame
	main.get_node("PhaseLoopController")._on_falha(["A carta IV pedia uma distância de 4 casas.\nVocê terminou a 2 casas do ponto de partida.", "Uma peça atacou a casa onde você parou."])
	await create_timer(0.6).timeout
	await _capture("correction_720")
	root.size = Vector2i(1920, 1080)
	await create_timer(0.2).timeout
	await _capture("correction_1080")
	root.size = Vector2i(1280, 720)
	main.phase_manager.start_phase(6)
	await create_timer(0.65).timeout
	assert(not hud.tutorial_book.visible)
	await _capture("globe_before_book")
	await create_timer(1.3).timeout
	assert(not hud.tutorial_book.visible)
	await _capture("scales_before_book")
	while hud.tutorial_book.state != TutorialBook.State.READING: await process_frame
	await _capture("book_after_scales")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	quit()

func _capture(name: String) -> void:
	var folder := "res://tmp/feedback_review/"
	DirAccess.make_dir_recursive_absolute(folder)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder + name + ".png")
	print("FEEDBACK_CAPTURE: ", name)
