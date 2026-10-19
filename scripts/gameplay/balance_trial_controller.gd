class_name BalanceTrialController
extends Node


signal round_started(left_weight: int, right_weight: int)
signal trial_completed

const TrialHUD = preload("res://scripts/ui/balance_hud.gd")
const Stardust = preload("res://scripts/gameplay/balance_stardust.gd")
const ScreenDust = preload("res://scripts/ui/balance_screen_dust.gd")
enum Stage { INACTIVE, TRANSITION, MALFUNCTION, DECISION, TILTING, RECOVERING, SETTLING, FALLING, FAILED, COMPLETE }

var stage := Stage.INACTIVE
var round_index := 0
var remaining := 5.0
var left_weight := 0
var right_weight := 0
var heavy_direction := 1
var slide_distance := 0.0
var slide_speed := 0.0
var _generation := 0
var _elapsed := 0.0
var _fall_velocity := Vector3.ZERO
var _round_count := 3
var _rounds: Array = []
var _decision_seconds := 5.0
var _max_angle := deg_to_rad(21.0)
var _slide_tiles := 3.0
var _recovery_angle := 0.0
var _manager: PhaseManager
var _board: Board3D
var _player: GridPlayer
var _hud: GameHUD
var _audio: GameAudio
var _queen: Node3D
var trial_hud: BalanceHUD
var stardust: BalanceStardust
var _mist: Node3D
var _slide_sound: StringName


func _ready() -> void:
	_manager = get_node("../PhaseManager")
	_board = get_node("../World/Board")
	_player = get_node("../World/Player")
	_hud = get_node("../HUD")
	_audio = get_node("../GameAudio")
	_queen = get_node("../World/Seraph")
	_mist = _board.get_node("LevitationMist")
	stardust = Stardust.new()
	stardust.name = "BalanceStardust"
	_board.add_child(stardust)
	stardust.screen_dust = ScreenDust.new()
	stardust.screen_dust.name = "BalanceScreenDust"
	_hud.add_child(stardust.screen_dust)
	trial_hud = TrialHUD.new()
	trial_hud.name = "BalanceHUD"
	_hud.add_child(trial_hud)
	_manager.phase_started.connect(_on_phase_started)


func _on_phase_started(number: int, data: Dictionary, _seed: int) -> void:
	_generation += 1
	stage = Stage.INACTIVE
	_board.rotation.z = 0.0
	trial_hud.hide()
	stardust.clear()
	var is_balance := String(data.get("resolution", "")) == "balance"
	_mist.set_follow_tilt(is_balance)
	if not is_balance:
		_queen.set_balance_mode(false)
		return
	_round_count = int(data.get("balance_round_count", 3))
	_rounds = data.get("balance_rounds", []).duplicate(true)
	if is_instance_valid(_queen.balance):
		_queen.balance.reset_weights()
	_decision_seconds = float(data.get("seconds_per_edict", 5.0))
	remaining = _decision_seconds
	_max_angle = deg_to_rad(float(data.get("tilt_degrees", 21.0)))
	_slide_tiles = float(data.get("slide_tiles", 3.0))
	round_index = 0
	stage = Stage.TRANSITION
	_player.set_input_enabled(false)
	_board.set_safe_spot_visible(false)
	_hud.announcement.hide()
	_hud.result_panel.hide()
	call_deferred("_begin", _generation)


func _begin(run_id: int) -> void:
	await get_tree().process_frame
	if run_id != _generation:
		return
	_queen.set_balance_mode(true)

	while _queen.balance.reveal < 0.999 or _queen.get_node("Model/Seraph/Skeleton3D/OrbAttachment/AstraiaOrb").visible:
		await get_tree().process_frame
		if run_id != _generation:
			return

	if int(_manager.current_phase_data.get("tutorial_chapter", 0)) == 6 and _hud.tutorial_book.needs_chapter(6):
		await get_tree().create_timer(0.55).timeout
		if run_id != _generation: return
		var read_ok := await _hud.play_balance_intro()
		if not read_ok or run_id != _generation: return
	_open_round()


func _open_round() -> void:
	var pair := _draw_weights()
	left_weight = pair.x
	right_weight = pair.y
	heavy_direction = 1 if right_weight > left_weight else -1
	remaining = _decision_seconds
	_elapsed = 0.0
	slide_distance = 0.0
	slide_speed = 0.0
	var concealed := bool(_rounds[round_index].concealed)
	_queen.balance.set_weights(left_weight, right_weight, concealed)
	if concealed:
		stage = Stage.MALFUNCTION
		trial_hud.hide()
		_player.set_input_enabled(false)
		_wait_for_malfunction(_generation)
		return
	_open_decision()

func _wait_for_malfunction(run_id: int) -> void:
	var completed: bool = await _queen.balance.malfunction_finished
	if completed and run_id == _generation and stage == Stage.MALFUNCTION:
		_open_decision()

func _open_decision() -> void:
	var concealed := bool(_rounds[round_index].concealed)
	if not concealed:
		_audio.play_effect(&"balance_weigh_right" if heavy_direction > 0 else &"balance_weigh_left")
	trial_hud.show_round(left_weight, right_weight)
	stage = Stage.DECISION
	_player.set_input_enabled(true)
	round_started.emit(left_weight, right_weight)

func _draw_weights() -> Vector2i:
	var round_data: Dictionary = _rounds[round_index]
	return Vector2i(int(round_data.left), int(round_data.right))


func _physics_process(delta: float) -> void:
	match stage:
		Stage.DECISION:
			remaining = maxf(0.0, remaining - delta)
			if remaining <= 0.0:
				_player.begin_platform_slide(heavy_direction)
				stardust.start(heavy_direction)
				_slide_sound = &"balance_slide_right" if heavy_direction > 0 else &"balance_slide_left"
				_audio.play_effect(_slide_sound)
				stage = Stage.TILTING
				_elapsed = 0.0
		Stage.TILTING:
			_elapsed += delta
			stardust.strength = smoothstep(0.0,0.38,_elapsed)
			_board.rotation.z = -heavy_direction * _max_angle * smoothstep(0.0, 1.0, minf(_elapsed / 0.95, 1.0))
			# A física move o personagem; a animação não aplica deslocamento próprio.

			var acceleration := absf(sin(_board.rotation.z)) * _board.tile_size * 11.0
			slide_speed += acceleration * delta
			var step := minf(slide_speed * delta, _board.tile_size * _slide_tiles - slide_distance)
			slide_distance += step
			_player.platform_local_position.x += step * heavy_direction
			_player.sync_to_platform()
			if absf(_player.platform_local_position.x) > _board.tile_size * 2.5:
				_start_fall()
			elif slide_distance >= _board.tile_size * _slide_tiles - 0.001:
				stardust.fade()
				_audio.fade_effect(_slide_sound)
				stage = Stage.RECOVERING
				_elapsed = 0.0
				_recovery_angle = _board.rotation.z
				_player.recover_platform_slide()
		Stage.RECOVERING:
			_elapsed += delta
			stardust.strength = 1.0-smoothstep(0.0,0.75,_elapsed)
			_board.rotation.z = lerpf(_recovery_angle, 0.0, smoothstep(0.0, 1.0, minf(_elapsed, 1.0)))
			_player.sync_to_platform()
			if _elapsed >= 1.0:
				_board.rotation.z = 0.0
				_player.finish_platform_slide()
				stage = Stage.SETTLING
				_elapsed = 0.0
		Stage.SETTLING:
			_elapsed += delta
			if _elapsed >= 0.55:
				round_index += 1
				if round_index < _round_count:
					_audio.play_effect(&"round_success")
					_open_round()
				else:
					_finish_success(_generation)
		Stage.FALLING:
			_elapsed += delta
			stardust.strength = 1.0-smoothstep(0.0,0.75,_elapsed)
			_fall_velocity.y -= 32.0 * delta
			_player.global_position += _fall_velocity * delta

			_player.rotation.z -= float(heavy_direction) * delta * 0.85
			_board.rotation.z = move_toward(_board.rotation.z, 0.0, delta * _max_angle)
			if stage == Stage.FALLING and _elapsed >= 1.5:
				stage = Stage.FAILED
	if stage in [Stage.DECISION, Stage.TILTING, Stage.RECOVERING, Stage.SETTLING, Stage.FALLING, Stage.FAILED]:
		_player.update_platform_motion(slide_speed, stardust.strength)


func _start_fall() -> void:
	stage = Stage.FALLING
	_elapsed = 0.0
	_fall_velocity = _board.global_basis.x * float(heavy_direction) * slide_speed
	_player.begin_platform_fall(heavy_direction)
	trial_hud.hide()
	stardust.fade()
	_audio.fade_effect(_slide_sound)
	_audio.play_effect(&"fail")
	_wait_for_retry(_generation)


func _wait_for_retry(run_id: int) -> void:
	var side := "esquerdo" if heavy_direction < 0 else "direito"
	var weights := "À esquerda: %s (%d). À direita: %s (%d)." % [GameConstants.to_roman(left_weight), left_weight, GameConstants.to_roman(right_weight), right_weight]
	var accepted := await _hud.show_failure([weights, "O lado %s ficou mais pesado e puxou o tabuleiro. O personagem acabou caindo pela borda." % side])
	if accepted and run_id == _generation:
		_manager.restart_phase()


func _finish_success(run_id: int) -> void:
	stage = Stage.COMPLETE
	trial_hud.hide()
	_player.set_input_enabled(false)
	_audio.play_effect(&"next_phase")
	trial_completed.emit()
	await get_tree().create_timer(0.35).timeout
	if run_id == _generation:
		_queen.balance.reset_weights()
		_manager.advance_phase()
