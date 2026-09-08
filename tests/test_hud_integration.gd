extends SceneTree

const HudScene = preload("res://scenes/ui/hud.tscn")

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run_tests")


func _run_tests() -> void:
	_test_interior_mist_scope()
	await _test_minimal_hud()
	await _test_phase_one_presentation()
	if failures.is_empty():
		print("OK: HUD e tutorial da fase I validados.")
		quit(0)
		return
	for failure in failures:
		printerr("FALHA: " + failure)
	quit(1)


func _test_interior_mist_scope() -> void:
	var Aura = preload("res://scripts/gameplay/square_aura.gd")
	var attack := Aura.new()
	attack.configure(7.9, Color(0.64, 0.08, 1.0, 0.72), 1.15)
	_expect(attack.get_child_count() == 5 and attack.get_node_or_null("InteriorMist0") == null,
		"O ataque aprovado não pode receber névoa interna nem mudar sua geometria.")
	attack.free()
	var guidance := Aura.new()
	guidance.configure(7.9, Color.GREEN, 2.25, 0.0, true)
	_expect(guidance.get_child_count() == 8, "As auras de orientação devem ter três camadas suaves de névoa interna.")
	guidance.reveal = 0.0
	for index in range(3):
		var material := guidance.get_node("InteriorMist%d" % index).material_override as ShaderMaterial
		_expect(material.get_shader_parameter("reveal") == 0.0, "A névoa deve acompanhar a revelação gradual da casa.")
	guidance.free()


func _test_minimal_hud() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame
	hud.set_phase(1, {}, 0)
	_expect(not hud.get_node("PhasePanel").visible, "O título PROVA não deve aparecer no topo da HUD.")
	_expect(not hud.tutorial_hint.visible, "As dicas de movimentação devem permanecer ocultas.")
	_expect(hud.get_node_or_null("TopPanel/Content/GoalLabel") == null,
		"A HUD não pode revelar linha e coluna do destino.")
	_expect(hud.get_node_or_null("TopPanel/Content/PositionLabel") == null,
		"A HUD não pode revelar linha e coluna do jogador.")
	hud.free()
	await process_frame


func _test_phase_one_presentation() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	manager.start_phase(1)
	await create_timer(0.15).timeout
	var hud := main.get_node("HUD") as GameHUD
	var board := main.get_node("World/Board") as Board3D
	var player := main.get_node("World/Player") as GridPlayer
	_expect(not board.get_node("LevitationMist") is FogVolume,
		"O tabuleiro isolado não deve conter um FogVolume sem ambiente no editor.")
	_expect(board.get_node_or_null("LevitationMist/VolumetricMist") is FogVolume,
		"A neblina volumétrica deve ser preservada no jogo em execução.")
	_expect(hud.announcement.visible and hud.announcement_label.text == "INÍCIO",
		"A primeira fase deve começar com INÍCIO no mesmo anúncio dos éditos.")
	_expect(hud.announcement_label.get_theme_font("font").resource_path.ends_with("dune_rise.otf"),
		"Frases de apresentação devem manter a fonte Dune.")
	var saw_first_edict := false
	for attempt in range(200):
		if hud.announcement.visible and hud.announcement_label.text == "IV":
			saw_first_edict = true
		if player.input_enabled:
			break
		await create_timer(0.05).timeout
	_expect(saw_first_edict, "Após INÍCIO, a primeira fase deve apresentar IV antes de liberar o jogador.")
	_expect(player.input_enabled, "O jogador deve ser liberado depois da apresentação do édito.")
	var reminder := hud.get_node("RoundEdicts") as Label
	_expect(player.get_node_or_null("RemainingMoves") == null,
		"O jogador não deve mais exibir o numeral de movimentos sobre a cabeça.")
	_expect(reminder.text == "IV" and reminder.visible,
		"O édito original deve permanecer visível durante a rodada.")
	_expect(is_equal_approx(reminder.anchor_left, 0.87) and is_equal_approx(reminder.anchor_top, 0.52),
		"O par fixo deve ocupar a lateral direita durante a rodada.")
	_expect(reminder.get_theme_font("font").resource_path.ends_with("jupiter_pro.otf"),
		"Os numerais romanos fixos devem utilizar Jupiter Pro Regular.")
	_expect(board._tutorial_markers.size() == 4,
		"As quatro casas do caminho tutorial devem acender em sequência.")
	_expect(board.can_player_enter(Vector2i(2, 2)), "A casa central deve estar jogável.")
	await create_timer(0.8).timeout
	_expect(board._tutorial_markers[0].reveal > 0.99,
		"A primeira casa deve permanecer acesa quando a segunda começa.")
	_expect(board._tutorial_markers[2].reveal == 0.0,
		"O tutorial deve revelar as casas lentamente, sem acender todas juntas.")
	await create_timer(2.9).timeout
	for marker in board._tutorial_markers:
		_expect(marker.reveal > 0.99, "As casas já apresentadas devem continuar acesas.")
	player._try_move(Vector2i.UP)
	await create_timer(0.9).timeout
	_expect(reminder.text == "IV" and reminder.visible, "O édito fixo não pode diminuir ao andar.")
	manager.restart_phase()
	await create_timer(0.15).timeout
	_expect(hud.announcement_label.text == "IV", "INÍCIO não deve se repetir ao reiniciar a primeira fase.")
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
