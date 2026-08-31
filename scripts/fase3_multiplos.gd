extends Node

## ===========================================
## FASE 3 — TUTORIAL DE MÚLTIPLOS
## Queens-Trial
## ===========================================
## Introduz o conceito de número-alvo: em vez de terminar em um
## número primo, o jogador precisa terminar em um MÚLTIPLO do
## número-alvo definido na fase.
## Mantém a mesma mecânica de soma/entrada em área das fases 1 e 2.


# --- Textos da fase (critério: "escrever instrução") ---
const INSTRUCAO_FASE3 := "Comece com %d. Entre em uma área para somar seu valor. Termine em um múltiplo de %d."
const DICA_FASE3 := "Exemplo: %d + %d = %d. %d é múltiplo de %d. Se sair da área, a soma volta a %d."


func _ready() -> void:
	print("=== TESTE FASE 3 — TUTORIAL DE MÚLTIPLOS ===")

	var fase = gerar_fase3()

	print("Dados gerados: ", fase)
	print("Instrução: ", INSTRUCAO_FASE3 % [fase.x_inicial, fase.numero_alvo])

	var area_solucao = fase.areas[fase.solucao_indice]
	var resultado_solucao = fase.x_inicial + area_solucao
	print("Dica: ", DICA_FASE3 % [fase.x_inicial, area_solucao, resultado_solucao, resultado_solucao, fase.numero_alvo, fase.x_inicial])

	salvar_fase3_json(fase)
	print("=== FIM DO TESTE — confira data/fase3_multiplos.json ===")


## Verifica se um número é múltiplo do alvo
func eh_multiplo(n: int, alvo: int) -> bool:
	if alvo == 0:
		return false
	return n % alvo == 0


## Garante que existe EXATAMENTE uma jogada correta
func validar_unicidade(x_inicial: int, areas: Array, numero_alvo: int) -> Dictionary:
	var solucoes := []
	var todos_resultados := []

	for i in range(areas.size()):
		var resultado = x_inicial + areas[i]
		todos_resultados.append(resultado)
		if eh_multiplo(resultado, numero_alvo):
			solucoes.append(i)

	return {
		"valida": solucoes.size() == 1,
		"indice_solucao": solucoes[0] if solucoes.size() == 1 else -1,
		"todos_resultados": todos_resultados,
		"quantidade_solucoes": solucoes.size()
	}


## Gera os dados completos da fase 3.
## Números pequenos e simples, por ser tutorial (primeira vez
## que o jogador vê o conceito de número-alvo/múltiplo).
func gerar_fase3() -> Dictionary:
	var numero_alvo := 5   # "Escolher alvo"
	var x_inicial := 2
	var areas := [3, 4, 6, 9]   # "Escolher opções"

	var check = validar_unicidade(x_inicial, areas, numero_alvo)

	assert(check.valida, "ERRO: conjunto de valores inválido — %d soluções encontradas (precisa ser exatamente 1)" % check.quantidade_solucoes)

	return {
		"fase": 3,
		"tipo": "multiplo",
		"numero_alvo": numero_alvo,
		"x_inicial": x_inicial,
		"areas": areas,
		"solucao_indice": check.indice_solucao,
		"tempo_limite": 30
	}


## Salva os dados gerados em JSON dentro de res://data/
## Mesmo formato provisório das fases anteriores.
func salvar_fase3_json(dados: Dictionary) -> void:
	var caminho := "res://data/fase3_multiplos.json"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível criar o arquivo em " + caminho + ". Confira se a pasta 'data' existe no projeto.")
		return
	file.store_string(JSON.stringify(dados, "\t"))
	file.close()
	print("Salvo em: ", caminho)
