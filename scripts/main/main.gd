extends Node

const INTRO_MUSIC: AudioStream = preload("res://assets/audio/music/opening_with_atlas.ogg")
const GAME_MUSIC: AudioStream = preload("res://assets/audio/music/vanilla_the_final_day.ogg")
const SAVAGE_MUSIC: AudioStream = preload("res://assets/audio/music/savage_with_hearts_aligned.ogg")

@export var opening_cutscene_enabled := true
var _opening_skipped := false
var _music_transition: Tween
var _music_level_db := -12.0
var _atlas_music_fading := false

@onready var phase_manager: PhaseManager = $PhaseManager
@onready var board: Board3D = $World/Board
@onready var player: GridPlayer = $World/Player
@onready var hud: GameHUD = $HUD
@onready var board_camera: BoardOrbitCamera = $World/BoardCamera
@onready var celestial_space: CelestialSpace = $World/CelestialSpace
@onready var game_audio: GameAudio = $GameAudio
@onready var opening_cutscene: OpeningCutscene = $OpeningCutscene
@onready var ending_cutscene: EndingCutscene = $EndingCutscene
@onready var chaotic_cutscene: ChaoticOpeningCutscene = $ChaoticOpeningCutscene
@onready var chaotic_completion: ChaoticCompletion = $ChaoticCompletion
@onready var music: AudioStreamPlayer = $Music


func _ready() -> void:
	_music_level_db = music.volume_db
	# As consultas pausam a cena; somente o menu de pausa suspende a música.

	music.process_mode = Node.PROCESS_MODE_ALWAYS
	phase_manager.phase_started.connect(_on_phase_started)
	phase_manager.campaign_completed.connect(ending_cutscene.play)
	phase_manager.savage_completed.connect(chaotic_completion.play)
	player.restart_requested.connect(phase_manager.restart_phase)
	player.movement_started.connect(game_audio.play_character_move)
	hud.card_presentation.burn_started.connect(game_audio.play_effect.bind(&"paper_burn"))
	hud.card_presentation.burn_cancelled.connect(game_audio.stop_effect.bind(&"paper_burn"))
	hud.roman_map.final_reached.connect(_fade_atlas_music)
	hud.roman_map.departure_started.connect(_fade_atlas_music)
	if get_tree().has_meta(&"queen_trial_start_chaotic"):
		get_tree().remove_meta(&"queen_trial_start_chaotic")
		if PhaseManager.can_start_phase(PhaseManager.Savage.FIRST):
			opening_cutscene_enabled = false
			chaotic_cutscene.cover_entry()
			call_deferred("start_chaotic")
			return
	var menu_phase := int(get_tree().get_meta(&"queen_trial_start_phase", 0))
	if get_tree().has_meta(&"queen_trial_start_phase"):
		get_tree().remove_meta(&"queen_trial_start_phase")
	if PhaseManager.can_start_phase(menu_phase):
		opening_cutscene_enabled = false
		call_deferred("start_test_phase", menu_phase)
		return
	for argument in OS.get_cmdline_user_args():
		if argument == "--chaotic-intro" and not get_tree().has_meta(&"queen_trial_chaotic_preview_done"):
			get_tree().set_meta(&"queen_trial_chaotic_preview_done",true)
			if PhaseManager.can_start_phase(PhaseManager.Savage.FIRST):
				opening_cutscene_enabled = false
				chaotic_cutscene.cover_entry()
				call_deferred("start_chaotic")
				return
		if argument == "--ending" and not get_tree().has_meta(&"queen_trial_ending_preview_done"):
			opening_cutscene_enabled = false
			call_deferred("_preview_ending")
			return
		if argument.begins_with("--phase=") and not get_tree().has_meta(&"queen_trial_phase_preview_done"):
			var number := int(argument.trim_prefix("--phase="))
			if PhaseManager.can_start_phase(number):
				get_tree().set_meta(&"queen_trial_phase_preview_done",true)
				opening_cutscene_enabled = false
				call_deferred("start_test_phase", number)
				return
	if opening_cutscene_enabled:
		board.set_safe_spot_visible(false)
		opening_cutscene.cover_entry()
		call_deferred("_play_opening")
	else:
		call_deferred("_play_game_music")


func _play_opening() -> void:
	if _opening_skipped:
		return
	var first_board := phase_manager.prepare_opening_board()
	if not first_board.is_empty():
		player.starting_cell = Vector2i(int(first_board.starting_cell[0]), int(first_board.starting_cell[1]))
		player.reset_to_start()

	opening_cutscene.play()
	if DisplayServer.get_name() == "headless":
		await get_tree().process_frame
	else:
		await RenderingServer.frame_post_draw
	if not is_inside_tree() or _opening_skipped:
		return
	music.stream = INTRO_MUSIC
	music.play()
	await opening_cutscene.finished
	if not is_inside_tree() or _opening_skipped:
		return


	_atlas_music_fading = false
	var previous_music_mode := music.process_mode

	music.process_mode = Node.PROCESS_MODE_ALWAYS
	var learned := await hud.show_roman_map(true)
	if not is_inside_tree(): return
	music.process_mode = previous_music_mode
	if not is_inside_tree() or _opening_skipped or not learned: return
	_play_game_music()
	if is_inside_tree() and phase_manager.current_phase == 0:
		phase_manager.start_phase(phase_manager.initial_phase)


func _play_game_music() -> void:
	if _music_transition != null and _music_transition.is_valid():
		_music_transition.kill()
	music.process_mode = Node.PROCESS_MODE_ALWAYS
	music.stop()
	music.stream = GAME_MUSIC
	music.volume_db = _music_level_db
	music.play()


func _fade_atlas_music() -> void:
	if _atlas_music_fading or not hud.roman_map.guided or music.stream != INTRO_MUSIC: return
	_atlas_music_fading = true
	if _music_transition != null and _music_transition.is_valid(): _music_transition.kill()
	_music_transition = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_music_transition.tween_property(music, "volume_db", -65.0, 0.9)


func start_test_phase(phase_number: int) -> void:
	if not PhaseManager.can_start_phase(phase_number):
		return
	var was_opening := phase_manager.current_phase == 0
	_opening_skipped = true
	hud.roman_map.cancel()
	opening_cutscene.skip()
	if was_opening:
		_play_game_music()
	phase_manager.start_phase(phase_number)

func start_chaotic() -> void:
	if not PhaseManager.can_start_phase(PhaseManager.Savage.FIRST): return
	if chaotic_cutscene.is_active(): return
	if chaotic_completion.is_active(): chaotic_completion.cancel()
	_opening_skipped = true
	hud.roman_map.cancel()
	opening_cutscene.skip()
	if ending_cutscene.is_active(): ending_cutscene.cancel()
	if _music_transition != null and _music_transition.is_valid(): _music_transition.kill()
	get_node("SavageController").stop_encounter()
	chaotic_cutscene.play(PhaseManager.Savage.FIRST)


func _on_phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int) -> void:
	if chaotic_completion.is_active(): chaotic_completion.cancel()
	if ending_cutscene.is_active(): ending_cutscene.cancel()
	if chaotic_cutscene.is_active():
		chaotic_cutscene.cancel()
		get_node("SavageController").effects.set_active(PhaseManager.Savage.contains(phase_number))
	board_camera.enter_gameplay()

	board_camera.set_horizontal_orbit_enabled(String(phase_data.get("resolution", "")) == "moves")
	celestial_space.enter_gameplay_composition(board_camera.camera, board_camera.transition_seconds)
	hud.set_phase(phase_number, phase_data, phase_seed)
	var spawn: Array = phase_data.get("starting_cell", [2, 2])
	player.starting_cell = Vector2i(int(spawn[0]), int(spawn[1]))
	player.reset_to_start()
	player.visible = String(phase_data.get("resolution", "")) in ["moves", "balance"] or PhaseManager.Savage.contains(phase_number)
	var desired: AudioStream = SAVAGE_MUSIC if PhaseManager.Savage.contains(phase_number) else GAME_MUSIC
	if music.stream != desired:
		music.stop()
		music.stream = desired
		music.volume_db = _music_level_db
		music.play()

func _preview_ending() -> void:
	await get_tree().process_frame
	if not is_inside_tree(): return
	phase_manager.campaign_finished = true
	music.play()
	ending_cutscene.play()
