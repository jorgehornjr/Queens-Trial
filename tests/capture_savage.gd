extends SceneTree
## Actual Forward+ render of the new encounter; no saved progress is changed.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1920,1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	main.start_test_phase(105)
	await create_timer(1.0,false).timeout
	await _capture("savage_banner")
	var trial: SavageController = main.get_node("SavageController")
	var cards: CardPresentation = main.get_node("HUD").card_presentation
	await _until(func(): return cards.visible and cards._cards.size() == 2 and not cards._cards[0].disabled)
	await _capture("savage_cards")
	for card in cards._cards: card.pressed.emit()
	await create_timer(0.7,false).timeout
	await _capture("savage_cards_revealed")
	await _until(func(): return trial.stage == SavageController.Stage.PREPARATION)
	await create_timer(1.4,false).timeout
	await _capture("savage_preparation")
	# Record the actual ten-second preparation, including its live countdown.
	var frames: Array[Image] = []
	var started := Time.get_ticks_msec()
	var last_capture := -1.0
	while float(Time.get_ticks_msec()-started)/1000.0 < 5.0:
		await RenderingServer.frame_post_draw
		var elapsed := float(Time.get_ticks_msec()-started)/1000.0
		if elapsed - last_capture >= 1.0/24.0:
			frames.append(root.get_texture().get_image())
			last_capture = elapsed
	var folder := "res://.godot/qa/savage_frames"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for index in range(frames.size()): frames[index].save_png(folder+"/frame_%04d.png" % index)
	FileAccess.open(folder+"/fps.txt",FileAccess.WRITE).store_string(str(frames.size()/5.0))
	FileAccess.open(folder+"/count.txt",FileAccess.WRITE).store_string(str(frames.size()))
	print("SAVAGE_CAPTURE frames=",frames.size()," duration=5.0")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()

func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec()+20000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	quit(1)

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/previews/savage"))
	root.get_texture().get_image().save_png("res://docs/previews/savage/%s.png" % filename)
	print("QA: ",filename)
