extends SceneTree
## Captura toda a abertura, o menu com Iniciar e seu hover.


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	create_timer(60.0).timeout.connect(func(): quit(1))
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1920, 1080)
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate() as QueenMainMenu
	root.add_child(menu)
	current_scene = menu
	var folder := "res://docs/previews/main_menu/motion/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var started := menu.effect_time
	var frame := 0
	var stages := [1.5, 4.5, 8.2]
	var names := ["intro_earth", "intro_orbit", "intro_logo"]
	var stage := 0
	while menu.effect_time < MainMenuMoonWorld.INTRO_DURATION + 1.0:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(folder + "%03d.png" % frame)
		frame += 1
		if stage < stages.size() and menu.world.intro_time >= stages[stage]:
			await _capture(names[stage])
			stage += 1
		await create_timer(0.1).timeout
	var duration := menu.effect_time - started
	var report := FileAccess.open("res://docs/previews/main_menu/motion.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"frames": frame, "duration": duration, "fps": frame / duration}, "\t"))
	report.close()
	await _capture("home")
	await _mouse_move(menu.start_button.get_global_rect().get_center())
	await create_timer(0.30).timeout
	await _capture("hover_start")
	await _mouse_move(Vector2(20, 20))
	menu.start_button.grab_focus()
	await create_timer(0.25).timeout
	print("QA: abertura completa, menu lunar com Iniciar e hover em docs/previews/main_menu/")
	menu.queue_free()
	await process_frame
	quit()


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/main_menu/%s.png" % name)


func _mouse_move(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	root.push_input(event, true)
	await process_frame
