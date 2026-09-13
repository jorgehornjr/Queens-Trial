extends Node

@onready var phase_manager: PhaseManager = $PhaseManager
@onready var board: Board3D = $World/Board
@onready var player: GridPlayer = $World/Player
@onready var hud: GameHUD = $HUD
@onready var board_camera: BoardOrbitCamera = $World/BoardCamera
@onready var celestial_space: CelestialSpace = $World/CelestialSpace


func _ready() -> void:
	phase_manager.phase_started.connect(_on_phase_started)
	player.restart_requested.connect(phase_manager.restart_phase)


func _unhandled_input(event: InputEvent) -> void:
	# Atalho de entrada na prévia da fase.
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ENTER:
		if phase_manager.current_phase == 0:
			phase_manager.start_phase(phase_manager.initial_phase)
			get_viewport().set_input_as_handled()


func _on_phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int) -> void:
	board_camera.enter_gameplay()
	celestial_space.enter_gameplay_composition(board_camera.camera, board_camera.transition_seconds)
	hud.set_phase(phase_number, phase_data, phase_seed)
	player.reset_to_start()
