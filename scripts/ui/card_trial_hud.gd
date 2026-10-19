class_name CardTrialHUD
extends Control

signal submitted
signal slot_clicked(index: int)
signal card_dropped(index: int, value: int)
const Hand = preload("res://scripts/ui/card_trial_hand.gd")
const Slot = preload("res://scripts/ui/card_trial_slot.gd")
const FONT = preload("res://assets/fonts/jupiter_pro.otf")
const BODY_FONT = preload("res://assets/fonts/Alegreya-Variable.ttf")
const BASE := Vector2(1920, 1080)
var canvas: Control
var input_shield: ColorRect
var hand: CardTrialHand
var slots_root: Control
var slots: Array[CardTrialSlot] = []
var title: Label
var feedback: Label
var submit: Button
var revision := 0
var _turn_tween: Tween

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	input_shield = ColorRect.new()
	input_shield.name = "CardInputShield"
	input_shield.color = Color.TRANSPARENT
	add_child(input_shield)
	input_shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	input_shield.mouse_filter = Control.MOUSE_FILTER_STOP
	canvas = Control.new()
	canvas.name = "CardTable"
	canvas.size = BASE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	title = _label(Rect2(150, 84, 1620, 85), 56)
	slots_root = Control.new()
	slots_root.size = BASE
	slots_root.pivot_offset = BASE * 0.5
	slots_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(slots_root)
	feedback = _label(Rect2(200, 650, 1520, 62), 31, true)
	submit = _button("Confirmar", Rect2(810, 722, 300, 60))
	submit.pressed.connect(func(): submitted.emit())
	hand = Hand.new() as CardTrialHand
	hand.name = "ShuffledDeck"
	hand.position = Vector2(80, 595)
	canvas.add_child(hand)
	canvas.move_child(hand, 0)
	get_viewport().size_changed.connect(_fit)
	_fit()
	hide()

func _label(rect: Rect2, font_size: int, body := false) -> Label:
	var label := Label.new()
	label.position = rect.position
	label.size = rect.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", BODY_FONT if body else FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.94, 0.88, 0.77))
	canvas.add_child(label)
	return label

func _button(words: String, rect: Rect2) -> Button:
	var button := Button.new()
	button.text = words
	button.position = rect.position
	button.size = rect.size
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 34)
	button.add_theme_color_override("font_color", Color(0.96, 0.88, 0.70))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for name in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(name, StyleBoxEmpty.new())
	canvas.add_child(button)
	return button

func _fit() -> void:
	var viewport := get_viewport_rect().size
	var fit := minf(viewport.x / BASE.x, viewport.y / BASE.y)
	canvas.scale = Vector2.ONE * fit
	canvas.position = (viewport - BASE * fit) * 0.5

func show_round(state: CardTrialState) -> void:
	cancel_turn()
	revision += 1
	canvas.show()
	slots_root.show()
	hand.mouse_filter = Control.MOUSE_FILTER_STOP
	for child in slots_root.get_children():
		slots_root.remove_child(child)
		child.queue_free()
	slots.clear()
	feedback.text = ""
	title.text = ("Ordem crescente" if state.ascending else "Ordem decrescente") if state.kind == CardTrialState.Kind.ORDER else ("Associe os números" if state.kind == CardTrialState.Kind.MATCH else "Ache o decreto falso")
	var count := state.options.size() if state.kind == CardTrialState.Kind.FALSE_DECREE else state.slots.size()
	var card_size := Vector2(205, 292) if count == 6 else Vector2(238, 339)
	var gap := 32.0 if count == 6 else 155.0
	var start := (BASE.x - (card_size.x * count + gap * (count - 1))) * 0.5
	for i in range(count):
		var slot := Slot.new() as CardTrialSlot
		slot.name = "Slot%d" % i
		slot.index = i
		slot.size = card_size
		slot.position = Vector2(start + i * (card_size.x + gap), 300)
		slot.locked = i == state.anchor_index
		slot.false_decree = state.kind == CardTrialState.Kind.FALSE_DECREE
		slot.value = state.options[i] if slot.false_decree else state.slots[i]
		slot.claim = state.claims[i] if slot.false_decree else (state.targets[i] if state.kind == CardTrialState.Kind.MATCH else 0)
		slot.revision = revision
		slot.dropped.connect(func(index: int, value: int): card_dropped.emit(index, value))
		slot.clicked.connect(func(index: int): slot_clicked.emit(index))
		slots_root.add_child(slot)
		slots.append(slot)
	hand.visible = state.kind != CardTrialState.Kind.FALSE_DECREE
	hand.configure(state.deck, state.slots, revision)
	submit.visible = state.kind != CardTrialState.Kind.FALSE_DECREE
	submit.text = "Confirmar ordem" if state.kind == CardTrialState.Kind.ORDER else "Confirmar"
	show()

func refresh(state: CardTrialState) -> void:
	for i in range(slots.size()):
		if state.kind != CardTrialState.Kind.FALSE_DECREE: slots[i].value = state.slots[i]
		slots[i].refresh()
	hand.configure(state.deck, state.slots, revision)

func show_feedback(result: Dictionary) -> void:
	feedback.text = String(result.message)
	if result.correct:
		title.text = "Fase concluída"
		hand._leave()
		hand.mouse_filter = Control.MOUSE_FILTER_IGNORE
		submit.hide()

func show_transition() -> void:
	title.text = "Fase concluída"
	feedback.text = ""
	slots_root.hide()
	hand.hide()
	submit.hide()

func cancel_turn() -> void:
	if _turn_tween != null and _turn_tween.is_valid(): _turn_tween.kill()
	slots_root.scale = Vector2.ONE
	slots_root.modulate.a = 1.0

func turn_out() -> void:
	_turn_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_turn_tween.tween_property(slots_root, "scale:x", 0.02, 0.3)
	_turn_tween.tween_property(slots_root, "modulate:a", 0.0, 0.3)
	await _turn_tween.finished

func turn_in() -> void:
	slots_root.scale.x = 0.02
	slots_root.modulate.a = 0.0
	_turn_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_turn_tween.tween_property(slots_root, "scale:x", 1.0, 0.4)
	_turn_tween.tween_property(slots_root, "modulate:a", 1.0, 0.4)
	await _turn_tween.finished
