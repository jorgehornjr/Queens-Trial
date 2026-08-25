extends Node

@onready var phase_manager: PhaseManager = $PhaseManager
@onready var board: Board3D = $World/Board
@onready var player: GridPlayer = $World/Player
@onready var camera: Camera3D = $World/Camera3D
@onready var hud: GameHUD = $HUD


func _ready() -> void:
	camera.look_at(Vector3.ZERO, Vector3.UP)
	phase_manager.phase_started.connect(_on_phase_started)
	phase_manager.phase_restarted.connect(_on_phase_restarted)
	player.cell_changed.connect(_on_player_cell_changed)
	player.move_rejected.connect(hud.show_blocked_cell)
	player.restart_requested.connect(phase_manager.restart_phase)


func _on_phase_started(phase_number: int, phase_data: Dictionary, phase_seed: int) -> void:
	hud.set_phase(phase_number, phase_data, phase_seed)
	player.reset_to_start()


func _on_phase_restarted(_phase_number: int, _phase_seed: int) -> void:
	hud.show_restart()


func _on_player_cell_changed(cell: Vector2i, _previous_cell: Vector2i) -> void:
	hud.set_player_cell(cell)
