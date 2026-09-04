class_name GameHUD
extends CanvasLayer

@onready var phase_label: Label = $TopPanel/Content/PhaseLabel
@onready var rule_label: Label = $TopPanel/Content/RuleLabel
@onready var position_label: Label = $TopPanel/Content/PositionLabel


func _ready() -> void:
	_reset_edito_display()


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


func show_blocked_cell(cell: Vector2i) -> void:
	status_label.text = "Movimento ignorado: a casa (%d, %d) está fora da arena ou ocupada." % [
		cell.x + 1,
		cell.y + 1,
	]


func show_restart() -> void:
	status_label.text = "Fase reiniciada com a mesma configuração."
	_reset_edito_display()


## Chamado pelo controller quando os éditos da fase são cumpridos com sucesso.
func show_success() -> void:
	if _edito_machine == null:
		return
	_set_state_text("Concluído", _COR_SUCESSO)
	_atualizar_ordens(_edito_machine.indice_edito_atual, "sucesso")


## Chamado pelo controller quando o julgamento reprova o jogador.
func show_failure(motivos: Array) -> void:
	if _edito_machine != null:
		_set_state_text("Falhou", _COR_FALHA)
		_atualizar_ordens(_edito_machine.indice_edito_atual, "falha")
	if motivos.size() > 0:
		status_label.text = String(motivos[0])


## Liga a HUD aos sinais da máquina de estados dos éditos (edito_iniciado,
## estado_mudou) para refletir a ordem do édito atual, o valor em numeral
## romano e o estado do gameplay em tempo real.
func connect_to_edito_machine(machine: Node) -> void:
	if not is_node_ready():
		# Evita crash se for chamado antes de @onready resolver os Labels
		# (ex.: HUD instanciada e conectada no mesmo frame por outro nó).
		await ready

	if _edito_machine == machine:
		return
	if _edito_machine != null:
		_disconnect_edito_machine()

	_edito_machine = machine
	_edito_machine.edito_iniciado.connect(_on_edito_iniciado)
	_edito_machine.estado_mudou.connect(_on_estado_mudou)
	_reset_edito_display()


func _disconnect_edito_machine() -> void:
	if _edito_machine.edito_iniciado.is_connected(_on_edito_iniciado):
		_edito_machine.edito_iniciado.disconnect(_on_edito_iniciado)
	if _edito_machine.estado_mudou.is_connected(_on_estado_mudou):
		_edito_machine.estado_mudou.disconnect(_on_estado_mudou)


func _reset_edito_display() -> void:
	_total_editos = 0
	edito_order_1_label.text = "1ª ordem  •  —"
	edito_order_1_label.add_theme_color_override("font_color", _COR_AGUARDANDO)
	edito_order_2_label.text = "2ª ordem  •  —"
	edito_order_2_label.add_theme_color_override("font_color", _COR_AGUARDANDO)
	_set_state_text("Aguardando início", _COR_AGUARDANDO)


func _on_edito_iniciado(indice: int, _valor: int) -> void:
	_total_editos = _edito_machine.editos.size()
	_atualizar_ordens(indice)


func _on_estado_mudou(estado: int) -> void:
	if estado == EditoMachineModel.Estado.FINALIZADO:
		return # texto final é decidido por show_success()/show_failure()
	_set_state_text(_NOMES_ESTADO.get(estado, "Desconhecido"), _COR_EM_ANDAMENTO)
	_atualizar_ordens(_edito_machine.indice_edito_atual)


## Atualiza as duas labels de ordem do édito, distinguindo ordem pendente,
## em andamento e concluída (ou reprovada) sem depender de nós do tabuleiro —
## toda a informação vem do próprio EditoStateMachine.
func _atualizar_ordens(indice_atual: int, resultado_final: String = "") -> void:
	_atualizar_label_ordem(edito_order_1_label, 0, indice_atual, resultado_final)
	_atualizar_label_ordem(edito_order_2_label, 1, indice_atual, resultado_final)


func _atualizar_label_ordem(label: Label, ordem_indice: int, indice_atual: int, resultado_final: String) -> void:
	var prefixo := "%dª ordem" % (ordem_indice + 1)

	if ordem_indice >= _total_editos:
		label.text = "%s  •  não configurada" % prefixo
		label.add_theme_color_override("font_color", _COR_AGUARDANDO)
		return

	var valor: int = _edito_machine.editos[ordem_indice]["valor"]
	var valor_romano := _numeral(valor)

	if ordem_indice < indice_atual:
		label.text = "%s  •  %s  •  concluído" % [prefixo, valor_romano]
		label.add_theme_color_override("font_color", _COR_SUCESSO)
	elif ordem_indice == indice_atual:
		var status := "em andamento"
		var cor := _COR_EM_ANDAMENTO
		if resultado_final == "sucesso":
			status = "concluído"
			cor = _COR_SUCESSO
		elif resultado_final == "falha":
			status = "falhou"
			cor = _COR_FALHA
		label.text = "%s  •  %s  •  %s" % [prefixo, valor_romano, status]
		label.add_theme_color_override("font_color", cor)
	else:
		label.text = "%s  •  %s  •  pendente" % [prefixo, valor_romano]
		label.add_theme_color_override("font_color", _COR_AGUARDANDO)


func _set_state_text(texto: String, cor: Color) -> void:
	state_label.text = "Estado  •  %s" % texto
	state_label.add_theme_color_override("font_color", cor)


func _numeral(valor: int) -> String:
	return _NUMERAIS_ROMANOS.get(valor, str(valor))
