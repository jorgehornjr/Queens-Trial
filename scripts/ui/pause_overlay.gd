class_name PauseOverlay
extends CanvasLayer

## Overlay mínimo de pausa. Fica isolado do resto da árvore (só este nó usa
## PROCESS_MODE_ALWAYS) para continuar recebendo o input de pausar/retomar
## mesmo com a SceneTree pausada, sem que World/Player/PhaseManager herdem
## esse comportamento e continuem rodando durante a pausa.

@export var music_path := NodePath("../Music")
@export var phase_manager_path := NodePath("../PhaseManager")

@onready var screen: Control = $Screen
@onready var continue_button: Button = $Screen/Panel/Content/ContinueButton
@onready var restart_button: Button = $Screen/Panel/Content/RestartButton

var _music: AudioStreamPlayer
var _phase_manager: PhaseManager
var _music_was_paused := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = get_node_or_null(music_path) as AudioStreamPlayer
	_phase_manager = get_node_or_null(phase_manager_path) as PhaseManager
	screen.visible = false
	continue_button.pressed.connect(_resume)
	restart_button.pressed.connect(_restart_phase)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif screen.visible and event.is_action_pressed("restart_phase"):
		_restart_phase()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	_set_paused(not get_tree().paused)


func _set_paused(paused: bool) -> void:
	if paused:
		_music_was_paused = _music != null and _music.stream_paused
	get_tree().paused = paused
	screen.visible = paused
	if _music != null:
		_music.stream_paused = paused or _music_was_paused
	if paused:
		restart_button.disabled = _phase_manager == null or _phase_manager.current_phase == 0
		continue_button.grab_focus()


func _resume() -> void:
	_set_paused(false)


func _restart_phase() -> void:
	if _phase_manager == null or _phase_manager.current_phase == 0:
		return
	_set_paused(false)
	_phase_manager.restart_phase()
