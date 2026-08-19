extends Node

signal fase_iniciada(numero, dados_fase)
signal fase_concluida(numero)
signal fase_reiniciada(numero)
signal bloco_concluido(numero_bloco)
signal jogo_concluido()

const TOTAL_FASES := 20
const FASES_POR_BLOCO := 4

@export var board_path: NodePath
@export var avancar_automaticamente: bool = true

var board: Node
var gerador
var numero_fase_atual: int = 1
var dados_fase_atual: Dictionary = {}
var casas_corretas_selecionadas: Array = []

func _ready() -> void:
	board = get_node(board_path)
	gerador = preload("res://scripts/core/fase_generator.gd").new()
	board.casa_selecionada.connect(_on_casa_selecionada)
	iniciar_fase(numero_fase_atual)

func iniciar_fase(numero: int) -> void:
	if numero < 1 or numero > TOTAL_FASES:
		push_error("Índice de fase inválido: %d (deve ser entre 1 e %d)" % [numero, TOTAL_FASES])
		return

	numero_fase_atual = numero
	dados_fase_atual = gerador.gerar_fase(numero)
	limpar_selecao()
	_aplicar_fase_ao_board()
	fase_iniciada.emit(numero, dados_fase_atual)
	print("Fase %d iniciada (%s)" % [numero, dados_fase_atual.get("modo", "?")])

func reiniciar_fase() -> void:
	iniciar_fase(numero_fase_atual)
	fase_reiniciada.emit(numero_fase_atual)

func avancar_proxima_fase() -> void:
	if numero_fase_atual >= TOTAL_FASES:
		jogo_concluido.emit()
		print("Todas as %d fases concluídas! Jogo finalizado." % TOTAL_FASES)
		return

	if numero_fase_atual % FASES_POR_BLOCO == 0:
		var numero_bloco = numero_fase_atual / FASES_POR_BLOCO
		bloco_concluido.emit(numero_bloco)
		print("Bloco %d concluído! Diálogo da Rainha desbloqueado." % numero_bloco)

	iniciar_fase(numero_fase_atual + 1)

func limpar_selecao() -> void:
	casas_corretas_selecionadas.clear()
	for row in range(8):
		for col in range(8):
			board.definir_estado(Vector2i(col, row), board.TileState.NORMAL)

func _aplicar_fase_ao_board() -> void:
	if dados_fase_atual["modo"] == "selecao":
		for coord in dados_fase_atual["valores"]:
			board.definir_valor(coord, dados_fase_atual["valores"][coord])
	else: # navegacao
		# Placeholder: destaca o safe spot pra debug visual.
		# O sistema de fases navegação (outro membro) deve tratar
		# movimento do Viajante e zona de ataque de verdade.
		board.definir_selecionavel(dados_fase_atual["safe_spot"], true)

func _on_casa_selecionada(coordenada: Vector2i, valor) -> void:
	if dados_fase_atual["modo"] == "selecao":
		_processar_selecao(coordenada)
	else:
		_processar_navegacao(coordenada)

func _processar_selecao(coordenada: Vector2i) -> void:
	var solucoes = dados_fase_atual["solucoes"]
	if coordenada in solucoes and not (coordenada in casas_corretas_selecionadas):
		casas_corretas_selecionadas.append(coordenada)
		board.definir_selecionado(coordenada, true)
		if casas_corretas_selecionadas.size() == solucoes.size():
			_concluir_fase()
	elif not (coordenada in solucoes):
		print("Casa errada, reiniciando fase.")
		reiniciar_fase()

func _processar_navegacao(coordenada: Vector2i) -> void:
	if coordenada == dados_fase_atual["safe_spot"]:
		_concluir_fase()
	else:
		print("Casa fora do safe spot, reiniciando fase.")
		reiniciar_fase()

func _concluir_fase() -> void:
	fase_concluida.emit(numero_fase_atual)
	print("Fase %d concluída!" % numero_fase_atual)
	if avancar_automaticamente:
		avancar_proxima_fase()
