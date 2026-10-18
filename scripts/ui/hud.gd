class_name GameHUD
extends CanvasLayer

const EdictDust = preload("res://scripts/ui/edict_dust.gd")
const TutorialBookScene = preload("res://scripts/ui/tutorial_book.gd")
const FailureView = preload("res://scripts/ui/failure_feedback.gd")
const STORY_FONT: FontFile = preload("res://assets/fonts/CormorantSC-SemiBold.ttf")
const JUPITER_FONT: FontFile = preload("res://assets/fonts/jupiter_pro.otf")
const ANNOUNCEMENT_FONT_SIZE := 112

@onready var phase_label: Label = $PhasePanel/PhaseLabel
@onready var announcement: Control = $Announcement
@onready var announcement_label: Label = $Announcement/EdictLabel
@onready var announcement_halo: ColorRect = $Announcement/Halo
var result_panel: PanelContainer
var result_label: Label
var failure_feedback: FailureFeedback
@onready var card_presentation: CardPresentation = $CardPresentation

var _dust_effect: Node2D
var _intro_generation := 0
var _dust_tween: Tween
var _phase_number := 0
var tutorial_book: TutorialBook
var _consulting := false
var book_button: TextureButton
var _book_hover: Tween


func _ready() -> void:
	_build_book_button()
	tutorial_book = TutorialBookScene.new()
	tutorial_book.name = "TutorialBook"
	add_child(tutorial_book)
	failure_feedback = FailureView.new()
	failure_feedback.name = "FailureFeedback"
	add_child(failure_feedback)
	result_panel = failure_feedback.panel
	result_label = failure_feedback.body
	announcement.visible = false
	failure_feedback.cancel()
	announcement_label.add_theme_font_override("font", STORY_FONT)
	announcement_label.add_theme_font_size_override("font_size", ANNOUNCEMENT_FONT_SIZE)


func set_phase(phase_number: int, _phase_data: Dictionary, _phase_seed: int) -> void:
	_intro_generation += 1
	_release_reading()
	tutorial_book.cancel()
	_phase_number = phase_number
	if phase_number <= PhaseManager.LAST_PLAYABLE_PHASE: tutorial_book.unlock_to(phase_number)
	announcement.hide()
	phase_label.text = ""
	# A apresentação fica concentrada nos éditos inferiores e nas telas de resultado.
	failure_feedback.cancel()
	_clear_dust()
	card_presentation.cancel()


func _exit_tree() -> void:
	_intro_generation += 1
	if is_instance_valid(tutorial_book): tutorial_book.cancel()
	if is_instance_valid(card_presentation): card_presentation.cancel()
	if is_instance_valid(failure_feedback): failure_feedback.cancel()
	_clear_dust()
	if _consulting: get_tree().paused = false


func play_phase_intro(values: Array) -> void:
	var run_id := _intro_generation
	var read_ok := await tutorial_book.present(_phase_number)
	if not read_ok or run_id != _intro_generation:
		return
	await card_presentation.present(values)


func play_balance_intro() -> bool:
	var run_id := _intro_generation
	var read_ok := await tutorial_book.present(6)
	return read_ok and run_id == _intro_generation


func _release_reading() -> void:
	if _consulting:
		get_tree().paused = false
		_consulting = false
	tutorial_book.process_mode = Node.PROCESS_MODE_INHERIT
	tutorial_book.consultation = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_N:
		var player := get_parent().get_node_or_null("World/Player") as GridPlayer
		if _phase_number in range(1, 7) and not get_tree().paused and not tutorial_book.visible and player != null and player.input_enabled:
			get_viewport().set_input_as_handled()
			_consult_book()


func _consult_book() -> void:
	var player := get_parent().get_node_or_null("World/Player") as GridPlayer
	if _phase_number not in range(1, 7) or _consulting or tutorial_book.visible or failure_feedback.screen.visible or get_tree().paused or player == null or not player.input_enabled: return
	var run_id := _intro_generation
	_consulting = true
	book_button.hide()
	get_tree().paused = true
	tutorial_book.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_book.consultation = true
	var read_ok := await tutorial_book.present(0 if _phase_number in [7, 8] else _phase_number, true)
	if not read_ok or run_id != _intro_generation: return
	_release_reading()


func _process(_delta: float) -> void:
	if not is_instance_valid(book_button) or not is_instance_valid(tutorial_book): return
	var player := get_parent().get_node_or_null("World/Player") as GridPlayer
	book_button.visible = _phase_number in range(1, 7) and player != null and player.input_enabled and not tutorial_book.visible and not failure_feedback.screen.visible and not card_presentation.visible and not get_tree().paused


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


func show_failure(reasons: Array, button_text := "Tentar novamente") -> bool:
	announcement.hide()
	book_button.hide()
	return await failure_feedback.present(reasons, _failure_guidance(reasons), button_text)


func _failure_guidance(reasons: Array) -> String:
	var text := " ".join(PackedStringArray(reasons)).to_lower()
	if _phase_number == 6:
		return "Antes de o tabuleiro inclinar, procure o lado mais leve."
	if "distância" in text:
		return "Voltar pelo mesmo caminho gasta passos, mas não aumenta a distância do começo."
	if "atacou" in text:
		return "As torres atacam em linha reta. Observe onde vão parar." if _phase_number <= 4 else "As torres atacam em linha reta; os bispos, pelas diagonais. Observe onde vão parar."
	if "iluminada" in text:
		return "Planeje o caminho para terminar na casa iluminada."
	return "Observe os números e ajuste sua resposta. Você pode tentar de novo."


func show_success() -> void:
	failure_feedback.cancel()
	await _play_announcement("FASE CONCLUÍDA")


func show_restart() -> void:
	failure_feedback.cancel()


func _clear_dust() -> void:
	if _dust_tween != null:
		_dust_tween.kill()
		_dust_tween = null
	if is_instance_valid(_dust_effect):
		_dust_effect.queue_free()
	_dust_effect = null
