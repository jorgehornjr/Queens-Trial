extends SceneTree

const HudScene = preload("res://scenes/ui/hud.tscn")
const CARD_BACK = preload("res://assets/cards/back.png")
const CARD_FOUR = preload("res://assets/cards/4.jpg")

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
	_expect(hud.get_node_or_null("StartPrompt") == null, "A abertura não deve mostrar instrução de Enter.")
	_expect(hud.get_node_or_null("TutorialHint") == null, "A HUD não deve mostrar frases de movimentação fora do livro.")
	_expect(hud.get_node_or_null("RoundEdicts") == null, "A HUD não pode manter os numerais fora das cartas.")
	_expect(hud.get_node_or_null("TopPanel/Content/GoalLabel") == null,
		"A HUD não pode revelar linha e coluna do destino.")
	_expect(hud.get_node_or_null("TopPanel/Content/PositionLabel") == null,
		"A HUD não pode revelar linha e coluna do jogador.")
	hud.free()
	await process_frame


func _test_phase_one_presentation() -> void:
	var scene := load("res://scenes/main/main.tscn") as PackedScene
	var main := scene.instantiate()
	main.set("opening_cutscene_enabled", false)
	root.add_child(main)
	await process_frame
	await process_frame
	var manager := main.get_node("PhaseManager") as PhaseManager
	manager.start_phase(1)
	await create_timer(0.15).timeout
	var hud := main.get_node("HUD") as GameHUD
	var presentation := hud.card_presentation
	var board := main.get_node("World/Board") as Board3D
	var player := main.get_node("World/Player") as GridPlayer
	_expect(not board.get_node("LevitationMist") is FogVolume,
		"O tabuleiro isolado não deve conter um FogVolume sem ambiente no editor.")
	_expect(board.get_node_or_null("LevitationMist/VolumetricMist") is FogVolume,
		"A neblina volumétrica deve ser preservada no jogo em execução.")
	var book := hud.tutorial_book
	_expect(book.visible and book.cover.visible and not player.input_enabled,
		"O livro deve chegar fechado e impedir movimentos antes das cartas.")
	_expect(await _wait_until(func(): return book.state == TutorialBook.State.OPENING),
		"O livro deve entrar na animação de abertura.")
	_expect(book.closing_cover.visible and not book.cover.visible and not book.spread.visible,
		"A abertura deve girar a capa pela lombada em vez de trocar sua opacidade.")
	var opening_progress := float(book.closing_cover.get("progress"))
	await create_timer(0.35).timeout
	_expect(float(book.closing_cover.get("progress")) < opening_progress,
		"Abrir deve percorrer o mesmo movimento do fechamento em sentido inverso.")
	_expect(await _wait_until(func(): return book.state == TutorialBook.State.READING),
		"O livro deve se abrir no primeiro capítulo.")
	_expect("Torre" not in book.body_label.text and "Bispo" not in book.body_label.text,
		"A primeira fase deve ensinar somente um édito e os movimentos.")
	_expect(book.illustration.texture != null and book.title_label.get_theme_font("font") == TutorialBook.TITLE_FONT,
		"O livro deve ter gravura própria e usar Engravers nos títulos.")
	book.turn_page(-1)
	await _wait_until(func(): return book.state == TutorialBook.State.READING and book.table_visible)
	_expect(book.table_visible and not book.illustration.visible,
		"A aba deve abrir a tabela sem fechar o tutorial.")
	book.turn_page(1)
	await _wait_until(func(): return book.state == TutorialBook.State.READING and not book.table_visible)
	await create_timer(0.3).timeout
	_expect(book.visible and presentation._cards.is_empty() and not player.input_enabled,
		"O livro deve aguardar o clique antes de apresentar as cartas.")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = Vector2(40, 40)
	click.pressed = true
	book._input(click)
	await process_frame
	_expect(book.state == TutorialBook.State.CLOSING,
		"O clique fora do livro também deve solicitar o fechamento.")
	_expect(await _wait_until(func(): return book.closing_cover.visible and float(book.closing_cover.get("progress")) > 0.55),
		"A capa da frente deve girar pela lombada durante o fechamento.")
	_expect(book.visible and not book.spread.visible and presentation._cards.is_empty(),
		"A animação da capa deve manter as cartas bloqueadas.")
	_expect(await _wait_until(func(): return book.cover.visible),
		"O fechamento deve terminar mostrando a capa da frente.")
	_expect(book.visible and book.cover.visible and not book.spread.visible,
		"A capa deve reaparecer antes de o livro sumir.")
	_expect(book.cover_art.texture == TutorialBook.COVER,
		"A imagem final deve ser a capa aprovada, com o desenho da rainha.")
	_expect(book.right_stack.modulate.a < 0.001,
		"O bloco de folhas deve estar totalmente coberto antes de a camada ser ocultada.")
	_expect(await _wait_until(func(): return presentation._cards.size() == 1 and not presentation._cards[0].disabled),
		"A carta da fase I deve ficar disponível após o livro.")
	if presentation._cards.size() == 1:
		_expect(presentation._cards[0].texture_normal == CARD_BACK, "A carta deve entrar mostrando o verso.")
		_expect(presentation.card_area.get_node_or_null("ClickHint") == null,
			"A instrução de clique sob a carta deve ficar no livro.")
		var card := presentation._cards[0] as TextureButton
		var rest_position: Vector2 = card.get_meta("rest_position")
		card.mouse_entered.emit()
		await create_timer(0.25).timeout
		_expect(card.scale.x > 1.08 and card.position.y < rest_position.y,
			"Passar o mouse deve aproximar a carta sem virá-la.")
		_expect(card.texture_normal == CARD_BACK, "Hover não deve virar a carta.")
		card.mouse_exited.emit()
		await create_timer(0.25).timeout
		_expect(card.scale.is_equal_approx(Vector2.ONE), "A carta deve voltar ao tamanho normal ao sair do hover.")
		presentation._cards[0].pressed.emit()
		_expect(await _wait_until(func(): return presentation._cards[0].texture_normal == CARD_FOUR),
			"O clique deve virar a carta IV para a frente correta.")
		_expect(presentation._cards[0].material == null,
			"A frente da carta deve manter o fundo claro e as cores originais.")
		_expect(await _wait_until(func(): return presentation.card_area.get_node_or_null("CardBurnAura") != null),
			"A queima deve criar a camada de chamas e fumaça junto à carta.")
		_expect(presentation.card_area.get_node_or_null("CardEmbers") == null,
			"A queima não deve reutilizar as partículas circulares antigas.")
	_expect(await _wait_until(func(): return is_instance_valid(board._tutorial_guide) and board._tutorial_guide.playing),
		"A queima da carta deve iniciar o caminho estrelado.")
	_expect(not presentation.visible, "A carta deve desaparecer depois da queima.")
	_expect(player.get_node_or_null("RemainingMoves") == null,
		"O jogador não deve mais exibir o numeral de movimentos sobre a cabeça.")
	_expect(not player.input_enabled,
		"O jogador deve esperar o caminho chegar ao refúgio.")
	var origin := player.current_cell
	player._try_move(Vector2i.LEFT)
	_expect(player.current_cell == origin, "Andar durante a orientação deve ser ignorado.")
	_expect(board.can_player_enter(Vector2i(2, 2)), "A casa central deve estar jogável.")
	await create_timer(0.8).timeout
	_expect(board._tutorial_guide.reveal > 0.0 and board._tutorial_guide.reveal < 0.6,
		"As estrelas devem se revelar ao longo da curva, sem acender juntas.")
	_expect(await _wait_until(func(): return player.input_enabled),
		"O jogador deve ser liberado quando o caminho terminar.")
	_expect(board._tutorial_guide.reveal > 0.99,
		"O caminho completo deve continuar visível depois da orientação.")
	player._try_move(Vector2i.UP)
	await create_timer(0.9).timeout
	_expect(not presentation.visible, "O numeral não pode reaparecer depois de andar.")
	manager.restart_phase()
	await create_timer(0.15).timeout
	_expect(not book.visible, "O guia não deve se repetir ao reiniciar a fase.")
	_expect(await _wait_until(func(): return presentation._cards.size() == 1 and not presentation._cards[0].disabled),
		"O reinício deve apresentar novamente a carta fechada.")
	if presentation._cards.size() == 1:
		presentation._cards[0].pressed.emit()
		await _wait_until(func(): return player.input_enabled)
	main.queue_free()
	await process_frame
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _wait_until(predicate: Callable, limit := 2400) -> bool:
	for _frame in range(limit):
		if predicate.call():
			return true
		await process_frame
	return false
