class_name TutorialBodyText
extends Control
## Capitulares da arte aprovada, com texto vivo e espaçamento controlado.

const BODY_FONT: Font = preload("res://assets/fonts/Alegreya-Variable.ttf")
const INITIAL_SHADER: Shader = preload("res://shaders/tutorial_illuminated_initial.gdshader")
const INITIALS := {
	"V": [preload("res://assets/ui/tutorial_book/initial_sources/v.png"), Rect2(184, 454, 104, 113)],
	"D": [preload("res://assets/ui/tutorial_book/initial_sources/d.png"), Rect2(170, 389, 107, 143)],
	"A": [preload("res://assets/ui/tutorial_book/initial_sources/a.png"), Rect2(177, 417, 106, 116)],
	"O": [preload("res://assets/ui/tutorial_book/initial_sources/o.png"), Rect2(161, 372, 92, 107)],
}

var text := ""
var _height := 0
var _glyph: TextureRect
var _lines: Array[Label] = []
var _reveal_material: ShaderMaterial
var _reveal_progress := 1.0


func set_reveal_material(value: ShaderMaterial) -> void:
	_reveal_material = value
	for line in _lines: line.material = value


func set_ink_progress(value: float) -> void:
	_reveal_progress = value
	if is_instance_valid(_glyph):
		(_glyph.material as ShaderMaterial).set_shader_parameter("reveal_progress", value)


func set_story(content: String, font_size: int) -> void:
	text = content
	add_theme_font_size_override("normal_font_size", font_size)
	for line in _lines: line.free()
	_lines.clear()
	if _glyph == null:
		_glyph = TextureRect.new()
		_glyph.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ink := ShaderMaterial.new()
		ink.shader = INITIAL_SHADER
		_glyph.material = ink
		add_child(_glyph)
	var initial: String = text.left(1)
	var spec: Array = INITIALS.get(initial, INITIALS["A"])
	var atlas := AtlasTexture.new()
	atlas.atlas = spec[0]
	atlas.region = spec[1]
	_glyph.texture = atlas
	_glyph.size = Vector2(atlas.region.size.x / atlas.region.size.y * 120.0, 120.0)
	_glyph.position = Vector2(0, -4)
	set_ink_progress(_reveal_progress)
	var line_step := ceilf(BODY_FONT.get_height(font_size)) + 2.0
	var space := BODY_FONT.get_string_size(" ", HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var y := 22.0
	var paragraphs := text.split("\n\n", false)
	for paragraph_index in paragraphs.size():
		var paragraph := paragraphs[paragraph_index].substr(1) if paragraph_index == 0 else paragraphs[paragraph_index]
		var words := paragraph.split(" ", false)
		var word_index := 0
		while word_index < words.size():
			var indent := _glyph.size.x + 14.0 if y < 124.0 else 0.0
			var available := size.x - indent
			var line_text := ""
			var width := 0.0
			while word_index < words.size():
				var word: String = words[word_index]
				var next_width := BODY_FONT.get_string_size(word, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				var extra := next_width + (space if not line_text.is_empty() else 0.0)
				if not line_text.is_empty() and width + extra > available: break
				line_text += (" " if not line_text.is_empty() else "") + word
				width += extra
				word_index += 1
			var line := Label.new()
			line.text = line_text
			line.position = Vector2(indent, y)
			line.size = Vector2(available, line_step)
			line.mouse_filter = Control.MOUSE_FILTER_IGNORE
			line.material = _reveal_material
			line.add_theme_font_override("font", BODY_FONT)
			line.add_theme_font_size_override("font_size", font_size)
			line.add_theme_color_override("font_color", Color(0.16, 0.09, 0.065))
			add_child(line)
			_lines.append(line)
			y += line_step
		if paragraph_index < paragraphs.size() - 1: y += 14.0
	_height = int(maxf(y, 124.0))


func get_content_height() -> int:
	return _height
