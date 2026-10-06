class_name BalanceHUD
extends Control

const CARDS := [
	preload("res://assets/cards/1.jpg"), preload("res://assets/cards/2.jpg"),
	preload("res://assets/cards/3.jpg"), preload("res://assets/cards/4.jpg"),
]

var left_card: TextureRect
var right_card: TextureRect


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	left_card = _card("LeftCard")
	right_card = _card("RightCard")
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()


func _card(node_name: String) -> TextureRect:
	var card := TextureRect.new()
	card.name = node_name
	card.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	return card


func _layout() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / 1920.0, viewport.y / 1080.0)
	var card_size := Vector2(300, 427) * fit
	var top := viewport.y * 0.47 - card_size.y * 0.20
	left_card.size = card_size
	right_card.size = card_size
	# Center each card in its side gutter while keeping the existing artwork size.
	var gutter_center := viewport.x * 0.17
	left_card.position = Vector2(gutter_center - card_size.x * 0.5, top)
	right_card.position = Vector2(viewport.x - gutter_center - card_size.x * 0.5, top)


func show_round(left: int, right: int) -> void:
	left_card.texture = CARDS[left - 1]
	right_card.texture = CARDS[right - 1]
	show()
