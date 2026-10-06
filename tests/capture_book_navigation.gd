extends SceneTree
## Prova visual do ícone, leitura mágica e consulta dentro da cena real.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	main.start_test_phase(1)
	var hud := main.get_node("HUD") as GameHUD
	var book := hud.tutorial_book
	await _until(func(): return book.state == TutorialBook.State.READING)
	await _until(func(): return book.reveal_progress > 0.999)
	book.request_close()
	await _until(func(): return hud.card_presentation._cards.size() == 1 and not hud.card_presentation._cards[0].disabled)
	hud.card_presentation._cards[0].pressed.emit()
	await _until(func(): return hud.book_button.visible)
	await _capture("game_book_icon")
	hud.book_button.pressed.emit()
	await _until(func(): return book.state == TutorialBook.State.READING)
	await create_timer(1.5, true).timeout
	await _capture("game_book_painting")
	await _until(func(): return book.reveal_progress > 0.999)
	await _capture("game_book_current")
	book.turn_page(-1)
	await _until(func(): return book.state == TutorialBook.State.READING and book.reveal_progress > 0.999)
	await _capture("game_book_frontmatter")
	book.request_close()
	await _until(func(): return not paused and not book.visible)
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()


func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 20000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("QA: espera do livro excedida")
	quit(1)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := "res://docs/previews/tutorial_book/%s.png" % name
	root.get_texture().get_image().save_png(path)
	print("QA: " + ProjectSettings.globalize_path(path))
