class_name PauseOverlay
extends CanvasLayer

## Folha ilustrada e controles continuam ativos enquanto a prova está pausada.

const SHEET_SIZE := Vector2(1778, 1000)

@export var music_path := NodePath("../Music")
@export var phase_manager_path := NodePath("../PhaseManager")
@export var audio_path := NodePath("../GameAudio")

@onready var screen: Control = $Screen
@onready var sheet: Control = $Screen/Sheet
@onready var content: Control = $Screen/Sheet/Content
@onready var continue_button: Button = $Screen/Sheet/Content/ContinueButton
@onready var restart_button: Button = $Screen/Sheet/Content/RestartButton
@onready var phase_selector: OptionButton = $Screen/Sheet/Content/PhaseSelector
@onready var phase_button: Button = $Screen/Sheet/Content/PhaseButton

var _music: AudioStreamPlayer
var _phase_manager: PhaseManager
var _audio: GameAudio
var _music_was_paused := false
var _animation: Tween
var _closing := false
var _fit_scale := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = get_node_or_null(music_path) as AudioStreamPlayer
	_phase_manager = get_node_or_null(phase_manager_path) as PhaseManager
	_audio = get_node_or_null(audio_path) as GameAudio
	screen.visible = false
	sheet.pivot_offset = SHEET_SIZE * 0.5
	get_viewport().size_changed.connect(_fit_sheet)
	_fit_sheet()
	continue_button.pressed.connect(_resume)
	restart_button.pressed.connect(_restart_phase)
	for phase_number in range(1, 7):
		phase_selector.add_item("Fase %d" % phase_number, phase_number)
	phase_button.pressed.connect(_jump_to_phase)
	_style_phase_popup()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif screen.visible and event.is_action_pressed("restart_phase"):
		_restart_phase()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if _closing:
		return
	_set_paused(not get_tree().paused)


func _set_paused(paused: bool) -> void:
	if paused:
		if screen.visible:
			return
		_music_was_paused = _music != null and _music.stream_paused
		get_tree().paused = true
		screen.visible = true
		if _music != null:
			_music.stream_paused = true
		if _audio != null:
			_audio.set_effects_paused(true)
		restart_button.disabled = _phase_manager == null or _phase_manager.current_phase == 0
		phase_button.disabled = _phase_manager == null
		if _phase_manager != null:
			phase_selector.select(clampi(_phase_manager.current_phase - 1, 0, phase_selector.item_count - 1))
		_open_sheet()
	else:
		_close_sheet()


func _fit_sheet() -> void:
	var view := get_viewport().get_visible_rect().size
	_fit_scale = minf((view.x - 36.0) / SHEET_SIZE.x, (view.y - 28.0) / SHEET_SIZE.y)
	sheet.scale = Vector2.ONE * _fit_scale


func _open_sheet() -> void:
	if _animation != null and _animation.is_valid():
		_animation.kill()
	content.modulate.a = 0.0
	sheet.scale = Vector2.ONE * _fit_scale * 0.975
	sheet.modulate.a = 0.0
	_animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_animation.tween_property(sheet, "scale", Vector2.ONE * _fit_scale, 0.45)
	_animation.tween_property(sheet, "modulate:a", 1.0, 0.35)
	_animation.tween_property(content, "modulate:a", 1.0, 0.30).set_delay(0.10)
	await _animation.finished
	if screen.visible and not _closing:
		continue_button.grab_focus()


func _close_sheet() -> void:
	if _closing or not screen.visible:
		return
	_closing = true
	if _animation != null and _animation.is_valid():
		_animation.kill()
	_animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_animation.tween_property(sheet, "scale", Vector2.ONE * _fit_scale * 0.98, 0.25)
	_animation.tween_property(sheet, "modulate:a", 0.0, 0.25)
	_animation.tween_property(content, "modulate:a", 0.0, 0.18)
	await _animation.finished
	if not is_inside_tree():
		return
	screen.visible = false
	get_tree().paused = false
	if _music != null:
		_music.stream_paused = _music_was_paused
	if _audio != null:
		_audio.set_effects_paused(false)
	_closing = false


func _resume() -> void:
	_set_paused(false)


func _restart_phase() -> void:
	if _closing or _phase_manager == null or _phase_manager.current_phase == 0:
		return
	await _close_sheet()
	_phase_manager.restart_phase()


func _jump_to_phase() -> void:
	if _closing or _phase_manager == null or phase_selector.selected < 0:
		return
	var selected_phase := phase_selector.get_selected_id()
	await _close_sheet()
	get_parent().start_test_phase(selected_phase)


func _style_phase_popup() -> void:
	var popup := phase_selector.get_popup()
	popup.add_theme_font_override("font", phase_selector.get_theme_font("font"))
	popup.add_theme_font_size_override("font_size", 28)
	popup.add_theme_color_override("font_color", Color(0.2, 0.075, 0.065))
	popup.add_theme_color_override("font_hover_color", Color(0.32, 0.06, 0.07))
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.94, 0.88, 0.76)
	paper.set_border_width_all(1)
	paper.border_color = Color(0.54, 0.35, 0.17, 0.7)
	paper.content_margin_left = 18
	paper.content_margin_right = 18
	paper.content_margin_top = 10
	paper.content_margin_bottom = 10
	popup.add_theme_stylebox_override("panel", paper)
	popup.add_theme_stylebox_override("hover", phase_selector.get_theme_stylebox("hover"))
