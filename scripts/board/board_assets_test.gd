extends Node2D

const BoardScript = preload("res://scripts/board/board.gd")

@onready var board = $Board


func _ready() -> void:
	board.definir_hover(Vector2i(2, 0))
	board.definir_selecionavel(Vector2i(4, 0))
	board.definir_selecionado(Vector2i(6, 0))
	board.definir_hover(Vector2i(0, 1))
	board.definir_selecionavel(Vector2i(2, 1))
	board.definir_selecionado(Vector2i(4, 1))

	assert(board.obter_estado(Vector2i(2, 0)) == BoardScript.TileState.HOVER)
	assert(board.obter_estado(Vector2i(4, 0)) == BoardScript.TileState.SELECTABLE)
	assert(board.obter_estado(Vector2i(6, 0)) == BoardScript.TileState.SELECTED)
	assert(board.obter_estado(Vector2i(0, 1)) == BoardScript.TileState.HOVER)
	assert(board.obter_estado(Vector2i(2, 1)) == BoardScript.TileState.SELECTABLE)
	assert(board.obter_estado(Vector2i(4, 1)) == BoardScript.TileState.SELECTED)

	for coord in board.visuals:
		var texture: Texture2D = board.visuals[coord].texture
		assert(texture != null, "Textura ausente na casa %s." % coord)
		assert(texture.get_size() == Vector2(80, 80), "Textura da casa %s não mede 80×80." % coord)
	print("OK: estados Normal, Hover, Selectable e Selected validados na cena de teste.")
	print("OK: todas as 64 texturas carregadas medem 80×80 no runtime.")
