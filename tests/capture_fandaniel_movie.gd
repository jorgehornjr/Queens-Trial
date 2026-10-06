extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await create_timer(OpeningCutscene.ENTRY_START + 9.5).timeout
	main.get_node("Music").stop()
	main.get_node("OpeningCutscene").skip()
	main.queue_free()
	await process_frame
	quit()
