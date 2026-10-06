extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var players: Array[GridPlayer] = []
	var board := (load("res://scenes/board/Board.tscn") as PackedScene).instantiate() as Board3D
	board.name = "Board"
	world.add_child(board)
	for i in range(2):
		var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as GridPlayer
		player.board_path = NodePath("../Board")
		world.add_child(player)
		players.append(player)
	await process_frame
	await process_frame
	var fast = players[0].get_node("Model").cape
	var reference = players[1].get_node("Model").cape
	_expect(fast._native_solver != null, "O módulo nativo deve carregar no Windows x64.")
	if fast._native_solver == null:
		world.queue_free()
		await process_frame
		quit(1)
		return
	for player in players:
		player.set_physics_process(false)
		player.get_node("Model").animation_player.pause()
		player.get_node("Model").cape.set_physics_process(false)
		player.position = Vector3.ZERO
	reference._native_solver = null
	fast.reset_cloth()
	reference.reset_cloth()
	var held_state: PackedByteArray = fast._native_state
	var snapshot := held_state.duplicate()
	for step in range(180):
		# Repeat identical floor, wind and shoulder motion in both solvers.
		for i in range(2):
			players[i].position = Vector3(sin(step*.04)*.12, 0, 0)
			var cape = players[i].get_node("Model").cape
			cape.wind = Vector3(0.8, 0, -0.6)
			cape._physics_process(1.0/120.0)
		if step % 30 == 0: await process_frame
	_expect(held_state == snapshot, "O módulo não pode alterar arrays guardados pelo chamador.")
	var max_delta := 0.0
	for i in range(fast.points.size()):
		max_delta = maxf(max_delta, fast.points[i].distance_to(reference.points[i]))
		_expect(fast.points[i].is_finite(), "O solver deve produzir posições finitas.")
	_expect(max_delta < 0.025, "O cálculo nativo deve preservar a reação física original (diferença %f)." % max_delta)
	_expect(fast.max_stretch_ratio() < 1.35, "A otimização deve preservar o comprimento da capa.")
	print("CAPE_NATIVE_REFERENCE_MAX_DELTA: ", max_delta)
	world.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: " + failure)
	print("CAPE_SOLVER_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
