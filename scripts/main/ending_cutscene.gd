class_name EndingCutscene
extends Node3D

signal finished
const Departure := preload("res://scripts/characters/queen_departure.gd")
const BURST_TIME := 6.5
const DISSOLVE_TIME := 9.0
const QUEEN_GONE := DISSOLVE_TIME+QueenDeparture.DISSOLVE_LENGTH
const FIRST_WALK := 21.0
const FIRST_STOP := 28.0
const EXIT_WALK := 43.5
const FADE_TIME := 48.8
const FADE_END := 50.4
const EXIT_STOP := 52.0
const TOTAL_LENGTH := 54.5
const MUSIC_HANDOFF := 0.85
const PIANO_META := &"queen_trial_continuing_piano"
const END_FONT: Font = preload("res://assets/fonts/WhiteDreamPERSONALUSEONLY-Regular.otf")

@export_range(0.1, 2.0, 0.05) var duration_scale := 1.0
@onready var camera: Camera3D = $CinematicCamera
@onready var fade: ColorRect = $Overlay/Fade
@onready var top_bar: ColorRect = $Overlay/TopBar
@onready var bottom_bar: ColorRect = $Overlay/BottomBar
@onready var key_light: OmniLight3D = $PlayerKeyLight
var _main: Node
var _queen: Node3D
var _player: GridPlayer
var _model: Node3D
var _board: Board3D
var _rig: BoardOrbitCamera
var _effect: QueenDeparture
var _orb: Node3D
var _queen_rest: Vector3
var _center := Vector3.ZERO
var _head := Vector3.ZERO
var _orb_anchor := Vector3.ZERO
var _walk_speed := 1.0
var _music_level := -12.0
var _elapsed := 0.0
var _running := false
var _preparing := false
var _generation := 0
var _handoff: Tween
var _burst_started := false
var _walk_started := false
var _walk_stopped := false
var _exit_started := false
var _exit_stopped := false
var _end_screen: Control
var _end_title: Label
var _audio: AudioStreamPlayer
var _score: AudioStreamPlayer
var _score_level := -6.0
var _queen_was_processing := true
var _screen_tween: Tween
var _epilogue: TutorialBook
var _pause_input_processing := true

func _ready() -> void:
	set_process(false)
	fade.modulate.a = 0.0
	top_bar.hide()
	bottom_bar.hide()
	key_light.hide()
	_main = get_parent()
	_queen = _main.get_node("World/Seraph")
	_player = _main.get_node("World/Player")
	_model = _player.get_node("Model")
	_board = _main.get_node("World/Board")
	_rig = _main.get_node("World/BoardCamera")
	_orb = _queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb")
	_queen_rest = _queen.position

func play() -> void:
	if _running or _preparing: return
	_generation += 1
	var run_id := _generation
	_preparing = true
	_running = true
	_music_level = _main.music.volume_db
	_main.get_node("GameAudio").stop_effects()
	_main.get_node("CardTrialController").active = false
	_player.set_input_enabled(false)
	_pause_input_processing = _main.get_node("PauseOverlay").is_processing_unhandled_input()
	_main.get_node("PauseOverlay").set_process_unhandled_input(false)


	_handoff = create_tween().set_parallel(true)
	_handoff.tween_method(_fade_game_music,0.0,1.0,MUSIC_HANDOFF)
	_handoff.tween_property(fade,"modulate:a",1.0,0.35).set_delay(MUSIC_HANDOFF-0.35)
	await _handoff.finished
	if run_id != _generation or not is_inside_tree(): return
	_main.music.stop()
	_begin_story()

func _fade_game_music(amount: float) -> void:
	_main.music.volume_db = _music_level+linear_to_db(maxf(0.0001,pow(1.0-amount,2.0)))

func _begin_story() -> void:
	_preparing = false
	_elapsed = 0.0
	_burst_started = false
	_walk_started = false
	_walk_stopped = false
	_exit_started = false
	_exit_stopped = false
	# Troca o cenário sob o véu para evitar um quadro intermediário visível.
	fade.modulate.a = 1.0
	var cards: CardTrialController = _main.get_node("CardTrialController")
	cards.active = false
	cards.table.hide()
	cards.space_transition.leave_space()
	_main.get_node("HUD").hide()
	_board.rotation = Vector3.ZERO
	_board.state.clear_dynamic_occupants()
	_board.clear_tutorial_path()
	_board.set_safe_spot_visible(false)
	_player.starting_cell = Vector2i(2,2)
	_player.reset_to_start()
	_player.set_input_enabled(false)
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_player.show()
	_center = _player.global_position
	_model.begin_cinematic_idle()
	_model.set_cinematic_look_up(0.85)
	_walk_speed = _model.cinematic_walk_speed()
	_queen.show()
	_queen.position = _queen_rest
	_queen._snap_head_to_player()
	_queen_was_processing = _queen.is_processing()
	_queen.set_process(false)
	_queen.set_balance_mode(false)
	_orb.release_charge = 0.0
	_orb.ritual_reveal = 1.0
	_orb.show()
	_head = _queen._skeleton.to_global(_queen._skeleton.get_bone_global_pose(_queen._skeleton.find_bone("head")).origin)
	_orb_anchor = _orb.global_position
	_effect = Departure.new()
	_effect.name = "QueenAetherRelease"
	add_child(_effect)
	_effect.configure(_queen)
	_rig.begin_cinematic()
	top_bar.show()
	bottom_bar.show()
	key_light.show()
	key_light.light_color = Color(0.68,0.83,1.0)
	key_light.light_energy = 0.9
	_update_camera(0.0)
	camera.make_current()
	_score = AudioStreamPlayer.new()
	_score.name = "FarewellScore"
	_score.stream = preload("res://assets/audio/music/ending_answers_piano.ogg")
	_score_level = _music_level+6.0
	_score.volume_db = _score_level
	_score.pitch_scale = 1.0/duration_scale
	if AudioServer.get_bus_index("Music") >= 0: _score.bus = "Music"
	add_child(_score)
	_score.play()
	set_process(true)

func is_active() -> bool:
	return _running or _preparing or is_instance_valid(_effect)

func _process(delta: float) -> void:
	if not _running: return
	_elapsed = minf(_elapsed+delta/duration_scale,TOTAL_LENGTH)
	_update_story(_elapsed)
	if _elapsed >= TOTAL_LENGTH:
		set_process(false)
		_main.music.stop()
		if is_instance_valid(_audio): _audio.stop()
		_show_epilogue(_generation)

func _update_story(t: float) -> void:
	_orb.release_charge = smoothstep(BURST_TIME-1.0,BURST_TIME,t)
	if t >= BURST_TIME and not _burst_started:
		_burst_started = true
		_orb_anchor = _orb.global_position
		_effect.set_burst_origin(_orb_anchor)
		_orb.hide()
		_play_release_sound()
	_effect.set_burst_age(t-BURST_TIME)
	if t >= DISSOLVE_TIME and not _effect.prepared: _effect.prepare_dissolve()
	_effect.set_dissolve_age(t-DISSOLVE_TIME)
	if is_instance_valid(_audio):
		_audio.volume_db = -8.0 + _main.game_audio.effects_volume_db + linear_to_db(maxf(1.0 - smoothstep(9.7, 10.0, t), 0.0001))
		if t >= 10.0: _audio.stop()

	_queen.visible = t < QUEEN_GONE
	if t >= FIRST_WALK and not _walk_started:
		_walk_started = true
		_model.begin_cinematic_arrival(duration_scale)
	if t >= FIRST_STOP and not _walk_stopped:
		_walk_stopped = true
		_model.begin_cinematic_idle()
	if t >= EXIT_WALK and not _exit_started:
		_exit_started = true
		_model.begin_cinematic_arrival(duration_scale)
	if t >= EXIT_STOP and not _exit_stopped:
		_exit_stopped = true
		_model.begin_cinematic_idle()
	var distance := _walk_speed*(_walk_integral(t-FIRST_WALK,FIRST_STOP-FIRST_WALK)+_walk_integral(t-EXIT_WALK,EXIT_STOP-EXIT_WALK))
	_player.global_position = _center+Vector3.FORWARD*distance
	_model.set_cinematic_look_up((1.0-smoothstep(QUEEN_GONE,QUEEN_GONE+3.0,t))*0.85)
	key_light.global_position = _player.global_position+Vector3(-2,4,2)
	_update_camera(t)
	fade.modulate.a = maxf(1.0-smoothstep(0.0,1.1,t),smoothstep(FADE_TIME,FADE_END,t))

func _walk_integral(time: float, duration: float) -> float:
	var ramp := 0.65
	var t := clampf(time,0,duration)
	if t < ramp:
		var u := t/ramp
		return ramp*(u*u*u-0.5*u*u*u*u)
	if t <= duration-ramp: return t-ramp*0.5
	var u := (t-duration+ramp)/ramp
	return duration-ramp*1.5+ramp*(u-u*u*u+0.5*u*u*u*u)

func _shot(t: float, start: float, end: float, from: Vector3, to: Vector3, focus_from: Vector3, focus_to: Vector3, fov: float) -> void:
	var weight := smoothstep(start,end,t)
	camera.global_position = from.lerp(to,weight)
	camera.look_at(focus_from.lerp(focus_to,weight),Vector3.UP)
	camera.fov = fov

func _update_camera(t: float) -> void:
	var board := _board.global_position
	if t < 5.0:
		_shot(t,0,5,board+Vector3(10,9,27),board+Vector3(7.5,11,25),_head+Vector3(0,-1,8),_head+Vector3(0,0,5),53)
	elif t < 10.0:
		_shot(t,5,10,_orb_anchor+Vector3(9,3,14),_orb_anchor+Vector3(11,4,18),_orb_anchor,_orb_anchor,42)
	elif t < 18.0:
		_shot(t,10,18,_head+Vector3(-18,4,31),_head+Vector3(-15,6,33),_head+Vector3(0,3,0),_head+Vector3(0,4,0),49)
	elif t < 26.0:

		_shot(t,18,26,board+Vector3(-8,6,14),board+Vector3(-5,7.5,10),_head+Vector3(0,-3,8),_head+Vector3(0,-1,5),55)
	elif t < 35.0:
		_shot(t,26,35,board+Vector3(50,24,9),board+Vector3(46,26,7),_head+Vector3(0,4,6),_head+Vector3(0,5,6),53)
	elif t < 40.0:
		_shot(t,35,40,board+Vector3(-33,24,-22),board+Vector3(-29,22,-21),board+Vector3(0,0,-6),board+Vector3(0,0,-8),54)
	elif t < EXIT_WALK:
		_shot(t,40,EXIT_WALK,board+Vector3(24,12,24),board+Vector3(21,13,26),board+Vector3(0,1,-6),board+Vector3(0,2,-9),51)
	else:

		var focus := _player.global_position+Vector3(0,3.0,-2.0)
		_shot(t,EXIT_WALK,TOTAL_LENGTH,board+Vector3(10,6,10),board+Vector3(7,7,3),focus,focus+Vector3(0,0,-0.6),47)
	var impact := t-BURST_TIME
	if impact >= 0 and impact < 0.6:
		camera.position += Vector3(sin(impact*83),cos(impact*71),0)*(1.0-impact/0.6)*0.07

func _play_release_sound() -> void:
	_audio = _sound(preload("res://assets/audio/sfx/queen_orb_release.wav"),-8.0)

func _sound(stream: AudioStream, level: float) -> AudioStreamPlayer:
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.volume_db = level+_main.game_audio.effects_volume_db
	voice.pitch_scale = 1.0/duration_scale
	add_child(voice)
	voice.finished.connect(voice.queue_free)
	voice.play()
	return voice

func _stop_audio() -> void:
	for voice in [_audio,_score]:
		if is_instance_valid(voice):
			voice.stop()
			voice.queue_free()

func _show_epilogue(run_id: int) -> void:
	top_bar.hide()
	bottom_bar.hide()
	_epilogue = TutorialBook.new()
	_epilogue.name = "EpilogueBook"
	$Overlay.add_child(_epilogue)
	_epilogue.page_audio.volume_db = -80.0
	_epilogue.close_audio.volume_db = -80.0
	if not await _epilogue.present_epilogue(): return
	if run_id != _generation or not is_inside_tree(): return
	_epilogue.queue_free()
	_epilogue = null
	_show_end_screen(run_id)

func _show_end_screen(run_id: int) -> void:
	_end_screen = Control.new()
	$Overlay.add_child(_end_screen)
	_end_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := Label.new()
	_end_title = title
	title.name = "FimCalligraphy"
	title.text = "Fim"
	title.add_theme_font_override("font", END_FONT)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_screen.add_child(title)
	title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fit_end_title()
	if not get_viewport().size_changed.is_connected(_fit_end_title): get_viewport().size_changed.connect(_fit_end_title)
	_end_screen.modulate.a = 0.0
	_screen_tween = create_tween()
	_screen_tween.tween_interval(0.6)
	_screen_tween.tween_property(_end_screen,"modulate:a",1.0,1.5)
	_screen_tween.tween_interval(3.5)
	_screen_tween.tween_property(_end_screen,"modulate:a",0.0,2.3)
	await _screen_tween.finished
	if run_id != _generation or not is_inside_tree(): return
	# Transfere o áudio em reprodução para manter o piano contínuo no menu.
	if is_instance_valid(_score):
		_score.reparent(get_tree().root)
		get_tree().set_meta(PIANO_META, _score)
		_score = null
	_stop_audio()
	_running = false
	get_tree().set_meta(&"queen_trial_ending_preview_done",true)
	finished.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _fit_end_title() -> void:
	if not is_instance_valid(_end_title): return
	var view := get_viewport().get_visible_rect().size
	_end_title.add_theme_font_size_override("font_size", int(340 * minf(view.x / 1920.0, view.y / 1080.0)))

func cancel() -> void:
	_generation += 1
	_preparing = false
	_running = false
	if _handoff != null and _handoff.is_valid(): _handoff.kill()
	set_process(false)
	if is_instance_valid(_effect):
		_effect.restore()
		remove_child(_effect)
		_effect.queue_free()
		_effect = null
	if _screen_tween != null and _screen_tween.is_valid(): _screen_tween.kill()
	if is_instance_valid(_epilogue):
		_epilogue.cancel()
		_epilogue.queue_free()
		_epilogue = null
	if is_instance_valid(_end_screen):
		_end_screen.queue_free()
		_end_screen = null
	_stop_audio()
	fade.modulate.a = 0.0
	top_bar.hide()
	bottom_bar.hide()
	key_light.hide()
	_queen.position = _queen_rest
	_queen.set_process(_queen_was_processing)
	_queen.show()
	_orb.show()
	_orb.release_charge = 0.0
	_orb.ritual_reveal = 1.0
	_model.stop_intro_looking()
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_main.get_node("PauseOverlay").set_process_unhandled_input(_pause_input_processing)
	_main.get_node("HUD").show()
	_main.music.volume_db = _music_level
	if not _main.music.playing: _main.music.play()
	_rig.enter_gameplay(true)
	_rig.camera.make_current()
