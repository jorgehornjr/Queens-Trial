extends SceneTree

var failures := PackedStringArray()

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
	player.name = "Player"
	player.board_path = NodePath("../Board")
	player.starting_cell = Vector2i(2, 2)
	preload("res://tests/fixtures/priest_model.gd").replace(player)
	world.add_child(player)
	await process_frame
	await process_frame
	var model: Node3D = player.get_node("Model")
	var animation: AnimationPlayer = model.animation_player
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/characters/fallen_priest/mixamo/animation_import_report.json"))
	for clip: String in report.clips:
		_expect(animation.has_animation(clip), "Todos os downloads do Mixamo devem estar no rig completo: " + clip)
		_expect(absf(animation.get_animation(clip).length - float(report.clips[clip].duration)) < 0.06, "A duração do Mixamo deve ser preservada: " + clip)
	for clip in ["breathing_idle", "walk", "left_slide", "right_slide"]:
		_expect(animation.get_animation(clip).loop_mode == Animation.LOOP_LINEAR, "Idle, Walking e os Strafes devem repetir: " + clip)
	_expect(model.cape.points.size() == 117 and model.skeleton.get_bone_count() == 139, "O auto-rig da Adobe não deve substituir a capa e o rig completo.")
	var face: Node = model.get_node("FaceSigil")
	_expect(face.attachment.bone_name == "Head" and face.attachment.get_child_count() == 3, "O símbolo e o brilho precisam acompanhar a cabeça animada.")
	player.set_input_enabled(true)
	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var start_yaw := player.rotation.y
		player._try_move(direction)
		_expect(animation.current_animation == "walk", "A caminhada deve iniciar assim que o jogador se move.")
		_expect(is_equal_approx(player.rotation.y, start_yaw), "Mudar a direção não pode girar instantaneamente.")
		player._move_tween.pause()
		player._move_tween.custom_step(player.turn_duration * 0.5)
		var destination := GridPlayer._yaw_for_direction(direction)
		_expect(absf(wrapf(player.rotation.y-start_yaw,-PI,PI)) > 0.02, "A virada deve avançar suavemente durante a caminhada.")
		_expect(absf(wrapf(player.rotation.y-destination,-PI,PI)) > 0.02, "A virada deve passar por ângulos intermediários.")
		player._move_tween.play()
		while player.movement_locked: await process_frame
		_expect(player.position.is_equal_approx(board.grid_to_world(player.current_cell) + Vector3.UP * player.surface_offset), "A suavização deve preservar o destino exato da grade.")
		_expect(absf(wrapf(player.rotation.y-destination,-PI,PI)) < 0.001, "A caminhada precisa terminar voltada ao destino.")
		_expect(animation.current_animation == "breathing_idle", "Parar deve iniciar Idle imediatamente.")
	var idle_length := animation.get_animation("breathing_idle").length
	await create_timer(idle_length * 2.1).timeout
	_expect(animation.is_playing() and animation.current_animation == "breathing_idle", "Idle precisa repetir continuamente, sem esperar inatividade.")
	model.begin_platform_slide(-1)
	await create_timer(1.6).timeout
	_expect(animation.is_playing() and animation.current_animation == "left_slide", "O Strafe deve continuar durante a inclinação, além do primeiro ciclo.")
	model.recover_platform_slide()
	_expect(animation.current_animation == "breathing_idle", "A recuperação deve mesclar o Strafe de volta ao Idle.")
	world.queue_free()
	await process_frame
	for failure in failures: printerr("FALHA: ", failure)
	print("PRIEST_MIXAMO_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
