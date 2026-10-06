class_name OpeningCutscene
extends Node3D

signal finished

const FIRST_ESTABLISHING_END := 5.2
const EMPTY_BOARD_END := 10.4
const PORTAL_START := EMPTY_BOARD_END + 0.2
const ENTRY_START := PORTAL_START + 1.2
const ENTRY_END := ENTRY_START + 400.0 / 30.0
const WALK_RAMP := 0.45
const QUEEN_REVEAL := ENTRY_START + 15.0
const WALK_END := QUEEN_REVEAL
const QUEEN_CLOSE := QUEEN_REVEAL + 3.3
const TOTAL_LENGTH := QUEEN_CLOSE + 12.9

@export var board_camera_path := NodePath("../World/BoardCamera")
@export var player_path := NodePath("../World/Player")
@export var board_path := NodePath("../World/Board")
@export var seraph_path := NodePath("../World/Seraph")
@export_range(0.25, 2.0, 0.05) var duration_scale := 1.0

@onready var cinematic_camera: Camera3D = $CinematicCamera
@onready var player_key_light: OmniLight3D = $PlayerKeyLight
@onready var teleport: AscianArrival = $TeleportArrival
@onready var teleport_sound: AudioStreamPlayer = $TeleportSound
@onready var fade: ColorRect = $Overlay/Fade
@onready var top_bar: ColorRect = $Overlay/TopBar
@onready var bottom_bar: ColorRect = $Overlay/BottomBar

var _rig: BoardOrbitCamera
var _player: GridPlayer
var _seraph: Node3D
var _character_model: Node3D
var _arrival_anchor := Vector3.ZERO
var _spawn_anchor := Vector3.ZERO
var _walk_speed := 0.0
var _tracks: Array[Dictionary] = []
var _cut_times := PackedFloat32Array([FIRST_ESTABLISHING_END, EMPTY_BOARD_END, QUEEN_REVEAL, QUEEN_CLOSE])
var _running := false
var _elapsed := 0.0
var _length := 0.0
var _teleport_started := false
var _player_revealed := false
var _reaction_started := false
var _reaction_finished := false
var _bars_tween: Tween
var _reaction_end := ENTRY_END


func _ready() -> void:
	set_process(false)
	fade.modulate.a = 0.0
	top_bar.visible = false
	bottom_bar.visible = false
	player_key_light.visible = false


func play() -> void:
	if _running:
		await finished
		return
	_rig = get_node_or_null(board_camera_path) as BoardOrbitCamera
	_player = get_node_or_null(player_path) as GridPlayer
	var board := get_node_or_null(board_path) as Board3D
	var seraph := get_node_or_null(seraph_path) as Node3D
	if _rig == null or _player == null or board == null or seraph == null:
		push_error("A abertura precisa da câmera, do tabuleiro, do jogador e da Seraph.")
		finished.emit()
		return

	_character_model = _player.get_node_or_null("Model") as Node3D
	var animations := _character_model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animations != null and animations.has_animation("intro_arrival"):
		_reaction_end = ENTRY_START + animations.get_animation("intro_arrival").length
	_arrival_anchor = _player.global_position
	_walk_speed = float(_character_model.call("cinematic_walk_speed")) if _character_model.has_method("cinematic_walk_speed") else 0.0
	_spawn_anchor = _arrival_anchor + Vector3.BACK * _walk_speed * (WALK_END - ENTRY_START - WALK_RAMP)
	if _walk_speed > 0.0: _reaction_end = WALK_END
	_seraph = seraph
	_rig.enter_gameplay(true)
	var game_position := _rig.camera.global_position
	var game_focus := board.global_position + Vector3.UP * _rig.gameplay_vertical_focus
	_rig.begin_cinematic()
	_build_tracks(board.global_position, _spawn_anchor, _seraph_head_position(seraph), game_position, game_focus)

	_running = true
	_elapsed = 0.0
	_teleport_started = false
	_player_revealed = false
	_reaction_started = false
	_reaction_finished = false
	_player.visible = false
	if _character_model.has_method("set_arrival_reveal"):
		_character_model.call("set_arrival_reveal", 0.0)
	_player.global_position = _spawn_anchor
	_seraph.visible = false
	teleport.stop()
	# AVFX bind point 29 is the character's center, rather than its floor origin.
	teleport.global_position = _spawn_anchor + Vector3.UP * (1.77 * 2.45 * 0.5)
	teleport.scale = Vector3.ONE * 2.45
	player_key_light.global_position = _player.global_position + Vector3(1.0, 2.8, -3.0)
	player_key_light.light_energy = 0.0
	player_key_light.visible = true
	_apply_camera_pose(0.0)
	cinematic_camera.make_current()
	fade.modulate.a = 1.0
	top_bar.visible = true
	bottom_bar.visible = true
	top_bar.offset_bottom = 72.0
	bottom_bar.offset_top = -72.0
	var bars := create_tween()
	_bars_tween = bars
	bars.set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bars.tween_property(top_bar, "offset_bottom", 0.0, 1.2 * duration_scale).set_delay(_length - 1.2 * duration_scale)
	bars.tween_property(bottom_bar, "offset_top", 0.0, 1.2 * duration_scale).set_delay(_length - 1.2 * duration_scale)
	set_process(true)
	await finished


func _process(delta: float) -> void:
	if not _running:
		return
	_elapsed = minf(_elapsed + delta, _length)
	var story_time := _elapsed / duration_scale
	if story_time >= PORTAL_START and not _teleport_started:
		_teleport_started = true
		teleport.burst()
		teleport_sound.play()
	if _teleport_started:
		teleport.set_age(story_time - PORTAL_START)
	if story_time >= ENTRY_START and not _player_revealed:
		_player_revealed = true
		_player.visible = true
	if story_time >= QUEEN_REVEAL and not _seraph.visible:
		_seraph.visible = true
	if story_time >= ENTRY_START and not _reaction_started:
		_reaction_started = true
		if _character_model != null:
			if _character_model.has_method("begin_cinematic_arrival"):
				_character_model.call("begin_cinematic_arrival", duration_scale)
			elif _character_model.has_method("play_intro_looking"):
				_character_model.call("play_intro_looking")
	if _reaction_started:
		if _walk_speed > 0.0:
			var walked := _walking_time_integral(story_time - ENTRY_START)
			_player.global_position = _spawn_anchor + Vector3.FORWARD * _walk_speed * walked
		player_key_light.global_position = _player.global_position + Vector3(-1.4, 3.5, -2.6)
		if _character_model.has_method("set_arrival_reveal"):
			_character_model.call("set_arrival_reveal", smoothstep(ENTRY_START, ENTRY_START + 0.85, story_time))
		if not _reaction_finished and _character_model.has_method("set_cinematic_look_up"):
			_character_model.call("set_cinematic_look_up", smoothstep(ENTRY_START + 5.5, ENTRY_START + 8.5, story_time))
	if story_time >= _reaction_end and not _reaction_finished:
		_reaction_finished = true
		if _character_model != null and _character_model.has_method("stop_intro_looking"):
			_character_model.call("stop_intro_looking")
	_apply_camera_pose(story_time)
	_update_lighting(story_time)
	_update_fade(story_time)
	if _elapsed >= _length:
		_complete()


func _build_tracks(board: Vector3, player: Vector3, queen: Vector3, game_position: Vector3, game_focus: Vector3) -> void:
	# Cada plano possui uma trajetória própria; as transições são cortes breves.
	_tracks = [
		{"start": 0.0, "end": FIRST_ESTABLISHING_END, "keys": [
			_key(0.0, board + Vector3(-29.0, 38.0, -29.0), board + Vector3(0.0, 2.5, 0.0), 52.0),
			_key(FIRST_ESTABLISHING_END, board + Vector3(-28.0, 33.0, -27.0), board + Vector3(0.0, 0.5, 0.0), 52.0),
		]},
		{"start": FIRST_ESTABLISHING_END, "end": EMPTY_BOARD_END, "keys": [
			_key(0.0, board + Vector3(22.0, 20.0, 31.0), board + Vector3(0.0, 0.4, 3.0), 48.0),
			_key(EMPTY_BOARD_END - FIRST_ESTABLISHING_END, board + Vector3(19.0, 17.5, 30.0), board + Vector3(0.0, 0.4, 2.0), 48.0),
		]},
		{"start": EMPTY_BOARD_END, "end": QUEEN_REVEAL, "follow_player": true, "keys": [
			_key(0.0, player + Vector3(-4.3, 2.85, -5.0), player + Vector3(0.0, 2.4, 0.0), 42.0),
			_key(4.0, player + Vector3(-2.3, 3.15, -6.0), player + Vector3(0.0, 2.5, 0.0), 39.0),
			_key(9.0, player + Vector3(3.0, 3.35, -7.1), player + Vector3(0.0, 2.4, 0.0), 39.0),
			_key(14.4, player + Vector3(5.0, 4.4, -11.0), player + Vector3(0.0, 2.3, 0.0), 42.0),
		]},
		{"start": QUEEN_REVEAL, "end": QUEEN_CLOSE, "keys": [
			_key(0.0, board + Vector3(-41.0, 23.0, 2.0), board + Vector3(1.0, 9.0, -31.0), 56.0),
			_key(3.3, board + Vector3(-32.0, 27.0, 19.0), queen + Vector3(0.0, -2.0, 0.0), 55.0),
		]},
		{"start": QUEEN_CLOSE, "end": TOTAL_LENGTH, "keys": [
			_key(0.0, queen + Vector3(0.0, 3.4, 15.0), queen + Vector3(0.0, 2.5, 0.0), 38.0),
			_key(2.8, queen + Vector3(0.0, 4.0, 23.0), queen + Vector3(0.0, 2.3, 0.0), 42.0),
			_key(5.8, board + Vector3(0.0, 25.0, -3.0), queen + Vector3(0.0, 0.0, 0.0), 49.0),
			_key(9.0, board + Vector3(0.0, 35.0, 25.0), board + Vector3(0.0, 10.0, -28.0), 55.0),
			_key(12.9, game_position, game_focus, _rig.gameplay_fov),
		]},
	]
	_length = TOTAL_LENGTH * duration_scale


func _key(time: float, position: Vector3, focus: Vector3, fov: float) -> Dictionary:
	return {"time": time, "position": position, "focus": focus, "fov": fov}


func _seraph_head_position(seraph: Node3D) -> Vector3:
	var skeleton := seraph.get_node_or_null("Model/Seraph/Skeleton3D") as Skeleton3D
	if skeleton != null:
		var head_bone := skeleton.find_bone("head")
		if head_bone >= 0:
			return skeleton.global_transform * skeleton.get_bone_global_pose(head_bone).origin
	return seraph.global_position + Vector3(0.0, 62.0, 0.0)


func _apply_camera_pose(story_time: float) -> void:
	var track: Dictionary = _tracks.back()
	for candidate in _tracks:
		if story_time < float(candidate["end"]):
			track = candidate
			break
	var local_time := story_time - float(track["start"])
	var keys: Array = track["keys"]
	var index := keys.size() - 2
	for candidate_index in range(keys.size() - 1):
		if local_time <= float(keys[candidate_index + 1]["time"]):
			index = candidate_index
			break
	var first: Dictionary = keys[index]
	var second: Dictionary = keys[index + 1]
	var span := float(second["time"]) - float(first["time"])
	var blend := clampf((local_time - float(first["time"])) / span, 0.0, 1.0)
	var before: Dictionary = keys[maxi(index - 1, 0)]
	var after: Dictionary = keys[mini(index + 2, keys.size() - 1)]
	var incoming_span := float(second["time"]) - float(before["time"])
	var outgoing_span := float(after["time"]) - float(first["time"])
	var position_tangent_a: Vector3 = (second["position"] - before["position"]) / incoming_span
	var position_tangent_b: Vector3 = (after["position"] - first["position"]) / outgoing_span
	var focus_tangent_a: Vector3 = (second["focus"] - before["focus"]) / incoming_span
	var focus_tangent_b: Vector3 = (after["focus"] - first["focus"]) / outgoing_span
	var fov_tangent_a: float = (float(second["fov"]) - float(before["fov"])) / incoming_span
	var fov_tangent_b: float = (float(after["fov"]) - float(first["fov"])) / outgoing_span
	cinematic_camera.global_position = _hermite_vec3(first["position"], second["position"], position_tangent_a * span, position_tangent_b * span, blend)
	var focus := _hermite_vec3(first["focus"], second["focus"], focus_tangent_a * span, focus_tangent_b * span, blend)
	if bool(track.get("follow_player", false)):
		var travel := _player.global_position - _spawn_anchor
		cinematic_camera.global_position += travel
		focus += travel
	cinematic_camera.look_at(focus, Vector3.UP)
	cinematic_camera.fov = _hermite_float(float(first["fov"]), float(second["fov"]), fov_tangent_a * span, fov_tangent_b * span, blend)


func _hermite_vec3(a: Vector3, b: Vector3, tangent_a: Vector3, tangent_b: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * a + (t3 - 2.0 * t2 + t) * tangent_a + (-2.0 * t3 + 3.0 * t2) * b + (t3 - t2) * tangent_b


func _walking_time_integral(elapsed: float) -> float:
	var duration := WALK_END - ENTRY_START
	var time := clampf(elapsed, 0.0, duration)
	if time < WALK_RAMP:
		var u := time / WALK_RAMP
		return WALK_RAMP * (u * u * u - 0.5 * u * u * u * u)
	if time <= duration - WALK_RAMP: return time - WALK_RAMP * 0.5
	var u := (time - duration + WALK_RAMP) / WALK_RAMP
	return duration - WALK_RAMP * 1.5 + WALK_RAMP * (u - u * u * u + 0.5 * u * u * u * u)


func _hermite_float(a: float, b: float, tangent_a: float, tangent_b: float, t: float) -> float:
	var t2 := t * t
	var t3 := t2 * t
	return (2.0 * t3 - 3.0 * t2 + 1.0) * a + (t3 - 2.0 * t2 + t) * tangent_a + (-2.0 * t3 + 3.0 * t2) * b + (t3 - t2) * tangent_b


func _update_lighting(story_time: float) -> void:
	var emphasis := smoothstep(ENTRY_START + 0.4, ENTRY_START + 1.4, story_time) * (1.0 - smoothstep(QUEEN_REVEAL - 2.3, QUEEN_REVEAL - 0.2, story_time))
	player_key_light.light_energy = 1.6 * emphasis


func _update_fade(story_time: float) -> void:
	var opacity := 1.0 - smoothstep(0.0, 1.05, story_time)
	for cut in _cut_times:
		opacity = maxf(opacity, 1.0 - smoothstep(0.0, 0.11, absf(story_time - cut)))
	fade.modulate.a = opacity


func skip() -> void:
	if not _running:
		return
	if _bars_tween != null and _bars_tween.is_valid():
		_bars_tween.kill()
	teleport_sound.stop()
	_complete()


func _complete() -> void:
	set_process(false)
	_running = false
	_player.visible = true
	_player.global_position = _arrival_anchor
	if _character_model.has_method("set_arrival_reveal"):
		_character_model.call("set_arrival_reveal", 1.0)
	_seraph.visible = true
	teleport.stop()
	if _character_model != null and _character_model.has_method("stop_intro_looking"):
		_character_model.call("stop_intro_looking")
	_rig.enter_gameplay(true)
	_rig.camera.make_current()
	player_key_light.visible = false
	top_bar.visible = false
	bottom_bar.visible = false
	fade.modulate.a = 0.0
	finished.emit()
