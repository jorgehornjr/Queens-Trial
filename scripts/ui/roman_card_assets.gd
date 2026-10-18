class_name RomanCardAssets
extends RefCounted

const FRONTS := [
	preload("res://assets/cards/1.jpg"), preload("res://assets/cards/2.jpg"),
	preload("res://assets/cards/3.jpg"), preload("res://assets/cards/4.jpg"),
	preload("res://assets/cards/5.jpg"), preload("res://assets/cards/6.jpg"),
	preload("res://assets/cards/7.jpg"), preload("res://assets/cards/8.jpg"),
	preload("res://assets/cards/9.jpg"), preload("res://assets/cards/10.jpg"),
	preload("res://assets/cards/11.jpg"), preload("res://assets/cards/12.jpg"),
	preload("res://assets/cards/13.jpg"), preload("res://assets/cards/14.jpg"),
	preload("res://assets/cards/15.jpg"), preload("res://assets/cards/16.jpg"),
	preload("res://assets/cards/17.jpg"), preload("res://assets/cards/18.jpg"),
	preload("res://assets/cards/19.jpg"), preload("res://assets/cards/20.jpg"),
]
const SURFACE = preload("res://shaders/card_surface.gdshader")
const PAPER_TONE_ENABLED := true
# Measured from the unpainted paper in each original JPG, in sRGB (0–255).
const PAPER_TONES := [
	Vector3(242.0, 233.9, 216.1), Vector3(218.2, 215.2, 200.0),
	Vector3(224.3, 220.8, 202.3), Vector3(226.6, 226.5, 208.9),
	Vector3(225.4, 222.2, 202.6), Vector3(217.3, 214.0, 199.1),
	Vector3(208.0, 207.8, 193.0), Vector3(210.9, 208.4, 192.3),
	Vector3(216.9, 216.4, 200.4), Vector3(223.0, 221.5, 206.0),
	Vector3(210.8, 208.8, 194.8), Vector3(211.8, 206.7, 190.2),
	Vector3(207.8, 208.3, 192.7), Vector3(210.7, 207.2, 190.5),
	Vector3(226.9, 224.2, 207.3), Vector3(230.4, 226.7, 208.6),
	Vector3(219.4, 217.5, 198.9), Vector3(208.0, 207.9, 193.2),
	Vector3(226.6, 228.5, 215.5), Vector3(233.1, 231.1, 213.4),
]

static func card_material(value := 0) -> ShaderMaterial:
	var ink := ShaderMaterial.new()
	ink.shader = SURFACE
	apply_paper_tone(ink, value)
	return ink

static func apply_paper_tone(ink: ShaderMaterial, value: int) -> void:
	ink.set_shader_parameter("paper_tone_enabled", PAPER_TONE_ENABLED and value in range(1, 21))
	if value in range(1, 21):
		ink.set_shader_parameter("paper_source", PAPER_TONES[value - 1] / 255.0)

static func front(value: int) -> Texture2D:
	return FRONTS[value - 1] if value in range(1, 21) else null
