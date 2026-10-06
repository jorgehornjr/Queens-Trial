extends SceneTree

const EditoMachine = preload("res://scripts/gameplay/edito_state_machine.gd")
const FAIL_STREAM = preload("res://assets/audio/sfx/user/fail.wav")

var failures := PackedStringArray()


func _initialize() -> void:
	Engine.time_scale = 10.0
	call_deferred("_run")


func _run() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.set("opening_cutscene_enabled", false)
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	var controller := main.get_node("PhaseLoopController") as PhaseLoopController
	var player := main.get_node("World/Player") as GridPlayer
	var audio := main.get_node("GameAudio") as GameAudio
	var presentation := (main.get_node("HUD") as GameHUD).card_presentation
	var music := main.get_node("Music") as AudioStreamPlayer
	var original_music_db := music.volume_db

	manager.start_phase(1)
	var book := (main.get_node("HUD") as GameHUD).tutorial_book
	if await _wait_until(func(): return book.state == TutorialBook.State.READING):
		book.request_close()
	else:
		failures.append("O livro inicial não abriu para receber o clique.")
	if await _wait_until(func(): return presentation._cards.size() == 1 and not presentation._cards[0].disabled):
		presentation._cards[0].pressed.emit()
	else:
		failures.append("A carta inicial não ficou disponível.")
	if not await _wait_until(func(): return player.input_enabled):
		failures.append("A fase 1 não liberou o jogador.")
	else:
		# Four legal steps return to the start, so the edict must fail.
		for direction in [Vector2i.UP, Vector2i.UP, Vector2i.DOWN, Vector2i.DOWN]:
			player._try_move(direction)
			if not await _wait_until(func(): return not player.movement_locked):
				failures.append("O movimento do jogador travou.")
				break
		if not await _wait_until(func(): return controller._edito_machine.estado_atual == EditoMachine.Estado.FINALIZADO):
			failures.append("A falha não foi julgada.")
		else:
			var fail_playing := false
			for voice in audio._voices:
				if voice.stream == FAIL_STREAM and voice.playing:
					fail_playing = true
			if not fail_playing:
				failures.append("O arquivo fail.wav não está tocando após a falha.")
			if not is_equal_approx(music.volume_db, original_music_db - 12.0):
				failures.append("A música não baixou durante o áudio de falha.")

	audio.stop_effects()
	if not is_equal_approx(music.volume_db, original_music_db):
		failures.append("O volume da música não foi restaurado.")
	var generation_after_failure := controller._generation
	if not await _wait_until(func(): return controller._generation > generation_after_failure and presentation._cards.size() == 1 and not presentation._cards[0].disabled):
		failures.append("A fase não reiniciou após o áudio de falha.")
	else:
		presentation._cards[0].pressed.emit()
		if not await _wait_until(func(): return player.input_enabled):
			failures.append("A fase reiniciada não liberou o jogador após a carta.")
	# Let the mixer release its final voices before destroying the scene.
	presentation.cancel()
	audio.stop_effects()
	music.stop()
	await create_timer(0.12, true, false, true).timeout
	main.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	if failures.is_empty():
		print("OK: falha toca fail.wav e reduz temporariamente a música.")
		quit(0)
		return
	for failure in failures:
		printerr("FALHA: " + failure)
	quit(1)


func _wait_until(predicate: Callable) -> bool:
	for _frame in range(1200):
		if predicate.call():
			return true
		await process_frame
	return false
