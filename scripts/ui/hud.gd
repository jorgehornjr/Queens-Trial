class_name GameHUD
extends CanvasLayer

signal position_confirmed

const EdictDust = preload("res://scripts/ui/edict_dust.gd")
const TutorialBookScene = preload("res://scripts/ui/tutorial_book.gd")
const FailureView = preload("res://scripts/ui/failure_feedback.gd")
const Atlas = preload("res://scripts/ui/roman_star_map.gd")
const BOOK_ICON: Texture2D = preload("res://assets/ui/hud/moon_book.tres")
const ATLAS_ICON: Texture2D = preload("res://assets/ui/hud/roman_atlas.tres")
const ICON_CUTOUT: Shader = preload("res://shaders/hud_paper_cutout.gdshader")
const STORY_FONT: FontFile = preload("res://assets/fonts/CormorantSC-SemiBold.ttf")
const JUPITER_FONT: FontFile = preload("res://assets/fonts/jupiter_pro.otf")
const ANNOUNCEMENT_FONT_SIZE := 112

@onready var phase_label: Label = $PhasePanel/PhaseLabel
@onready var announcement: Control = $Announcement
@onready var announcement_label: Label = $Announcement/EdictLabel
@onready var announcement_halo: ColorRect = $Announcement/Halo
var result_panel: PanelContainer
var failure_feedback: FailureFeedback
@onready var card_presentation: CardPresentation = $CardPresentation

var _dust_effect: Node2D
var _intro_generation := 0
var _dust_tween: Tween
var _phase_number := 0
var _chapter := 0
var _board_trial := false
var _chaotic_trial := false
var tutorial_book: TutorialBook
var _consulting := false
var book_button: TextureButton
var atlas_button: TextureButton
var roman_map: RomanStarMap
var _book_hover: Tween
var _atlas_hover: Tween
var _preparing := false


func _ready() -> void:
	_build_book_button()
	roman_map = Atlas.new() as RomanStarMap
	roman_map.name = "RomanStarMap"
	roman_map.z_index = 50
	add_child(roman_map)
	tutorial_book = TutorialBookScene.new()
	tutorial_book.name = "TutorialBook"
	add_child(tutorial_book)
	failure_feedback = FailureView.new()
	failure_feedback.name = "FailureFeedback"
	add_child(failure_feedback)
	result_panel = failure_feedback.panel
	announcement.visible = false
	failure_feedback.cancel()
	announcement_label.add_theme_font_override("font", STORY_FONT)
	announcement_label.add_theme_font_size_override("font_size", ANNOUNCEMENT_FONT_SIZE)


func set_phase(phase_number: int, _phase_data: Dictionary, _phase_seed: int) -> void:
	_intro_generation += 1
	end_preparation()
	_release_reading()
	roman_map.cancel()
	tutorial_book.cancel()
	_phase_number = phase_number
	_chapter = int(_phase_data.get("tutorial_chapter", 0))
	_board_trial = String(_phase_data.get("resolution", "")) in ["moves", "balance"]
	_chaotic_trial = PhaseManager.Savage.contains(phase_number)
	if _chaotic_trial:
		_chapter = 7
		tutorial_book.unlock_to(7)
	failure_feedback.chaotic_style = _chaotic_trial
	book_button.offset_left = -118
	book_button.offset_right = -30
	atlas_button.offset_left = -218
	atlas_button.offset_right = -130
	if _board_trial: tutorial_book.unlock_to(_chapter if _chapter > 0 else (6 if _phase_data.resolution == "balance" else 5))
	announcement.hide()
	phase_label.text = ""

	failure_feedback.cancel()
	_clear_dust()
	card_presentation.cancel()


func _exit_tree() -> void:
	_intro_generation += 1
	if is_instance_valid(roman_map): roman_map.cancel()
	if is_instance_valid(tutorial_book): tutorial_book.cancel()
	if is_instance_valid(card_presentation): card_presentation.cancel()
	if is_instance_valid(failure_feedback): failure_feedback.cancel()
	_clear_dust()
	if _consulting: get_tree().paused = false


func play_phase_intro(values: Array) -> void:
	var run_id := _intro_generation
	var can_present := true
	if _chapter > 0:
		can_present = await tutorial_book.present(_chapter)
	if can_present and run_id == _intro_generation:
		await card_presentation.present(values)


func play_balance_intro() -> bool:
	var run_id := _intro_generation
	var read_ok := await tutorial_book.present(6)
	return read_ok and run_id == _intro_generation


func play_chaotic_intro() -> bool:
	var run_id := _intro_generation
	if not tutorial_book.needs_chapter(7): return true
	var read_ok := await tutorial_book.present(7, true)
	return read_ok and run_id == _intro_generation


func _release_reading() -> void:
	if _consulting:
		get_tree().paused = false
		_consulting = false
	tutorial_book.process_mode = Node.PROCESS_MODE_INHERIT
	tutorial_book.consultation = false


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo): return
	if _preparing and event.keycode in [KEY_ENTER, KEY_KP_ENTER] and _reference_available():
		get_viewport().set_input_as_handled()
		position_confirmed.emit()
	elif event.keycode == KEY_N and _reference_available() and (_board_trial or _chaotic_trial):
		get_viewport().set_input_as_handled()
		_consult_book()
	elif event.keycode == KEY_M and not _chaotic_trial and _reference_available():
		get_viewport().set_input_as_handled()
		show_roman_map()


func show_roman_map(guided := false) -> bool:
	if _consulting or tutorial_book.visible or roman_map.visible or get_tree().paused: return false
	if not guided and (_chaotic_trial or not _reference_available()): return false
	# A ordem dos irmãos define os cliques dos modais, independentemente do z_index.

	move_child(roman_map, get_child_count() - 1)
	var run_id := _intro_generation
	_consulting = true
	book_button.hide()
	atlas_button.hide()
	get_tree().paused = true
	var completed := await roman_map.present(guided)
	if not is_inside_tree() or run_id != _intro_generation: return false
	_release_reading()
	return completed


func _consult_book() -> void:
	var player := get_parent().get_node_or_null("World/Player") as GridPlayer
	if not (_board_trial or _chaotic_trial) or _consulting or tutorial_book.visible or failure_feedback.screen.visible or get_tree().paused or player == null or not player.input_enabled: return
	var run_id := _intro_generation
	_consulting = true
	book_button.hide()
	atlas_button.hide()
	get_tree().paused = true
	tutorial_book.process_mode = Node.PROCESS_MODE_ALWAYS
	tutorial_book.consultation = true
	var read_ok := await tutorial_book.present(_chapter if _chapter > 0 else tutorial_book.unlocked_chapter, true)
	if not read_ok or run_id != _intro_generation: return
	_release_reading()


func _process(_delta: float) -> void:
	if not is_instance_valid(book_button) or not is_instance_valid(tutorial_book): return
	var available := _reference_available()
	book_button.visible = available and (_board_trial or _chaotic_trial)
	atlas_button.visible = available and not _chaotic_trial


func begin_preparation() -> void:
	_preparing = true


func end_preparation() -> void:
	_preparing = false


func _reference_available() -> bool:
	if _phase_number <= 0 or _consulting or get_tree().paused or tutorial_book.visible or roman_map.visible or failure_feedback.screen.visible or card_presentation.visible: return false
	var manager := get_parent().get_node_or_null("PhaseManager") as PhaseManager
	if manager == null or manager.campaign_finished: return false
	var player := get_parent().get_node_or_null("World/Player") as GridPlayer
	if _board_trial or _chaotic_trial: return player != null and player.input_enabled
	var cards := get_parent().get_node_or_null("CardTrialController") as CardTrialController
	return cards != null and cards.active and cards.table.visible and not cards._advancing and not cards._feedback_pending


func _build_book_button() -> void:
	book_button = TextureButton.new()
	book_button.name = "OpenTutorialBook"
	book_button.texture_normal = BOOK_ICON
	book_button.material = ShaderMaterial.new()
	(book_button.material as ShaderMaterial).shader = ICON_CUTOUT
	book_button.ignore_texture_size = true
	book_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	book_button.focus_mode = Control.FOCUS_NONE
	book_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	book_button.tooltip_text = "Livro de tutoriais (N)"
	book_button.visible = false
	add_child(book_button)
	book_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	book_button.offset_left = -118
	book_button.offset_right = -30
	book_button.offset_top = 24
	book_button.offset_bottom = 112
	book_button.pivot_offset = Vector2(44, 44)
	book_button.pressed.connect(_consult_book)
	book_button.mouse_entered.connect(_hover_book.bind(true))
	book_button.mouse_exited.connect(_hover_book.bind(false))
	atlas_button = TextureButton.new()
	atlas_button.name = "OpenRomanAtlas"
	atlas_button.texture_normal = ATLAS_ICON
	atlas_button.material = ShaderMaterial.new()
	(atlas_button.material as ShaderMaterial).shader = ICON_CUTOUT
	atlas_button.ignore_texture_size = true
	atlas_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	atlas_button.focus_mode = Control.FOCUS_NONE
	atlas_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	atlas_button.tooltip_text = "Atlas de números romanos (M)"
	atlas_button.visible = false
	add_child(atlas_button)
	atlas_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	atlas_button.offset_left = -218
	atlas_button.offset_right = -130
	atlas_button.offset_top = 24
	atlas_button.offset_bottom = 112
	atlas_button.pivot_offset = Vector2(44, 44)
	atlas_button.pressed.connect(func(): show_roman_map())
	atlas_button.mouse_entered.connect(_hover_atlas.bind(true))
	atlas_button.mouse_exited.connect(_hover_atlas.bind(false))


func _hover_book(hovered: bool) -> void:
	if _book_hover != null and _book_hover.is_valid(): _book_hover.kill()
	_book_hover = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_book_hover.tween_property(book_button, "scale", Vector2.ONE * (1.04 if hovered else 1.0), 0.18)


func _hover_atlas(hovered: bool) -> void:
	if _atlas_hover != null and _atlas_hover.is_valid(): _atlas_hover.kill()
	_atlas_hover = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_atlas_hover.tween_property(atlas_button, "scale", Vector2.ONE * (1.08 if hovered else 1.0), 0.18)


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


func show_failure(reasons: Array, button_text := "Tentar novamente", auto_seconds := 0.0) -> bool:
	announcement.hide()
	book_button.hide()
	return await failure_feedback.present(reasons, _failure_guidance(reasons), button_text, auto_seconds)


func _failure_guidance(reasons: Array) -> String:
	var text := " ".join(PackedStringArray(reasons)).to_lower()
	if _board_trial and _phase_number in range(8, 11):
		return "Antes de o tabuleiro inclinar, procure o lado mais leve."
	if "distância" in text:
		return "Some as casas na horizontal e na vertical entre o início e o destino. Um contorno pode gastar passos sem aumentar essa distância, mesmo sem repetir casas."
	if "atacou" in text:
		return "As torres atacam em linha reta. Observe onde vão parar." if _phase_number <= 4 else "As torres atacam em linha reta; os bispos, pelas diagonais. Observe onde vão parar."
	if "iluminada" in text:
		return "Planeje o caminho para terminar na casa iluminada."
	return "Observe os números e ajuste sua resposta. Você pode tentar de novo."


func show_success() -> void:
	failure_feedback.cancel()
	await _play_announcement("FASE CONCLUÍDA")


func _clear_dust() -> void:
	if _dust_tween != null:
		_dust_tween.kill()
		_dust_tween = null
	if is_instance_valid(_dust_effect):
		_dust_effect.queue_free()
	_dust_effect = null
