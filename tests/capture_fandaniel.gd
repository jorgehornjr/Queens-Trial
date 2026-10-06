extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	root.add_child(world)
	var model := (load("res://scenes/player/fandaniel_animated_model.tscn") as PackedScene).instantiate()
	world.add_child(model)
	await process_frame
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 36
	camera.position = Vector3(2.2, 1.8, 4)
	camera.look_at(Vector3(0, 0.95, 0))
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.021, 0.032)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.7
	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	camera.environment = environment
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 1.3
	world.add_child(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.055, 0.062, 0.08)
	floor_mesh.material_override = material
	for clip in ["breathing_idle", "walk", "intro_arrival", "left_slide", "right_slide", "standing_death"]:
		model.animation_player.play(clip, 0.0)
		var length: float = model.animation_player.get_animation(clip).length
		for sample in [0.0, length * 0.5, length - 0.01]:
			model.animation_player.seek(sample, true)
			model.animation_player.advance(0.0)
			model.animation_player.pause()
			if clip == "standing_death":
				var focus: Vector3 = model.skeleton.to_global(model.skeleton.get_bone_global_pose(model.skeleton.find_bone("n_hara")).origin)
				camera.position = focus + Vector3(2.2, 1.8, 4)
				camera.look_at(focus)
			for frame in range(3): await process_frame
			await _capture("fandaniel_" + clip + "_%03d" % int(sample * 100))
	model.animation_player.play("breathing_idle", 0.0)
	model.animation_player.seek(0.0, true)
	model.animation_player.advance(0.0)
	model.animation_player.pause()
	camera.position = Vector3(0.40, 1.70, 1.4)
	camera.look_at(Vector3(0, 1.55, 0.1))
	camera.fov = 28
	for frame in range(3): await process_frame
	await _capture("fandaniel_face")
	model.animation_player.play("intro_arrival", 0.0)
	model.animation_player.seek(0.8, true)
	model.animation_player.advance(0.0)
	model.animation_player.pause()
	for amount in [0.0, 1.0]:
		model.set_cinematic_look_up(amount)
		for frame in range(3): await process_frame
		await _capture("fandaniel_gaze_%d" % int(amount))
	world.queue_free()
	await process_frame
	quit()

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/qa/ffxiv/"+filename+".png")
	print("FANDANIEL_CAPTURE: ", filename)
