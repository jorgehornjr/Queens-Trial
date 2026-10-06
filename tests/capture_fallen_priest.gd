extends SceneTree

func _initialize() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	call_deferred("_run")

func _run() -> void:
	var preview := (load("res://scenes/previews/fallen_priest_phase_six_preview.tscn") as PackedScene).instantiate()
	preview.character_scene = load("res://scenes/player/fallen_priest_animated_model.tscn") as PackedScene
	root.add_child(preview)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var main: Node = preview.main
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	var player := main.get_node("World/Player") as GridPlayer
	var model := player.get_node("Model")
	await create_timer(3.5).timeout
	main.get_node("Music").stop()
	await _capture("priest_phase_six")
	# A close camera follows the real character to inspect deformation in engine.
	var camera := Camera3D.new()
	camera.fov = 40
	main.get_node("World").add_child(camera)
	camera.current = true
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.04, 0.055)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.8, 0.85, 1.0)
	environment.ambient_light_energy = 0.8
	camera.environment = environment
	# Keep tracking even while a capture awaits the next rendered frame.
	var track_camera := func():
		if is_instance_valid(camera) and is_instance_valid(player):
			camera.global_position = player.global_position + Vector3(3.4, 3.6, 8.0)
			camera.look_at(player.global_position + Vector3.UP * 2.2)
	process_frame.connect(track_camera)
	main.get_node("World/CelestialSpace").hide()
	main.get_node("World/Seraph").hide()
	main.get_node("World/Board/LevitationMist").hide()
	main.get_node("HUD").hide()
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 1.3
	main.get_node("World").add_child(key)
	for direction in [-1, 1]:
		preview.repeat_test(direction)
		while trial.stage != BalanceTrialController.Stage.TILTING: await process_frame
		camera.make_current()
		var side := "left" if direction < 0 else "right"
		var sample := 0
		var frame := 0
		var slide_captured := false
		var fall_started := -1
		var fall_captured := false
		DirAccess.make_dir_recursive_absolute("res://.godot/qa/priest_"+side+"_frames")
		while trial.stage in [BalanceTrialController.Stage.TILTING, BalanceTrialController.Stage.RECOVERING, BalanceTrialController.Stage.FALLING]:
			await process_frame
			camera.global_position = player.global_position + Vector3(3.4, 3.6, 8.0)
			camera.look_at(player.global_position + Vector3.UP * 2.2)
			if frame % 3 == 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://.godot/qa/priest_"+side+"_frames/%03d.png" % sample)
				sample += 1
			if trial.stage == BalanceTrialController.Stage.TILTING and model.animation_player.current_animation_position > 0.65 and not slide_captured:
				slide_captured = true
				await _capture("priest_"+side+"_slide")
			if trial.stage == BalanceTrialController.Stage.FALLING:
				if fall_started < 0: fall_started = Time.get_ticks_msec()
				if Time.get_ticks_msec()-fall_started > 350 and not fall_captured:
					fall_captured = true
					await _capture("priest_"+side+"_fall")
			frame += 1
		print("PRIEST_CAPTURE ", side, " samples=",sample," stretch=",model.cape.max_stretch_ratio()," solver_usec=",model.cape.last_step_usec)
	process_frame.disconnect(track_camera)
	preview.queue_free()
	await process_frame
	quit()

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/qa/"+filename+".png")
