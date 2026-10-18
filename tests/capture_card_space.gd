extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(960, 540)
	root.content_scale_size = Vector2i(1920, 1080)
	var folder := "res://docs/previews/card_trials/passage/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	main.get_node("OpeningCutscene").skip()
	main.get_node("World/BoardCamera").enter_gameplay(true)
	await create_timer(2.0).timeout
	# Reproduce the accumulated-time case that previously made the blue flow jump.
	main.get_node("World/CelestialSpace").set_effect_time(180.0)
	await process_frame
	var trial := main.get_node("CardTrialController") as CardTrialController
	main.get_node("PhaseManager").start_phase(7, 1207)
	var frames: Array[Image] = []
	var next_capture := 0.0
	var elapsed := 0.0
	var clock_start := Time.get_ticks_msec()
	while elapsed < trial.space_transition.duration + 1.0:
		await RenderingServer.frame_post_draw
		elapsed = (Time.get_ticks_msec() - clock_start) / 1000.0
		if elapsed >= next_capture:
			frames.append(root.get_texture().get_image())
			next_capture = elapsed + 1.0 / 24.0
	# Encode PNGs after the shot so disk compression does not stall the animation.
	for index in range(frames.size()): frames[index].save_png(folder + "%03d.png" % index)
	var report := FileAccess.open(folder + "timing.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"frames": frames.size(), "duration": elapsed, "fps": frames.size() / elapsed}))
	report.close()
	print("PASSAGE_CAPTURED: ", frames.size(), " frames, ", elapsed, " seconds; only sky: ", trial.space_transition.in_space)
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()
