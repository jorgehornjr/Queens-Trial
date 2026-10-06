extends SceneTree
## Quadros reais das duas animações para conferir a lombada e a troca final.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(25.0).timeout.connect(func(): quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.02, 0.04)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(backdrop)
	var book := TutorialBook.new()
	root.add_child(book)
	await process_frame
	book.present(1, true)
	await _until(func(): return book.state == TutorialBook.State.OPENING)
	var opening := 0
	while book.state == TutorialBook.State.OPENING:
		await _capture("opening_%03d" % opening)
		opening += 1
		await create_timer(0.035).timeout
	await _until(func(): return book.state == TutorialBook.State.READING and book.reveal_progress > 0.999)
	await _capture("open_complete")
	book.request_close()
	var closing := 0
	while book.closing_cover.visible:
		await _capture("closing_%03d" % closing)
		closing += 1
		await create_timer(0.035).timeout
	await _capture("closed_complete")
	print("QA: abertura %d quadros; fechamento %d quadros, em docs/previews/book_hinge/" % [opening, closing])
	await _until(func(): return not book.visible)
	book.queue_free()
	await process_frame
	quit()


func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec() + 12000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("QA: espera da capa excedida")
	quit(1)


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var folder := "res://docs/previews/book_hinge/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	root.get_texture().get_image().save_png(folder + name + ".png")
