extends SceneTree
## Inspect the live Savage material up close without changing the gameplay camera.
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/previews/savage")
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	main.start_test_phase(105)
	await create_timer(2.6,false).timeout
	main.get_node("HUD").hide()
	main.get_node("SavageController").ui.canvas.hide()
	main.get_node("SavageController")._pieces.hide()
	var camera := Camera3D.new()
	main.get_node("World").add_child(camera)
	camera.position = Vector3(0,9,-8)
	camera.look_at(Vector3(0,3,-33))
	camera.fov = 55.0
	camera.current = true
	await create_timer(1.0,false).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/savage/queen_internal_embers.png")
	var frames: Array[Image] = []
	var started := Time.get_ticks_msec()
	var last_capture := -1.0
	while float(Time.get_ticks_msec()-started)/1000.0 < 5.0:
		await RenderingServer.frame_post_draw
		var elapsed := float(Time.get_ticks_msec()-started)/1000.0
		if elapsed-last_capture >= 1.0/24.0:
			frames.append(root.get_texture().get_image())
			last_capture = elapsed
	var folder := "res://.godot/qa/queen_ember_frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for index in range(frames.size()): frames[index].save_png(folder+"/frame_%04d.png" % index)
	FileAccess.open(folder+"/fps.txt",FileAccess.WRITE).store_string(str(frames.size()/5.0))
	FileAccess.open(folder+"/count.txt",FileAccess.WRITE).store_string(str(frames.size()))
	print("QUEEN_EMBERS_CAPTURE frames=",frames.size()," duration=5.0")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()
