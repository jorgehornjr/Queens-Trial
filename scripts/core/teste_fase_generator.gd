extends Node

func _ready():
	var gerador = preload("res://scripts/core/fase_generator.gd").new()
	print(gerador.gerar_fase(1))
	print(gerador.gerar_fase(9))
	print(gerador.gerar_fase(13))
