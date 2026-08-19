extends Node

const TAMANHO = 8
const NUMERAIS = {1:"I", 2:"II", 3:"III", 4:"IV", 5:"V", 6:"VI", 7:"VII"}

func gerar_fase(numero_fase: int) -> Dictionary:
	if numero_fase >= 1 and numero_fase <= 4:
		return _gerar_selecao("primos")
	elif numero_fase >= 5 and numero_fase <= 8:
		return _gerar_selecao("multiplos")
	elif numero_fase >= 9 and numero_fase <= 12:
		return _gerar_navegacao(1, 3, [])
	elif numero_fase >= 13 and numero_fase <= 16:
		return _gerar_navegacao(3, 4, ["torre", "torre"])
	elif numero_fase >= 17 and numero_fase <= 20:
		return _gerar_navegacao(3, 7, ["torre", "bispo", "cavalo"])
	else:
		push_error("Fase fora do intervalo 1-20: %d" % numero_fase)
		return {}

# ---------- MODO SELEÇÃO (fases 1-8) ----------

func _gerar_selecao(tipo_regra: String) -> Dictionary:
	var valores = {}
	for row in range(TAMANHO):
		for col in range(TAMANHO):
			valores[Vector2i(col, row)] = randi_range(1, 100)

	var parametro = null
	var solucoes = []
	if tipo_regra == "primos":
		for coord in valores:
			if _eh_primo(valores[coord]):
				solucoes.append(coord)
	else: # multiplos
		parametro = randi_range(2, 9)
		for coord in valores:
			if valores[coord] % parametro == 0:
				solucoes.append(coord)

	return {
		"modo": "selecao",
		"regra": tipo_regra,
		"parametro": parametro,
		"valores": valores,
		"solucoes": solucoes
	}

func _eh_primo(n: int) -> bool:
	if n < 2:
		return false
	for i in range(2, int(sqrt(n)) + 1):
		if n % i == 0:
			return false
	return true

# ---------- MODO NAVEGAÇÃO (fases 9-20) ----------

func _gerar_navegacao(rodadas: int, numeral_max: int, tipos_inimigos: Array) -> Dictionary:
	for tentativa in range(200):
		var inimigos = []
		for tipo in tipos_inimigos:
			var numeral_valor = randi_range(1, numeral_max)
			inimigos.append({
				"tipo": tipo,
				"pos": Vector2i(randi_range(0, 7), randi_range(0, 7)),
				"numeral_valor": numeral_valor,
				"numeral": NUMERAIS[numeral_valor]
			})

		var zona_ataque = _calcular_zona_ataque(inimigos)
		var posicao_atual = Vector2i(0, 7) # ponto de partida do Viajante
		if posicao_atual in zona_ataque:
			continue

		var caminho_valido = true
		var historico_rodadas = []

		for r in range(rodadas):
			var par = _sortear_par_numerais(inimigos, numeral_max)
			var passos = par[0] + par[1] # soma das operações -- ajustar se o time decidir outra operação
			passos = clampi(passos, 1, 7)

			var proxima = _achar_destino(posicao_atual, passos, zona_ataque)
			if proxima == null:
				caminho_valido = false
				break

			historico_rodadas.append({
				"rodada": r + 1,
				"numerais": [NUMERAIS[par[0]], NUMERAIS[par[1]]],
				"passos": passos,
				"destino": proxima
			})
			posicao_atual = proxima

		if caminho_valido:
			return {
				"modo": "navegacao",
				"posicao_inicial": Vector2i(0, 7),
				"inimigos": inimigos,
				"zona_ataque": zona_ataque,
				"rodadas": historico_rodadas,
				"safe_spot": posicao_atual
			}

	push_error("Não foi possível gerar uma fase navegável válida")
	return {}

func _sortear_par_numerais(inimigos: Array, numeral_max: int) -> Array:
	if inimigos.size() >= 2:
		var copia = inimigos.duplicate()
		copia.shuffle()
		return [copia[0]["numeral_valor"], copia[1]["numeral_valor"]]
	elif inimigos.size() == 1:
		return [inimigos[0]["numeral_valor"], randi_range(1, numeral_max)]
	else:
		return [randi_range(1, numeral_max), randi_range(1, numeral_max)]

func _calcular_zona_ataque(inimigos: Array) -> Array:
	var zona = []
	for inimigo in inimigos:
		match inimigo["tipo"]:
			"torre":
				zona.append_array(_zona_torre(inimigo["pos"]))
			"bispo":
				zona.append_array(_zona_bispo(inimigo["pos"]))
			"cavalo":
				zona.append_array(_zona_cavalo(inimigo["pos"]))
	return zona

func _zona_torre(pos: Vector2i) -> Array:
	var zona = []
	for i in range(TAMANHO):
		zona.append(Vector2i(i, pos.y))
		zona.append(Vector2i(pos.x, i))
	return zona

func _zona_bispo(pos: Vector2i) -> Array:
	var zona = []
	for d in range(-7, 8):
		if d == 0:
			continue
		var p1 = pos + Vector2i(d, d)
		var p2 = pos + Vector2i(d, -d)
		if _dentro(p1): zona.append(p1)
		if _dentro(p2): zona.append(p2)
	return zona

func _zona_cavalo(pos: Vector2i) -> Array:
	var offsets = [Vector2i(1,2), Vector2i(2,1), Vector2i(-1,2), Vector2i(-2,1),
		Vector2i(1,-2), Vector2i(2,-1), Vector2i(-1,-2), Vector2i(-2,-1)]
	var zona = []
	for o in offsets:
		var p = pos + o
		if _dentro(p):
			zona.append(p)
	return zona

func _dentro(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < TAMANHO and p.y >= 0 and p.y < TAMANHO

func _achar_destino(origem: Vector2i, passos: int, zona_ataque: Array):
	var direcoes = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1),
		Vector2i(1,1), Vector2i(1,-1), Vector2i(-1,1), Vector2i(-1,-1)]
	direcoes.shuffle()
	for dir in direcoes:
		var destino = origem + dir * passos
		if _dentro(destino) and not (destino in zona_ataque):
			return destino
	return null
