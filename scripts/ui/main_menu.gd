class_name QueenMainMenu
extends Control
## Menu principal diante da Lua, usando apenas o cenário 3D existente.

const BASE_SIZE := Vector2(1920, 1080)
const GAME_PATH := "res://scenes/main/main.tscn"
const ENTRY_META := &"queen_trial_start_phase"
const JUPITER: Font = preload("res://assets/fonts/jupiter_pro.otf")
const LOGO: Texture2D = preload("res://assets/logo/QTlogo.png")
const MoonWorld = preload("res://scripts/ui/main_menu_moon_world.gd")
const LOGO_GLOW = preload("res://shaders/main_menu_logo_glow.gdshader")
const MENU_SCORE = preload("res://assets/audio/music/menu_orbits.ogg")
const SCORE_BODY_TIME := 12.0
const LENS = preload("res://shaders/main_menu_lens.gdshader")
const GRADE = preload("res://shaders/main_menu_grade.gdshader")
const IVORY := Color(0.94, 0.87, 0.73)

enum Page { HOME, LAUNCHING }
var page := Page.HOME
var effect_time := 0.0
var world: MainMenuMoonWorld
var ui: Control
var home: Control
var fade: ColorRect
var logo: TextureRect
var music: AudioStreamPlayer
var start_button: Button
var _hover_tweens: Dictionary = {}
var intro_ready := false
var _lens_material: ShaderMaterial
var _logo_material: ShaderMaterial
var _grade_material: ShaderMaterial
var _launch_tween: Tween


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_world()
	_build_home()
	_build_fade()
	get_viewport().size_changed.connect(_fit)
	_fit()
	start_button.modulate.a = 0.0
	start_button.disabled = true
	world.intro_finished.connect(_finish_intro)
	_update_intro()
	_build_audio()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--phase="):
			var number := int(argument.trim_prefix("--phase="))
			if PhaseManager.can_start_phase(number): call_deferred("launch_phase", number)


func _exit_tree() -> void:
	if music != null:
		music.stop()
		music.stream = null
	if _launch_tween != null and _launch_tween.is_valid(): _launch_tween.kill()
	for tween in _hover_tweens.values():
		if tween != null and tween.is_valid(): tween.kill()
	_hover_tweens.clear()


func _process(delta: float) -> void:
	effect_time += delta
	_update_intro()


func _input(event: InputEvent) -> void:
	if intro_ready or page == Page.LAUNCHING: return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("pause_game") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		skip_intro()
		get_viewport().set_input_as_handled()


func skip_intro() -> void:
	world.skip_intro()
	_update_intro()
	if music != null and music.playing and music.get_playback_position() < SCORE_BODY_TIME:
		music.seek(SCORE_BODY_TIME)


func _finish_intro() -> void:
	intro_ready = true
	start_button.disabled = false
	if page == Page.HOME: start_button.grab_focus()


func _update_intro() -> void:
	var time := world.intro_time
	logo.modulate.a = smoothstep(7.0, 9.6, time)
	_logo_material.set_shader_parameter("effect_time", effect_time)
	_lens_material.set_shader_parameter("light_uv", world.light_uv)
	_lens_material.set_shader_parameter("strength", world.light_strength)
	_lens_material.set_shader_parameter("aspect", get_viewport_rect().size.x / maxf(get_viewport_rect().size.y, 1.0))
	_grade_material.set_shader_parameter("opening", smoothstep(0.0, 1.3, time))
	start_button.modulate.a = smoothstep(9.5, 10.5, time)


func launch_phase(number: int) -> void:
	if page == Page.LAUNCHING or (number != 0 and not PhaseManager.can_start_phase(number)): return
	page = Page.LAUNCHING
	start_button.disabled = true
	fade.show()
	_launch_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_launch_tween.tween_property(fade, "color:a", 1.0, 0.7)
	_launch_tween.parallel().tween_property(music, "volume_db", -50.0, 0.7)
	await _launch_tween.finished
	var scene := load(GAME_PATH) as PackedScene
	if scene == null:
		_launch_failed()
		return
	get_tree().paused = false
	get_tree().set_meta(ENTRY_META, number)
	var error := get_tree().change_scene_to_packed(scene)
	if error != OK:
		get_tree().remove_meta(ENTRY_META)
		_launch_failed()


func _launch_failed() -> void:
	push_error("Não foi possível abrir a cena do jogo pelo menu.")
	page = Page.HOME
	music.volume_db = -2.0
	fade.hide()
	fade.color.a = 0.0
	start_button.disabled = false
	home.show()
	start_button.grab_focus()


func _fit() -> void:
	var view := get_viewport_rect().size
	var text_scale := minf(view.x / BASE_SIZE.x, view.y / BASE_SIZE.y)
	ui.scale = Vector2.ONE * text_scale
	ui.position = (view - BASE_SIZE * text_scale) * 0.5


func _build_world() -> void:
	world = MoonWorld.new() as MainMenuMoonWorld
	world.name = "MoonBoardWorld"
	add_child(world)
	_lens_material = ShaderMaterial.new()
	_lens_material.shader = LENS
	_grade_material = ShaderMaterial.new()
	_grade_material.shader = GRADE
	for pair in [["LensLight", _lens_material], ["CinematicGrade", _grade_material]]:
		var overlay := ColorRect.new()
		overlay.name = pair[0]
		overlay.material = pair[1]
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(overlay)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui = Control.new()
	ui.name = "MenuUI"
	ui.size = BASE_SIZE
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ui)

func _build_home() -> void:
	home = Control.new()
	home.name = "Home"
	home.size = BASE_SIZE
	home.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(home)
	logo = TextureRect.new()
	logo.name = "Logo"
	logo.texture = LOGO
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo_material = ShaderMaterial.new()
	_logo_material.shader = LOGO_GLOW
	logo.material = _logo_material
	logo.position = Vector2(490, 195)
	logo.size = Vector2(940, 415)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	home.add_child(logo)
	start_button = _button(home, "Start", "Iniciar", Rect2(680, 625, 560, 78), 50)
	start_button.pressed.connect(launch_phase.bind(0))

func _build_audio() -> void:
	music = AudioStreamPlayer.new()
	music.name = "MenuMusic"
	music.stream = MENU_SCORE
	music.volume_db = -2.0
	if AudioServer.get_bus_index("Music") >= 0: music.bus = "Music"
	add_child(music)
	music.play()


func _build_fade() -> void:
	fade = ColorRect.new()
	fade.name = "LaunchFade"
	fade.color = Color(0.008, 0.010, 0.02, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.hide()


func _button(parent: Control, node_name: String, words: String, rect: Rect2, font_size: int) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = words
	button.position = rect.position
	button.size = rect.size
	button.pivot_offset = rect.size * 0.5
	button.set_meta("rest_position", rect.position)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", JUPITER)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.BLACK if parent == home else IVORY)
	button.add_theme_color_override("font_disabled_color", Color.BLACK if parent == home else IVORY)
	button.add_theme_color_override("font_hover_color", Color.BLACK if parent == home else Color(1.0, 0.96, 0.83))
	button.add_theme_color_override("font_focus_color", Color.BLACK if parent == home else Color(1.0, 0.96, 0.83))
	button.add_theme_color_override("font_pressed_color", Color.BLACK if parent == home else Color(1.0, 0.90, 0.63))
	button.add_theme_color_override("font_shadow_color", Color.TRANSPARENT if parent == home else Color(0.01, 0.02, 0.06, 0.95))
	button.add_theme_constant_override("outline_size", 0)
	button.add_theme_constant_override("shadow_offset_y", 0 if parent == home else 3)
	for style in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	parent.add_child(button)
	button.mouse_entered.connect(_mouse_entered.bind(button))
	button.mouse_exited.connect(_hover.bind(button, false))
	button.focus_entered.connect(_hover.bind(button, true))
	button.focus_exited.connect(_hover.bind(button, false))
	return button


func _mouse_entered(button: Button) -> void:
	if page == Page.LAUNCHING: return
	button.grab_focus()
	_hover(button, true)


func _hover(button: Button, active: bool) -> void:
	if page == Page.LAUNCHING: return
	var previous: Tween = _hover_tweens.get(button.get_instance_id())
	if previous != null and previous.is_valid(): previous.kill()
	var tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_hover_tweens[button.get_instance_id()] = tween
	tween.tween_property(button, "scale", Vector2.ONE * (1.10 if active else 1.0), 0.22)
	var rest: Vector2 = button.get_meta("rest_position")
	tween.tween_property(button, "position", rest - Vector2(0, 5 if active else 0), 0.22)
	button.z_index = 10 if active else 0

