extends SceneTree

var failures := PackedStringArray()
var death_finished := false
var modified_head := Transform3D.IDENTITY

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var board := (load("res://scenes/board/Board.tscn") as PackedScene).instantiate() as Board3D
	board.name = "Board"
	board.show_preview_pieces = false
	world.add_child(board)
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as GridPlayer
	player.board_path = NodePath("../Board")
	player.starting_cell = Vector2i(2, 2)
	world.add_child(player)
	await process_frame
	await process_frame
	var model: Node = player.get_node("Model")
	var animation: AnimationPlayer = model.animation_player
	var skeleton: Skeleton3D = model.skeleton
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/fandaniel/rig_report.json"))
	_expect(skeleton.get_bone_count() == 106 and skeleton.find_bone("j_kao") >= 0, "O personagem deve conservar o esqueleto original do FFXIV.")
	for clip: String in report.clips:
		_expect(animation.has_animation(clip), "Animação sem skin ausente: " + clip)
		_expect(absf(animation.get_animation(clip).length - float(report.clips[clip].duration)) < 0.04, "A duração do novo download deve ser preservada: " + clip)
	_expect(model.get_node("FandanielFace").attachment.bone_name == "j_kao", "O símbolo original deve acompanhar o rosto animado.")
	var face: Node = model.get_node("FandanielFace")
	_expect(face.attachment.get_node("ShadowedFace").mesh.get_surface_count() > 0, "O interior do capuz deve conter um rosto fechado que bloqueia o cenário.")
	# Fade across the former pipeline-switch boundary and retain depth writing.
	for reveal in [0.0, 0.5, 0.998, 0.999, 1.0]:
		model.set_arrival_reveal(reveal)
		for material: ShaderMaterial in model._appearance:
			_expect(material.shader == model.ARRIVAL_SKIN and is_equal_approx(float(material.get_shader_parameter("reveal")), reveal), "A chegada deve preservar o shader dos materiais, inclusive ao terminar.")
		_expect(is_equal_approx(face._shadow_material.albedo_color.a, reveal) and is_equal_approx(float(face._glyph_material.get_shader_parameter("reveal")), reveal), "O rosto escuro e o símbolo devem aparecer junto com o corpo.")
	animation.play("intro_arrival", 0.0)
	animation.seek(0.8, true)
	animation.advance(0.0)
	animation.pause()
	model.cinematic_gaze.modification_processed.connect(func(): modified_head = skeleton.get_bone_global_pose(skeleton.find_bone("j_kao")))
	for frame in range(3): await process_frame
	var neutral_head := modified_head
	model.set_cinematic_look_up(1.0)
	for frame in range(3): await process_frame
	var change := neutral_head.basis.get_rotation_quaternion().angle_to(modified_head.basis.get_rotation_quaternion())
	_expect(absf(change - deg_to_rad(12.0)) < 0.01, "O levantar do rosto deve somar apenas 12 graus à caminhada, sem girar a máscara para dentro do capuz.")
	_expect(neutral_head.origin.distance_to(modified_head.origin) < 0.06, "O olhar deve preservar a posição da cabeça sobre o pescoço.")
	model.set_cinematic_look_up(0.0)
	animation.play("breathing_idle", 0.0)
	player.set_input_enabled(true)
	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var start_yaw := player.rotation.y
		player._try_move(direction)
		_expect(animation.current_animation == "walk" and is_equal_approx(player.rotation.y, start_yaw), "Walking deve começar sem giro instantâneo.")
		# Observe the midpoint deterministically even on a loaded render host.
		player._move_tween.pause()
		player._move_tween.custom_step(player.turn_duration * 0.5)
		var destination := GridPlayer._yaw_for_direction(direction)
		_expect(absf(wrapf(player.rotation.y-start_yaw,-PI,PI)) > 0.02 and absf(wrapf(player.rotation.y-destination,-PI,PI)) > 0.02, "A virada deve passar por ângulos intermediários.")
		player._move_tween.play()
		while player.movement_locked: await process_frame
		_expect(player.position.is_equal_approx(board.grid_to_world(player.current_cell) + Vector3.UP * player.surface_offset), "A animação não deve duplicar o movimento da grade.")
		_expect(animation.current_animation == "breathing_idle", "Idle deve começar imediatamente ao parar.")
	var length := animation.get_animation("breathing_idle").length
	animation.advance(length * 2.25)
	_expect(animation.is_playing() and animation.current_animation == "breathing_idle", "Idle deve repetir continuamente.")
	for direction in [-1, 1]:
		model.begin_platform_slide(direction)
		animation.advance(1.7)
		_expect(animation.current_animation == ("left_slide" if direction < 0 else "right_slide") and animation.is_playing(), "Os Strafes devem repetir durante a inclinação.")
		model.recover_platform_slide()
		_expect(animation.current_animation == "breathing_idle", "A recuperação deve mesclar para Idle.")
	var original_position := player.position
	_finish_death(player)
	var limit := Time.get_ticks_msec() + 5500
	while not death_finished and Time.get_ticks_msec() < limit: await process_frame
	_expect(death_finished and player.position.is_equal_approx(original_position), "A morte deve terminar sem deslocar a raiz lógica.")
	var head := skeleton.to_global(skeleton.get_bone_global_pose(skeleton.find_bone("j_kao")).origin)
	_expect(head.y < original_position.y + 0.85 and head.y > original_position.y - 0.1, "A morte deve acomodar a cabeça junto ao chão.")
	player.reset_to_start()
	await process_frame
	_expect(animation.current_animation == "breathing_idle" and not player.movement_locked, "Reiniciar deve restaurar Idle e limpar a morte.")
	world.queue_free()
	await process_frame
	for failure in failures: printerr("FALHA: ", failure)
	print("FANDANIEL_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _finish_death(player: GridPlayer) -> void:
	await player.play_death_animation()
	death_finished = true

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
