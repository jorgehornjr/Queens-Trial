extends SceneTree
## Capturas reais do livro, com texto do jogo e efeitos do Godot.

var book: TutorialBook


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(95.0).timeout.connect(func():
		printerr("QA: tempo máximo de captura excedido")
		quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720) if "--qa-720" in OS.get_cmdline_user_args() else Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	var background := ColorRect.new()
	background.color = Color(0.035, 0.024, 0.052)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	book = TutorialBook.new()
	root.add_child(book)
	await process_frame
	var first_chapter := 6 if "--qa-balance" in OS.get_cmdline_user_args() else 1
	for number in range(first_chapter, 7):
		book.present(number)
		if number == 1:
			await create_timer(0.95).timeout
			await _capture("cover")
		if number == 2:
			while book.state != TutorialBook.State.TURNING:
				await process_frame
			await create_timer(0.22).timeout
			await _capture("page_turn")
		while book.state != TutorialBook.State.READING:
			await process_frame
		if number == 1:
			await create_timer(1.5).timeout
			await _capture("painting_reveal")
		while book.reveal_progress < 0.999: await process_frame
		await process_frame
		print("LAYOUT phase %d: body content %d / available %.1f; font %d; title bottom %.1f / body top %.1f" % [number, book.body_label.get_content_height(), book.body_label.size.y, book.body_label.get_theme_font_size("normal_font_size"), book.title_label.position.y + book.title_label.size.y, book.body_label.position.y])
		await _capture("phase_%d" % number)
		if number == 1:
			book.turn_page(-1)
			while book.state != TutorialBook.State.READING or book.reveal_progress < 0.999: await process_frame
			await _capture("roman_table")
			book.turn_page(1)
			while book.state != TutorialBook.State.READING: await process_frame
		book.request_close()
		if number == 1:
			while not book.cover.visible: await process_frame
			await _capture("closed_again")
		while book.state != TutorialBook.State.HIDDEN:
			await process_frame
	book.free()
	quit()


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var suffix := "_720" if "--qa-720" in OS.get_cmdline_user_args() else ""
	var path := "res://docs/previews/tutorial_book/%s%s.png" % [name, suffix]
	root.get_texture().get_image().save_png(path)
	print("QA: " + ProjectSettings.globalize_path(path))
