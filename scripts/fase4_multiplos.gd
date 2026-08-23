extends Node

## ===========================================
## FASE 4 — MÚLTIPLOS (fechamento da N1)
## Queens-Trial
## ===========================================
## Desafio mais completo que fecha a N1:
## - 6 áreas em vez de 4 ("aumentar opções")
## - Validação reforçada: verifica também se o X inicial sozinho
##   já não seria uma resposta válida por acidente ("evitar ambiguidade"
##   e "testar seleção/confirmar" — o jogador é obrigado a jogar de verdade)
## - Guarda um nível de dificuldade nos dados ("registrar dificuldade")


# --- Textos da fase ---
const INSTRUCAO_FASE4 := "Comece com %d. Entre em uma área para somar seu valor. Termine em um múltiplo de %d."
const DICA_FASE4 := "Exemplo: %d + %d = %d. %d é múltiplo de %d. Se sair da área, a soma volta a %d."


func _ready() -> void:
	print("=== TESTE FASE 4 — MÚLTIPLOS (FECHAMENTO N1) ===")

	var fase = gerar_fase4()

	print("Dados gerados: ", fase)
	print("Instrução: ", INSTRUCAO_FASE4 % [fase.x_inicial, fase.numero_alvo])

	var area_solucao = fase.areas[fase.solucao_indice]
	var resultado_solucao = fase.x_inicial + area_solucao
	print("Dica: ", DICA_FASE4 % [fase.x_inicial, area_solucao, resultado_solucao, resultado_solucao, fase.numero_alvo, fase.x_inicial])

	salvar_fase4_json(fase)
	print("=== FIM DO TESTE — confira data/fase4_multiplos.json ===")


## Verifica se um número é múltiplo do alvo
func eh_multiplo(n: int, alvo: int) -> bool:
	if alvo == 0:
		return false
	return n % alvo == 0


## Garante que existe EXATAMENTE uma jogada correta entre as áreas
## E que o X inicial sozinho NÃO satisfaz o objetivo
## (critério "evitar ambiguidade" + "testar seleção/confirmar":
## o jogador precisa obrigatoriamente escolher uma área,
## não pode "confirmar" sem jogar)
func validar_unicidade(x_inicial: int, areas: Array, numero_alvo: int) -> Dictionary:
	var solucoes := []
	var todos_resultados := []

	for i in range(areas.size()):
		var resultado = x_inicial + areas[i]
		todos_resultados.append(resultado)
		if eh_multiplo(resultado, numero_alvo):
			solucoes.append(i)

	var x_sozinho_valido = eh_multiplo(x_inicial, numero_alvo)

	return {
		"valida": solucoes.size() == 1 and not x_sozinho_valido,
		"indice_solucao": solucoes[0] if solucoes.size() == 1 else -1,
		"todos_resultados": todos_resultados,
		"quantidade_solucoes": solucoes.size(),
		"x_sozinho_valido": x_sozinho_valido
	}


## Gera os dados completos da fase 4.
## 6 áreas (mais opções que as fases anteriores), números maiores,
## fechando a N1 com um desafio mais completo.
func gerar_fase4() -> Dictionary:
	var numero_alvo := 11
	var x_inicial := 20
	var areas := [5, 9, 13, 15, 18, 21]   # 6 áreas — "aumentar opções"

	var check = validar_unicidade(x_inicial, areas, numero_alvo)

	assert(check.valida, "ERRO: conjunto de valores inválido — %d soluções entre as áreas (precisa ser exatamente 1) ou X sozinho já é válido (%s)" % [check.quantidade_solucoes, check.x_sozinho_valido])

	return {
		"fase": 4,
		"tipo": "multiplo",
		"numero_alvo": numero_alvo,
		"x_inicial": x_inicial,
		"areas": areas,
		"solucao_indice": check.indice_solucao,
		"dificuldade": "dificil",   # "registrar dificuldade"
		"tempo_limite": 30
	}


## Salva os dados gerados em JSON dentro de res://data/
## Mesmo formato provisório das fases anteriores, com o campo
## novo "dificuldade" incluído.
func salvar_fase4_json(dados: Dictionary) -> void:
	var caminho := "res://data/fase4_multiplos.json"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível criar o arquivo em " + caminho + ". Confira se a pasta 'data' existe no projeto.")
		return
	file.store_string(JSON.stringify(dados, "\t"))
	file.close()
	print("Salvo em: ", caminho)
