extends SceneTree
const Assets = preload("res://scripts/ui/roman_card_assets.gd")

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://docs/previews/card_trials")
	call_deferred("_run")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 1280)
	root.content_scale_size = Vector2i(1280, 1280)
	var cards: Array[TextureRect] = []
	for i in range(20):
		var art := TextureRect.new()
		art.texture = Assets.front(i + 1)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_SCALE
		art.size = Vector2(210, 300)
		art.position = Vector2(28 + (i % 5) * 250, 20 + floori(i / 5.0) * 315)
		art.material = Assets.card_material(i + 1)
		root.add_child(art)
		cards.append(art)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/card_trials/paper_uniform.png")
	for art in cards: art.material.set_shader_parameter("paper_tone_enabled", false)
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/previews/card_trials/paper_original.png")
	for art in cards: art.queue_free()
	await process_frame
	var back := TextureRect.new()
	back.texture = preload("res://assets/cards/back.png")
	back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	back.stretch_mode = TextureRect.STRETCH_SCALE
	back.position = Vector2(340, 210)
	back.size = Vector2(600, 850)
	back.material = Assets.card_material()
	root.add_child(back)
	await process_frame
	await RenderingServer.frame_post_draw
	var rendered := root.get_texture().get_image()
	rendered.save_png("res://docs/previews/card_trials/back_square.png")
	var corner := rendered.get_pixel(342, 212)
	assert(corner.r > 0.3 and corner.g > 0.2, "The new square back must fill the corner with its parchment artwork.")
	back.queue_free()
	await process_frame
	print("PALETTE_CAPTURED: I–XX before/after and square back.")
	quit()
