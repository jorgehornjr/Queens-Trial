extends SceneTree

const BURN = preload("res://assets/audio/sfx/cards/paper_burn.wav")
var failures := PackedStringArray()
var starts := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	var audio := main.get_node("GameAudio") as GameAudio
	var presentation := (main.get_node("HUD") as GameHUD).card_presentation
	var menu := main.get_node("PauseOverlay") as PauseOverlay
	main.get_node("Music").stop()
	presentation.burn_started.connect(func(): starts += 1)
	# Two cards share one sound, starting only when the burn is visible.
	presentation.present([2, 3])
	await _until(func(): return presentation._cards.size() == 2 and not presentation._cards[0].disabled)
	_expect(_burn_voices(audio).is_empty(), "Não deve haver fogo antes de virar as cartas.")
	for card in presentation._cards: card.pressed.emit()
	await _until(func(): return starts > 0)
	var voices := _burn_voices(audio)
	_expect(starts == 1 and voices.size() == 1, "Duas cartas devem iniciar um único efeito de queima.")
	_expect(presentation._cards[0].material is ShaderMaterial, "O som deve começar junto com o shader de queima.")
	_expect(absf(BURN.get_length() - CardPresentation.BURN_DURATION) < 0.01, "O Candle deve durar os mesmos 1,65 segundos da queima visual.")
	await create_timer(0.2).timeout
	var material := presentation._cards[0].material as ShaderMaterial
	var progress: float = material.get_shader_parameter("burn_progress")
	menu._set_paused(true)
	await create_timer(0.25, true, false, true).timeout
	_expect(is_equal_approx(progress, material.get_shader_parameter("burn_progress")), "A pausa deve congelar a queima visual.")
	_expect(voices.size() == 1 and voices[0].stream_paused, "A pausa deve congelar o som junto com o fogo.")
	menu._set_paused(false)
	await _until(func(): return not paused)
	_expect(voices.size() == 1 and not voices[0].stream_paused, "Retomar deve continuar o efeito de queima.")
	presentation.cancel()
	_expect(_burn_voices(audio).is_empty(), "Cancelar a apresentação deve interromper o fogo.")
	# Restarted presentation must not leave or duplicate the previous voice.
	presentation.present([4])
	await _until(func(): return presentation._cards.size() == 1 and not presentation._cards[0].disabled)
	presentation._cards[0].pressed.emit()
	await _until(func(): return starts == 2)
	_expect(_burn_voices(audio).size() == 1, "Recomeçar deve usar somente uma voz nova.")
	main.start_test_phase(6)
	_expect(_burn_voices(audio).is_empty(), "Trocar de fase deve cancelar o fogo das cartas anteriores.")
	main.get_node("Music").stop()
	audio.stop_effects()
	await create_timer(0.12, true, false, true).timeout
	main.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: " + failure)
	print("CARD_BURN_AUDIO_FAILURES: ", failures.size())
	quit(0 if failures.is_empty() else 1)

func _burn_voices(audio: GameAudio) -> Array[AudioStreamPlayer]:
	var result: Array[AudioStreamPlayer] = []
	for voice in audio._voices:
		if voice.stream == BURN and voice.playing: result.append(voice)
	return result

func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	failures.append("Tempo esgotado esperando as cartas.")

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
