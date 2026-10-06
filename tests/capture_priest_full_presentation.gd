extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var cutscene := main.get_node("OpeningCutscene") as OpeningCutscene
	for sample in [2.6, 7.8, OpeningCutscene.ENTRY_START, OpeningCutscene.ENTRY_START + 1.45, OpeningCutscene.ENTRY_START + 6.2, OpeningCutscene.ENTRY_START + 9.0, OpeningCutscene.QUEEN_REVEAL + 0.7, OpeningCutscene.QUEEN_CLOSE + 0.9, OpeningCutscene.TOTAL_LENGTH - 0.2]:
		while cutscene._elapsed < sample: await process_frame
		await _capture("priest_opening_%04d" % int(sample * 100))
	main.start_test_phase(6)
	main.get_node("Music").stop()
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	trial.set_physics_process(false)
	main.get_node("World/CelestialSpace").hide()
	main.get_node("World/Seraph").hide()
	main.get_node("World/Board/LevitationMist").hide()
	main.get_node("HUD").hide()
	var player := main.get_node("World/Player") as GridPlayer
	var model := player.get_node("Model")
	var camera := Camera3D.new()
	main.get_node("World").add_child(camera)
	camera.current = true
	camera.fov = 40
	camera.position = player.global_position + Vector3(3.8, 3.3, -8.0)
	camera.look_at(player.global_position + Vector3.UP * 2.0)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.04, 0.045, 0.06)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.8
	camera.environment = environment
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, 140, 0)
	key.light_energy = 1.2
	main.get_node("World").add_child(key)
	player.platform_sliding = true
	for clip in ["walk", "left_slide", "right_slide", "left_fall", "standing_death"]:
		player.reset_to_start()
		player.platform_sliding = true
		model.animation_player.play(clip, 0.0)
		var clip_start := Time.get_ticks_msec()
		for sample in [0.35, 0.85, 1.30, 2.2]:
			while Time.get_ticks_msec() - clip_start < int(sample * 1000):
				await process_frame
			await _capture("priest_pose_"+clip+"_%03d" % int(sample*100))
	main.queue_free()
	await process_frame
	await process_frame
	quit()

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/qa/"+filename+".png")
	print("PRIEST_PRESENTATION_CAPTURE: ", filename)
