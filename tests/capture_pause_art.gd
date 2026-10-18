extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1600, 900)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	main.start_test_phase(8)
	await create_timer(5.6).timeout
	var pause_menu := main.get_node("PauseOverlay") as PauseOverlay
	pause_menu._set_paused(true)
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://docs/previews/pause_menu")
	root.get_texture().get_image().save_png("res://docs/previews/pause_menu/watercolor_pause.png")
	pause_menu.phase_selector.get_popup().hide()
	paused = false
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	print("PAUSE_WATERCOLOR_CAPTURED")
	quit()
