extends SceneTree
## Rendered timing around the real phase-five to phase-six handoff.

var frames: Array[float] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD") as GameHUD
	for number in range(1, 7): hud.tutorial_book.seen_chapters[number] = true
	main.phase_manager.start_phase(5, 171026)
	await create_timer(2.0).timeout
	hud.card_presentation.cancel()
	var queen: Node = main.get_node("World/Seraph")
	var prepared := queen.balance as QueenBalance
	var before := await _sample(1.0)
	var started := Time.get_ticks_usec()
	main.phase_manager.start_phase(6)
	var handler_ms := float(Time.get_ticks_usec() - started) / 1000.0
	var transition := await _sample(3.0)
	var reused: bool = queen.balance == prepared
	var output := "res://tmp/current_review"
	DirAccess.make_dir_recursive_absolute(output)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + "/balance.png")
	var report := {"resolution": "1280x720", "handler_ms": handler_ms,
		"reused_prepared_balance": reused, "baseline": before, "transition": transition,
		"renderer": RenderingServer.get_current_rendering_method()}
	var file := FileAccess.open(output + "/balance_transition.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("BALANCE_TRANSITION: ", JSON.stringify(report))
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	quit(0 if reused else 1)

func _sample(seconds: float) -> Dictionary:
	frames.clear()
	var previous := Time.get_ticks_usec()
	var end := previous + int(seconds * 1000000)
	while Time.get_ticks_usec() < end:
		await process_frame
		var now := Time.get_ticks_usec()
		frames.append(float(now - previous) / 1000.0)
		previous = now
	frames.sort()
	return {"frames": frames.size(), "p50_ms": frames[frames.size() / 2],
		"p95_ms": frames[mini(frames.size() - 1, int(frames.size() * 0.95))], "max_ms": frames[-1]}
