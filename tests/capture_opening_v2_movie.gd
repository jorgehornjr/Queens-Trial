extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var opening: OpeningCutscene = main.get_node("OpeningCutscene")
	while opening._elapsed < OpeningCutscene.TOTAL_LENGTH * opening.duration_scale: await process_frame
	await create_timer(1.8).timeout
	main.get_node("HUD").card_presentation.cancel()
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	quit()
