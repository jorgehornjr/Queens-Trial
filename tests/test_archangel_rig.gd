extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model := (load("res://scenes/player/archangel_animated_model.tscn") as PackedScene).instantiate() as ArchangelAnimatedModel
	root.add_child(model)
	await process_frame
	var skeleton := model.skeleton
	var animation := model.animation_player
	_expect(skeleton != null and skeleton.get_bone_count() == 81, "O Godot deve importar os 81 ossos de deformação.")
	for name in ["Head", "Hand_L", "Hand_R", "Foot_L", "Foot_R", "WingRoot_L", "WingRoot_R", "FeatherFan4_L", "FeatherFan4_R", "Sword", "Halo"]:
		_expect(skeleton.find_bone(name) >= 0, "Osso ausente: " + name)
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	_expect(meshes.size() == 8, "Corpo, cabeça, asas, espada, auréola e tecido devem permanecer separados.")
	var materials := {}
	for item in meshes:
		var mesh := item as MeshInstance3D
		_expect(mesh.skin != null, "Parte sem skin: " + String(mesh.name))
		var material := mesh.mesh.surface_get_material(0) as StandardMaterial3D
		_expect(material != null and material.albedo_texture != null and material.normal_texture != null, "As partes precisam preservar as texturas PBR.")
		materials[material.get_instance_id()] = true
		var arrays := mesh.mesh.surface_get_arrays(0)
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := maxi(1, weights.size() / 4000)
		for offset in range(0, weights.size(), stride * 4):
			if offset + 3 >= weights.size():
				break
			_expect(absf(weights[offset] + weights[offset + 1] + weights[offset + 2] + weights[offset + 3] - 1.0) < 0.001, "Pesos não normalizados em " + String(mesh.name))
	_expect(materials.size() == 8, "Cada parte deve ter seu material editável.")
	for clip in ["breathing_idle", "intro_presence", "wing_flex_test", "rig_pose_test"]:
		_expect(animation.has_animation(clip), "Animação ausente: " + clip)
	_expect(not animation.has_animation("intro_looking"), "O arcanjo deve usar sua própria presença na abertura.")
	var wing := skeleton.find_bone("WingUpper03_L")
	animation.play("wing_flex_test")
	animation.seek(0.0, true)
	await process_frame
	var start := skeleton.get_bone_global_pose(wing)
	animation.seek(1.0, true)
	await process_frame
	var changed := skeleton.get_bone_global_pose(wing)
	_expect(start.origin.distance_to(changed.origin) > 0.02 or start.basis != changed.basis, "A animação deve mover a cadeia das asas no Godot.")
	model.play_intro_looking()
	_expect(animation.current_animation == "intro_presence", "A cutscene deve acionar a presença do arcanjo.")
	model.stop_intro_looking()
	_expect(animation.current_animation == "breathing_idle", "A cutscene deve devolver o repouso.")
	model.queue_free()
	await process_frame
	# Exercise the real opening and phase manager with the replacement model.
	Engine.time_scale = 8.0
	var preview := (load("res://scenes/previews/archangel_phase_one_preview.tscn") as PackedScene).instantiate()
	root.add_child(preview)
	await process_frame
	var main := preview.get_child(0)
	var player := main.get_node("World/Player") as GridPlayer
	var avatar := player.get_node("Model") as ArchangelAnimatedModel
	_expect(avatar != null, "A prévia deve substituir o mago pelo arcanjo.")
	await create_timer(OpeningCutscene.ENTRY_START + 1.0).timeout
	_expect(avatar.animation_player.current_animation == "intro_presence", "A abertura real deve usar a presença do arcanjo.")
	main.start_test_phase(1)
	var book := (main.get_node("HUD") as GameHUD).tutorial_book
	while book.state != TutorialBook.State.READING: await process_frame
	book.request_close()
	while book.visible: await process_frame
	await create_timer(1.0).timeout
	main.get_node("HUD").card_presentation.cancel()
	await create_timer(0.25).timeout
	_expect(main.get_node("PhaseManager").current_phase == 1 and player.input_enabled, "A fase 1 deve continuar jogável na prévia.")
	var cell := player.current_cell
	player._try_move(Vector2i.LEFT)
	await create_timer(player.move_duration + 0.1).timeout
	_expect(player.current_cell == cell + Vector2i.LEFT and not player.movement_locked, "O arcanjo deve continuar usando o movimento da grade.")
	main.get_node("Music").stop()
	preview.queue_free()
	await process_frame
	if failures.is_empty():
		print("PASS: archangel rig, skin, materials, opening and phase-one movement")
		quit()
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
