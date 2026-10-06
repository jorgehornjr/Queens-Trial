extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	var world := Node3D.new()
	root.add_child(world)
	var model := (load("res://scenes/player/fallen_priest_animated_model.tscn") as PackedScene).instantiate() as Node3D
	world.add_child(model)
	await process_frame
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.current = true
	camera.fov = 36.0
	camera.position = Vector3(2.5, 1.8, 4.2)
	camera.look_at(Vector3(0, 1.05, 0))
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.018, 0.021, 0.032)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_energy = 0.7
	environment.glow_enabled = true
	environment.glow_intensity = 0.65
	environment.glow_bloom = 0.03
	camera.environment = environment
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-35, -35, 0)
	key.light_energy = 1.25
	world.add_child(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	floor_mesh.mesh = plane
	world.add_child(floor_mesh)
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.055, 0.062, 0.08)
	floor_mesh.material_override = floor_material
	var animation: AnimationPlayer = model.animation_player
	model.cape.floor_half_extent = 6.0
	for clip in ["breathing_idle", "walk", "intro_arrival", "left_slide", "right_slide", "standing_death"]:
		animation.play(clip, 0.0)
		var length := animation.get_animation(clip).length
		for sample in [0.0, length * 0.5, length - 0.01]:
			animation.seek(sample, true)
			animation.advance(0.0)
			animation.pause()
			if clip == "standing_death":
				var focus: Vector3 = model.skeleton.to_global(model.skeleton.get_bone_global_pose(model.skeleton.find_bone("Pelvis")).origin)
				camera.position = focus + Vector3(2.5, 1.8, 4.2)
				camera.look_at(focus)
			model.cape.reset_cloth()
			for frame in range(20): await physics_frame
			await _capture("mixamo_" + clip + "_%03d" % int(sample * 100))
	camera.position = Vector3(0.45, 2.02, 1.45)
	camera.look_at(Vector3(0, 1.96, 0.17))
	camera.fov = 29.0
	animation.play("breathing_idle", 0.0)
	animation.seek(0.0, true)
	animation.advance(0.0)
	animation.pause()
	for frame in range(10): await process_frame
	await _capture("mixamo_face_close")
	world.queue_free()
	await process_frame
	quit()

func _capture(filename: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/qa/" + filename + ".png")
	print("MIXAMO_CAPTURE: ", filename)
