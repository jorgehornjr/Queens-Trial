class_name TutorialBook
extends Control

signal dismissed
signal continue_requested
signal chapter_ready(number: int)
signal page_changed(number: int)

const Chapters = preload("res://scripts/ui/tutorial_chapters.gd")
const TurningPage = preload("res://scripts/ui/tutorial_page_turn.gd")
const ClosingCover = preload("res://scripts/ui/tutorial_cover_close.gd")
const InkOrnaments = preload("res://scripts/ui/tutorial_ink_ornaments.gd")
const StoryText = preload("res://scripts/ui/tutorial_body_text.gd")
const SPREAD: Texture2D = preload("res://assets/ui/tutorial_book/spread_cosmic.png")
const CONSULT_SPREAD: Texture2D = preload("res://assets/ui/tutorial_book/spread_consult.png")
const COVER: Texture2D = preload("res://assets/ui/tutorial_book/cover_burgundy.png")
const TITLE_FONT: Font = preload("res://assets/fonts/OPTIEngraversOldEnglish.otf")
const BODY_FONT: Font = preload("res://assets/fonts/Alegreya-Variable.ttf")
const SMALL_FONT: Font = preload("res://assets/fonts/CormorantSC-SemiBold.ttf")
const NUMERAL_FONT: Font = preload("res://assets/fonts/jupiter_pro.otf")
const PAGE_SOUND: AudioStream = preload("res://assets/audio/sfx/book/page_turn.wav")
const SHUT_SOUND: AudioStream = preload("res://assets/audio/sfx/book/book_close.wav")
const PRINTED_INK: Shader = preload("res://shaders/tutorial_printed_illustration.gdshader")
const TEXT_REVEAL: Shader = preload("res://shaders/tutorial_text_reveal.gdshader")
const REVEAL_DURATION := 5.0
const BOOK_SIZE := Vector2(1600, 1067)
const INK := Color(0.19, 0.105, 0.07)
const RUBRIC := Color(0.35, 0.08, 0.105)
const BODY_RECT := Rect2(198, 443, 542, 372)
const NUMERAL_ROW_Y := 424.0
const NUMERAL_ROW_STEP := 51.0
const ART_PAPER := {
	"color_first_edict": Color8(237, 212, 177),
	"color_two_edicts": Color8(252, 236, 211),
	"color_rooks": Color8(249, 232, 205),
	"color_attack_order": Color8(249, 231, 203),
	"color_bishops": Color8(243, 223, 195),
	"color_balance": Color8(245, 228, 204),
}
enum State { HIDDEN, ARRIVING, OPENING, TURNING, READING, CLOSING }

var state := State.HIDDEN
var current_chapter := 0
var last_chapter := 0
var unlocked_chapter := 0
var seen_chapters: Dictionary = {}
var table_visible := false
var consultation := false
var _generation := 0
var _animation: Tween
var _reveal_tween: Tween
var _text_material: ShaderMaterial
var _header_ink: ShaderMaterial
var reveal_progress := 1.0
var _requested_close := false
var _fit := 1.0
var _close_origin := Vector2.ZERO
var _cover_motion := 0.0
var _textures: Dictionary = {}
var _displayed_chapter := 0
var _body_fit_generation := 0
var _wait_timer: Timer
var veil: ColorRect
var volume: Control
var spread: TextureRect
var cover: Control
var cover_art: TextureRect
var page_audio: AudioStreamPlayer
var close_audio: AudioStreamPlayer
var right_stack: TextureRect
var closing_cover: Node2D
var content: Control
var chapter_label: Label
var title_label: Label
var body_label: TutorialBodyText
var initial_ornaments: Node2D
var controls: Control
var illustration: TextureRect
var numeral_table: Control
var leaf: Node2D


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	hide()
	get_viewport().size_changed.connect(_fit_book)
	_fit_book()
	set_process(false)


func _exit_tree() -> void:
	cancel()


func _delay(seconds: float) -> void:
	_wait_timer.start(seconds)
	await _wait_timer.timeout


func needs_chapter(number: int) -> bool:
	return Chapters.CHAPTERS.has(number) and not seen_chapters.has(number)


func unlock_to(number: int) -> void:
	unlocked_chapter = maxi(unlocked_chapter, clampi(number, 0, 6))


func present(number: int, force := false) -> bool:
	unlock_to(number)
	if not force and not needs_chapter(number):
		return true
	cancel()
	var run_id := _generation
	_cover_motion = 1.0
	_fit_book()
	current_chapter = number
	_requested_close = false
	var starting_page := number if force or number <= 1 else number - 1
	_set_page(starting_page)
	_set_reveal_progress(1.0 if starting_page != number else 0.0)
	show()
	set_process(true)
	state = State.ARRIVING
	veil.modulate.a = 0.0
	volume.modulate.a = 0.0
	volume.position.y += 65.0 * _fit
	cover.show()
	cover.position = Vector2(800, 51)
	cover.rotation = 0.0
	cover.scale = Vector2.ONE
	cover.modulate = Color.WHITE
	spread.hide()
	content.hide()
	leaf.hide()
	_animation = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_animation.tween_property(veil, "modulate:a", 1.0, 0.55)
	_animation.tween_property(volume, "modulate:a", 1.0, 0.8)
	_animation.tween_property(volume, "position:y", volume.position.y - 65.0 * _fit, 0.9)
	await _delay(1.5)
	if run_id != _generation: return false
	state = State.OPENING
	_prepare_hinge(1.0)
	cover.hide()
	_animation = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_method(_close_cover_progress, 1.0, 0.0, 1.1)
	await _delay(1.13)
	if run_id != _generation: return false
	closing_cover.hide()
	right_stack.hide()
	spread.scale = Vector2.ONE
	spread.show()
	content.show()
	content.modulate.a = 1.0
	if starting_page != number:
		await _delay(0.35)
		if run_id != _generation: return false
		await _turn_to(number, run_id)
		if run_id != _generation: return false
	else:
		_start_reveal()
	state = State.READING
	chapter_ready.emit(number)
	if not _requested_close:
		await continue_requested
	if run_id != _generation: return false
	await _close(run_id)
	if run_id != _generation: return false
	seen_chapters[number] = true
	last_chapter = _displayed_chapter
	state = State.HIDDEN
	_body_fit_generation += 1
	hide()
	set_process(false)
	dismissed.emit()
	return true


func can_turn(direction: int) -> bool:
	var target := _displayed_chapter + direction
	return target >= 0 and target <= unlocked_chapter


func turn_page(direction: int) -> void:
	if state != State.READING or abs(direction) != 1 or not can_turn(direction):
		return
	var run_id := _generation
	await _turn_to(_displayed_chapter + direction, run_id)
	if run_id != _generation: return
	state = State.READING
	page_changed.emit(_displayed_chapter)
	if _requested_close: continue_requested.emit()


func request_close() -> void:
	if state == State.HIDDEN or state == State.CLOSING:
		return
	_requested_close = true
	if state != State.TURNING:
		continue_requested.emit()


func _page_click(position: Vector2) -> void:
	var local := volume.get_global_transform_with_canvas().affine_inverse() * position
	if not Rect2(40, 30, 1520, 1010).has_point(local):
		request_close()
	elif state == State.READING:
		turn_page(-1 if local.x < BOOK_SIZE.x * 0.5 else 1)


func _input(event: InputEvent) -> void:
	if not visible or state == State.CLOSING: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_page_click(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		_page_click(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_LEFT, KEY_RIGHT]:
			turn_page(-1 if event.keycode == KEY_LEFT else 1)
			get_viewport().set_input_as_handled()
		elif consultation and event.keycode in [KEY_ESCAPE, KEY_N]:
			request_close()
			get_viewport().set_input_as_handled()


func cancel() -> void:
	_generation += 1
	_body_fit_generation += 1
	if _animation != null and _animation.is_valid(): _animation.kill()
	if _reveal_tween != null and _reveal_tween.is_valid(): _reveal_tween.kill()
	state = State.HIDDEN
	if is_instance_valid(_wait_timer):
		_wait_timer.stop()
		_wait_timer.timeout.emit()
	continue_requested.emit()
	if is_instance_valid(page_audio): page_audio.stop()
	if is_instance_valid(close_audio): close_audio.stop()
	if is_instance_valid(closing_cover): closing_cover.hide()
	if is_instance_valid(right_stack): right_stack.hide()
	hide()
	set_process(false)


func _turn_to(number: int, run_id: int) -> void:
	state = State.TURNING
	page_audio.pitch_scale = 1.0 if number > _displayed_chapter else 0.96
	page_audio.play()
	if _reveal_tween != null and _reveal_tween.is_valid(): _reveal_tween.kill()
	_set_reveal_progress(1.0)
	var forward := number > _displayed_chapter
	leaf.set("paper", spread.texture)
	leaf.set("illustration", illustration.texture if illustration.visible and forward else null)
	leaf.set("ink_material", (illustration.material as ShaderMaterial).duplicate())
	if illustration.texture != null:
		var painted_size := illustration.texture.get_size()
		painted_size *= minf(illustration.size.x / painted_size.x, illustration.size.y / painted_size.y)
		leaf.set("illustration_rect", Rect2(illustration.position + (illustration.size - painted_size) * 0.5 - leaf.position, painted_size))
	leaf.set("progress", 0.0)
	leaf.set("backwards", not forward)
	leaf.show()
	_animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_property(leaf, "progress", 0.48, 0.48)
	await _delay(0.5)
	if run_id != _generation: return
	_set_page(number)
	_start_reveal()
	_animation = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_animation.tween_property(leaf, "progress", 1.0, 0.6)
	await _delay(0.62)
	if run_id == _generation: leaf.hide()


func _set_page(number: int) -> void:
	_displayed_chapter = number
	if number == 0:
		_set_table(true)
	else:
		_set_chapter(number)


func _start_reveal() -> void:
	if _reveal_tween != null and _reveal_tween.is_valid(): _reveal_tween.kill()
	_set_reveal_progress(0.0)
	_reveal_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_reveal_tween.tween_method(_set_reveal_progress, 0.0, 1.0, REVEAL_DURATION)


func _set_reveal_progress(value: float) -> void:
	reveal_progress = value
	_text_material.set_shader_parameter("reveal_progress", value)
	body_label.set_ink_progress(value)
	(illustration.material as ShaderMaterial).set_shader_parameter("paint_progress", value)
	_header_ink.set_shader_parameter("paint_progress", value)
	controls.modulate.a = value


func _close(run_id: int) -> void:
	state = State.CLOSING
	if _reveal_tween != null and _reveal_tween.is_valid(): _reveal_tween.kill()
	_prepare_hinge(0.0)
	spread.hide()
	cover.hide()
	close_audio.play()
	_animation = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_animation.tween_property(content, "modulate:a", 0.0, 0.24)
	_animation.tween_method(_close_cover_progress, 0.0, 1.0, 1.1)
	await _delay(1.13)
	if run_id != _generation: return
	closing_cover.hide()
	right_stack.hide()
	content.hide()
	cover.position = Vector2(800, 51)
	cover.scale = Vector2.ONE
	cover.modulate = Color.WHITE
	cover.show()
	await _delay(0.4)
	if run_id != _generation: return
	_animation = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_animation.tween_property(volume, "position:y", volume.position.y + 75.0 * _fit, 0.5)
	_animation.tween_property(volume, "modulate:a", 0.0, 0.5)
	_animation.tween_property(veil, "modulate:a", 0.0, 0.5)
	await _delay(0.52)


func _prepare_hinge(value: float) -> void:
	var half := AtlasTexture.new()
	half.atlas = spread.texture
	half.region = Rect2(Vector2(spread.texture.get_width() * 0.5, 0), Vector2(spread.texture.get_width() * 0.5, spread.texture.get_height()))
	right_stack.texture = half
	right_stack.show()
	closing_cover.set("paper", spread.texture)
	closing_cover.show()
	_close_cover_progress(value)


func _close_cover_progress(value: float) -> void:
	_cover_motion = value
	closing_cover.set("progress", value)
	right_stack.scale = Vector2(lerpf(1.0, 0.8, value), lerpf(1.0, 960.0 / 1067.0, value))
	right_stack.position.y = 51.0 * value
	# The exposed page block vanishes continuously as the front covers it.
	# Hiding the node at the end therefore cannot pop a strip beside the spine.
	right_stack.modulate.a = 1.0 - smoothstep(0.82, 1.0, value)
	volume.position.x = _close_origin.x - 320.0 * _fit * smoothstep(0.5, 1.0, value)


func _set_chapter(number: int) -> void:
	var data := Chapters.chapter(number)
	if data.is_empty(): return
	_displayed_chapter = number
	table_visible = false
	numeral_table.hide()
	spread.texture = SPREAD
	chapter_label.text = "FASE %s" % [GameConstants.to_roman(number)]
	title_label.text = data.title
	_style_title(96 if "\n" in String(data.title) else 106)
	var body_top := 443.0 if "\n" in String(data.title) else (369.0 if number == 6 else 397.0)
	body_label.position = Vector2(BODY_RECT.position.x, body_top)
	body_label.size = Vector2(BODY_RECT.size.x, 815.0 - body_top)
	body_label.show()
	initial_ornaments.show()
	controls.visible = number == 1
	illustration.show()
	_set_body(String(data.body), 34)
	_body_fit_generation += 1
	call_deferred("_fit_body", _body_fit_generation)
	var art_name: String = data.art
	if not _textures.has(art_name):
		_textures[art_name] = load("res://assets/ui/tutorial_book/%s.png" % art_name)
	illustration.texture = _textures[art_name]
	(illustration.material as ShaderMaterial).set_shader_parameter("source_paper", ART_PAPER[art_name])
	get_node("Volume/Content/LeftFolio").text = str(number * 2 + 1)
	get_node("Volume/Content/RightFolio").text = str(number * 2 + 2)


func _set_table(value: bool) -> void:
	table_visible = value
	if not is_instance_valid(numeral_table): return
	numeral_table.visible = value
	if value:
		_body_fit_generation += 1
		_displayed_chapter = 0
		spread.texture = CONSULT_SPREAD
		chapter_label.text = "CONSULTA"
		title_label.text = "Números\nromanos"
		_style_title(72)
		body_label.hide()
		initial_ornaments.hide()
		controls.hide()
		illustration.hide()
		get_node("Volume/Content/LeftFolio").text = "1"
		get_node("Volume/Content/RightFolio").text = "2"
	else:
		_set_chapter(current_chapter)


func _style_title(font_size: int) -> void:
	var longest := 0.0
	for line in title_label.text.split("\n"):
		longest = maxf(longest, TITLE_FONT.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	if longest > 565.0:
		font_size = int(float(font_size) * 565.0 / longest)
	title_label.add_theme_font_size_override("font_size", font_size)
	title_label.size = Vector2(565, 244 if "\n" in title_label.text else 210)


func _set_body(plain_text: String, font_size: int) -> void:
	body_label.set_story(plain_text, font_size)
	initial_ornaments.position = body_label.position + Vector2(4, 4)


func _fit_body(run_id: int) -> void:
	var plain_text: String = Chapters.chapter(_displayed_chapter).get("body", "")
	for font_size in range(34, 28, -1):
		if run_id != _body_fit_generation: return
		_set_body(plain_text, font_size)
		await get_tree().process_frame
		if run_id != _body_fit_generation or not is_inside_tree(): return
		if body_label.get_content_height() <= body_label.size.y:
			return


func _fit_book() -> void:
	if not is_instance_valid(volume): return
	var view := get_viewport_rect().size
	_fit = minf((view.x - 48.0) / BOOK_SIZE.x, (view.y - 100.0) / BOOK_SIZE.y)
	volume.scale = Vector2.ONE * _fit
	_close_origin = (view - BOOK_SIZE * _fit) * 0.5 - Vector2(0, 10)
	volume.position = _close_origin - Vector2(320.0 * _fit * smoothstep(0.5, 1.0, _cover_motion), 0)


func _build() -> void:
	_text_material = ShaderMaterial.new()
	_text_material.shader = TEXT_REVEAL
	_wait_timer = Timer.new()
	_wait_timer.name = "BookAnimationDelay"
	_wait_timer.one_shot = true
	add_child(_wait_timer)
	page_audio = AudioStreamPlayer.new()
	page_audio.name = "PageFoley"
	page_audio.stream = PAGE_SOUND
	page_audio.volume_db = 6.0
	add_child(page_audio)
	close_audio = AudioStreamPlayer.new()
	close_audio.name = "CoverFoley"
	close_audio.stream = SHUT_SOUND
	close_audio.volume_db = 8.0
	add_child(close_audio)
	veil = ColorRect.new()
	veil.name = "Veil"
	veil.color = Color(0.012, 0.008, 0.023, 0.84)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	volume = Control.new()
	volume.name = "Volume"
	volume.size = BOOK_SIZE
	volume.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(volume)
	spread = _texture(volume, "Spread", SPREAD, Rect2(Vector2.ZERO, BOOK_SIZE))
	right_stack = _texture(volume, "ClosingPageStack", null, Rect2(800, 0, 800, 1067))
	right_stack.hide()
	content = Control.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	volume.add_child(content)
	chapter_label = _label(content, "Chapter", "", Rect2(217, 128, 500, 42), SMALL_FONT, 29)
	chapter_label.add_theme_color_override("font_color", RUBRIC)
	title_label = _label(content, "Title", "", Rect2(184, 174, 565, 244), TITLE_FONT, 96)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.add_theme_constant_override("line_spacing", -16)
	title_label.add_theme_color_override("font_color", RUBRIC)
	body_label = StoryText.new()
	body_label.name = "Body"
	body_label.position = BODY_RECT.position
	body_label.size = BODY_RECT.size
	body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_label.add_theme_font_size_override("normal_font_size", 34)
	content.add_child(body_label)
	body_label.set_reveal_material(_text_material)
	initial_ornaments = InkOrnaments.new()
	initial_ornaments.name = "InitialInkStars"
	content.add_child(initial_ornaments)
	initial_ornaments.material = _text_material
	illustration = _texture(content, "Illustration", null, Rect2(830, 68, 674, 925))
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var ink_material := ShaderMaterial.new()
	ink_material.shader = PRINTED_INK
	illustration.material = ink_material
	controls = Control.new()
	controls.name = "MovementKeys"
	controls.position = Vector2(258, 702)
	controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(controls)
	for index in range(4):
		var key := Panel.new()
		key.name = "Key%s" % ["W", "A", "S", "D"][index]
		key.position = Vector2(index * 96, 0)
		key.size = Vector2(72, 70)
		key.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var key_frame := StyleBoxFlat.new()
		key_frame.bg_color = Color(0.86, 0.75, 0.56, 0.12)
		key_frame.border_color = Color(0.40, 0.28, 0.15, 0.9)
		key_frame.set_border_width_all(2)
		key_frame.set_corner_radius_all(5)
		key.add_theme_stylebox_override("panel", key_frame)
		controls.add_child(key)
		var glyph := _label(key, "Glyph", ["W", "A", "S", "D"][index], Rect2(0, 0, 72, 70), BODY_FONT, 42)
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label(content, "LeftFolio", "", Rect2(430, 973, 50, 34), BODY_FONT, 23).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label(content, "RightFolio", "", Rect2(1140, 973, 50, 34), BODY_FONT, 23).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numeral_table = Control.new()
	numeral_table.name = "NumeralTable"
	numeral_table.size = BOOK_SIZE
	numeral_table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(numeral_table)
	var header_atlas := AtlasTexture.new()
	header_atlas.atlas = preload("res://assets/ui/tutorial_book/initial_sources/numeral_header.png")
	header_atlas.region = Rect2(814, 78, 615, 280)
	var right_header := _texture(numeral_table, "RightAstronomy", header_atlas, Rect2(862, 93, 640, 292))
	_header_ink = ShaderMaterial.new()
	_header_ink.shader = PRINTED_INK
	_header_ink.set_shader_parameter("source_paper", Color8(239, 216, 180))
	right_header.material = _header_ink
	for index in range(20):
		var column := 0 if index < 10 else 1
		var row := index % 10
		var number := Control.new()
		number.name = "Number%d" % index
		number.position = Vector2(240 + column * 820, NUMERAL_ROW_Y + row * NUMERAL_ROW_STEP)
		number.size = Vector2(405, 58)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		numeral_table.add_child(number)
		var roman := _label(number, "Roman", Chapters.ROMANS[index], Rect2(0, 0, 174, 58), NUMERAL_FONT, 42)
		roman.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		roman.add_theme_color_override("font_color", RUBRIC)
		_label(number, "Equals", "=", Rect2(190, 0, 70, 58), NUMERAL_FONT, 42).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_label(number, "Arabic", str(index + 1), Rect2(285, 0, 86, 58), NUMERAL_FONT, 42).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	leaf = TurningPage.new()
	leaf.name = "TurningLeaf"
	leaf.position = Vector2(800, 43)
	volume.add_child(leaf)
	closing_cover = ClosingCover.new()
	closing_cover.name = "ClosingFrontCover"
	closing_cover.position = Vector2(800, 0)
	closing_cover.set("front", COVER)
	volume.add_child(closing_cover)
	closing_cover.hide()
	cover = Control.new()
	cover.name = "Cover"
	cover.position = Vector2(480, 51)
	cover.size = Vector2(640, 960)
	cover.pivot_offset = Vector2(320, 480)
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	volume.add_child(cover)
	cover_art = _texture(cover, "Cloth", COVER, Rect2(0, 0, 640, 960))
	_set_table(false)


func _texture(parent: Node, node_name: String, tex: Texture2D, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.name = node_name
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = tex
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node


func _label(parent: Node, node_name: String, text: String, rect: Rect2, font: Font, font_size: int) -> Label:
	var node := Label.new()
	node.name = node_name
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_theme_font_override("font", font)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", INK)
	if parent != self: node.material = _text_material
	parent.add_child(node)
	return node
