extends Node

func _ready():
	var maquina = preload("res://scripts/gameplay/edito_state_machine.gd").new()
	add_child(maquina)

	maquina.estado_mudou.connect(func(e): print("Estado: ", maquina.Estado.keys()[e]))
	maquina.falha.connect(func(motivos): print("FALHA: ", motivos))
	maquina.sucesso.connect(func(): print("SUCESSO!"))

	# testa transição inválida antes de configurar
	maquina.avancar_primeira_peca() # deve recusar, ainda em SELECAO_PAR

	# configura fase com 2 éditos válidos
	maquina.configurar_fase([
		{"valor": 3, "par": "horizontal"},
		{"valor": 4, "par": "vertical"}
	], Vector2i(0, 0))

	# testa reutilizar valor (deve falhar a configuração)
	var ok = maquina.configurar_fase([
		{"valor": 2, "par": "horizontal"},
		{"valor": 2, "par": "vertical"}
	], Vector2i(0, 0))
	print("Configuração com valor repetido aceita? ", ok) # deve imprimir false
