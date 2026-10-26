class_name ChaoticCardPresentation
extends CardPresentation


const SYMBOL_FONT: Font = preload("res://assets/fonts/Alegreya-Variable.ttf")
const MEMORY_SECONDS := 5.0
var _operations: Array = []
var _groups: Array[Control] = []
var _second_pair := false

func present_operations(operations: Array) -> void:
	_operations = operations.duplicate(true)
	var values: Array = []
	for equation: Dictionary in _operations:
		values.append(int(equation.left))
		values.append(int(equation.right))
	cancel()
	var run_id := _generation
	_current_values = values
	show()
	veil.modulate = Color.WHITE
	card_area.modulate = Color.WHITE
	_spawn_cards(values, run_id, CARD_BACK_CHAOTIC)
	await get_tree().create_timer(0.75, false).timeout
	if run_id != _generation: return
	_cards[0].disabled = false
	_cards[1].disabled = false
	await finished

func _spawn_cards(values: Array, run_id: int, back_texture: Texture2D) -> void:
	_groups.clear()
	_second_pair = false
	card_area.show()
	var view := get_viewport_rect().size
	var factor := minf(view.x / 1920.0, view.y / 1080.0)
	for pair in range(2):
		var group := Control.new()
		group.name = "Equation%d" % (pair + 1)
		group.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.size = Vector2(710, 500)
		group.scale = Vector2.ONE * factor
		group.position = (view - Vector2(710, 427) * factor) * 0.5 - Vector2(0, 80 * factor)
		group.z_index = pair * 4
		card_area.add_child(group)
		_groups.append(group)
		var symbol := Label.new()
		symbol.name = "OperationSymbol"
		symbol.text = "÷" if _operations[pair].operator == "divide" else "−"
		symbol.position = Vector2(300, 145)
		symbol.size = Vector2(110, 120)
		symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		symbol.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		symbol.add_theme_font_override("font", SYMBOL_FONT)
		symbol.add_theme_font_size_override("font_size", 110)
		symbol.add_theme_color_override("font_color", Color(1.0, 0.91, 0.75))
		symbol.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.01))
		symbol.add_theme_constant_override("outline_size", 7)
		symbol.mouse_filter = Control.MOUSE_FILTER_IGNORE
		group.add_child(symbol)
		for side in range(2):
			var index := pair * 2 + side
			var card := TextureButton.new()
			card.name = "Operand%d" % index
			card.texture_normal = back_texture
			card.material = Assets.card_material()
			card.ignore_texture_size = true
			card.stretch_mode = TextureButton.STRETCH_SCALE
			card.size = CARD_SIZE
			card.pivot_offset = CARD_SIZE * 0.5
			card.position = Vector2(side * 410, 0)
			card.set_meta("rest_position", card.position)
			card.set_meta("hover_lift", 12.0)
			card.focus_mode = Control.FOCUS_NONE
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			card.disabled = true
			card.pressed.connect(_on_card_pressed.bind(index, run_id))
			card.mouse_entered.connect(_animate_card_hover.bind(index, run_id, true))
			card.mouse_exited.connect(_animate_card_hover.bind(index, run_id, false))
			group.add_child(card)
			_cards.append(card)
			_revealed.append(false)
			_flipping.append(false)
		group.visible = pair == 0
	_groups[0].modulate.a = 0.0
	var entrance := create_tween()
	_track(entrance)
	entrance.tween_property(_groups[0], "modulate:a", 1.0, 0.65)

func _on_card_pressed(index: int, run_id: int) -> void:
	if index >= 2 and not _second_pair: return
	super._on_card_pressed(index, run_id)

func _flip_card(index: int, run_id: int) -> void:
	await super._flip_card(index, run_id)
	if run_id != _generation: return
	if _revealed[0] and _revealed[1] and not _second_pair:
		_second_pair = true
		await get_tree().create_timer(1.8, false).timeout
		if run_id != _generation: return
		var factor := _groups[0].scale.x
		var slide := create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_track(slide)
		slide.tween_property(_groups[0], "position:y", _groups[0].position.y - 110 * factor, 0.6)
		_groups[1].position.y += 100 * factor
		_groups[1].modulate.a = 0.0
		_groups[1].show()
		slide.tween_property(_groups[1], "modulate:a", 1.0, 0.6)
		await slide.finished
		if run_id != _generation: return
		_cards[2].disabled = false
		_cards[3].disabled = false

func _finish_cards(run_id: int) -> void:
	await get_tree().create_timer(0.7, false).timeout
	if run_id != _generation: return
	var view := get_viewport_rect().size
	var factor := minf(view.x / 1920.0, view.y / 1080.0)
	var size_factor := factor * 0.55
	var slide := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_track(slide)
	for index in range(2):
		var target := Vector2(32 * factor if index == 0 else view.x - 32 * factor - 710 * size_factor, view.y * 0.31)
		slide.tween_property(_groups[index], "position", target, 0.9)
		slide.tween_property(_groups[index], "scale", Vector2.ONE * size_factor, 0.9)
	slide.tween_property(veil, "modulate:a", 0.22, 0.9)
	await slide.finished
	if run_id != _generation: return
	await get_tree().create_timer(MEMORY_SECONDS, false).timeout
	if run_id != _generation: return
	var overlays: Array[ColorRect] = []
	burn_started.emit()
	for index in range(4):
		var card := _cards[index]
		var material := ShaderMaterial.new()
		material.shader = BURN_SHADER
		Assets.apply_paper_tone(material, int(_current_values[index]))
		material.set_shader_parameter("burn_seed", float(index) * 2.37 + 0.41)
		card.material = material
		var aura := _create_burn_aura(card, float(index) * 2.37 + 0.41)
		card.get_parent().add_child(aura)
		overlays.append(aura)
		var burn := create_tween()
		_track(burn)
		burn.tween_method(_set_burn_progress.bind(card, aura), 0.0, 1.0, BURN_DURATION)
	for group in _groups:
		var ink := create_tween()
		_track(ink)
		ink.tween_property(group.get_node("OperationSymbol"), "modulate:a", 0.0, BURN_DURATION)
	await get_tree().create_timer(BURN_DURATION + 0.05, false).timeout
	if run_id != _generation: return
	for card in _cards: card.hide()
	var fade_out := create_tween().set_parallel(true)
	_track(fade_out)
	fade_out.tween_property(card_area, "modulate:a", 0.0, 0.6)
	fade_out.tween_property(veil, "modulate:a", 0.0, 0.6)
	await fade_out.finished
	if run_id != _generation: return
	burn_cancelled.emit()
	hide()
	finished.emit()
