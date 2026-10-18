extends SceneTree

var failures := PackedStringArray()


func _initialize() -> void:
	Engine.time_scale = 5.0
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	var scene := load("res://scenes/ui/main_menu.tscn") as PackedScene
	var menu := scene.instantiate() as QueenMainMenu
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	_expect(ProjectSettings.get_setting("application/run/main_scene") == "res://scenes/ui/main_menu.tscn", "F5 deve iniciar pelo menu principal.")
	_expect(menu.music.playing and not menu.music.stream.loop and menu.music.stream.get_length() >= 140.0, "A trilha original deve tocar uma vez e continuar por mais de dois minutos.")
	_expect(menu.start_button.get_theme_font("font") == QueenMainMenu.JUPITER, "As opções devem usar Jupiter Pro.")
	_expect(menu.start_button.text == "Iniciar" and menu.home.find_children("*", "Button", true, false).size() == 1 and menu.find_child("SelectPhase", true, false) == null, "O menu principal deve oferecer somente Iniciar.")
	_expect(menu.world.moon.name == "Moon" and menu.world.moon.body_radius >= 30.0, "A Lua original deve ser o astro grande do cenário.")
	_expect(not menu.intro_ready and menu.start_button.disabled, "As opções devem aguardar a revelação cinematográfica.")
	_expect(menu.world.earth.position.z > menu.world.moon.position.z, "A abertura deve começar com a Terra diante da Lua.")
	_expect(menu.world.find_child("SatelliteA", true, false) == null and menu.find_child("Queen", true, false) == null and menu.find_child("Traveler", true, false) == null, "O cenário do menu não deve conter satélites ou personagens.")
	_expect(menu.world.find_children("*", "EnemyPieceController", true, false).is_empty(), "O tabuleiro do menu não deve carregar peças de jogo.")
	var world := menu.world
	var saved_time := world.intro_time
	for step in range(101):
		world.intro_time = step * MainMenuMoonWorld.INTRO_DURATION / 100.0
		world._apply_shot()
		var separation := world.earth.position.distance_to(world.moon.position)
		var outer_radii := 5.1 * world.earth.scale.x + world.moon.body_radius
		_expect(separation > outer_radii + 10.0, "As superfícies dos astros devem permanecer separadas ao longo da órbita.")
		if step == 40:
			_expect(absf(world.earth.position.x - world.moon.position.x) > 90.0, "A troca de profundidade deve percorrer um arco lateral, sem atravessar os astros.")
	world.intro_time = saved_time
	world._apply_shot()
	await _until(func(): return menu.intro_ready)
	_expect(menu.world.earth.position.z < menu.world.moon.position.z and menu.world.earth.position.y < menu.world.moon.position.y, "A Terra deve terminar atrás e abaixo da Lua.")
	_expect(menu.world.camera.position.y >= 9.0 and menu.world.camera.position.z >= 24.0, "O enquadramento final deve afastar e elevar a câmera do piso.")
	_expect(menu.world.earth.position.x - menu.world.moon.position.x > 55.0, "A Terra deve terminar à direita do observador, atrás da Lua.")
	_expect(menu.logo.material.shader == QueenMainMenu.LOGO_GLOW and menu.logo.texture == QueenMainMenu.LOGO and is_equal_approx(menu.logo.modulate.a, 1.0), "O glow branco deve preservar os contornos da logo original.")
	_expect(menu.start_button.get_theme_constant("outline_size") == 0 and menu.start_button.get_theme_color("font_shadow_color").a == 0.0, "As opções principais devem mostrar apenas a cor da fonte, sem contorno ou sombra preta.")
	await _mouse_move(menu.start_button.get_global_rect().get_center())
	await create_timer(0.3).timeout
	_expect(menu.start_button.scale.x > 1.08 and menu.start_button.position.y < Vector2(menu.start_button.get_meta("rest_position")).y, "O hover deve aproximar a opção e elevá-la suavemente.")
	await _mouse_move(Vector2(20, 20))
	await create_timer(0.3).timeout
	_expect(menu.start_button.scale.is_equal_approx(Vector2.ONE), "A opção deve voltar ao sair do hover.")
	menu.music.seek(menu.music.stream.get_length() - 0.10)
	await _until(func(): return not menu.music.playing)
	await process_frame
	_expect(not menu.music.playing, "O término da faixa deve deixar silêncio, sem repetir a introdução.")
	_expect(menu.start_button.get_theme_color("font_color") == Color.BLACK, "Iniciar deve permanecer preto.")
	await _click(menu.start_button.get_global_rect().get_center())
	await _until(func(): return current_scene != null and current_scene.name == "Main")
	var game := current_scene
	await _until(func(): return game.get_node("OpeningCutscene")._running)
	var game_id := game.get_instance_id()
	var pause_menu: PauseOverlay = game.get_node("PauseOverlay")
	pause_menu._set_paused(true)
	await create_timer(0.55).timeout
	await _click(pause_menu.main_menu_button.get_global_rect().get_center())
	await _until(func(): return current_scene is QueenMainMenu and not paused, "retorno pelo botão Menu principal")
	await process_frame
	await process_frame
	_expect(not is_instance_id_valid(game_id), "Menu principal deve liberar a partida antiga e encerrar sua música e callbacks.")
	menu = current_scene as QueenMainMenu
	_expect(not has_meta(QueenMainMenu.ENTRY_META), "Voltar ao menu não deve carregar uma fase antiga na próxima partida.")
	var accept := InputEventKey.new()
	accept.keycode = KEY_ENTER
	accept.physical_keycode = KEY_ENTER
	accept.pressed = true
	root.push_input(accept, true)
	await process_frame
	_expect(menu.intro_ready and not menu.start_button.disabled and menu.page == QueenMainMenu.Page.HOME, "Enter deve pular apenas a apresentação, sem iniciar a campanha no mesmo evento.")
	_expect(menu.music.playing and menu.music.get_playback_position() >= QueenMainMenu.SCORE_BODY_TIME - 0.1, "Pular a apresentação deve levar a música direto ao trecho contínuo.")
	await _click(menu.start_button.get_global_rect().get_center())
	await _until(func(): return current_scene != null and current_scene.name == "Main")
	game = current_scene
	await _until(func(): return game.get_node("OpeningCutscene")._running)
	_expect(game.get_node("PhaseManager").current_phase == 0, "Iniciar deve entregar a abertura original, antes da fase um.")
	game.get_node("OpeningCutscene").skip()
	game.get_node("Music").stop()
	game.get_node("GameAudio").stop_effects()
	game.queue_free()
	await process_frame
	await process_frame
	Engine.time_scale = 1.0
	for failure in failures: printerr("FALHA: " + failure)
	if failures.is_empty(): print("OK: abertura Terra/Lua, revelação, câmera, pular apresentação, hover, menu com Iniciar, retorno pelo ESC, áudio e campanha.")
	quit(0 if failures.is_empty() else 1)


func _until(predicate: Callable, context := "menu, música ou abertura") -> void:
	var deadline := Time.get_ticks_msec() + 18000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("FALHA: espera excedida: ", context, "; cena=", current_scene.name if current_scene != null else "null", "; pausa=", paused)
	quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)


func _mouse_move(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	root.push_input(event, true)
	await process_frame


func _click(position: Vector2) -> void:
	await _mouse_move(position)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = position
		event.global_position = position
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame
