class_name PauseOverlay
extends CanvasLayer

const BASE := Vector2(1920, 1080)
const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const Astrolabe = preload("res://scripts/ui/main_menu_astrolabe.gd")
const Roller = preload("res://scripts/ui/phase_roller.gd")
const FONT: Font = preload("res://assets/fonts/jupiter_pro.otf")
const SHADE: Shader = preload("res://shaders/main_menu_astrolabe_shade.gdshader")
const BLUR: Shader = preload("res://shaders/pause_snapshot.gdshader")

@export var music_path := NodePath("../Music")
@export var phase_manager_path := NodePath("../PhaseManager")
@export var audio_path := NodePath("../GameAudio")

var screen: Control
var sheet: Control
var content: Control
var continue_button: Button
var main_menu_button: Button
var phase_button: Button
var roller: PhaseRoller
var snapshot: TextureRect
var _astrolabe: Node2D
@onready var _music := get_node_or_null(music_path) as AudioStreamPlayer
@onready var _phase_manager := get_node_or_null(phase_manager_path) as PhaseManager
@onready var _audio := get_node_or_null(audio_path) as GameAudio
var _music_was_paused := false
var _animation: Tween
var _closing := false
var _opening := false
var _owns_pause := false
var _hover_tweens: Dictionary = {}

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_build()
	get_viewport().size_changed.connect(_fit_sheet)
	_fit_sheet()
	screen.hide()

func _build() -> void:
	screen = Control.new()
	screen.name = "Screen"
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	snapshot = TextureRect.new()
	snapshot.name = "FrozenArena"
	snapshot.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	snapshot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snapshot.material = ShaderMaterial.new()
	(snapshot.material as ShaderMaterial).shader = BLUR
	screen.add_child(snapshot)
	snapshot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet = Control.new()
	sheet.name = "CelestialPause"
	sheet.size = BASE
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(sheet)
	var heading := Label.new()
	heading.text = "Pausa"
	heading.position = Vector2(680, 210)
	heading.size = Vector2(560, 100)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", FONT)
	heading.add_theme_font_size_override("font_size", 64)
	heading.add_theme_color_override("font_color", Color(0.92, 0.87, 0.76))
	sheet.add_child(heading)
	content = Control.new()
	content.position = Vector2(440, 370)
	content.size = Vector2(1040, 340)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sheet.add_child(content)
	var shade := ColorRect.new()
	shade.position = Vector2(-80, -35)
	shade.size = Vector2(1200, 400)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.material = ShaderMaterial.new()
	(shade.material as ShaderMaterial).shader = SHADE
	content.add_child(shade)
	_astrolabe = Astrolabe.new()
	content.add_child(_astrolabe)
	continue_button = _button("Continuar", Rect2(340, 57, 360, 84), 56, 0)
	continue_button.pressed.connect(_resume)
	phase_button = _button("Fase 1", Rect2(70, 170, 300, 78), 46, 1)
	phase_button.pressed.connect(_toggle_roller)
	main_menu_button = _button("Menu", Rect2(670, 170, 300, 78), 46, 2)
	main_menu_button.pressed.connect(_return_to_main_menu)
	roller = Roller.new() as PhaseRoller
	roller.name = "PhaseRoller"
	roller.position = Vector2(35, 60)
	roller.size = Vector2(370, 300)
	content.add_child(roller)
	roller.activated.connect(_jump_to_phase)
	roller.hide()

func _button(words: String, rect: Rect2, font_size: int, index: int) -> Button:
	var button := Button.new()
	button.text = words
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(0.94, 0.87, 0.73))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.83))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.96, 0.83))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.90, 0.63))
	button.add_theme_color_override("font_disabled_color", Color(0.6, 0.59, 0.56))
	for style in ["normal", "hover", "pressed", "focus", "disabled"]: button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	content.add_child(button)
	button.mouse_entered.connect(func(): button.grab_focus())
	button.focus_entered.connect(_hover.bind(button, index, true))
	button.focus_exited.connect(_hover.bind(button, index, false))
	return button

func _hover(button: Button, index: int, active: bool) -> void:
	var previous: Tween = _hover_tweens.get(index)
	if previous != null and previous.is_valid(): previous.kill()
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tweens[index] = tween
	tween.tween_property(button, "scale", Vector2.ONE * (1.10 if active else 1.0), 0.22)
	tween.tween_property(_astrolabe, "emphasis:" + ["x", "y", "z"][index], 1.0 if active else 0.0, 0.22)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game") or event.is_echo(): return
	if get_tree().paused and not (screen.visible or _opening): return
	get_viewport().set_input_as_handled()
	if _closing or _opening: return
	if roller.visible: _hide_roller()
	elif screen.visible: _close_sheet()
	else: _set_paused(true)


func _set_paused(requested: bool) -> void:
	if not requested:
		_close_sheet()
	elif not (screen.visible or _opening or get_tree().paused):
		_opening = true
		_owns_pause = true
		_music_was_paused = is_instance_valid(_music) and _music.stream_paused
		get_tree().paused = true
		if is_instance_valid(_music): _music.stream_paused = true
		if is_instance_valid(_audio): _audio.set_effects_paused(true)
		await _prepare_snapshot()
		if not is_inside_tree(): return
		phase_button.disabled = not is_instance_valid(_phase_manager)
		if is_instance_valid(_phase_manager):
			phase_button.text = PhaseRoller.caption(maxi(1, _phase_manager.current_phase))
			roller.configure(_phase_manager.current_phase)
		_hide_roller(false)
		screen.show()
		_opening = false
		_open_sheet()


func _prepare_snapshot() -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	if is_inside_tree():
		snapshot.texture = ImageTexture.create_from_image(get_viewport().get_texture().get_image())


func _release_pause() -> void:
	if not _owns_pause: return
	_owns_pause = false
	get_tree().paused = false
	if is_instance_valid(_music): _music.stream_paused = _music_was_paused
	if is_instance_valid(_audio): _audio.set_effects_paused(false)


func _fit_sheet() -> void:
	var view := get_viewport().get_visible_rect().size
	var factor := minf(view.x / BASE.x, view.y / BASE.y)
	sheet.scale = Vector2.ONE * factor
	sheet.position = (view - BASE * factor) * 0.5

func _open_sheet() -> void:
	if _animation != null and _animation.is_valid(): _animation.kill()
	sheet.modulate.a = 0.0
	_animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.tween_property(sheet, "modulate:a", 1.0, 0.28)
	continue_button.grab_focus()

func _close_sheet() -> void:
	if _closing or not screen.visible: return
	_closing = true
	if _animation != null and _animation.is_valid(): _animation.kill()
	_animation = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_animation.tween_property(sheet, "modulate:a", 0.0, 0.18)
	await _animation.finished
	if not is_inside_tree(): return
	screen.hide()
	snapshot.texture = null
	_release_pause()
	_closing = false

func _toggle_roller() -> void:
	if roller.visible: _hide_roller()
	else:
		roller.show()
		phase_button.hide()
		roller.grab_focus()

func _hide_roller(focus_button := true) -> void:
	roller.hide()
	phase_button.show()
	if focus_button: phase_button.grab_focus()

func _resume() -> void:
	_set_paused(false)

func _return_to_main_menu() -> void:
	if _closing: return
	await _close_sheet()
	var error := get_tree().change_scene_to_file(MAIN_MENU_PATH)
	if error != OK: push_error("Não foi possível voltar ao menu principal.")

func _jump_to_phase(selected_phase: int) -> void:
	if _closing or _phase_manager == null or not PhaseManager.can_start_phase(selected_phase): return
	await _close_sheet()
	get_parent().start_test_phase(selected_phase)

func _exit_tree() -> void:
	_release_pause()
	if _animation != null and _animation.is_valid(): _animation.kill()
