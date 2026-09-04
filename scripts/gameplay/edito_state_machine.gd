extends Node

signal estado_mudou(estado_novo)
signal edito_iniciado(indice, valor)
signal movimento_registrado(passos_atuais, passos_necessarios)
signal falha(motivos: Array)
signal sucesso()

enum Estado {
	SELECAO_PAR,
	AGUARDANDO_MOVIMENTO,
	PRIMEIRA_PECA,
	SEGUNDA_PECA,
	ATAQUE,
	JULGAMENTO,
	FINALIZADO,
}

# Transições permitidas: de onde pode ir pra onde
const TRANSICOES_VALIDAS := {
	Estado.SELECAO_PAR: [Estado.AGUARDANDO_MOVIMENTO],
	Estado.AGUARDANDO_MOVIMENTO: [Estado.PRIMEIRA_PECA],
	Estado.PRIMEIRA_PECA: [Estado.SEGUNDA_PECA],
	Estado.SEGUNDA_PECA: [Estado.ATAQUE],
	Estado.ATAQUE: [Estado.JULGAMENTO],
	Estado.JULGAMENTO: [Estado.SELECAO_PAR, Estado.FINALIZADO],
	Estado.FINALIZADO: [],
}

var estado_atual: int = Estado.SELECAO_PAR
var editos: Array = []          # [{valor: int, par: String}, ...]
var indice_edito_atual: int = 0
var origem_atual: Vector2i
var posicao_jogador: Vector2i
var passos_dados: int = 0
var passos_necessarios: int = 0

func configurar_fase(lista_editos: Array, posicao_inicial: Vector2i) -> bool:
	if not _validar_editos(lista_editos):
		push_error("Configuração de éditos inválida: valores ou pares repetidos indevidamente.")
		return false
	editos = lista_editos
	indice_edito_atual = 0
	posicao_jogador = posicao_inicial
	# Configurar uma fase reinicia o ciclo, inclusive após FINALIZADO.
	estado_atual = Estado.SELECAO_PAR
	_transicionar(Estado.SELECAO_PAR)
	_iniciar_edito_atual()
	return true

func _validar_editos(lista: Array) -> bool:
	if lista.size() == 0 or lista.size() > 2:
		return false
	if lista.size() == 2:
		if lista[0]["valor"] == lista[1]["valor"]:
			return false # segundo édito não pode reutilizar o mesmo valor
		if lista[0]["par"] == lista[1]["par"]:
			return false # segundo édito não pode reutilizar o mesmo par de peças
	for edito in lista:
		if not edito["valor"] in [2, 3, 4]:
			return false
	return true

func _iniciar_edito_atual() -> void:
	origem_atual = posicao_jogador
	passos_dados = 0
	passos_necessarios = editos[indice_edito_atual]["valor"]
	edito_iniciado.emit(indice_edito_atual, passos_necessarios)
	_transicionar(Estado.AGUARDANDO_MOVIMENTO)

func registrar_movimento(direcao: Vector2i) -> bool:
	if estado_atual != Estado.AGUARDANDO_MOVIMENTO:
		push_warning("Movimento ignorado: fora do estado de movimentação (%s)." % Estado.keys()[estado_atual])
		return false

	var destino = posicao_jogador + direcao
	if not _dentro_da_grade(destino) or destino == Vector2i(2, 2): # casa central da Rainha
		return false # não consome passo, conforme a especificação

	posicao_jogador = destino
	passos_dados += 1
	movimento_registrado.emit(passos_dados, passos_necessarios)

	if passos_dados >= passos_necessarios:
		_transicionar(Estado.PRIMEIRA_PECA)
	return true

func _dentro_da_grade(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < 5 and p.y >= 0 and p.y < 5

func avancar_primeira_peca() -> bool:
	return _tentar_transicionar(Estado.PRIMEIRA_PECA, Estado.SEGUNDA_PECA)

func avancar_segunda_peca() -> bool:
	return _tentar_transicionar(Estado.SEGUNDA_PECA, Estado.ATAQUE)

func avancar_ataque() -> bool:
	return _tentar_transicionar(Estado.ATAQUE, Estado.JULGAMENTO)

func julgar(zona_ataque: Array, safe_spot: Vector2i) -> void:
	if estado_atual != Estado.JULGAMENTO:
		push_warning("Julgamento chamado fora de hora (estado atual: %s)." % Estado.keys()[estado_atual])
		return

	var motivos: Array = []
	var distancia = abs(posicao_jogador.x - origem_atual.x) + abs(posicao_jogador.y - origem_atual.y)

	if distancia != passos_necessarios:
		motivos.append("Édito %s não cumprido: distância final %d." % [_numeral(passos_necessarios), distancia])
	if posicao_jogador in zona_ataque:
		motivos.append("A casa também foi atingida por uma peça.")

	var eh_ultimo_edito = indice_edito_atual >= editos.size() - 1

	if motivos.size() > 0:
		falha.emit(motivos)
		_transicionar(Estado.FINALIZADO)
		return

	if eh_ultimo_edito:
		if posicao_jogador != safe_spot:
			falha.emit(["Posição final não é o safe spot."])
			_transicionar(Estado.FINALIZADO)
			return
		sucesso.emit()
		_transicionar(Estado.FINALIZADO)
	else:
		indice_edito_atual += 1
		_transicionar(Estado.SELECAO_PAR)
		_iniciar_edito_atual()

func _tentar_transicionar(de_esperado: int, para: int) -> bool:
	if estado_atual != de_esperado:
		push_warning("Transição inválida: tentou ir para %s a partir de %s (esperado %s)." % [
			Estado.keys()[para], Estado.keys()[estado_atual], Estado.keys()[de_esperado]
		])
		return false
	return _transicionar(para)

func _transicionar(novo_estado: int) -> bool:
	if novo_estado != estado_atual and not (novo_estado in TRANSICOES_VALIDAS.get(estado_atual, [])):
		push_warning("Transição recusada: %s -> %s não é permitida." % [
			Estado.keys()[estado_atual], Estado.keys()[novo_estado]
		])
		return false
	estado_atual = novo_estado
	estado_mudou.emit(estado_atual)
	return true

func _numeral(valor: int) -> String:
	const NUMERAIS = {2: "II", 3: "III", 4: "IV"}
	return NUMERAIS.get(valor, str(valor))
