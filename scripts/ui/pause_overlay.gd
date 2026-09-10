class_name PauseOverlay
extends CanvasLayer

## Overlay mínimo de pausa. Fica isolado do resto da árvore (só este nó usa
## PROCESS_MODE_ALWAYS) para continuar recebendo o input de pausar/retomar
## mesmo com a SceneTree pausada, sem que World/Player/PhaseManager herdem
## esse comportamento e continuem rodando durante a pausa.

@onready var panel: Control = $Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause_game"):
		return
	_toggle_pause()
	get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	panel.visible = paused
