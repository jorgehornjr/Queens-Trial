extends Node

const NUMERAIS_VALOR := {"II": 2, "III": 3, "IV": 4}
const NUMERAIS_TEXTO := {2: "II", 3: "III", 4: "IV"}
const TAMANHO_GRADE := 5
const CASA_RAINHA := Vector2i(2, 2) # coluna 3, linha 3 (1-indexado) -- centro da grade 5x5

func calcular_deslocamento(origem_externa: String, valor, posicao_fixa: int) -> Dictionary:
	var valor_num = valor if typeof(valor) == TYPE_INT else NUMERAIS_VALOR.get(valor, -1)

	if not valor_num in [2, 3, 4]:
		return {"sucesso": false, "motivo": "Numeral inválido: %s (aceito apenas II, III, IV)." % str(valor)}

	if posicao_fixa < 0 or posicao_fixa >= TAMANHO_GRADE:
		return {"sucesso": false, "motivo": "Posição fixa fora da grade: %d." % posicao_fixa}

	var entrada: Vector2i
	var destino: Vector2i
	var direcao: Vector2i

	match origem_externa:
		"esquerda":
			entrada = Vector2i(-1, posicao_fixa)
			destino = Vector2i(valor_num - 1, posicao_fixa)
			direcao = Vector2i(1, 0)
		"direita":
			entrada = Vector2i(TAMANHO_GRADE, posicao_fixa)
			destino = Vector2i(TAMANHO_GRADE - valor_num, posicao_fixa)
			direcao = Vector2i(-1, 0)
		"superior":
			entrada = Vector2i(posicao_fixa, -1)
			destino = Vector2i(posicao_fixa, valor_num - 1)
			direcao = Vector2i(0, 1)
		"inferior":
			entrada = Vector2i(posicao_fixa, TAMANHO_GRADE)
			destino = Vector2i(posicao_fixa, TAMANHO_GRADE - valor_num)
			direcao = Vector2i(0, -1)
		_:
			return {"sucesso": false, "motivo": "Origem externa desconhecida: %s." % origem_externa}

	if destino == CASA_RAINHA:
		return {"sucesso": false, "motivo": "Destino (%s) cairia na casa central da Rainha." % destino}

	return {
		"sucesso": true,
		"origem_externa": origem_externa,
		"entrada": entrada,
		"destino": destino,
		"direcao": direcao,
		"valor": valor_num,
		"numeral": NUMERAIS_TEXTO[valor_num],
	}
