class_name CardTrialHand
extends Control

signal selected(value: int)
signal returned(value: int)
const Assets = preload("res://scripts/ui/roman_card_assets.gd")
const CARD_SIZE := Vector2(188, 270)
const STEP := (1760.0 - CARD_SIZE.x) / 19.0
var order: Array[int] = []
var used: Array[int] = []
var revision := 0
var _deck: Array[int] = []
var _hovered := -1
var _dragged_value := 0
var _start_x := 0.0
var _cards: Array[TextureRect] = []
var _art_by_value: Dictionary = {}
var _motions: Dictionary = {}

func _ready() -> void:
	size = Vector2(1760, 480)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_exited.connect(_leave)

func configure(values: Array[int], occupied: Array[int], token: int) -> void:
	if revision != token:
		_clear_cards()
		_dragged_value = 0
	_deck.assign(values)
	used.assign(occupied)
	revision = token
	if _dragged_value in used: _dragged_value = 0
	_reflow()

func _reflow() -> void:
	order.clear()
	for value in _deck:
		if value not in used and value != _dragged_value: order.append(value)
	for value in _art_by_value.keys():
		if value not in order:
			var art: TextureRect = _art_by_value[value]
			_stop_motion(value)
			remove_child(art)
			art.queue_free()
			_art_by_value.erase(value)
	_cards.clear()
	_hovered = -1
	_start_x = (size.x - CARD_SIZE.x - STEP * maxf(0, order.size() - 1)) * 0.5
	for i in range(order.size()):
		var value := order[i]
		var art: TextureRect = _art_by_value.get(value)
		var destination := Vector2(_start_x + i * STEP, 210)
		if art == null:
			art = TextureRect.new()
			art.name = "HandCard%d" % value
			art.texture = Assets.front(value)
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_SCALE
			art.size = CARD_SIZE
			art.position = destination
			art.pivot_offset = CARD_SIZE * 0.5
			art.material = Assets.card_material(value)
			art.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(art)
			_art_by_value[value] = art
		_stop_motion(value)
		art.z_index = i
		var motion := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_motions[value] = motion
		motion.tween_property(art, "position", destination, 0.24)
		motion.tween_property(art, "scale", Vector2.ONE, 0.24)
		_cards.append(art)

func _index_at(point: Vector2) -> int:
	if order.is_empty(): return -1
	if point.y >= 210 and point.y <= 480:
		var end := _start_x + STEP * (order.size() - 1) + CARD_SIZE.x
		if point.x < _start_x or point.x > end: return -1
		return clampi(floori((point.x - _start_x) / STEP), 0, order.size() - 1)
	if _hovered >= 0 and _hovered < _cards.size() and _cards[_hovered].get_rect().has_point(point): return _hovered
	return -1

func _gui_input(event: InputEvent) -> void:
	if order.is_empty(): return
	if event is InputEventMouseMotion:
		_hover(_index_at(event.position))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var index := _index_at(event.position)
		if index >= 0: selected.emit(order[index])
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_hover(wrapi(_hovered + (-1 if event.is_action_pressed("ui_left") else 1), 0, order.size()))
		accept_event()
	elif event.is_action_pressed("ui_accept") and _hovered >= 0:
		selected.emit(order[_hovered])
		accept_event()

func _get_drag_data(point: Vector2) -> Variant:
	var index := _index_at(point)
	if index < 0: return null
	var value := order[index]
	var preview := TextureRect.new()
	preview.texture = Assets.front(value)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_SCALE
	preview.size = CARD_SIZE
	preview.position = -CARD_SIZE * 0.5
	preview.material = Assets.card_material(value)
	set_drag_preview(preview)
	_dragged_value = value
	_reflow.call_deferred()
	return {"roman_card": value, "revision": revision}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _dragged_value > 0:
		_dragged_value = 0
		_reflow()

func _can_drop_data(_point: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("revision", -1) == revision and int(data.get("roman_card", 0)) in used

func _drop_data(_point: Vector2, data: Variant) -> void:
	returned.emit(int(data.roman_card))

func _hover(index: int) -> void:
	if index == _hovered: return
	var previous := _hovered
	_hovered = index
	if previous >= 0: _animate(previous, false)
	if index >= 0: _animate(index, true)

func _animate(index: int, lifted: bool) -> void:
	var value := order[index]
	_stop_motion(value)
	var art := _cards[index]
	art.z_index = 100 if lifted else index
	var motion := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motions[value] = motion
	motion.tween_property(art, "position", Vector2(_start_x + index * STEP, 36.0 if lifted else 210.0), 0.20)
	motion.tween_property(art, "scale", Vector2.ONE * (1.08 if lifted else 1.0), 0.20)

func _stop_motion(value: int) -> void:
	var tween: Tween = _motions.get(value)
	if tween != null and tween.is_valid(): tween.kill()
	_motions.erase(value)

func _clear_cards() -> void:
	for value in _motions.keys(): _stop_motion(value)
	for art: TextureRect in _art_by_value.values():
		remove_child(art)
		art.queue_free()
	_art_by_value.clear()
	_cards.clear()
	_hovered = -1

func _leave() -> void:
	_hover(-1)

func _exit_tree() -> void:
	for value in _motions.keys(): _stop_motion(value)
