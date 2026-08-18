extends Node2D

signal casa_selecionada(coordenada: Vector2i, valor)

const TILE_SIZE = 80
const BOARD_SIZE = 8

const COLOR_LIGHT = Color(0.85, 0.8, 0.65)
const COLOR_DARK = Color(0.15, 0.15, 0.3)
const COLOR_HOVER = Color(0.4, 0.7, 0.9)

var tiles = {}       # {Vector2i(col, row): Button}
var visuals = {}      # {Vector2i(col, row): ColorRect}
var valores = {}      # {Vector2i(col, row): valor} -- usado no modo seleção

func _ready():
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			_create_tile(row, col)
	testar_todas_as_posicoes()

func _create_tile(row: int, col: int):
	var coord = Vector2i(col, row)

	var visual = ColorRect.new()
	visual.size = Vector2(TILE_SIZE, TILE_SIZE)
	visual.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
	visual.color = COLOR_LIGHT if (row + col) % 2 == 0 else COLOR_DARK
	add_child(visual)
	visuals[coord] = visual

	var button = Button.new()
	button.size = Vector2(TILE_SIZE, TILE_SIZE)
	button.position = visual.position
	button.flat = true
	button.self_modulate = Color(1, 1, 1, 0) # invisível, mas clicável
	button.mouse_entered.connect(_on_tile_hover.bind(coord, true))
	button.mouse_exited.connect(_on_tile_hover.bind(coord, false))
	button.pressed.connect(_on_tile_pressed.bind(coord))
	add_child(button)
	tiles[coord] = button

func _on_tile_hover(coord: Vector2i, entrando: bool):
	var visual = visuals[coord]
	if entrando:
		visual.color = COLOR_HOVER
	else:
		visual.color = COLOR_LIGHT if (coord.y + coord.x) % 2 == 0 else COLOR_DARK

func _on_tile_pressed(coord: Vector2i):
	var valor = valores.get(coord, null)
	print("Casa clicada: coluna %d, linha %d, valor: %s" % [coord.x, coord.y, str(valor)])
	casa_selecionada.emit(coord, valor)

func definir_valor(coord: Vector2i, valor):
	valores[coord] = valor

func testar_todas_as_posicoes():
	assert(tiles.size() == BOARD_SIZE * BOARD_SIZE, "Esperado 64 casas, encontrado %d" % tiles.size())
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			assert(tiles.has(Vector2i(col, row)), "Faltando casa (%d, %d)" % [col, row])
	print("OK: 64 casas instanciadas e todas as coordenadas presentes.")
