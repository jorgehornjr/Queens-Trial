extends Node

const INTRO_MUSIC: AudioStream = preload("res://assets/audio/music/priest_opening.ogg")
const GAME_MUSIC: AudioStream = preload("res://assets/audio/music/5.21 Ascension.ogg")

@export var opening_cutscene_enabled := true
var _opening_skipped := false
var _incoming_music: AudioStreamPlayer
var _music_transition: Tween
var _music_level_db := -12.0

@onready var phase_manager: PhaseManager = $PhaseManager
@onready var board: Board3D = $World/Board
@onready var player: GridPlayer = $World/Player
@onready var hud: GameHUD = $HUD
@onready var board_camera: BoardOrbitCamera = $World/BoardCamera
@onready var celestial_space: CelestialSpace = $World/CelestialSpace
@onready var game_audio: GameAudio = $GameAudio
@onready var opening_cutscene: OpeningCutscene = $OpeningCutscene
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	_music_level_db = music.volume_db
	phase_manager.phase_started.connect(_on_phase_started)
	player.restart_requested.connect(phase_manager.restart_phase)
	player.movement_started.connect(game_audio.play_character_move)
	hud.card_presentation.burn_started.connect(game_audio.play_effect.bind(&"paper_burn"))
	hud.card_presentation.burn_cancelled.connect(game_audio.stop_effect.bind(&"paper_burn"))
	if "--phase=6" in OS.get_cmdline_user_args():
		opening_cutscene_enabled = false
		phase_manager.call_deferred("start_phase", 6)
	if opening_cutscene_enabled:
		call_deferred("_play_opening")
	else:
		call_deferred("_play_game_music")


func _play_opening() -> void:
	if _opening_skipped:
		return
	# Set the first cinematic frame before starting audio, after the splash screen.
	opening_cutscene.play()
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	if not is_inside_tree() or _opening_skipped:
		return
	music.stream = INTRO_MUSIC
	music.play()
	# Keep music present while the camera returns to the board. Equal-power
	# overlap prevents a dip between the two scores at the cinematic handoff.
	_music_transition = create_tween()
	_music_transition.tween_interval((OpeningCutscene.TOTAL_LENGTH - 1.6) * opening_cutscene.duration_scale)
	_music_transition.tween_callback(_begin_music_handoff)
	await opening_cutscene.finished
	if not is_inside_tree() or _opening_skipped:
		return
	_play_game_music()
	if is_inside_tree() and phase_manager.current_phase == 0:
		phase_manager.start_phase(phase_manager.initial_phase)


func _play_game_music() -> void:
	if _music_transition != null and _music_transition.is_valid():
		_music_transition.kill()
	var position_seconds := 0.0
	if is_instance_valid(_incoming_music):
		position_seconds = _incoming_music.get_playback_position()
	music.stop()
	music.stream = GAME_MUSIC
	music.volume_db = _music_level_db
	music.play(position_seconds)
	if is_instance_valid(_incoming_music):
		_incoming_music.stop()
		_incoming_music.queue_free()
		_incoming_music = null


func _begin_music_handoff() -> void:
	if _opening_skipped or not opening_cutscene._running:
		return
	_incoming_music = AudioStreamPlayer.new()
	_incoming_music.name = "IncomingGameplayMusic"
	_incoming_music.stream = GAME_MUSIC
	_incoming_music.volume_db = -80.0
	add_child(_incoming_music)
	_incoming_music.play()
	_music_transition = create_tween()
	_music_transition.tween_method(_blend_music, 0.0, 1.0, 1.6 * opening_cutscene.duration_scale)


func _blend_music(progress: float) -> void:
	if not is_instance_valid(_incoming_music): return
	music.volume_db = _music_level_db + linear_to_db(maxf(0.0001, cos(progress * PI * 0.5)))
	_incoming_music.volume_db = _music_level_db + linear_to_db(maxf(0.0001, sin(progress * PI * 0.5)))


func start_test_phase(phase_number: int) -> void:
	if phase_number < 1 or phase_number > 6:
		return
	var was_opening := phase_manager.current_phase == 0
	_opening_skipped = true
	opening_cutscene.skip()
	if was_opening:
		_play_game_music()
	phase_manager.start_phase(phase_number)


func _on_phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int) -> void:
	board_camera.enter_gameplay()
	# Keep the lateral cards aligned with screen-left/right during this trial.
	board_camera.set_horizontal_orbit_enabled(phase_number != 6)
	celestial_space.enter_gameplay_composition(board_camera.camera, board_camera.transition_seconds)
	hud.set_phase(phase_number, phase_data, phase_seed)
	player.reset_to_start()
