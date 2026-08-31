extends Node

## ===========================================
## FASE 1 — TUTORIAL DE PRIMOS
## Queens-Trial
## ===========================================
## Este script:
## 1. Verifica se um número é primo
## 2. Garante que existe EXATAMENTE uma jogada correta
## 3. Gera os dados da fase 1
## 4. Salva esses dados em JSON (formato provisório, até o Lorenzo definir o schema final)


# --- Textos da fase (critério: "escrever instrução curta") ---
const INSTRUCAO_FASE1 := "Comece com %d. Entre em uma área para somar seu valor. Termine em um número primo."
const DICA_FASE1 := "Exemplo: %d + %d = %d. Se sair da área, a soma volta a %d."


func _ready() -> void:
	# Isso roda automaticamente quando a cena é executada.
	# É o "teste" — olha o painel Output do Godot depois de rodar.
	print("=== TESTE FASE 1 — TUTORIAL DE PRIMOS ===")

	var fase = gerar_fase1()

	print("Dados gerados: ", fase)
	print("Instrução: ", INSTRUCAO_FASE1 % fase.x_inicial)

	var area_solucao = fase.areas[fase.solucao_indice]
	var resultado_solucao = fase.x_inicial + area_solucao
	print("Dica: ", DICA_FASE1 % [fase.x_inicial, area_solucao, resultado_solucao, fase.x_inicial])

	salvar_fase1_json(fase)
	print("=== FIM DO TESTE — confira data/fase1_primos.json ===")


## Verifica se um número inteiro é primo
func eh_primo(n: int) -> bool:
	if n < 2:
		return false
	if n == 2:
		return true
	if n % 2 == 0:
		return false
	var limite = int(sqrt(n))
	var i = 3
	while i <= limite:
		if n % i == 0:
			return false
		i += 2
	return true


## Testa um conjunto de valores (x_inicial + areas) e garante
## que exatamente UM resultado é primo (critério: solução única)
func validar_unicidade(x_inicial: int, areas: Array) -> Dictionary:
	var solucoes := []
	var todos_resultados := []

	for i in range(areas.size()):
		var resultado = x_inicial + areas[i]
		todos_resultados.append(resultado)
		if eh_primo(resultado):
			solucoes.append(i)

	return {
		"valida": solucoes.size() == 1,
		"indice_solucao": solucoes[0] if solucoes.size() == 1 else -1,
		"todos_resultados": todos_resultados,
		"quantidade_solucoes": solucoes.size()
	}


## Gera os dados completos da fase 1.
## Se algum dia você quiser trocar os valores, troca aqui e o assert
## avisa na hora se o conjunto ficou ambíguo (mais de 1 solução).
func gerar_fase1() -> Dictionary:
	var x_inicial := 8
	var areas := [3, 4, 6, 7]

	var check = validar_unicidade(x_inicial, areas)

	assert(check.valida, "ERRO: conjunto de valores inválido — %d soluções encontradas (precisa ser exatamente 1)" % check.quantidade_solucoes)

	return {
		"fase": 1,
		"tipo": "primo",
		"x_inicial": x_inicial,
		"areas": areas,
		"solucao_indice": check.indice_solucao,
		"tempo_limite": 30
	}


## Salva os dados gerados em JSON dentro de res://data/
## Formato provisório — ajustar quando o Lorenzo definir o schema final.
func salvar_fase1_json(dados: Dictionary) -> void:
	var caminho := "res://data/fase1_primos.json"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível criar o arquivo em " + caminho + ". Confira se a pasta 'data' existe no projeto.")
		return
	file.store_string(JSON.stringify(dados, "\t"))
	file.close()
	print("Salvo em: ", caminho)
