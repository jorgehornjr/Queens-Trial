class_name PhaseLoopController
extends Node

## Une éditos, movimento, ataques, julgamento, reinício e avanço para que a
## campanha rode da fase 1 até a 4 sem intervenção do editor. Fases 5+
## (Bispo) ficam fora do escopo desta integração.

const EditoMachineModel = preload("res://scripts/gameplay/edito_state_machine.gd")
const DeslocamentoModel = preload("res://scripts/gameplay/deslocamento_externo.gd")
const RookResolverModel = preload("res://scripts/pieces/rook_resolver.gd")
const AttackEventModel = preload("res://scripts/gameplay/attack_event.gd")

@export var phase_manager_path: NodePath
@export var board_path: NodePath
@export var player_path: NodePath
@export var hud_path: NodePath

var _phase_manager: PhaseManager
var _board: Board3D
var _player: GridPlayer
var _hud: GameHUD

var _edito_machine
var _attack_event

var _current_phase_data: Dictionary = {}
var _current_positions: Array[Vector2i] = []


func _ready() -> void:
	_phase_manager = get_node(phase_manager_path)
	_board = get_node(board_path)
	_player = get_node(player_path)
	_hud = get_node(hud_path)

	_edito_machine = EditoMachineModel.new()
	add_child(_edito_machine)
	_attack_event = AttackEventModel.new()
	add_child(_attack_event)

	_edito_machine.estado_mudou.connect(_on_estado_mudou)
	_edito_machine.falha.connect(_on_falha)
	_edito_machine.sucesso.connect(_on_sucesso)

	_phase_manager.phase_started.connect(_on_phase_started)


func _on_phase_started(phase_number: int, phase_data: Dictionary, _phase_seed: int) -> void:
	if _player.cell_changed.is_connected(_on_player_moved):
		_player.cell_changed.disconnect(_on_player_moved)

	if phase_number > 4:
		return # loop integrado desta task cobre apenas as fases 1 a 4

	_current_phase_data = phase_data
	call_deferred("_setup_edito_machine")


func _setup_edito_machine() -> void:
	var editos := _build_editos(_current_phase_data)
	if not _edito_machine.configurar_fase(editos, _player.current_cell):
		push_error("Não foi possível configurar os éditos da fase atual.")
		return
	_player.cell_changed.connect(_on_player_moved)


func _build_editos(phase_data: Dictionary) -> Array:
	var edict_count := int(phase_data.get("edict_count", 1))
	var valores := [2, 3, 4]
	valores.shuffle()
	var editos: Array = []
	for i in range(edict_count):
		var par_key := "first_pair" if i == 0 else "second_pair"
		editos.append({"valor": valores[i], "par": par_key})
	return editos


func _on_player_moved(cell: Vector2i, previous_cell: Vector2i) -> void:
	_edito_machine.registrar_movimento(cell - previous_cell)


func _on_estado_mudou(estado: int) -> void:
	match estado:
		EditoMachineModel.Estado.PRIMEIRA_PECA:
			_current_positions = _calcular_posicoes_do_par_atual()
			_edito_machine.avancar_primeira_peca()
		EditoMachineModel.Estado.SEGUNDA_PECA:
			_edito_machine.avancar_segunda_peca()
		EditoMachineModel.Estado.ATAQUE:
			_resolver_ataque()


func _par_atual_key() -> String:
	return "first_pair" if _edito_machine.indice_edito_atual == 0 else "second_pair"


func _calcular_posicoes_do_par_atual() -> Array[Vector2i]:
	var tipos: Array = _current_phase_data.get(_par_atual_key(), [])
	if tipos.is_empty():
		return []

	var indice: int = _edito_machine.indice_edito_atual
	var valor: int = _edito_machine.editos[indice]["valor"]
	var lados := ["esquerda", "direita"] if indice == 0 else ["superior", "inferior"]
	var eixo_fixo := 2 # fases 1-4 usam sempre o eixo central para o par ativo

	var posicoes: Array[Vector2i] = []
	for lado in lados:
		var resultado := DeslocamentoModel.calcular_deslocamento(lado, valor, eixo_fixo)
		if resultado["sucesso"]:
			posicoes.append(resultado["destino"])
	return posicoes


func _resolver_ataque() -> void:
	var tipos: Array = _current_phase_data.get(_par_atual_key(), [])
	var casas_atacadas: Array[Vector2i] = []

	if tipos.size() > 0 and _current_positions.size() > 0:
		var resultado_torre := RookResolverModel.resolve_pair(_board.state, _current_positions, _player.current_cell)
		casas_atacadas = resultado_torre["attacked_cells"]

	_edito_machine.avancar_ataque()
	_edito_machine.julgar(casas_atacadas, _board.state.safe_spot)


func _on_falha(motivos: Array) -> void:
	if _hud.has_method("show_failure"):
		_hud.show_failure(motivos)
	_phase_manager.restart_phase()


func _on_sucesso() -> void:
	_phase_manager.advance_phase()
