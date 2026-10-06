extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var opening: OpeningCutscene = main.get_node("OpeningCutscene")
	for sample in [5.25, 10.5, 17.5]:
		while opening._elapsed < sample: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/qa/mixamo_opening_%04d.png" % int(sample*100))
		print("MIXAMO_OPENING_CAPTURE: ", sample)
	main.get_node("Music").stop()
	opening.skip()
	main.queue_free()
	await process_frame
	quit()
