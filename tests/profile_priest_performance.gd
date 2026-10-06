extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	root.mode = Window.MODE_WINDOWED
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var cape := main.get_node("World/Player/Model").cape as Node3D
	var disabled := "--no-cape" in OS.get_cmdline_user_args()
	if disabled: cape.set_physics_process(false)
	var frames := 0
	var solver := 0.0
	var physics := 0.0
	var process := 0.0
	var frame_times: Array[float] = []
	var start := Time.get_ticks_usec()
	var previous := start
	while Time.get_ticks_usec() - start < 13000000:
		await process_frame
		var now := Time.get_ticks_usec()
		if now-start > 2000000:
			frames += 1
			frame_times.append(float(now-previous)/1000.0)
			solver += cape.last_step_usec if not disabled else 0
			physics += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
			process += Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
		previous = now
	frame_times.sort()
	var report := {"cape_enabled": not disabled, "frames": frames, "fps": float(frames)/11.0, "frame_ms_p50": frame_times[frame_times.size()/2], "frame_ms_p95": frame_times[int(frame_times.size()*.95)], "cape_solver_ms": solver/frames/1000.0, "physics_ms": physics/frames, "process_ms": process/frames, "triangles": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	print("PRIEST_PERFORMANCE: ", JSON.stringify(report))
	var label := "no_cape" if disabled else "cape"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="): label = arg.trim_prefix("--label=")
	var file := FileAccess.open("res://.godot/qa/performance_"+label+".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.get_node("OpeningCutscene").skip()
	await create_timer(.12,true,false,true).timeout
	main.queue_free()
	await process_frame
	quit()
