extends SceneTree

var failures := PackedStringArray()
var main: Node
var trial: SavageController
var player: GridPlayer
var _card_pause_checked := false

func _initialize() -> void:
	Engine.time_scale = 8.0
	call_deferred("_run")

func _run() -> void:
	_expect(SavageCatalog.validate().is_empty(), "Cinco desafios legais e solucionáveis.")
	var report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://docs/design/savage_solutions.json"))
	for index in range(5):
		var stage_data := SavageCatalog.find(101+index)
		var sides := {}
		for wave: Array in stage_data.piece_waves:
			for definition: Dictionary in wave: sides[String(definition.side)] = true
		_expect(sides.size() == 4, "Cada desafio precisa distribuir suas quatro peças pelos quatro lados.")
		var solutions := SavageCatalog.solutions(stage_data)
		_expect(solutions.size() == report[index].solutions.size(), "Solucionadores independentes precisam concordar.")
		for solution: Dictionary in solutions:
			_expect(solution.first.size() - 1 == int(stage_data.edict_values[0]) and solution.second.size() - 1 == int(stage_data.edict_values[1]), "As soluções devem caber nos éditos, sem voltas artificiais.")
	var progress_path := "user://savage_test_%s.cfg" % Time.get_ticks_usec()
	_expect(not CampaignProgress.savage_unlocked(progress_path), "Visitar uma fase não pode liberar Savage.")
	for number in range(1,8): CampaignProgress.record_completion(number, progress_path)
	_expect(not CampaignProgress.savage_unlocked(progress_path), "Progresso incompleto deve continuar bloqueado.")
	CampaignProgress.record_completion(8, progress_path)
	_expect(CampaignProgress.savage_unlocked(progress_path), "Completar toda a campanha libera Savage.")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(progress_path))
	_expect(PhaseManager.SAVAGE_TEST_ACCESS and PhaseManager.can_start_phase(101) and not PhaseManager.can_start_phase(106), "O acesso de teste precisa existir e respeitar os cinco IDs.")
	main = (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").save_progress = false
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame
	trial = main.get_node("SavageController")
	player = main.get_node("World/Player")
	var manager: PhaseManager = main.get_node("PhaseManager")
	var pause_menu: PauseOverlay = main.get_node("PauseOverlay")
	main.start_test_phase(101)
	await _prepare()
	_expect(player.visible and player.input_enabled and trial.remaining > 9.8, "Preparação livre começa com dez segundos.")
	_expect(root.get_visible_rect().has_point(trial.ui.timer.get_global_rect().get_center()) and trial.ui.canvas.find_child("SavageStage") == null and trial.ui.canvas.find_child("TimerCaption") == null and trial.ui.canvas.find_child("Distance") == null, "Só o número do timer deve permanecer na HUD.")
	_expect(trial._pieces.get_child_count() == 4, "Savage deve ter dois pares, sem oito peças simultâneas.")
	var font_sizes := {}
	for piece: SavageEnemyPiece in trial._pieces.get_children():
		var numeral := piece.get_node("RomanNumeral") as PieceNumeral
		font_sizes[numeral.label.get_theme_font_size("font_size")] = true
		_expect(numeral.text == GameConstants.to_roman(piece.move_value) and piece.find_children("*","Label3D",true,false).is_empty(), "As peças devem mostrar somente seu próprio numeral, sem rótulo de édito.")
		_expect(piece._arrows.size() == 1, "Cada peça deve ter uma única seta discreta.")
		_expect(piece._arrows[0].visible == (piece.wave_index == 0), "Somente o primeiro par mostra flechas durante a preparação.")
	_expect(font_sizes.size() == 1, "O tamanho dos numerais precisa ser idêntico em todas as distâncias.")
	var solar := main.get_node("World/CelestialSpace/SolarSystem")
	for satellite_name in ["SpaceStation","SatelliteA","SatelliteB"]:
		_expect(not solar.get_node(satellite_name).visible, "Satélites precisam ficar ausentes no Savage.")
	var dress := main.get_node("World/Seraph").find_child("Dress",true,false) as MeshInstance3D
	_expect(dress.get_active_material(0) is ShaderMaterial and trial.effects._fire._samples.size() > 100, "As brasas precisam fazer parte do material e da superfície real do tecido.")
	_expect(trial.effects._fire.find_children("ClothFlame*","MeshInstance3D",true,false).is_empty() and trial.effects._fire.has_node("ClothEmbers"), "A combustão interna deve usar tecido e partículas, sem volumes de chama externos.")
	_expect(main.get_node("Music").stream == main.SAVAGE_MUSIC and trial.effects.active, "Música e atmosfera exclusivas do Savage.")
	var hud: GameHUD = main.get_node("HUD")
	hud._consult_book()
	var book_key := InputEventKey.new()
	book_key.keycode = KEY_N
	book_key.physical_keycode = KEY_N
	book_key.pressed = true
	root.push_input(book_key,true)
	await process_frame
	_expect(not hud.tutorial_book.visible and not hud.card_presentation.visible and not hud.book_button.visible, "Savage não mostra livro ou cartas.")
	pause_menu._set_paused(true)
	var saved_time := trial.remaining
	var effect_time: float = trial.effects._time
	for frame in range(10): await process_frame
	_expect(is_equal_approx(saved_time,trial.remaining) and is_equal_approx(effect_time,trial.effects._time), "ESC congela preparação, fogo e relógios.")
	await pause_menu._close_sheet()
	# Distances must follow displacement rather than accumulated keypresses.
	var solution: Dictionary = SavageCatalog.solutions(trial.data)[0]
	await _walk(SavageCatalog.route(player.current_cell,solution.start,8))
	await _until(func(): return trial.stage == SavageController.Stage.MOVING)
	_expect(trial.edict_origin == solution.start and not player.movement_locked, "A casa escolhida no fim da preparação é a origem real do édito.")
	await _step(solution.first[1]-solution.first[0])
	await _step(solution.first[0]-solution.first[1])
	_expect(main.get_node("World/Board").state.manhattan_distance(trial.edict_origin,player.current_cell) == 0, "Andar e voltar não cumpre o édito.")
	# Cancel while guards are resolving, then allow their former callbacks to expire.
	trial.remaining = 0.0
	await _until(func(): return trial.stage == SavageController.Stage.RESOLVING)
	await create_timer(0.85,false).timeout
	manager.restart_phase()
	await _prepare()
	await create_timer(2.2,false).timeout
	_expect(trial.stage == SavageController.Stage.PREPARATION and trial.wave_index == 0, "Reiniciar durante resolução não deixa ataques antigos ativos.")
	var spawns := {}
	trial._rng.seed = 142026
	for attempt in range(8):
		manager.restart_phase()
		await _prepare()
		spawns[trial.random_spawn] = true
	_expect(spawns.size() > 3, "O spawn deve variar e não indicar a solução.")
	var completed := [false]
	manager.savage_completed.connect(func(): completed[0] = true)
	for number in range(101,106):
		if manager.current_phase != number: main.start_test_phase(number)
		if trial.stage != SavageController.Stage.PREPARATION: await _prepare()
		solution = SavageCatalog.solutions(trial.data)[0]
		await _walk(SavageCatalog.route(player.current_cell,solution.start,8))
		await _until(func(): return trial.stage == SavageController.Stage.MOVING and trial.wave_index == 0)
		await _walk(solution.first)
		await _until(func(): return trial.stage == SavageController.Stage.MOVING and trial.wave_index == 1)
		for piece: SavageEnemyPiece in trial._pieces.get_children():
			_expect(piece._arrows[0].visible == (piece.wave_index == 1), "As flechas devem acompanhar somente o par da segunda onda.")
		await _walk(solution.second)
		await _until(func(): return trial.stage == SavageController.Stage.CLEARED)
		_expect(player.current_cell == SavageCatalog.cell(trial.data.safe_spot), "O desafio deve terminar no safe spot com duas ondas corretas.")
		_expect(hud.announcement.visible and hud.announcement_label.text == "FASE CONCLUÍDA" and hud.announcement_label.get_theme_font("font") == GameHUD.JUPITER_FONT and hud.announcement_label.get_theme_font_size("font_size") == GameHUD.ANNOUNCEMENT_FONT_SIZE, "Chaotic deve usar o mesmo anúncio de conclusão, fonte e tamanho da campanha.")
		print("OK: Savage ",number-100," preparação, dois éditos e ataques reais.")
		if number < 105: await _until(func(): return manager.current_phase == number+1)
	await _until(func(): return completed[0])
	_expect(manager.current_phase == 105 and trial.stage == SavageController.Stage.CLEARED, "O quinto Savage encerra a sequência sem iniciar fase inexistente.")
	# One deliberately invalid edict must fail, not silently advance.
	manager.start_phase(101)
	await _prepare()
	trial.remaining = 0.0
	await _until(func(): return trial.stage == SavageController.Stage.MOVING)
	trial.remaining = 0.0
	await _until(func(): return trial.stage == SavageController.Stage.FAILED)
	_expect(manager.current_phase == 101, "Errar a distância mantém o desafio atual.")
	_expect(hud.result_panel.visible and "distância" in hud.result_label.text, "As falhas devem usar a correção central e explicar a distância.")
	# Jumping out must restore the original blue environment and ordinary controllers.
	main.start_test_phase(7)
	await process_frame
	var space: CelestialSpace = main.get_node("World/CelestialSpace")
	_expect(not trial.effects.active and float(space._sky_material.get_shader_parameter("inferno_mix")) == 0.0 and not trial.ui.canvas.visible, "Sair restaura a atmosfera, encerra fogo e HUD.")
	_expect(main.get_node("Music").stream == main.GAME_MUSIC, "Sair restaura a música da campanha.")
	_expect(dress.get_active_material(0) is StandardMaterial3D and solar.get_node("SpaceStation").visible, "Sair deve restaurar o tecido original e os satélites.")
	main.start_test_phase(8)
	await process_frame
	hud._consult_book()
	await process_frame
	_expect(not hud.book_button.visible and not hud.tutorial_book.visible, "Fase oito também não oferece o livro.")
	pause_menu._set_paused(true)
	pause_menu.phase_selector.select(10)
	pause_menu.phase_button.pressed.emit()
	await _until(func(): return not pause_menu.screen.visible and manager.current_phase == 103)
	await _prepare()
	_expect(player.visible and trial.effects.active and trial.wave_index == 0, "O seletor ESC deve levar diretamente ao Savage III a partir das cartas.")
	main.get_node("Music").stop()
	main.get_node("GameAudio").stop_effects()
	main.queue_free()
	await process_frame
	await process_frame
	for failure in failures: printerr("FALHA: "+failure)
	quit(0 if failures.is_empty() else 1)

func _walk(path: Array) -> void:
	for index in range(1,path.size()): await _step(path[index]-path[index-1])

func _prepare() -> void:
	var cards: CardPresentation = main.get_node("HUD").card_presentation
	await _until(func(): return trial.stage == SavageController.Stage.PRESENTATION and cards.visible and cards._cards.size() == 2 and not cards._cards[0].disabled)
	_expect(cards._current_values == trial.data.edict_values and not player.input_enabled and not trial.ui.timer.visible, "As duas cartas vêm antes do relógio e mostram os éditos do jogador.")
	_expect(cards._cards.all(func(card): return card.texture_normal == CardPresentation.CARD_BACK_CHAOTIC), "Todas as cartas do Chaotic precisam entrar com o verso bordô.")
	if not _card_pause_checked:
		_card_pause_checked = true
		cards._cards[0].pressed.emit()
		await create_timer(0.01,false).timeout
		var pause_menu: PauseOverlay = main.get_node("PauseOverlay")
		pause_menu._set_paused(true)
		for frame in range(12): await process_frame
		_expect(not cards._revealed[0] and trial.stage == SavageController.Stage.PRESENTATION, "ESC deve congelar também a revelação das cartas.")
		await pause_menu._close_sheet()
	for card in cards._cards: card.pressed.emit()
	await _until(func(): return trial.stage == SavageController.Stage.PREPARATION)

func _step(direction: Vector2i) -> void:
	var previous := player.current_cell
	for action: StringName in [&"move_up",&"move_down",&"move_left",&"move_right"]:
		if GridPlayer.camera_direction_for_action(root.get_camera_3d().global_rotation.y,action) != direction: continue
		var event := InputEventKey.new()
		event.physical_keycode = {&"move_up":KEY_W,&"move_down":KEY_S,&"move_left":KEY_A,&"move_right":KEY_D}[action]
		event.pressed = true
		root.push_input(event,true)
		await process_frame
		event.pressed = false
		root.push_input(event,true)
		await _until(func(): return not player.movement_locked)
		_expect(player.current_cell == previous+direction, "Tecla real precisa mover a casa correta.")
		return

func _until(predicate: Callable) -> void:
	var deadline := Time.get_ticks_msec()+20000
	while Time.get_ticks_msec() < deadline:
		if predicate.call(): return
		await process_frame
	printerr("FALHA: timeout Savage stage ",trial.stage if trial != null else -1)
	quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition: failures.append(message)
