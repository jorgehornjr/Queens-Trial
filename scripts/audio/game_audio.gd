class_name GameAudio
extends Node

const SOUNDS := {
	&"paper_burn": preload("res://assets/audio/sfx/cards/paper_burn.wav"),
	&"character_move": preload("res://assets/audio/sfx/user/character_move.wav"),
	&"attack": preload("res://assets/audio/sfx/user/attack.wav"),
	&"fail": preload("res://assets/audio/sfx/user/fail.wav"),
	&"round_success": preload("res://assets/audio/sfx/user/round_success.wav"),
	&"next_phase": preload("res://assets/audio/sfx/user/next_phase.wav"),
	&"balance_weigh_left": preload("res://assets/audio/sfx/balance/weigh_left.wav"),
	&"balance_weigh_right": preload("res://assets/audio/sfx/balance/weigh_right.wav"),
	&"balance_slide_left": preload("res://assets/audio/sfx/balance/slide_left.wav"),
	&"balance_slide_right": preload("res://assets/audio/sfx/balance/slide_right.wav"),
}

const LEVELS := {
	&"paper_burn": -4.0,
	&"character_move": -10.0,
	&"attack": -5.0,
	&"fail": -4.0,
	&"round_success": 12.0,
	&"next_phase": -5.0,
	&"balance_weigh_left": -3.0,
	&"balance_weigh_right": -3.0,
	&"balance_slide_left": -3.0,
	&"balance_slide_right": -3.0,
}

@export_range(-30.0, 6.0, 0.5) var effects_volume_db := 0.0
@export var music_path := NodePath("../Music")

var _voices: Array[AudioStreamPlayer] = []
var _last_step := -1
var _music: AudioStreamPlayer
var _music_volume_db := 0.0


func _ready() -> void:
	_music = get_node_or_null(music_path) as AudioStreamPlayer
	if _music != null:
		_music_volume_db = _music.volume_db


func play_effect(sound: StringName) -> void:
	var stream: AudioStream = SOUNDS.get(sound)
	if stream == null or _voices.size() >= 12:
		return
	var voice := AudioStreamPlayer.new()
	voice.stream = stream
	voice.volume_db = effects_volume_db + float(LEVELS.get(sound, -8.0))
	voice.pitch_scale = randf_range(0.97, 1.03) if sound == &"character_move" else 1.0
	add_child(voice)
	_voices.append(voice)
	voice.finished.connect(_release_voice.bind(voice, sound))
	if sound == &"fail" and _music != null:
		_music.volume_db = _music_volume_db - 12.0
	voice.play()


func play_character_move() -> void:
	# A single keypress should have one footfall, even if input repeats rapidly.
	var now := Time.get_ticks_msec()
	if now - _last_step < 140:
		return
	_last_step = now
	play_effect(&"character_move")


func effect_duration(sound: StringName) -> float:
	var stream: AudioStream = SOUNDS.get(sound)
	return stream.get_length() if stream != null else 0.0


func stop_effect(sound: StringName) -> void:
	var stream: AudioStream = SOUNDS.get(sound)
	for voice in _voices.duplicate():
		if voice.stream == stream:
			_voices.erase(voice)
			voice.stop()
			voice.queue_free()


func stop_effects() -> void:
	for voice in _voices.duplicate():
		voice.stop()
		voice.queue_free()
	_voices.clear()
	_restore_music()


func fade_effect(sound: StringName, seconds := 0.35) -> void:
	var stream: AudioStream = SOUNDS.get(sound)
	for voice in _voices.duplicate():
		if voice.stream != stream:
			continue
		var fade: Tween = voice.create_tween()
		fade.tween_property(voice,"volume_db",-60.0,seconds)
		fade.tween_callback(func():
			voice.stop()
			_release_voice(voice,sound)
		)


func set_effects_paused(paused: bool) -> void:
	for voice in _voices:
		voice.stream_paused = paused


func _release_voice(voice: AudioStreamPlayer, sound: StringName) -> void:
	_voices.erase(voice)
	voice.queue_free()
	if sound == &"fail":
		_restore_music()


func _restore_music() -> void:
	if _music != null:
		_music.volume_db = _music_volume_db
