class_name GameHUD
extends CanvasLayer

@onready var phase_label: Label = $TopPanel/Content/PhaseLabel
@onready var rule_label: Label = $TopPanel/Content/RuleLabel
@onready var position_label: Label = $TopPanel/Content/PositionLabel


func set_phase(phase_number: int, phase_data: Dictionary, phase_seed: int) -> void:
	phase_label.text = "FASE %02d / 10" % phase_number
	var resolution := "por movimentos"
	if String(phase_data.get("resolution", "moves")) == "timer":
		resolution = "%d s por édito" % int(phase_data.get("seconds_per_edict", 15))
	var seed_suffix := ""
	if String(phase_data.get("configuration", "fixed")) == "procedural":
		seed_suffix = "  •  semente %d" % phase_seed
	rule_label.text = "%s  •  %s%s" % [phase_data.get("focus", ""), resolution, seed_suffix]


func set_player_cell(cell: Vector2i) -> void:
	position_label.text = "Jogador  •  coluna %d  •  linha %d" % [cell.x + 1, cell.y + 1]
