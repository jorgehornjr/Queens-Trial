class_name FailureFeedback
extends CanvasLayer


signal dismissed(accepted: bool)

const FONT := preload("res://assets/fonts/jupiter_pro.otf")
const BODY_FONT := preload("res://assets/fonts/Alegreya-Variable.ttf")
const INITIAL_FONT := preload("res://assets/fonts/OPTIEngraversOldEnglish.otf")
const InkStars := preload("res://scripts/ui/tutorial_ink_ornaments.gd")
const BLUE_CARD := preload("res://assets/cards/back.png")
const RED_CARD := preload("res://assets/cards/back_chaotic.png")
const BOOK_PAPER := preload("res://assets/ui/tutorial_book/spread_cosmic.png")
const GOLD_INK := preload("res://shaders/feedback_card_ornaments.gdshader")
const BASE := Vector2(1920, 1080)
const PAPER := Color(0.965, 0.915, 0.805)
const INK := Color(0.19, 0.105, 0.07)
const GOLD := Color(0.62, 0.44, 0.23)

var screen: Control
var canvas: Control
var panel: PanelContainer
var body: Label
var hint: Label
var action: Button
var chaotic_style := false:
	set(value):
		chaotic_style = value
		if is_instance_valid(panel): _style_card()
var _paper: StyleBoxFlat
var _card_art: Texture2D
var _parchment: AtlasTexture
var _ornaments: Node2D
var _initial: Label
var _generation := 0
var _animation: Tween
var _automatic := false


func _ready() -> void:
	layer = 50
	screen = Control.new()
	screen.name = "Screen"
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.mouse_filter = Control.MOUSE_FILTER_STOP
	var veil := ColorRect.new()
	veil.color = Color(0.015, 0.012, 0.03, 0.72)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas = Control.new()
	canvas.name = "Page"
	canvas.size = BASE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.add_child(canvas)
	panel = PanelContainer.new()
	panel.name = "Correction"
	panel.custom_minimum_size.x = 1040
	_paper = StyleBoxFlat.new()
	_paper.bg_color = PAPER
	_paper.set_corner_radius_all(10)
	_paper.shadow_color = Color(0.008, 0.005, 0.015, 0.70)
	_paper.shadow_size = 42
	_paper.content_margin_left = 84
	_paper.content_margin_right = 84
	_paper.content_margin_top = 48
	_paper.content_margin_bottom = 50
	panel.add_theme_stylebox_override("panel", _paper)
	_parchment = AtlasTexture.new()
	_parchment.atlas = BOOK_PAPER
	_parchment.region = Rect2(820, 360, 600, 420)
	panel.draw.connect(func(): panel.draw_texture_rect(_parchment, Rect2(Vector2.ZERO, panel.size), false))
	canvas.add_child(panel)
	_ornaments = Node2D.new()
	_ornaments.name = "GoldCorners"
	_ornaments.material = ShaderMaterial.new()
	(_ornaments.material as ShaderMaterial).shader = GOLD_INK
	_ornaments.draw.connect(_draw_ornaments)
	panel.add_child(_ornaments)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)
	_build_heading(column)
	body = _label("", 36, BODY_FONT, INK)
	body.name = "Explanation"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_constant_override("line_spacing", 5)
	column.add_child(body)
	hint = _label("", 30, BODY_FONT, Color(0.36, 0.28, 0.22))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)
	var center := CenterContainer.new()
	column.add_child(center)
	action = Button.new()
	action.name = "TryAgain"
	action.custom_minimum_size = Vector2(420, 76)
	action.add_theme_font_override("font", FONT)
	action.add_theme_font_size_override("font_size", 34)
	action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(GOLD, 0.08 if state == "hover" else 0.0)
		style.set_corner_radius_all(3)
		style.set_border_width_all(3 if state == "focus" else 1)
		style.border_color = GOLD
		if state == "focus": style.draw_center = false
		action.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_disabled_color"]:
		action.add_theme_color_override(state, INK)
	center.add_child(action)
	action.pressed.connect(acknowledge)
	_style_card()
	panel.minimum_size_changed.connect(_center_panel)
	get_viewport().size_changed.connect(_fit)
	_fit()
	panel.hide()
	screen.hide()


func _build_heading(column: VBoxContainer) -> void:
	var heading := HBoxContainer.new()
	heading.alignment = BoxContainer.ALIGNMENT_CENTER
	heading.add_theme_constant_override("separation", 2)
	column.add_child(heading)
	var initial := Control.new()
	initial.custom_minimum_size = Vector2(116, 130)
	heading.add_child(initial)
	var stars := InkStars.new()
	stars.position = Vector2(17, 0)
	stars.scale = Vector2.ONE * 0.82
	stars.modulate = Color(1, 1, 1, 0.8)
	initial.add_child(stars)
	_initial = _label("F", 126, INITIAL_FONT, PAPER)
	_initial.position = Vector2(10, -4)
	_initial.size = Vector2(104, 130)
	_initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_initial.add_theme_color_override("font_outline_color", Color(0.08, 0.18, 0.3))
	_initial.add_theme_constant_override("outline_size", 2)
	initial.add_child(_initial)
	var title := _label("eedback", 62, BODY_FONT, INK)
	title.custom_minimum_size.y = 130
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.add_child(title)


func _style_card() -> void:
	_card_art = RED_CARD if chaotic_style else BLUE_CARD
	_initial.add_theme_color_override("font_color", Color(0.57, 0.08, 0.12) if chaotic_style else Color(0.12, 0.31, 0.52))
	_initial.add_theme_color_override("font_outline_color", Color(0.31, 0.05, 0.07) if chaotic_style else Color(0.08, 0.18, 0.3))
	panel.queue_redraw()
	_ornaments.queue_redraw()


func _draw_ornaments() -> void:
	var source := _card_art.get_size()
	var edge := 100.0
	var source_x := [0.0, edge, source.x - edge, source.x]
	var source_y := [0.0, edge, source.y - edge, source.y]
	var target_x := [0.0, edge, panel.size.x - edge, panel.size.x]
	var target_y := [0.0, edge, panel.size.y - edge, panel.size.y]
	for row in range(3):
		for column in range(3):
			if row == 1 and column == 1: continue
			var region := Rect2(source_x[column], source_y[row], source_x[column + 1] - source_x[column], source_y[row + 1] - source_y[row])
			var destination := Rect2(target_x[column], target_y[row], target_x[column + 1] - target_x[column], target_y[row + 1] - target_y[row])
			_ornaments.draw_texture_rect_region(_card_art, destination, region)


func _label(words: String, size: int, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _fit() -> void:
	var viewport := get_viewport().get_visible_rect().size
	var fit := minf(viewport.x / BASE.x, viewport.y / BASE.y)
	canvas.scale = Vector2.ONE * fit
	canvas.position = (viewport - BASE * fit) * 0.5
	_center_panel()


func _center_panel() -> void:
	panel.size = Vector2(1040, panel.get_combined_minimum_size().y)
	panel.position = (BASE - panel.size) * 0.5
	panel.pivot_offset = panel.size * 0.5
	_ornaments.queue_redraw()


func present(reasons: Array, guidance: String, button_text := "Tentar novamente", auto_seconds := 0.0) -> bool:
	cancel()
	var run_id := _generation
	_automatic = auto_seconds > 0.0
	body.text = "\n\n".join(PackedStringArray(reasons))
	hint.text = guidance
	hint.visible = not guidance.is_empty()
	action.text = button_text
	action.visible = not _automatic
	action.disabled = true
	panel.show()
	screen.show()
	_center_panel()
	screen.modulate.a = 0.0
	panel.scale = Vector2.ONE * 0.975
	_animation = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	_animation.tween_property(screen, "modulate:a", 1.0, 0.24)
	_animation.tween_property(panel, "scale", Vector2.ONE, 0.32)
	# Evita que o envio da resposta também feche a correção.
	await get_tree().create_timer(0.40).timeout
	if run_id != _generation or not screen.visible: return false
	if _automatic:
		await get_tree().create_timer(maxf(0.0, auto_seconds - 0.4), false).timeout
		if run_id != _generation or not screen.visible: return false
		_animation = create_tween()
		_animation.tween_property(screen, "modulate:a", 0.0, 0.25)
		await _animation.finished
		if run_id != _generation: return false
		panel.hide()
		screen.hide()
		dismissed.emit(true)
		return true
	action.disabled = false
	action.grab_focus()
	return await dismissed


func acknowledge() -> void:
	if not screen.visible or action.disabled or _automatic: return
	panel.hide()
	screen.hide()
	dismissed.emit(true)


func cancel() -> void:
	_generation += 1
	if _animation != null and _animation.is_valid(): _animation.kill()
	if not is_instance_valid(screen) or not screen.visible: return
	panel.hide()
	screen.hide()
	dismissed.emit(false)


func _input(event: InputEvent) -> void:
	if not screen.visible or not event is InputEventKey or not event.pressed: return
	if event.echo:
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		acknowledge()
	elif event.keycode == KEY_N or event.is_action_pressed("move_up") or event.is_action_pressed("move_left") or event.is_action_pressed("move_down") or event.is_action_pressed("move_right"):
		get_viewport().set_input_as_handled()


func _exit_tree() -> void:
	cancel()
