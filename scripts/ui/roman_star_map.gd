class_name RomanStarMap
extends Control


signal dismissed(completed: bool)
signal final_reached
signal departure_started
const BASE := Vector2(1920, 1080)
const FONT: Font = preload("res://assets/fonts/jupiter_pro.otf")
const BODY: Font = preload("res://assets/fonts/Alegreya-Variable.ttf")
const SKY: Shader = preload("res://shaders/roman_sky.gdshader")
const Constellations = preload("res://scripts/ui/roman_constellation_field.gd")
const STAR_LIGHT: Texture2D = preload("res://assets/effects/queen_departure/ysayle_glow.png")
const STAR_SHADER: Shader = preload("res://shaders/roman_star_beacon.gdshader")
const NUMERAL_GLOW: Shader = preload("res://shaders/roman_numeral_glow.gdshader")
const NUMERAL_BLUR: Shader = preload("res://shaders/roman_numeral_blur.gdshader")
const SILVER := Color("dce7f5")
const GOLD := Color("eeb64f")
const BLUE := Color("4d9ee9")
const IVORY := Color(0.94, 0.91, 0.83)
const CENTER := Vector2(960, 580)
const RADII := Vector2(760, 320)

var guided := false
var selected := 1
var revealed := 1
var trace := 0.0
var canvas: Control
var drawing: Node2D
var beacons: Node2D
var number: RichTextLabel
var _glow_surfaces: Array[SubViewport] = []
var _number_image: TextureRect
var _heading_image: TextureRect
var equation: Label
var hint: Label
var heading: Label
var progress: Label
var advance: Button
var previous: Button
var exit_button: Button
var constellations: RomanConstellationField
var _nodes: Array[Button] = []
var _stars: Array[Vector3] = []
var _motion: Tween
var _busy := false
var _closing := false
var _age := 0.0
var _revision := 0

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var sky := ColorRect.new()
	sky.material = ShaderMaterial.new()
	(sky.material as ShaderMaterial).shader = SKY
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = Control.new()
	canvas.size = BASE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	constellations = Constellations.new() as RomanConstellationField
	constellations.name = "Constellations"
	canvas.add_child(constellations)
	drawing = Node2D.new()
	canvas.add_child(drawing)
	drawing.draw.connect(_draw_atlas)
	beacons = Node2D.new()
	beacons.name = "OrbitStars"
	beacons.material = ShaderMaterial.new()
	(beacons.material as ShaderMaterial).shader = STAR_SHADER
	canvas.add_child(beacons)
	beacons.draw.connect(_draw_beacons)
	var rng := RandomNumberGenerator.new()
	rng.seed = 12741
	for index in range(160): _stars.append(Vector3(rng.randf_range(30, 1890), rng.randf_range(30, 1050), rng.randf_range(0.3, 1.2)))
	heading = _label("Como ler Romanos", Rect2(340, 57, 1240, 74), 54, FONT, Color.WHITE)
	_heading_image = _luminous(heading, Vector2i(1240, 170), "Heading")
	_heading_image.position = Vector2(340, 9)
	canvas.add_child(_heading_image)
	progress = _label("", Rect2(1570, 77, 230, 48), 28, BODY, GOLD)
	progress.position = Vector2(1395, 132)
	progress.size = Vector2(160, 46)
	exit_button = _button("Sair", Rect2(1735, 5, 160, 48), 30)
	exit_button.pressed.connect(exit_guide)
	for value in range(1, 21):
		var point := _point(float(value - 1))
		var button := Button.new()
		button.position = point - Vector2(74, 55)
		button.size = Vector2(148, 100)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = "%s = %d" % [GameConstants.to_roman(value), value]
		for style in ["normal", "hover", "pressed", "focus", "disabled"]: button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
		canvas.add_child(button)
		button.pressed.connect(select.bind(value))
		var glyph := _label(GameConstants.to_roman(value), Rect2(0, 0, 148, 47), 32, FONT)
		glyph.reparent(button)
		glyph.position = Vector2.ZERO
		_glow(glyph, SILVER)
		var arabic := _label(str(value), Rect2(0, 76, 148, 26), 22, BODY, Color(0.7, 0.77, 0.85))
		arabic.reparent(button)
		arabic.position = Vector2(0, 76)
		_nodes.append(button)
	_glow(_label("I  =  1", Rect2(640, 335, 180, 46), 30, FONT, SILVER), SILVER)
	_glow(_label("V  =  5", Rect2(870, 335, 180, 46), 30, FONT, GOLD), GOLD)
	_glow(_label("X  =  10", Rect2(1100, 335, 180, 46), 30, FONT, BLUE), BLUE)
	number = RichTextLabel.new()
	number.size = Vector2(880, 145)
	number.bbcode_enabled = true
	number.scroll_active = false
	number.mouse_filter = Control.MOUSE_FILTER_IGNORE
	number.add_theme_font_override("normal_font", FONT)
	number.add_theme_font_size_override("normal_font_size", 112)
	_number_image = _luminous(number, Vector2i(880, 256), "Numeral")
	_number_image.position = Vector2(520, 352)
	canvas.add_child(_number_image)
	equation = _label("", Rect2(510, 552, 900, 56), 40, BODY, GOLD)
	hint = _label("", Rect2(580, 635, 760, 110), 32, BODY)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	previous = _button("Anterior", Rect2(470, 970, 280, 68), 32)
	previous.pressed.connect(func(): select(selected - 1))
	advance = _button("Próxima estrela", Rect2(1050, 959, 430, 80), 38)
	advance.pressed.connect(next)
	get_viewport().size_changed.connect(_fit)
	_fit()
	hide()


func _luminous(source: Control, extent: Vector2i, node_name: String) -> TextureRect:
	var ink := _surface(node_name + "Ink", extent)
	if source.get_parent() == null: ink.add_child(source)
	else: source.reparent(ink, false)
	source.position = Vector2(0, 48)
	var reduced := Vector2i(ceili(extent.x / 4.0), ceili(extent.y / 4.0))
	var horizontal := _blur_pass(node_name + "HaloHorizontal", ink.get_texture(), Vector2.RIGHT, reduced)
	var vertical := _blur_pass(node_name + "HaloVertical", horizontal.get_texture(), Vector2.DOWN, reduced)
	var image := TextureRect.new()
	image.name = "Luminous" + node_name
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = ink.get_texture()
	image.size = Vector2(extent)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.material = ShaderMaterial.new()
	(image.material as ShaderMaterial).shader = NUMERAL_GLOW
	(image.material as ShaderMaterial).set_shader_parameter("halo_texture", vertical.get_texture())
	return image


func _surface(node_name: String, extent: Vector2i) -> SubViewport:
	var surface := SubViewport.new()
	surface.name = node_name
	surface.size = extent
	surface.transparent_bg = true
	surface.disable_3d = true
	surface.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(surface)
	_glow_surfaces.append(surface)
	return surface


func _blur_pass(node_name: String, source: Texture2D, direction: Vector2, extent: Vector2i) -> SubViewport:
	var surface := _surface(node_name, extent)
	var image := TextureRect.new()
	image.texture = source
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.size = Vector2(surface.size)
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.material = ShaderMaterial.new()
	(image.material as ShaderMaterial).shader = NUMERAL_BLUR
	(image.material as ShaderMaterial).set_shader_parameter("sample_step", direction / Vector2(surface.size))
	surface.add_child(image)
	return surface

func _label(words: String, rect: Rect2, font_size: int, font: Font, color := IVORY) -> Label:
	var label := Label.new()
	label.text = words
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	canvas.add_child(label)
	return label

func _glow(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(color, 0.10))
	label.add_theme_color_override("font_shadow_color", Color(color, 0.26))
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_constant_override("shadow_outline_size", 10)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)

func _button(words: String, rect: Rect2, font_size: int) -> Button:
	var button := Button.new()
	button.text = words
	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.48, 0.51, 0.57))
	for style in ["normal", "hover", "pressed", "focus", "disabled"]: button.add_theme_stylebox_override(style, StyleBoxEmpty.new())
	canvas.add_child(button)
	return button

func present(as_guide := false) -> bool:
	if visible: return false
	_revision += 1
	guided = as_guide
	selected = 1
	revealed = 1 if guided else 20
	trace = 0.0 if guided else 20.0
	_busy = false
	_closing = false
	_age = 0.0
	canvas.modulate.a = 1.0
	constellations.reset(not guided)
	if guided: constellations.reveal_to(1)
	exit_button.visible = guided
	exit_button.disabled = false
	show()
	_refresh()
	advance.grab_focus()
	var completed: bool = await dismissed
	return completed

func _fit() -> void:
	var view := get_viewport_rect().size
	var factor := minf(view.x / BASE.x, view.y / BASE.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (view - BASE * factor) * 0.5

func _process(delta: float) -> void:
	if not visible: return
	_age += delta
	(_number_image.material as ShaderMaterial).set_shader_parameter("effect_time", _age)
	(_heading_image.material as ShaderMaterial).set_shader_parameter("effect_time", _age)
	drawing.queue_redraw()
	beacons.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("pause_game"):
		if guided: exit_guide()
		else: close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("ui_accept"):
		next()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left"):
		select(selected - 1)
		get_viewport().set_input_as_handled()

func next() -> void:
	if _busy or _closing or not visible: return
	if not guided or selected == 20:
		close()
		return
	if selected < revealed:
		select(selected + 1)
		return
	_busy = true
	var run_id := _revision
	revealed += 1
	selected = revealed
	constellations.reveal_to(revealed)
	if revealed == 20: final_reached.emit()
	_refresh()
	_motion = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_motion.tween_method(_set_trace, trace, float(revealed - 1), 0.55)
	await get_tree().create_timer(0.55, true).timeout
	if not is_inside_tree() or not visible or run_id != _revision: return
	_busy = false
	_refresh()
	advance.grab_focus()

func select(value: int) -> void:
	if _busy or _closing or value < 1 or value > revealed: return
	selected = value
	_refresh()

func _set_trace(value: float) -> void:
	trace = value
	drawing.queue_redraw()

func _refresh() -> void:
	number.text = "[center]" + _colored(GameConstants.to_roman(selected)) + "[/center]"
	for surface in _glow_surfaces: surface.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lesson := explain(selected)
	equation.text = lesson[0]
	hint.text = lesson[1]
	progress.text = "%02d / XX" % selected if guided else ""
	previous.visible = guided
	previous.disabled = selected == 1 or _busy
	advance.disabled = _busy
	advance.text = ("Entrar no tabuleiro" if selected == 20 else "Próxima estrela") if guided else "Voltar ao jogo"
	for index in range(20):
		var button := _nodes[index]
		button.visible = index < revealed
		button.disabled = _busy
		button.modulate = Color(1, 1, 1, 1.0 if index + 1 == selected else 0.64)
	drawing.queue_redraw()

static func explain(value: int) -> Array[String]:
	match value:
		1: return ["I  =  1", "Um traço vale uma unidade.\nEste é o primeiro símbolo do caminho."]
		2: return ["1 + 1 = 2", "Repita o I para somar unidades.\nDois traços formam II."]
		3: return ["1 + 1 + 1 = 3", "Três unidades, três traços: III.\nO I se repete até três vezes seguidas."]
		4: return ["5 − 1 = 4", "V vale cinco. Um I antes do V tira uma unidade.\nPor isso, quatro se escreve IV."]
		5: return ["V  =  5", "Cinco tem seu próprio símbolo: V.\nA partir dele, voltamos a somar unidades."]
		6, 7, 8: return ["5 + %d = %d" % [value - 5, value], "Depois do V, os traços somam.\n%s é cinco mais %d." % [GameConstants.to_roman(value), value - 5]]
		9: return ["10 − 1 = 9", "X vale dez. O I antes do X tira uma unidade.\nNove se escreve IX."]
		10: return ["X  =  10", "Com I, V e X, você já tem os três símbolos\nnecessários para chegar até vinte."]
		11, 12, 13: return ["10 + %d = %d" % [value - 10, value], "Comece com X e acrescente as unidades.\nO que vem depois do dez é somado."]
		14: return ["10 + (5 − 1) = 14", "O IV continua valendo quatro.\nColoque um X antes dele: X + IV = XIV."]
		15: return ["10 + 5 = 15", "Junte dez e cinco.\nX seguido de V forma XV."]
		16, 17, 18: return ["10 + 5 + %d = %d" % [value - 15, value], "Depois de XV, acrescente as unidades.\nOs símbolos maiores ficam à esquerda."]
		19: return ["10 + (10 − 1) = 19", "O IX continua valendo nove.\nX + IX forma XIX: dez mais nove."]
		20: return ["10 + 10 = 20", "Dois X, duas dezenas. A órbita está completa.\nEste atlas fica disponível no ícone ao lado do livro."]
	return ["", ""]

func _colored(words: String) -> String:
	var result := ""
	for glyph in words:
		var color := SILVER if glyph == "I" else (GOLD if glyph == "V" else BLUE)
		result += "[color=#%s]%s[/color]" % [color.to_html(false), glyph]
	return result

func _point(index: float) -> Vector2:
	var angle := -PI * 0.5 + index * TAU / 20.0
	return CENTER + Vector2(cos(angle), sin(angle)) * RADII

func _draw_atlas() -> void:
	for star in _stars:
		var alpha := 0.12 + 0.13 * (0.5 + 0.5 * sin(_age * 0.5 + star.x))
		drawing.draw_circle(Vector2(star.x, star.y), star.z, Color(0.7, 0.8, 1.0, alpha))
	for index in range(520):
		var at := float(index) * 20.0 / 520.0
		var color := Color(SILVER.lerp(BLUE, 0.38), 0.75) if at <= trace else Color(BLUE, 0.18)
		drawing.draw_circle(_point(at), 1.2 if at <= trace else 0.8, color)
	for index in range(20):
		var point := _point(float(index))
		var active := index + 1 == selected
		if active:
			drawing.draw_arc(point, 18.0, -_age * 0.3, TAU - _age * 0.3 - 0.65, 40, Color(GOLD, 0.65), 1.0, true)
	drawing.draw_line(Vector2(810, 775), Vector2(1110, 775), Color(SILVER, 0.23), 1, true)

func _draw_beacons() -> void:
	for index in range(20):
		var reached := index < revealed
		var active := index + 1 == selected
		var breath := 0.5 + 0.5 * sin(_age * TAU / 5.8 + float(index) * 0.73)
		var radius := (16.0 if active else 12.0) * lerpf(0.85, 1.15, breath) if reached else 6.0
		_beacon(_point(float(index)), radius, lerpf(0.64, 1.0, breath) if reached else 0.20)
	if _busy: _beacon(_point(trace), 19.0, 1.0)
	_beacon(Vector2(960, 775), 8.0, 0.8)

func _beacon(point: Vector2, radius: float, opacity: float) -> void:
	beacons.draw_texture_rect(STAR_LIGHT, Rect2(point - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, Color(1, 1, 1, opacity))

func close() -> void:
	if _busy or _closing or not visible: return
	_closing = true
	var run_id := _revision
	if guided:
		departure_started.emit()
		_motion = create_tween()
		_motion.tween_method(_set_trace, trace, 20.0, 0.45)
		_motion.tween_interval(0.5)
		await get_tree().create_timer(0.95, true).timeout
	if not is_inside_tree() or not visible or run_id != _revision: return
	hide()
	dismissed.emit(true)

func exit_guide() -> void:
	if not visible or not guided or _closing: return
	_revision += 1
	var run_id := _revision
	if _motion != null and _motion.is_valid(): _motion.kill()
	_busy = false
	_closing = true
	departure_started.emit()
	advance.disabled = true
	exit_button.disabled = true
	_motion = create_tween()
	_motion.tween_property(canvas, "modulate:a", 0.0, 0.9)
	await get_tree().create_timer(0.9, true).timeout
	if not is_inside_tree() or not visible or run_id != _revision: return
	hide()
	dismissed.emit(true)

func cancel() -> void:
	_revision += 1
	if _motion != null and _motion.is_valid(): _motion.kill()
	_busy = false
	_closing = false
	if visible:
		hide()
		dismissed.emit(false)
