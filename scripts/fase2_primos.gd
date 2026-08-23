extends Node

## ===========================================
## FASE 2 — PRIMOS (dificuldade moderada)
## Queens-Trial
## ===========================================
## Igual a fase 1, mas:
## - Números um pouco maiores (dificuldade moderada)
## - Áreas misturam valores primos e compostos como "pegadinha":
##   o jogador precisa somar de verdade, não pode confiar
##   em achar que "área com número primo = resposta certa"


# --- Textos da fase (critério: instrução curta, igual N1) ---
const INSTRUCAO_FASE2 := "Comece com %d. Entre em uma área para somar seu valor. Termine em um número primo."
const DICA_FASE2 := "Exemplo: %d + %d = %d. Se sair da área, a soma volta a %d."


func _ready() -> void:
	print("=== TESTE FASE 2 — PRIMOS (DIFICULDADE MODERADA) ===")

	var fase = gerar_fase2()

	print("Dados gerados: ", fase)
	print("Instrução: ", INSTRUCAO_FASE2 % fase.x_inicial)

	var area_solucao = fase.areas[fase.solucao_indice]
	var resultado_solucao = fase.x_inicial + area_solucao
	print("Dica: ", DICA_FASE2 % [fase.x_inicial, area_solucao, resultado_solucao, fase.x_inicial])

	salvar_fase2_json(fase)
	print("=== FIM DO TESTE — confira data/fase2_primos.json ===")


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


## Garante que existe EXATAMENTE uma jogada correta
## (mesma lógica da fase 1 — reaproveitável em qualquer fase de primos)
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


## Gera os dados completos da fase 2.
## Valores maiores que a fase 1 (dificuldade moderada) e áreas
## misturando propositalmente valores primos e compostos.
func gerar_fase2() -> Dictionary:
	var x_inicial := 18
	var areas := [5, 7, 15, 21]  # 5 e 7 são primos, 15 e 21 são compostos (pegadinha proposital)

	var check = validar_unicidade(x_inicial, areas)

	assert(check.valida, "ERRO: conjunto de valores inválido — %d soluções encontradas (precisa ser exatamente 1)" % check.quantidade_solucoes)

	return {
		"fase": 2,
		"tipo": "primo",
		"x_inicial": x_inicial,
		"areas": areas,
		"solucao_indice": check.indice_solucao,
		"tempo_limite": 30
	}


## Salva os dados gerados em JSON dentro de res://data/
## Mesmo formato provisório da fase 1, até o Lorenzo definir o schema final.
func salvar_fase2_json(dados: Dictionary) -> void:
	var caminho := "res://data/fase2_primos.json"
	var file = FileAccess.open(caminho, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível criar o arquivo em " + caminho + ". Confira se a pasta 'data' existe no projeto.")
		return
	file.store_string(JSON.stringify(dados, "\t"))
	file.close()
	print("Salvo em: ", caminho)
