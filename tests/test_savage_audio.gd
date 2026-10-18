extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var stream := load("res://assets/audio/music/savage_with_hearts_aligned.ogg") as AudioStreamOggVorbis
	if stream == null or not stream.loop or absf(stream.get_length()-334.421) > 0.1:
		printerr("FALHA: trilha Savage precisa ser áudio Vorbis integral com loop.")
		quit(1)
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	root.add_child(player)
	player.play()
	await create_timer(0.2).timeout
	var playing := player.playing
	player.stop()
	player.queue_free()
	await process_frame
	print("OK: trilha Savage Vorbis, 334,421 s, loop e reprodução." if playing else "FALHA: reprodução Savage.")
	quit(0 if playing else 1)
