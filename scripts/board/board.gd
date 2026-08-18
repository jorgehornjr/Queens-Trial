extends Node2D

signal casa_selecionada(coordenada: Vector2i, valor)

enum TileTone {
	LIGHT,
	DARK,
}

enum TileState {
	NORMAL,
	HOVER,
	SELECTABLE,
	SELECTED,
}

const TILE_SIZE := 80
const BOARD_SIZE := 8

const TILE_TEXTURES := {
	TileTone.LIGHT: {
		TileState.NORMAL: preload("res://assets/board/tiles/board_tile_light_normal.svg"),
		TileState.HOVER: preload("res://assets/board/tiles/board_tile_light_hover.svg"),
		TileState.SELECTABLE: preload("res://assets/board/tiles/board_tile_light_selectable.svg"),
		TileState.SELECTED: preload("res://assets/board/tiles/board_tile_light_selected.svg"),
	},
	TileTone.DARK: {
		TileState.NORMAL: preload("res://assets/board/tiles/board_tile_dark_normal.svg"),
		TileState.HOVER: preload("res://assets/board/tiles/board_tile_dark_hover.svg"),
		TileState.SELECTABLE: preload("res://assets/board/tiles/board_tile_dark_selectable.svg"),
		TileState.SELECTED: preload("res://assets/board/tiles/board_tile_dark_selected.svg"),
	},
}

var tiles := {} # {Vector2i(col, row): Button}
var visuals := {} # {Vector2i(col, row): TextureRect}
var tile_tones := {} # {Vector2i(col, row): TileTone}
var tile_states := {} # {Vector2i(col, row): TileState}
var valores := {} # {Vector2i(col, row): valor} -- usado no modo seleção


func _ready() -> void:
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			_create_tile(row, col)
	testar_todas_as_posicoes()


func _create_tile(row: int, col: int) -> void:
	var coord := Vector2i(col, row)
	var tone := TileTone.LIGHT if (row + col) % 2 == 0 else TileTone.DARK
	tile_tones[coord] = tone
	tile_states[coord] = TileState.NORMAL

	var visual := TextureRect.new()
	visual.name = "Visual_%d_%d" % [col, row]
	visual.size = Vector2(TILE_SIZE, TILE_SIZE)
	visual.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
	visual.texture = TILE_TEXTURES[tone][TileState.NORMAL]
	visual.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	visual.stretch_mode = TextureRect.STRETCH_SCALE
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(visual)
	visuals[coord] = visual

	var button := Button.new()
	button.name = "Button_%d_%d" % [col, row]
	button.size = Vector2(TILE_SIZE, TILE_SIZE)
	button.position = visual.position
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.self_modulate = Color(1, 1, 1, 0)
	button.tooltip_text = "Casa (%d, %d)" % [col, row]
	button.mouse_entered.connect(_on_tile_hover.bind(coord, true))
	button.mouse_exited.connect(_on_tile_hover.bind(coord, false))
	button.pressed.connect(_on_tile_pressed.bind(coord))
	add_child(button)
	tiles[coord] = button


func _on_tile_hover(coord: Vector2i, entrando: bool) -> void:
	var estado_atual: int = tile_states.get(coord, TileState.NORMAL)
	if entrando and estado_atual == TileState.NORMAL:
		definir_estado(coord, TileState.HOVER)
	elif not entrando and estado_atual == TileState.HOVER:
		definir_estado(coord, TileState.NORMAL)


func _on_tile_pressed(coord: Vector2i) -> void:
	var valor = valores.get(coord, null)
	print("Casa clicada: coluna %d, linha %d, valor: %s" % [coord.x, coord.y, str(valor)])
	casa_selecionada.emit(coord, valor)


func definir_estado(coord: Vector2i, estado: int) -> void:
	if not visuals.has(coord):
		push_warning("Não existe casa na coordenada %s." % coord)
		return
	if estado < TileState.NORMAL or estado > TileState.SELECTED:
		push_warning("Estado de casa inválido: %d." % estado)
		return
	tile_states[coord] = estado
	_apply_tile_texture(coord)


func definir_hover(coord: Vector2i, hover: bool = true) -> void:
	definir_estado(coord, TileState.HOVER if hover else TileState.NORMAL)


func definir_selecionavel(coord: Vector2i, selecionavel: bool = true) -> void:
	definir_estado(coord, TileState.SELECTABLE if selecionavel else TileState.NORMAL)


func definir_selecionado(coord: Vector2i, selecionado: bool = true) -> void:
	definir_estado(coord, TileState.SELECTED if selecionado else TileState.NORMAL)


func obter_estado(coord: Vector2i) -> int:
	return tile_states.get(coord, TileState.NORMAL)


func _apply_tile_texture(coord: Vector2i) -> void:
	var visual: TextureRect = visuals[coord]
	var tone: int = tile_tones[coord]
	var state: int = tile_states[coord]
	visual.texture = TILE_TEXTURES[tone][state]


func definir_valor(coord: Vector2i, valor) -> void:
	valores[coord] = valor


func testar_todas_as_posicoes() -> void:
	var expected_tile_count := BOARD_SIZE * BOARD_SIZE
	assert(tiles.size() == expected_tile_count, "Esperado 64 botões, encontrado %d" % tiles.size())
	assert(visuals.size() == expected_tile_count, "Esperado 64 visuais, encontrado %d" % visuals.size())
	for row in range(BOARD_SIZE):
		for col in range(BOARD_SIZE):
			var coord := Vector2i(col, row)
			assert(tiles.has(coord), "Faltando botão da casa (%d, %d)" % [col, row])
			assert(visuals.has(coord), "Faltando visual da casa (%d, %d)" % [col, row])
			assert(visuals[coord].texture != null, "Faltando textura da casa (%d, %d)" % [col, row])
	print("OK: 64 casas com texturas Figma instanciadas e todas as coordenadas presentes.")
