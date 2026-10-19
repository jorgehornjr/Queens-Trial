class_name PhaseRoller
extends Control


signal activated(phase: int)
const FONT: Font = preload("res://assets/fonts/jupiter_pro.otf")
const ROW := 68.0
var phases: Array[int] = []
var cursor := 0.0
var _dragging := false
var _drag_origin := 0.0
var _drag_cursor := 0.0
var _moved := false
var _snap: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(370, 300)
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	focus_mode = Control.FOCUS_ALL

static func caption(number: int) -> String:
	return "Chaotic %s" % GameConstants.to_roman(number - 100) if PhaseManager.Savage.contains(number) else "Fase %d" % number

func configure(current: int) -> void:
	phases.clear()
	for number in range(1, PhaseManager.LAST_PLAYABLE_PHASE + 1): phases.append(number)
	for number in range(PhaseManager.Savage.FIRST, PhaseManager.Savage.LAST + 1):
		if PhaseManager.can_start_phase(number): phases.append(number)
	cursor = float(maxi(0, phases.find(current)))
	_dragging = false
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	for offset in [-1, 1]:
		var y: float = center.y + offset * ROW * 0.57
		draw_line(Vector2(45, y), Vector2(size.x - 45, y), Color(0.70, 0.58, 0.36, 0.5), 1.0, true)
	for index in range(phases.size()):
		var distance := float(index) - cursor
		if absf(distance) > 2.05: continue
		var strength := 1.0 - smoothstep(0.25, 2.05, absf(distance))
		var words := caption(phases[index])
		var font_size := int(lerpf(31.0, 43.0, strength))
		var text_size := FONT.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var color := Color(0.94, 0.87, 0.73, strength)
		if PhaseManager.Savage.contains(phases[index]): color = Color(1.0, 0.34, 0.23, strength)
		draw_string(FONT, Vector2((size.x - text_size.x) * 0.5, center.y + sin(clampf(distance * 0.4, -1.2, 1.2)) * ROW * 2.5 + font_size * 0.32), words, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
	draw_circle(Vector2(32, center.y), 2.5, Color(0.87, 0.75, 0.49))
	draw_circle(Vector2(size.x - 32, center.y), 2.5, Color(0.87, 0.75, 0.49))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			step(-1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if _snap != null and _snap.is_valid(): _snap.kill()
				grab_focus()
				_dragging = true
				_moved = false
				_drag_origin = event.position.y
				_drag_cursor = cursor
			elif _dragging:
				_dragging = false
				if not _moved and absf(event.position.y - size.y * 0.5) < ROW * 0.5:
					activated.emit(phases[clampi(roundi(cursor), 0, phases.size() - 1)])
				else:
					var target := cursor if _moved else cursor + roundf((event.position.y - size.y * 0.5) / ROW)
					_snap_to(target)
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var travel: float = _drag_origin - event.position.y
		_moved = _moved or absf(travel) > 6.0
		cursor = clampf(_drag_cursor + travel / ROW, 0, phases.size() - 1)
		queue_redraw()
		accept_event()
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
		step(-1 if event.is_action_pressed("ui_up") else 1)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		activated.emit(phases[clampi(roundi(cursor), 0, phases.size() - 1)])
		accept_event()

func step(direction: int) -> void:
	_snap_to(roundf(cursor) + direction)

func _snap_to(value: float) -> void:
	if _snap != null and _snap.is_valid(): _snap.kill()
	_snap = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_snap.tween_method(_set_cursor, cursor, clampf(roundf(value), 0, phases.size() - 1), 0.22)

func _set_cursor(value: float) -> void:
	cursor = value
	queue_redraw()
