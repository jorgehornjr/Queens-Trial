class_name CardPresentation
extends Control

signal finished
signal burn_started
signal burn_cancelled

const CARD_BACK: Texture2D = preload("res://assets/cards/back.png")
const CARD_FRONTS := [
	preload("res://assets/cards/1.jpg"),
	preload("res://assets/cards/2.jpg"),
	preload("res://assets/cards/3.jpg"),
	preload("res://assets/cards/4.jpg"),
]
const BURN_SHADER: Shader = preload("res://shaders/card_burn.gdshader")
const BURN_AURA_SHADER: Shader = preload("res://shaders/card_burn_aura.gdshader")
const CARD_SIZE := Vector2(300.0, 427.0)
const BURN_PADDING := Vector2(40.0, 76.0)
const BURN_DURATION := 1.65

@onready var veil: ColorRect = $Veil
@onready var card_area: Control = $CardArea

var _generation := 0
var _tweens: Array[Tween] = []
var _cards: Array[TextureButton] = []
var _revealed: Array[bool] = []
var _flipping: Array[bool] = []
var _hover_tweens: Dictionary = {}
var _current_values: Array = []


func _ready() -> void:
	visible = false


func cancel() -> void:
	burn_cancelled.emit()
	_generation += 1
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	for hover_tween: Tween in _hover_tweens.values():
		if hover_tween.is_valid():
			hover_tween.kill()
	for child in card_area.get_children():
		child.queue_free()
	_cards.clear()
	_revealed.clear()
	_flipping.clear()
	_hover_tweens.clear()
	_current_values.clear()
	card_area.visible = false
	visible = false
	finished.emit()


func present(values: Array) -> void:
	cancel()
	var run_id := _generation
	_current_values = values.duplicate()
	visible = true
	veil.modulate = Color.WHITE
	card_area.modulate = Color.WHITE
	_spawn_cards(values, run_id)
	await get_tree().create_timer(0.75).timeout
	if run_id != _generation:
		return
	for card in _cards:
		card.disabled = false
		if card.get_global_rect().has_point(get_viewport().get_mouse_position()):
			_animate_card_hover(_cards.find(card), run_id, true)
	await finished


func _spawn_cards(values: Array, run_id: int) -> void:
	card_area.visible = true
	card_area.modulate = Color.WHITE
	var viewport_size := get_viewport_rect().size
	var scale_factor := minf(1.0, minf(viewport_size.x / 1150.0, viewport_size.y / 690.0))
	var card_size := CARD_SIZE * scale_factor
	var gap := 50.0 * scale_factor
	var total_width := float(values.size()) * card_size.x + float(maxi(values.size() - 1, 0)) * gap
	var first_x := (viewport_size.x - total_width) * 0.5
	var top_y := (viewport_size.y - card_size.y) * 0.5 - 40.0 * scale_factor
	for index in range(values.size()):
		var value := int(values[index])
		if value < 1 or value > CARD_FRONTS.size():
			push_error("Carta inválida para o édito: %d" % value)
			continue
		var card := TextureButton.new()
		card.name = "EdictCard%d" % index
		card.texture_normal = CARD_BACK
		card.ignore_texture_size = true
		card.stretch_mode = TextureButton.STRETCH_SCALE
		card.size = card_size
		card.custom_minimum_size = card_size
		card.pivot_offset = card_size * 0.5
		card.position = Vector2(first_x + float(index) * (card_size.x + gap), top_y + 115.0 * scale_factor)
		card.scale = Vector2(0.78, 0.78)
		card.modulate.a = 0.0
		card.disabled = true
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.set_meta("rest_position", Vector2(first_x + float(index) * (card_size.x + gap), top_y))
		card.set_meta("hover_lift", 15.0 * scale_factor)
		card.pressed.connect(_on_card_pressed.bind(index, run_id))
		card.mouse_entered.connect(_animate_card_hover.bind(index, run_id, true))
		card.mouse_exited.connect(_animate_card_hover.bind(index, run_id, false))
		card_area.add_child(card)
		_cards.append(card)
		_revealed.append(false)
		_flipping.append(false)
		var entrance := create_tween()
		_track(entrance)
		entrance.set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		entrance.tween_property(card, "position:y", top_y, 0.55).set_delay(float(index) * 0.11)
		entrance.tween_property(card, "scale", Vector2.ONE, 0.55).set_delay(float(index) * 0.11)
		entrance.tween_property(card, "modulate:a", 1.0, 0.38).set_delay(float(index) * 0.11)


func _on_card_pressed(index: int, run_id: int) -> void:
	if run_id != _generation or index >= _cards.size() or _revealed[index] or _flipping[index]:
		return
	_flipping[index] = true
	var card := _cards[index]
	card.disabled = true
	var hover_tween := _hover_tweens.get(index) as Tween
	if hover_tween != null and hover_tween.is_valid():
		hover_tween.kill()
	card.position = card.get_meta("rest_position")
	card.scale = Vector2.ONE
	card.z_index = 0
	_flip_card(index, run_id)


func _animate_card_hover(index: int, run_id: int, hovered: bool) -> void:
	if run_id != _generation or index >= _cards.size() or _flipping[index] or _revealed[index]:
		return
	var card := _cards[index]
	if card.disabled:
		return
	var old_tween := _hover_tweens.get(index) as Tween
	if old_tween != null and old_tween.is_valid():
		old_tween.kill()
	var rest_position: Vector2 = card.get_meta("rest_position")
	var target_position := rest_position - Vector2(0.0, float(card.get_meta("hover_lift"))) if hovered else rest_position
	card.z_index = 2 if hovered else 0
	var hover_tween := create_tween()
	_hover_tweens[index] = hover_tween
	hover_tween.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(card, "position", target_position, 0.22)
	hover_tween.tween_property(card, "scale", Vector2.ONE * (1.1 if hovered else 1.0), 0.22)


func _flip_card(index: int, run_id: int) -> void:
	var card := _cards[index]
	var close := create_tween()
	_track(close)
	close.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	close.tween_property(card, "scale:x", 0.0, 0.18)
	await get_tree().create_timer(0.19).timeout
	if run_id != _generation:
		return
	var value := int(_current_values[index])
	card.texture_normal = CARD_FRONTS[value - 1]
	card.material = null
	var open := create_tween()
	_track(open)
	open.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	open.tween_property(card, "scale:x", 1.0, 0.24)
	await get_tree().create_timer(0.25).timeout
	if run_id != _generation:
		return
	_revealed[index] = true
	if _revealed.all(func(revealed: bool): return revealed):
		_finish_cards(run_id)


func _finish_cards(run_id: int) -> void:
	await get_tree().create_timer(1.45).timeout
	if run_id != _generation:
		return
	var overlays: Array[ColorRect] = []
	burn_started.emit()
	for index in range(_cards.size()):
		var card := _cards[index]
		var material := ShaderMaterial.new()
		material.shader = BURN_SHADER
		material.set_shader_parameter("burn_seed", float(index) * 2.37 + 0.41)
		card.material = material
		var aura := _create_burn_aura(card, float(index) * 2.37 + 0.41)
		card_area.add_child(aura)
		overlays.append(aura)
		var burn := create_tween()
		_track(burn)
		burn.tween_interval(float(index) * 0.09)
		burn.tween_method(_set_burn_progress.bind(card, aura), 0.0, 1.0, BURN_DURATION)
	await get_tree().create_timer(BURN_DURATION + 0.13).timeout
	if run_id != _generation:
		return
	for card in _cards:
		card.visible = false
	for aura in overlays:
		var drift := create_tween()
		_track(drift)
		drift.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		drift.tween_property(aura.material, "shader_parameter/aftermath", 1.0, 0.68)
	await get_tree().create_timer(0.70).timeout
	if run_id != _generation:
		return
	var fade := create_tween()
	_track(fade)
	fade.set_parallel(true)
	fade.tween_property(card_area, "modulate:a", 0.0, 0.25)
	fade.tween_property(veil, "modulate:a", 0.0, 0.25)
	await get_tree().create_timer(0.28).timeout
	if run_id != _generation:
		return
	visible = false
	finished.emit()


func _set_burn_progress(progress: float, card: TextureButton, aura: ColorRect) -> void:
	if not is_instance_valid(card) or not is_instance_valid(aura):
		return
	(card.material as ShaderMaterial).set_shader_parameter("burn_progress", progress)
	(aura.material as ShaderMaterial).set_shader_parameter("burn_progress", progress)


func _create_burn_aura(card: TextureButton, seed: float) -> ColorRect:
	var aura := ColorRect.new()
	aura.name = "CardBurnAura"
	aura.position = card.position - BURN_PADDING
	aura.size = card.size + BURN_PADDING * 2.0
	aura.color = Color.WHITE
	aura.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aura.z_index = card.z_index + 1
	var material := ShaderMaterial.new()
	material.shader = BURN_AURA_SHADER
	material.set_shader_parameter("burn_seed", seed)
	material.set_shader_parameter("burn_progress", 0.0)
	material.set_shader_parameter("aftermath", 0.0)
	material.set_shader_parameter("card_size_px", card.size)
	material.set_shader_parameter("padding_px", BURN_PADDING)
	aura.material = material
	return aura


func _track(tween: Tween) -> void:
	_tweens.append(tween)
