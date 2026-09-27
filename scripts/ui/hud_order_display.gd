class_name HUDOrderDisplay
extends PanelContainer

## Componente do HUD que exibe a sequência das ordens dos éditos e o par ativo
## sem qualquer ambiguidade, conectado por sinais à EditoStateMachine.
## Permite ao jogador antecipar a ordem seguinte e identificar o par atuante.

signal order_activated(order_index: int, value: int, pair_description: String)
signal order_completed(order_index: int)

const Constants = preload("res://scripts/core/game_constants.gd")
const DUNE_FONT: FontFile = preload("res://assets/fonts/dune_rise.otf")
const JUPITER_FONT: FontFile = preload("res://assets/fonts/jupiter_pro.otf")

const COLOR_ACTIVE_TITLE := Color(1.0, 0.88, 0.42, 1.0)
const COLOR_ACTIVE_BORDER := Color(0.96, 0.76, 0.25, 0.90)
const COLOR_ACTIVE_BG := Color(0.12, 0.09, 0.03, 0.65)

const COLOR_PENDING_TITLE := Color(0.68, 0.74, 0.88, 0.70)
const COLOR_PENDING_BORDER := Color(0.28, 0.40, 0.65, 0.45)
const COLOR_PENDING_BG := Color(0.02, 0.04, 0.10, 0.40)

const COLOR_COMPLETED_TITLE := Color(0.55, 0.88, 0.65, 0.90)
const COLOR_COMPLETED_BORDER := Color(0.30, 0.65, 0.45, 0.55)
const COLOR_COMPLETED_BG := Color(0.02, 0.07, 0.04, 0.40)

@onready var title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var order1_panel: PanelContainer = $MarginContainer/VBoxContainer/Order1Panel
@onready var order1_badge: Label = $MarginContainer/VBoxContainer/Order1Panel/Margin/VBox/HBox/Badge
@onready var order1_value: Label = $MarginContainer/VBoxContainer/Order1Panel/Margin/VBox/HBox/Value
@onready var order1_status: Label = $MarginContainer/VBoxContainer/Order1Panel/Margin/VBox/HBox/Status
@onready var order1_pair_label: Label = $MarginContainer/VBoxContainer/Order1Panel/Margin/VBox/PairLabel

@onready var order2_panel: PanelContainer = $MarginContainer/VBoxContainer/Order2Panel
@onready var order2_badge: Label = $MarginContainer/VBoxContainer/Order2Panel/Margin/VBox/HBox/Badge
@onready var order2_value: Label = $MarginContainer/VBoxContainer/Order2Panel/Margin/VBox/HBox/Value
@onready var order2_status: Label = $MarginContainer/VBoxContainer/Order2Panel/Margin/VBox/HBox/Status
@onready var order2_pair_label: Label = $MarginContainer/VBoxContainer/Order2Panel/Margin/VBox/PairLabel

@onready var active_pair_panel: PanelContainer = $MarginContainer/VBoxContainer/ActivePairPanel
@onready var active_pair_title: Label = $MarginContainer/VBoxContainer/ActivePairPanel/Margin/VBox/ActivePairTitle
@onready var active_pair_label: Label = $MarginContainer/VBoxContainer/ActivePairPanel/Margin/VBox/ActivePairLabel

var _phase_data: Dictionary = {}
var _active_order_index: int = 0
var _total_orders: int = 0
var _values: Array = []
var _pair_descriptions: Array[String] = []


func _ready() -> void:
	_apply_fonts()
	visible = false


func _apply_fonts() -> void:
	if title_label != null:
		title_label.add_theme_font_override("font", DUNE_FONT)
		title_label.add_theme_font_size_override("font_size", 14)
	if order1_badge != null:
		order1_badge.add_theme_font_override("font", JUPITER_FONT)
		order1_badge.add_theme_font_size_override("font_size", 16)
	if order1_value != null:
		order1_value.add_theme_font_override("font", JUPITER_FONT)
		order1_value.add_theme_font_size_override("font_size", 18)
	if order1_status != null:
		order1_status.add_theme_font_override("font", JUPITER_FONT)
		order1_status.add_theme_font_size_override("font_size", 13)
	if order1_pair_label != null:
		order1_pair_label.add_theme_font_override("font", JUPITER_FONT)
		order1_pair_label.add_theme_font_size_override("font_size", 14)

	if order2_badge != null:
		order2_badge.add_theme_font_override("font", JUPITER_FONT)
		order2_badge.add_theme_font_size_override("font_size", 16)
	if order2_value != null:
		order2_value.add_theme_font_override("font", JUPITER_FONT)
		order2_value.add_theme_font_size_override("font_size", 18)
	if order2_status != null:
		order2_status.add_theme_font_override("font", JUPITER_FONT)
		order2_status.add_theme_font_size_override("font_size", 13)
	if order2_pair_label != null:
		order2_pair_label.add_theme_font_override("font", JUPITER_FONT)
		order2_pair_label.add_theme_font_size_override("font_size", 14)

	if active_pair_title != null:
		active_pair_title.add_theme_font_override("font", DUNE_FONT)
		active_pair_title.add_theme_font_size_override("font_size", 13)
	if active_pair_label != null:
		active_pair_label.add_theme_font_override("font", JUPITER_FONT)
		active_pair_label.add_theme_font_size_override("font_size", 18)


## Configura as ordens e os pares da fase a partir do catálogo.
func setup_phase(phase_data: Dictionary) -> void:
	_phase_data = phase_data
	if phase_data.is_empty():
		visible = false
		return

	_total_orders = int(phase_data.get("edict_count", 1))
	_values = phase_data.get("edict_values", [])
	_pair_descriptions.clear()
	for i in range(_total_orders):
		_pair_descriptions.append(_format_pair_description(phase_data, i))

	_active_order_index = 0
	_render_orders()
	visible = true


## Liga este componente à máquina de estados dos éditos por sinais.
func connect_to_machine(edito_machine: Node) -> void:
	if edito_machine == null:
		return
	if edito_machine.has_signal("edito_iniciado") and not edito_machine.edito_iniciado.is_connected(_on_edito_iniciado):
		edito_machine.edito_iniciado.connect(_on_edito_iniciado)
	if edito_machine.has_signal("sucesso") and not edito_machine.sucesso.is_connected(_on_sucesso):
		edito_machine.sucesso.connect(_on_sucesso)


func _on_edito_iniciado(index: int, _value: int) -> void:
	set_active_order(index)


func _on_sucesso() -> void:
	for i in range(_total_orders):
		order_completed.emit(i)
	_render_orders(true)


## Atualiza o destaque da ordem ativa e do par em jogo.
func set_active_order(index: int) -> void:
	_active_order_index = index
	_render_orders()

	var val := int(_values[index]) if index < _values.size() else 0
	var pair_desc := _pair_descriptions[index] if index < _pair_descriptions.size() else ""
	order_activated.emit(index, val, pair_desc)


func _render_orders(all_completed: bool = false) -> void:
	if _total_orders <= 0:
		visible = false
		return

	# Configura Ordem 1
	var val1 := int(_values[0]) if _values.size() > 0 else 0
	var roman1 := Constants.to_roman(val1) if val1 > 0 else "—"
	var desc1 := _pair_descriptions[0] if _pair_descriptions.size() > 0 else "Sem Peças"
	order1_value.text = roman1
	order1_pair_label.text = desc1

	if all_completed or _active_order_index > 0:
		_style_order_card(order1_panel, order1_badge, order1_status, "✓ 1ª ORDEM", "CONCLUÍDA", 2)
	elif _active_order_index == 0:
		_style_order_card(order1_panel, order1_badge, order1_status, "▸ 1ª ORDEM", "ATIVA", 0)
	else:
		_style_order_card(order1_panel, order1_badge, order1_status, "1ª ORDEM", "PENDENTE", 1)

	# Configura Ordem 2 (se existir)
	if _total_orders >= 2:
		order2_panel.visible = true
		var val2 := int(_values[1]) if _values.size() > 1 else 0
		var roman2 := Constants.to_roman(val2) if val2 > 0 else "—"
		var desc2 := _pair_descriptions[1] if _pair_descriptions.size() > 1 else "Sem Peças"
		order2_value.text = roman2
		order2_pair_label.text = desc2

		if all_completed:
			_style_order_card(order2_panel, order2_badge, order2_status, "✓ 2ª ORDEM", "CONCLUÍDA", 2)
		elif _active_order_index == 1:
			_style_order_card(order2_panel, order2_badge, order2_status, "▸ 2ª ORDEM", "ATIVA", 0)
		else:
			_style_order_card(order2_panel, order2_badge, order2_status, "2ª ORDEM", "A SEGUIR", 1)
	else:
		order2_panel.visible = false

	# Painel de destaque do par ativo
	var active_desc := _pair_descriptions[_active_order_index] if _active_order_index < _pair_descriptions.size() else "Sem Peças"
	if active_pair_label != null:
		active_pair_label.text = active_desc


func _style_order_card(panel: PanelContainer, badge: Label, status: Label, badge_text: String, status_text: String, state_mode: int) -> void:
	badge.text = badge_text
	status.text = status_text

	var border_color: Color
	var bg_color: Color
	var title_color: Color

	match state_mode:
		0: # ATIVA
			border_color = COLOR_ACTIVE_BORDER
			bg_color = COLOR_ACTIVE_BG
			title_color = COLOR_ACTIVE_TITLE
			panel.modulate.a = 1.0
		1: # A SEGUIR / PENDENTE
			border_color = COLOR_PENDING_BORDER
			bg_color = COLOR_PENDING_BG
			title_color = COLOR_PENDING_TITLE
			panel.modulate.a = 0.65
		2: # CONCLUÍDA
			border_color = COLOR_COMPLETED_BORDER
			bg_color = COLOR_COMPLETED_BG
			title_color = COLOR_COMPLETED_TITLE
			panel.modulate.a = 0.85

	badge.add_theme_color_override("font_color", title_color)
	status.add_theme_color_override("font_color", title_color)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border_color
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)


## Formata a descrição do par a partir dos dados da fase e da onda.
func _format_pair_description(phase_data: Dictionary, wave_index: int) -> String:
	var piece_waves: Array = phase_data.get("piece_waves", [])
	if wave_index < piece_waves.size() and not (piece_waves[wave_index] as Array).is_empty():
		var pieces: Array = piece_waves[wave_index]
		var types: Array[String] = []
		var sides: Array[String] = []
		for p in pieces:
			if typeof(p) == TYPE_DICTIONARY:
				var t = String(p.get("type", ""))
				if not t.is_empty():
					types.append(t)
				var s = String(p.get("side", ""))
				if not s.is_empty():
					sides.append(s)
		return _build_pair_string(types, sides)

	var pair_key := "first_pair" if wave_index == 0 else "second_pair"
	var declared: Array = phase_data.get(pair_key, [])
	if not declared.is_empty():
		var types: Array[String] = []
		for item in declared:
			types.append(String(item))
		var default_side := "left" if wave_index == 0 else "top"
		return _build_pair_string(types, [default_side])

	return "Sem Peças Atacantes"


func _build_pair_string(types: Array[String], sides: Array[String]) -> String:
	if types.is_empty():
		return "Sem Peças Atacantes"

	var piece_name := ""
	if types.size() == 2 and types[0] == types[1]:
		if types[0] == "rook":
			piece_name = "Torre + Torre"
		elif types[0] == "bishop":
			piece_name = "Bispo + Bispo"
		else:
			piece_name = types[0].capitalize() + " + " + types[1].capitalize()
	elif types.size() == 2:
		var n0 = "Torre" if types[0] == "rook" else ("Bispo" if types[0] == "bishop" else types[0].capitalize())
		var n1 = "Torre" if types[1] == "rook" else ("Bispo" if types[1] == "bishop" else types[1].capitalize())
		piece_name = "%s + %s" % [n0, n1]
	else:
		piece_name = "Torre" if types[0] == "rook" else ("Bispo" if types[0] == "bishop" else types[0].capitalize())

	var orientation := ""
	var has_horizontal := sides.has("left") or sides.has("right")
	var has_vertical := sides.has("top") or sides.has("bottom")
	if has_horizontal and not has_vertical:
		orientation = "Horizontal"
	elif has_vertical and not has_horizontal:
		orientation = "Vertical"

	if not orientation.is_empty():
		return "%s  •  %s" % [piece_name, orientation]
	return piece_name
