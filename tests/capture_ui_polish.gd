extends SceneTree
## Capturas do papel ilustrado, pinceladas curvas, consulta e capa em movimento.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(70.0, true).timeout.connect(func():
		printerr("QA: tempo de captura excedido")
		quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080) if "--qa-1080" in OS.get_cmdline_user_args() else Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	root.add_child(main)
	await process_frame
	await process_frame
	var hud := main.get_node("HUD") as GameHUD
	var book := hud.tutorial_book
	var menu_only := "--qa-menu" in OS.get_cmdline_user_args()
	if menu_only: book.seen_chapters[1] = true
	main.start_test_phase(1)
	if not menu_only:
		await _until(func(): return book.state == TutorialBook.State.READING)
		await create_timer(1.2, true).timeout
		await _capture("brush_early")
		await create_timer(0.9, true).timeout
		await _capture("brush_middle")
		await create_timer(0.9, true).timeout
		await _capture("brush_late")
		await _until(func(): return book.reveal_progress > 0.999)
		book.turn_page(-1)
		await _until(func(): return book.state == TutorialBook.State.READING and book.reveal_progress > 0.999)
		await _capture("jupiter_numerals")
		book.turn_page(1)
		await _until(func(): return book.state == TutorialBook.State.READING)
		book.request_close()
		await create_timer(0.73, true).timeout
		await _capture("front_cover_folding")
		await create_timer(0.46, true).timeout
		await _capture("front_cover_closed")
	await _until(func(): return hud.card_presentation._cards.size() == 1 and not hud.card_presentation._cards[0].disabled)
	hud.card_presentation._cards[0].pressed.emit()
	await _until(func(): return hud.book_button.visible)
	var menu := main.get_node("PauseOverlay") as PauseOverlay
	menu._set_paused(true)
	await create_timer(0.55, true).timeout
	await _capture("pause_illustrated")
	menu.phase_selector.show_popup()
	await process_frame
	await process_frame
	await _capture("pause_phase_selector")
	menu.phase_selector.get_popup().hide()
	menu._set_paused(false)
	await _until(func(): return not paused)
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	quit()


func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("QA: espera excedida")
	quit(1)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var suffix := "_1080" if "--qa-1080" in OS.get_cmdline_user_args() else "_720"
	var folder := "res://docs/previews/ui_polish/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := folder + name + suffix + ".png"
	root.get_texture().get_image().save_png(path)
	print("QA: " + ProjectSettings.globalize_path(path))
