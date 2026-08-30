class_name GameHUD
extends CanvasLayer

@onready var phase_label: Label = $TopPanel/Content/PhaseLabel
@onready var rule_label: Label = $TopPanel/Content/RuleLabel
@onready var position_label: Label = $TopPanel/Content/PositionLabel
@onready var status_label: Label = $BottomPanel/StatusLabel


func set_phase(phase_number: int, phase_data: Dictionary, phase_seed: int) -> void:
	phase_label.text = "FASE %02d / 10" % phase_number
	var resolution := "por movimentos"
	if String(phase_data.get("resolution", "moves")) == "timer":
		resolution = "%d s por édito" % int(phase_data.get("seconds_per_edict", 15))
	var seed_suffix := ""
	if String(phase_data.get("configuration", "fixed")) == "procedural":
		seed_suffix = "  •  semente %d" % phase_seed
	rule_label.text = "%s  •  %s%s" % [phase_data.get("focus", ""), resolution, seed_suffix]
	status_label.text = "Scaffold técnico: use WASD para mover e R para reiniciar a fase."


func set_player_cell(cell: Vector2i) -> void:
	position_label.text = "Jogador  •  coluna %d  •  linha %d" % [cell.x + 1, cell.y + 1]


func show_blocked_cell(cell: Vector2i) -> void:
	status_label.text = "Movimento ignorado: a casa (%d, %d) está fora da arena ou ocupada." % [
		cell.x + 1,
		cell.y + 1,
	]


func show_restart() -> void:
	status_label.text = "Fase reiniciada com a mesma configuração."
