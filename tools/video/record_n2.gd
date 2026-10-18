extends SceneTree
## Demonstration director: real game scenes, keyboard events and native card drags.
## MovieWriter records the viewport and the game's own audio, without desktop capture.

const FPS := 30.0
const EditoMachine = preload("res://scripts/gameplay/edito_state_machine.gd")
var frames := 0
var markers: Array = []
var main: Node
var manager: PhaseManager
var player: GridPlayer
var hud: GameHUD
var pointer: Node2D
var caption: Label
var mouse := Vector2(1770, 980)
var overlay: CanvasLayer
var dry_run := false
var report_path := "res://tmp/n2_video/timeline.json"

func _initialize() -> void:
	seed(20261018)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	root.content_scale_size = Vector2i(1920, 1080)
	for arg in OS.get_cmdline_user_args():
		if arg == "--dry-run": dry_run = true
	node_added.connect(_node_added)
	call_deferred("_run")

func _process(_delta: float) -> bool:
	frames += 1
	return false

func _node_added(node: Node) -> void:
	if node is PhaseManager: node.save_progress = false

func _time() -> float:
	return frames / FPS

func _mark(name: String) -> void:
	markers.append({"name": name, "time": _time(), "frame": frames})
	_write_report()
	print("N2_MARK: %s %.3f" % [name, _time()])

func _write_report() -> void:
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"fps": FPS, "duration": _time(), "markers": markers}, "\t"))

func _fail(message: String) -> void:
	printerr("N2_FAILURE: ", message)
	_mark("FAILED_" + message)
	quit(2)

func _wait(seconds: float) -> void:
	await create_timer(seconds, true).timeout

func _until(predicate: Callable, label: String, seconds := 60.0) -> void:
	var end := _time() + seconds
	while _time() < end:
		if predicate.call(): return
		await process_frame
	_fail("timeout: " + label)

func _run() -> void:
	var menu := (load("res://scenes/ui/main_menu.tscn") as PackedScene).instantiate()
	root.add_child(menu)
	current_scene = menu
	_build_overlay()
	_mark("menu_start")
	await _until(func(): return menu.intro_ready, "menu ready")
	await _wait(1.8)
	_mark("menu_click")
	await _click(menu.start_button.get_global_rect().get_center())
	await _until(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/main/main.tscn", "game scene")
	main = current_scene
	manager = main.get_node("PhaseManager")
	player = main.get_node("World/Player")
	hud = main.get_node("HUD")
	hud.tutorial_book.seen_chapters[2] = true
	hud.tutorial_book.seen_chapters[4] = true
	main.get_node("BalanceTrialController")._weight_rng.seed = 20261018
	main.get_node("SavageController")._rng.seed = 1842
	pointer.hide()
	_mark("opening_start")
	await _until(func(): return manager.current_phase == 1, "opening finished", 65.0)
	_mark("phase_1_start")
	await _read_book(1, 5.5)
	_caption("Objetivo: cumpra os éditos e termine na casa iluminada.\nWASD move uma casa por tecla. Nas fases iniciais, não há cronômetro.")
	await _reveal_cards("phase_1_first_cards")
	await _until(func(): return player.input_enabled, "phase 1 input")
	await _wait(1.5)
	var amount := int(manager.current_phase_data.edict_values[0])
	var wrong: Array = []
	_find_wrong(player.current_cell, player.current_cell, amount, [], wrong)
	_mark("failure_attempt_start")
	_caption("%s = %d. Cada movimento conta como um passo.\nIr e voltar pode deixar a distância final menor que a pedida." % [GameConstants.to_roman(amount), amount])
	for cell: Vector2i in wrong: await _step_to(cell)
	await _until(func(): return hud.failure_feedback.screen.visible, "failure explanation")
	_caption("")
	_mark("failure_visible")
	await _wait(7.0)
	_mark("failure_confirm")
	await _click(hud.failure_feedback.action.get_global_rect().get_center())
	await _reveal_cards("phase_1_retry_cards")
	await _until(func(): return player.input_enabled, "retry input")
	_mark("phase_1_solution")
	_caption("%s = %d. Agora, o caminho termina a %d casa(s) do início,\nexatamente no refúgio iluminado." % [GameConstants.to_roman(amount), amount, amount])
	await _solve_board(1)
	await _until(func(): return manager.current_phase == 2, "advance to 2")
	_mark("phase_2_start")
	_caption("Fase II · Dois éditos\nCumpra os números em ordem: primeiro a carta da esquerda, depois a da direita.")
	await _reveal_cards("phase_2_cards")
	await _solve_board(2)
	await _until(func(): return manager.current_phase == 3, "advance to 3")
	_mark("phase_3_start")
	_caption("")
	await _read_book(3, 6.0)
	_caption("Fase III · As torres atacam em linha reta.\nO numeral de cada peça indica quantas casas ela avança.")
	await _reveal_cards("phase_3_cards")
	await _solve_board(3)
	await _until(func(): return manager.current_phase == 4, "advance to 4")
	_mark("phase_4_start")
	_caption("Fase IV · Quatro torres, dois pares de ataques.\nAs flechas mostram qual par vai agir neste édito.")
	await _reveal_cards("phase_4_cards")
	await _solve_board(4)
	await _until(func(): return manager.current_phase == 5, "advance to 5")
	_mark("phase_5_start")
	_caption("")
	await _read_book(5, 5.5)
	_caption("Fase V · Bispos atacam pelas diagonais; torres, em linha reta.\nPlaneje a posição final de cada édito para evitar as duas ondas.")
	await _reveal_cards("phase_5_cards")
	await _solve_board(5)
	_caption("")
	await _until(func(): return manager.current_phase == 6, "advance to balance")
	_mark("phase_6_start")
	await _read_book(6, 7.0)
	var balance := main.get_node("BalanceTrialController") as BalanceTrialController
	for round_number in range(3):
		await _until(func(): return balance.stage == BalanceTrialController.Stage.DECISION and balance.round_index == round_number, "balance round")
		_mark("balance_round_%d" % round_number)
		var relation := ">" if balance.left_weight > balance.right_weight else "<"
		_caption("%s (%d) %s %s (%d)\nO lado mais pesado inclina o tabuleiro. Vá para o lado mais leve." % [GameConstants.to_roman(balance.left_weight), balance.left_weight, relation, GameConstants.to_roman(balance.right_weight), balance.right_weight])
		var safe_x := 0 if balance.heavy_direction > 0 else 4
		await _wait(0.6)
		while player.current_cell.x != safe_x:
			await _step_to(player.current_cell + (Vector2i.LEFT if safe_x < player.current_cell.x else Vector2i.RIGHT))
		await _until(func(): return balance.stage == BalanceTrialController.Stage.TILTING, "balance tilt")
		_mark("balance_tilt_%d" % round_number)
		await _until(func(): return balance.round_index > round_number or balance.stage == BalanceTrialController.Stage.COMPLETE, "balance resolved")
	_caption("")
	await _until(func(): return manager.current_phase == 7, "advance to cards")
	_mark("phase_7_transition")
	var trial := main.get_node("CardTrialController") as CardTrialController
	await _until(func(): return trial.table.visible and trial.table.canvas.modulate.a > 0.99, "card table")
	_mark("phase_7_ascending")
	_caption("Fase VII · Ordem crescente\nArraste os numerais do menor para o maior. A carta fixa serve de referência.")
	await _wait(2.5)
	await _solve_order(trial)
	await _wait(3.0)
	await _click(trial.table.submit.get_global_rect().get_center())
	_require(trial.state.solved, "ascending not solved")
	_mark("ascending_correct")
	await _wait(3.0)
	await _click(trial.table.continue_button.get_global_rect().get_center())
	_mark("phase_7_descending")
	_caption("Agora, ordem decrescente: do maior para o menor.\nA resposta só é confirmada depois de preencher os espaços.")
	await _wait(2.5)
	await _solve_order(trial)
	await _wait(2.5)
	await _click(trial.table.submit.get_global_rect().get_center())
	_require(trial.state.solved, "descending not solved")
	_mark("descending_correct")
	await _wait(2.5)
	await _click(trial.table.continue_button.get_global_rect().get_center())
	await _until(func(): return manager.current_phase == 8 and trial.table.title.text == "Associe os números", "matching")
	_mark("phase_8_matching")
	_caption("Fase VIII · Associe as escritas do mesmo número.\nXIV = 10 + 4 = 14 · XVIII = 10 + 5 + 3 = 18 · XIX = 10 + 9 = 19.")
	await _wait(3.5)
	for index in range(3):
		await _place(trial, index, trial.state.targets[index])
	await _wait(3.0)
	await _click(trial.table.submit.get_global_rect().get_center())
	_require(trial.state.solved, "matching not solved")
	_mark("matching_correct")
	await _wait(2.8)
	await _click(trial.table.continue_button.get_global_rect().get_center())
	_mark("phase_8_false_decree")
	_caption("Decreto falso · Encontre a correspondência incorreta.\nCompare o valor do numeral romano com o número indicado.")
	await _wait(5.0)
	var false_slot := trial.table.slots[trial.state.false_index]
	await _move(false_slot.get_global_rect().get_center(), 0.8)
	await _wait(1.6)
	await _click(false_slot.get_global_rect().get_center())
	_require(trial.state.solved, "false decree not solved")
	_mark("false_decree_correct")
	await _wait(3.5)
	_caption("")
	await _click(trial.table.continue_button.get_global_rect().get_center())
	await _wait(3.0)
	_mark("campaign_completed")
	await _key(KEY_ESCAPE)
	await _wait(1.0)
	_mark("pause_visible")
	_caption("O menu de pausa permite retomar a partida ou escolher uma prova.\nChaotic reúne desafios extras, com tempo e ataques combinados.")
	await _wait(4.0)
	var pause_menu := main.get_node("PauseOverlay") as PauseOverlay
	# The selector is an actual game control; the chosen item is changed before Ir.
	pause_menu.phase_selector.select(8)
	await _move(pause_menu.phase_selector.get_global_rect().get_center(), 0.6)
	await _wait(1.2)
	await _click(pause_menu.phase_button.get_global_rect().get_center())
	await _until(func(): return manager.current_phase == 101, "chaotic preview")
	_mark("chaotic_start")
	_caption("Chaotic · Desafio extra\nDez segundos para escolher a posição inicial; depois, cumpra os éditos no tempo.")
	await _reveal_cards("chaotic_cards")
	var savage := main.get_node("SavageController") as SavageController
	await _until(func(): return savage.stage == SavageController.Stage.PREPARATION, "chaotic preparation")
	_mark("chaotic_preparation")
	var solution: Dictionary = SavageCatalog.solutions(savage.data)[0]
	var prep: Array = SavageCatalog.route(player.current_cell, solution.start, 8)
	for i in range(1, prep.size()): await _step_to(prep[i])
	await _until(func(): return savage.stage == SavageController.Stage.MOVING, "chaotic moving")
	_mark("chaotic_moving")
	for i in range(1, solution.first.size()): await _step_to(solution.first[i])
	await _until(func(): return savage.wave_index == 1 and savage.stage == SavageController.Stage.MOVING, "chaotic second wave")
	_mark("chaotic_second_wave")
	for i in range(1, solution.second.size()): await _step_to(solution.second[i])
	await _until(func(): return savage.stage == SavageController.Stage.CLEARED, "chaotic completed")
	_mark("chaotic_completed")
	_caption("")
	await _wait(2.0)
	# Conclude on the original main menu, with its own soundtrack.
	await _key(KEY_ESCAPE)
	await _wait(0.7)
	await _click(pause_menu.main_menu_button.get_global_rect().get_center())
	await _until(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/ui/main_menu.tscn", "return to menu")
	_caption("")
	pointer.hide()
	await _wait(11.5)
	_mark("end")
	quit()

func _require(value: bool, message: String) -> void:
	if not value: _fail(message)

func _read_book(number: int, hold: float) -> void:
	await _until(func(): return hud.tutorial_book.state == TutorialBook.State.READING and hud.tutorial_book.current_chapter == number, "chapter %d" % number)
	_mark("book_%d_reading" % number)
	await _until(func(): return hud.tutorial_book.reveal_progress > 0.999, "chapter ink")
	_mark("book_%d_revealed" % number)
	await _wait(hold)
	_mark("book_%d_close" % number)
	# Clicking outside the volume uses the game's normal book-close interaction.
	await _click(Vector2(1870, 1000))
	await _until(func(): return not hud.tutorial_book.visible, "chapter closed")
	_mark("book_%d_hidden" % number)

func _reveal_cards(name: String) -> void:
	var cards := hud.card_presentation
	await _until(func(): return cards.visible and not cards._cards.is_empty() and not cards._cards[0].disabled, name)
	_mark(name + "_start")
	await _wait(0.5)
	for card in cards._cards:
		await _click(card.get_global_rect().get_center())
	_mark(name + "_flipped")
	await _until(func(): return not cards.visible, name + " burned")
	pointer.hide()
	_mark(name + "_end")

func _solve_board(number: int) -> void:
	var loop := main.get_node("PhaseLoopController") as PhaseLoopController
	var routes: Array = PhaseManager.Vanilla.solution(manager.current_phase_data)
	await _until(func(): return player.input_enabled, "board input %d" % number)
	_mark("phase_%d_walk" % number)
	await _wait(1.0)
	for index in range(routes.size()):
		if index > 0:
			await _until(func(): return player.input_enabled and loop._edito_machine.indice_edito_atual == index, "next edict")
			_mark("phase_%d_edict_%d" % [number, index])
		for destination: Vector2i in routes[index]: await _step_to(destination)
	await _until(func(): return loop._edito_machine.estado_atual == EditoMachine.Estado.FINALIZADO, "board cleared %d" % number)
	_mark("phase_%d_correct" % number)

func _find_wrong(origin: Vector2i, at: Vector2i, remaining: int, path: Array, result: Array) -> bool:
	if remaining == 0:
		var final := Vector2i(int(manager.current_phase_data.safe_spot[0]), int(manager.current_phase_data.safe_spot[1]))
		var amount := int(manager.current_phase_data.edict_values[0])
		if (at - origin).abs().x + (at - origin).abs().y != amount or (amount == 1 and at != final):
			result.assign(path)
			return true
		return false
	for direction in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next: Vector2i = at + direction
		if next.x < 0 or next.x > 4 or next.y < 0 or next.y > 4: continue
		var next_path := path.duplicate()
		next_path.append(next)
		if _find_wrong(origin, next, remaining - 1, next_path, result): return true
	return false

func _step_to(destination: Vector2i) -> void:
	await _until(func(): return not player.movement_locked and player.input_enabled, "step available")
	var direction := destination - player.current_cell
	var camera := root.get_camera_3d()
	var chosen := 0
	for pair in [[&"move_up", KEY_W], [&"move_left", KEY_A], [&"move_down", KEY_S], [&"move_right", KEY_D]]:
		if GridPlayer.camera_direction_for_action(camera.global_rotation.y, pair[0]) == direction:
			chosen = pair[1]
	_require(chosen != 0, "invalid route step")
	await _key(chosen)
	await _until(func(): return not player.movement_locked, "step finished")
	_require(player.current_cell == destination, "step rejected")
	await _wait(0.10)

func _key(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event, true)
	await process_frame

func _solve_order(trial: CardTrialController) -> void:
	for index in range(6):
		if index == trial.state.anchor_index: continue
		var value := trial.state.anchor_value + (index - trial.state.anchor_index) * (1 if trial.state.ascending else -1)
		await _place(trial, index, value)

func _place(trial: CardTrialController, index: int, value: int) -> void:
	await _move(trial.table.hand.card_point(value), 0.45)
	await _wait(0.30)
	var start := mouse
	await _button(true)
	await _move(trial.table.slots[index].get_global_rect().get_center(), 0.85, true)
	await _wait(0.15)
	await _button(false)
	await _wait(0.30)
	_require(trial.state.slots[index] == value, "drag failed %d at %d, from %s" % [value, index, start])
	_mark("drag_%d_%d" % [index, value])

func _move(target: Vector2, seconds := 0.35, dragging := false) -> void:
	pointer.show()
	var start := mouse
	var count := maxi(1, roundi(seconds * FPS))
	for index in range(1, count + 1):
		var point := start.lerp(target, smoothstep(0.0, 1.0, float(index) / count))
		var event := InputEventMouseMotion.new()
		event.position = point
		event.global_position = point
		event.relative = point - mouse
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if dragging else 0
		mouse = point
		pointer.position = point
		root.push_input(event, true)
		await process_frame

func _button(pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = mouse
	event.global_position = mouse
	root.push_input(event, true)
	pointer.modulate = Color(1.0, 0.78, 0.35) if pressed else Color.WHITE
	await process_frame

func _click(point: Vector2) -> void:
	await _move(point)
	await _button(true)
	await _wait(0.10)
	await _button(false)
	await _wait(0.10)

func _caption(words: String) -> void:
	caption.text = words
	caption.get_parent().visible = not words.is_empty()

func _build_overlay() -> void:
	overlay = CanvasLayer.new()
	overlay.layer = 120
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(overlay)
	var box := PanelContainer.new()
	box.position = Vector2(180, 20)
	box.size = Vector2(1560, 110)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.012, 0.03, 0.89)
	style.set_corner_radius_all(5)
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.border_color = Color(0.72, 0.55, 0.31, 0.8)
	style.border_width_bottom = 2
	box.add_theme_stylebox_override("panel", style)
	overlay.add_child(box)
	caption = Label.new()
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_override("font", load("res://assets/fonts/Alegreya-Variable.ttf"))
	caption.add_theme_font_size_override("font_size", 32)
	caption.add_theme_color_override("font_color", Color(0.98, 0.94, 0.84))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(caption)
	box.hide()
	pointer = Node2D.new()
	pointer.position = mouse
	var vertices := PackedVector2Array([Vector2(0,0), Vector2(0,29), Vector2(7,22), Vector2(13,34), Vector2(19,31), Vector2(13,20), Vector2(24,20)])
	var fill := Polygon2D.new()
	fill.polygon = vertices
	fill.color = Color(1, 0.98, 0.9)
	pointer.add_child(fill)
	var border := Line2D.new()
	border.points = vertices
	border.add_point(vertices[0])
	border.width = 2.0
	border.default_color = Color(0.05, 0.03, 0.02)
	pointer.add_child(border)
	overlay.add_child(pointer)
	pointer.hide()
