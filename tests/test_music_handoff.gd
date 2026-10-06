extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.get_node("OpeningCutscene").duration_scale = 0.15
	root.add_child(main)
	var opening: OpeningCutscene = main.get_node("OpeningCutscene")
	while opening._elapsed < (OpeningCutscene.TOTAL_LENGTH - 1.0) * opening.duration_scale: await process_frame
	_expect(is_instance_valid(main._incoming_music) and main._incoming_music.playing, "A trilha seguinte deve começar antes da abertura acabar.")
	var intro: AudioStreamPlayer = main.get_node("Music")
	var incoming: AudioStreamPlayer = main._incoming_music
	var intro_position := intro.get_playback_position()
	var incoming_position := incoming.get_playback_position()
	var progress := opening._elapsed
	main.get_node("PauseOverlay")._set_paused(true)
	await create_timer(0.18, true, false, true).timeout
	_expect(absf(intro.get_playback_position()-intro_position) < 0.05 and absf(incoming.get_playback_position()-incoming_position) < 0.05, "Pausar deve congelar as duas trilhas durante a passagem.")
	_expect(is_equal_approx(opening._elapsed, progress), "A câmera também deve pausar durante a passagem.")
	main.get_node("PauseOverlay")._set_paused(false)
	main.start_test_phase(6)
	_expect(main._incoming_music == null and intro.stream == load("res://assets/audio/music/5.21 Ascension.ogg") and intro.playing, "Pular para uma fase deve cancelar a sobreposição e conservar só a música do jogo.")
	_expect(is_equal_approx(intro.volume_db,-12.0), "Pular a abertura deve restaurar o volume normal.")
	main.get_node("HUD").card_presentation.cancel()
	intro.stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: ", failure)
	print("MUSIC_HANDOFF_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
