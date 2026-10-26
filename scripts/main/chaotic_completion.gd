class_name ChaoticCompletion
extends CanvasLayer


const MENU_PATH := "res://scenes/ui/main_menu.tscn"
const FADE_SECONDS := 3.2
const BLACK_HOLD := 0.7
const FireTitle = preload("res://scripts/ui/chaotic_title_fire.gd")
const CONGRATULATIONS: Texture2D = preload("res://assets/effects/chaotic_title/congratulations_fields.exr")
@onready var fade: ColorRect = $Fade
@onready var voice: AudioStreamPlayer = $Announcement
var _main: Node
var _running := false
var _generation := 0
var _fade_tween: Tween
var _music_level := -12.0
var _player_input_processing := true
var _pause_input_processing := true
var title_canvas: Control
var fire_title: Node2D
var _title_elapsed := 0.0

func _ready() -> void:
	_main = get_parent()
	fade.color.a = 0.0
	title_canvas = Control.new()
	title_canvas.name = "Congratulations"
	title_canvas.size = Vector2(1920, 1080)
	title_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_canvas)
	move_child(title_canvas, fade.get_index())
	fire_title = FireTitle.new()
	fire_title.name = "CongratulationsFire"
	fire_title.position = Vector2(240, 70)
	title_canvas.add_child(fire_title)
	fire_title.prepare(CONGRATULATIONS)
	title_canvas.hide()
	get_viewport().size_changed.connect(_fit)
	_fit()
	set_process(false)

func _fit() -> void:
	var view := get_viewport().get_visible_rect().size
	var factor := minf(view.x / 1920.0, view.y / 1080.0)
	title_canvas.scale = Vector2.ONE * factor
	title_canvas.position = (view - Vector2(1920, 1080) * factor) * 0.5

func _process(delta: float) -> void:
	if not _running: return
	_title_elapsed += delta
	if _title_elapsed <= FireTitle.DURATION:
		fire_title.set_elapsed(_title_elapsed)
	else:
		fire_title.hide()

func is_active() -> bool:
	return _running

func play() -> void:
	if _running: return
	_running = true
	_generation += 1
	var run_id := _generation
	_main.game_audio.stop_effects()
	_music_level = _main.music.volume_db
	_player_input_processing = _main.player.is_processing_unhandled_input()
	_pause_input_processing = _main.get_node("PauseOverlay").is_processing_unhandled_input()
	_main.player.set_input_enabled(false)
	_main.player.set_process_unhandled_input(false)
	_main.get_node("PauseOverlay").set_process_unhandled_input(false)
	_main.hud.hide()
	_main.get_node("SavageController").ui.cancel()
	_title_elapsed = 0.0
	title_canvas.show()
	fire_title.show()
	fire_title.set_elapsed(0.0)
	set_process(true)
	voice.volume_db = -2.0 + _main.game_audio.effects_volume_db
	voice.play()
	await voice.finished
	if not _valid_run(run_id): return
	_main.game_audio.play_effect(&"next_phase")


	await get_tree().create_timer(maxf(0.18, FireTitle.DURATION - _title_elapsed + 0.6), false).timeout
	if not _valid_run(run_id): return
	_fade_tween = create_tween()
	_fade_tween.tween_method(_set_fade, 0.0, 1.0, FADE_SECONDS)
	await _fade_tween.finished
	if not _valid_run(run_id): return
	await get_tree().create_timer(BLACK_HOLD, false).timeout
	if not _valid_run(run_id): return
	_main.music.stop()
	_main.game_audio.stop_effects()
	get_tree().set_meta(&"queen_trial_chaotic_preview_done", true)
	var error := get_tree().change_scene_to_file(MENU_PATH)
	if error != OK:
		push_error("Não foi possível retornar ao menu após a simulação.")
		cancel()

func _valid_run(run_id: int) -> bool:
	return _running and run_id == _generation and is_inside_tree()

func _set_fade(progress: float) -> void:
	var blend := smoothstep(0.0, 1.0, progress)
	fade.color.a = blend
	_main.music.volume_db = _music_level + linear_to_db(maxf(1.0-blend, 0.0001))

func cancel() -> void:
	if not _running: return
	_running = false
	set_process(false)
	title_canvas.hide()
	fire_title.hide()
	_generation += 1
	if _fade_tween != null and _fade_tween.is_valid(): _fade_tween.kill()
	voice.stop()
	fade.color.a = 0.0
	_main.music.volume_db = _music_level
	_main.player.set_process_unhandled_input(_player_input_processing)
	_main.get_node("PauseOverlay").set_process_unhandled_input(_pause_input_processing)
	_main.hud.show()

func _exit_tree() -> void:
	_generation += 1
	voice.stop()
	if _fade_tween != null and _fade_tween.is_valid(): _fade_tween.kill()
