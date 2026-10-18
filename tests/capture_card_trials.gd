extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/previews/card_trials"))
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var trial := main.get_node("CardTrialController") as CardTrialController
	manager.start_phase(7, 1207)
	await create_timer(trial.space_transition.duration + 0.8).timeout
	await _capture("phase_7_ascending")
	var point := trial.table.hand.card_point(20)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	await create_timer(0.3).timeout
	await _capture("phase_7_hover")
	for index in range(6):
		if index != trial.state.anchor_index:
			trial._drop(index, trial.state.anchor_value + index - trial.state.anchor_index)
	await create_timer(0.3).timeout
	await _capture("phase_7_filled")
	trial._submit()
	trial._continue()
	await create_timer(0.3).timeout
	await _capture("phase_7_descending")
	manager.start_phase(8, 1208)
	await create_timer(0.3).timeout
	await _capture("phase_8_matching")
	for index in range(3): trial._drop(index, trial.state.targets[index])
	trial._submit()
	trial._continue()
	await create_timer(0.3).timeout
	await _capture("phase_8_decree")
	var slot := trial.table.slots[trial.state.false_index]
	motion = InputEventMouseMotion.new()
	motion.position = slot.get_global_rect().get_center()
	motion.global_position = motion.position
	root.push_input(motion, true)
	await create_timer(0.2).timeout
	await _capture("phase_8_false_hover")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	print("CAPTURED: phase 7 order/hover, phase 8 matching/decree.")
	quit()

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/card_trials/%s.png" % name)
