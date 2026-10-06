class_name GameHUD
extends CanvasLayer

const EdictDust = preload("res://scripts/ui/edict_dust.gd")
const TutorialBookScene = preload("res://scripts/ui/tutorial_book.gd")
const STORY_FONT: FontFile = preload("res://assets/fonts/CormorantSC-SemiBold.ttf")
const JUPITER_FONT: FontFile = preload("res://assets/fonts/jupiter_pro.otf")
const ANNOUNCEMENT_FONT_SIZE := 112

@onready var phase_label: Label = $PhasePanel/PhaseLabel
@onready var announcement: Control = $Announcement
@onready var announcement_label: Label = $Announcement/EdictLabel
@onready var announcement_halo: ColorRect = $Announcement/Halo
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var card_presentation: CardPresentation = $CardPresentation

var _dust_effect: Node2D
var _intro_generation := 0
var _dust_tween: Tween
var _phase_number := 0
var tutorial_book: TutorialBook
var _balance_reading := false
var _balance_process_mode := Node.PROCESS_MODE_INHERIT
var _consulting := false
var book_button: TextureButton
var _book_hover: Tween


func _ready() -> void:
	_build_book_button()
	tutorial_book = TutorialBookScene.new()
	tutorial_book.name = "TutorialBook"
	add_child(tutorial_book)
	var trial := get_parent().get_node_or_null("BalanceTrialController")
	if trial != null:
		trial.round_started.connect(_hold_balance_for_reading)
	announcement.visible = false
	result_panel.visible = false
	announcement_label.add_theme_font_override("font", STORY_FONT)
	announcement_label.add_theme_font_size_override("font_size", ANNOUNCEMENT_FONT_SIZE)


func set_phase(phase_number: int, _phase_data: Dictionary, _phase_seed: int) -> void:
	_intro_generation += 1
	_release_reading()
	tutorial_book.cancel()
	_phase_number = phase_number
	tutorial_book.unlock_to(phase_number)
	phase_label.text = ""
	# A apresentação fica concentrada nos éditos inferiores e nas telas de resultado.
	result_panel.visible = false
	_clear_dust()
	card_presentation.cancel()
	if phase_number == 6 and tutorial_book.needs_chapter(6):
		_balance_reading = true
		call_deferred("_play_balance_intro", _intro_generation)


func _exit_tree() -> void:
	_intro_generation += 1
	if is_instance_valid(tutorial_book): tutorial_book.cancel()
	if is_instance_valid(card_presentation): card_presentation.cancel()
	_clear_dust()
	if _consulting: get_tree().paused = false


func play_phase_intro(values: Array) -> void:
	var run_id := _intro_generation
	var read_ok := await tutorial_book.present(_phase_number)
	if not read_ok or run_id != _intro_generation:
		return
	await card_presentation.present(values)


func _play_balance_intro(run_id: int) -> void:
	if run_id != _intro_generation: return
	var read_ok := await tutorial_book.present(6)
	if not read_ok or run_id != _intro_generation: return
	var trial := get_parent().get_node("BalanceTrialController") as BalanceTrialController
	_balance_reading = false
	trial.process_mode = _balance_process_mode
	if trial.stage == BalanceTrialController.Stage.DECISION:
		trial.trial_hud.show()
		get_parent().get_node("World/Player").set_input_enabled(true)


func _hold_balance_for_reading(_left: int, _right: int) -> void:
	if not _balance_reading: return
	var trial := get_parent().get_node("BalanceTrialController") as BalanceTrialController
	_balance_process_mode = trial.process_mode
	trial.process_mode = Node.PROCESS_MODE_DISABLED
	trial.trial_hud.hide()
	get_parent().get_node("World/Player").set_input_enabled(false)


func _release_reading() -> void:
	if _balance_reading:
		var trial := get_parent().get_node_or_null("BalanceTrialController")
		if trial != null: trial.process_mode = _balance_process_mode
	_balance_reading = false
	if _consulting:
		get_tree().paused = false
		_consulting = false
	tutorial_book.process_mode = Node.PROCESS_MODE_INHERIT
	tutorial_book.consultation = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		var player := get_parent().get_node_or_null("World/Player") as GridPlayer
		if not get_tree().paused and not tutorial_book.visible and player != null and player.input_enabled:
			get_viewport().set_input_as_handled()
			_consult_book()


func _consult_book() -> void:
	var player := get_parent().get_node_or_null("World/Player") as GridPlayer
	if _consulting or tutorial_book.visible or get_tree().paused or player == null or not player.input_enabled: return
	var run_id := _intro_generation
	_consulting = true
	book_button.hide()
	get_tree().paused = true
	tutorial_book.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_book.consultation = true
	var read_ok := await tutorial_book.present(_phase_number, true)
	if not read_ok or run_id != _intro_generation: return
	_release_reading()


func _process(_delta: float) -> void:
	if not is_instance_valid(book_button) or not is_instance_valid(tutorial_book): return
	var player := get_parent().get_node_or_null("World/Player") as GridPlayer
	book_button.visible = _phase_number > 0 and player != null and player.input_enabled and not tutorial_book.visible and not card_presentation.visible and not get_tree().paused


func _build_book_button() -> void:
	book_button = TextureButton.new()
	book_button.name = "OpenTutorialBook"
	book_button.texture_normal = TutorialBookScene.COVER
	book_button.ignore_texture_size = true
	book_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	book_button.focus_mode = Control.FOCUS_NONE
	book_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	book_button.tooltip_text = "Livro de tutoriais (N)"
	book_button.visible = false
	add_child(book_button)
	book_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	book_button.offset_left = -108
	book_button.offset_right = -32
	book_button.offset_top = 24
	book_button.offset_bottom = 138
	book_button.pivot_offset = Vector2(38, 57)
	book_button.pressed.connect(_consult_book)
	book_button.mouse_entered.connect(_hover_book.bind(true))
	book_button.mouse_exited.connect(_hover_book.bind(false))


func _hover_book(hovered: bool) -> void:
	if _book_hover != null and _book_hover.is_valid(): _book_hover.kill()
	_book_hover = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_book_hover.tween_property(book_button, "scale", Vector2.ONE * (1.04 if hovered else 1.0), 0.18)


func _play_announcement(text_value: String) -> void:
	var run_id := _intro_generation
	announcement_label.add_theme_font_override("font", JUPITER_FONT if text_value == "FASE CONCLUÍDA" else STORY_FONT)
	announcement_label.add_theme_font_size_override("font_size", ANNOUNCEMENT_FONT_SIZE)
	announcement_label.text = text_value
	announcement_label.visible = true
	announcement_label.visible_ratio = 1.0
	announcement.visible = true
	announcement.modulate = Color(1, 1, 1, 0)
	announcement.scale = Vector2(0.72, 0.72)
	announcement.pivot_offset = get_viewport().get_visible_rect().size * 0.5
	announcement_halo.scale = Vector2(0.05, 1.0)
	announcement_halo.visible = false
	_clear_dust()
	_dust_effect = EdictDust.new()
	announcement.add_child(_dust_effect)
	_dust_effect.prepare(announcement_label)

	var appear := create_tween()
	appear.set_parallel(true)
	appear.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	appear.tween_property(announcement, "modulate", Color.WHITE, 0.42)
	appear.tween_property(announcement, "scale", Vector2.ONE, 0.58)
	appear.tween_property(announcement_halo, "scale", Vector2.ONE, 0.52)
	await appear.finished
	if run_id != _intro_generation:
		return
	await get_tree().create_timer(0.90).timeout
	if run_id != _intro_generation:
		return
	announcement_label.visible = false
	_dust_effect.visible = true
	var vanish := create_tween()
	_dust_tween = vanish
	vanish.set_parallel(true)
	vanish.tween_method(_dust_effect.set_elapsed, 0.0, EdictDust.DURATION, EdictDust.DURATION)
	await vanish.finished
	if run_id != _intro_generation:
		return
	announcement.visible = false
	announcement_label.visible = true
	announcement_label.visible_ratio = 1.0
	announcement_halo.modulate.a = 1.0
	_clear_dust()


func show_failure(motivos: Array) -> void:
	result_label.text = "\n".join(PackedStringArray(motivos))
	result_label.add_theme_color_override("font_color", Color(0.96, 0.91, 0.82, 1.0))
	_show_result_panel()


func show_success() -> void:
	result_panel.visible = false
	await _play_announcement("FASE CONCLUÍDA")


func show_restart() -> void:
	result_panel.visible = false


func _show_result_panel() -> void:
	result_panel.visible = true
	result_panel.modulate = Color(1, 1, 1, 0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_panel, "modulate", Color.WHITE, 0.24)


func _clear_dust() -> void:
	if _dust_tween != null:
		_dust_tween.kill()
		_dust_tween = null
	if is_instance_valid(_dust_effect):
		_dust_effect.queue_free()
	_dust_effect = null
