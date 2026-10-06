extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var preview := (load("res://scenes/previews/archangel_rig_preview.tscn") as PackedScene).instantiate()
	root.add_child(preview)
	await process_frame
	await create_timer(0.5).timeout
	await _capture("archangel_godot_rest")
	preview.bone_lines.visible = true
	await _capture("archangel_godot_skeleton")
	preview.bone_lines.visible = false
	preview.model.animation_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	preview.model.animation_player.stop()
	preview.model.animation_player.play("wing_flex_test", 0.0)
	preview.find_children("*", "OptionButton", true, false)[0].select(2)
	DirAccess.make_dir_recursive_absolute("res://.godot/qa/archangel_frames")
	for index in range(48):
		preview.model.animation_player.seek(float(index) / 12.0, true)
		preview.model.animation_player.advance(0.0)
		await process_frame
		if index % 12 == 0:
			print("WING_FRAME ", index, " ", preview.model.animation_player.current_animation_position, " ", preview.model.skeleton.get_bone_pose_rotation(preview.model.skeleton.find_bone("WingRoot_L")))
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/qa/archangel_frames/%03d.png" % index)
	preview.queue_free()
	await process_frame
	var game := (load("res://scenes/previews/archangel_phase_one_preview.tscn") as PackedScene).instantiate()
	root.add_child(game)
	await process_frame
	var main := game.get_child(0)
	var cutscene := main.get_node("OpeningCutscene") as OpeningCutscene
	while not cutscene._running or cutscene._elapsed < 7.1:
		await process_frame
	cutscene.set_process(false)
	await _capture("archangel_opening")
	main.start_test_phase(1)
	await create_timer(1.0).timeout
	main.get_node("HUD").card_presentation.cancel()
	await create_timer(0.2).timeout
	await _capture("archangel_phase_one")
	main.get_node("Music").stop()
	game.queue_free()
	await process_frame
	quit()


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/qa/" + name + ".png")
	print("CAPTURE: " + name)
