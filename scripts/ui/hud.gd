class_name GameHUD
extends CanvasLayer

const Constants = preload("res://scripts/core/game_constants.gd")
const EdictDust = preload("res://scripts/ui/edict_dust.gd")
const DUNE_FONT: FontFile = preload("res://assets/fonts/dune_rise.otf")
const JUPITER_FONT: FontFile = preload("res://assets/fonts/jupiter_pro.otf")
const ANNOUNCEMENT_FONT_SIZE := 112
const ROUND_EDICT_FONT_SIZE := 62

@onready var phase_label: Label = $PhasePanel/PhaseLabel
@onready var tutorial_hint: Label = $TutorialHint
@onready var announcement: Control = $Announcement
@onready var announcement_label: Label = $Announcement/EdictLabel
@onready var announcement_halo: ColorRect = $Announcement/Halo
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/ResultLabel
@onready var round_edicts: Label = $RoundEdicts

var _dust_effect: Node2D
var _intro_generation := 0
var _dust_tween: Tween
var _phase_number := 0
var _opening_shown := false
var _round_edicts_home_position := Vector2.ZERO


func _ready() -> void:
	announcement.visible = false
	result_panel.visible = false
	announcement_label.add_theme_font_override("font", DUNE_FONT)
	announcement_label.add_theme_font_size_override("font_size", ANNOUNCEMENT_FONT_SIZE)
	round_edicts.add_theme_font_override("font", JUPITER_FONT)
	round_edicts.add_theme_font_size_override("font_size", ROUND_EDICT_FONT_SIZE)
	_round_edicts_home_position = round_edicts.position


func set_phase(phase_number: int, _phase_data: Dictionary, _phase_seed: int) -> void:
	_intro_generation += 1
	_phase_number = phase_number
	phase_label.text = ""
	# A apresentação fica concentrada nos éditos inferiores e nas telas de resultado.
	tutorial_hint.visible = false
	result_panel.visible = false
	_clear_dust()
	round_edicts.visible = false
	round_edicts.modulate = Color.WHITE
	round_edicts.position = _round_edicts_home_position


func play_phase_intro(values: Array) -> void:
	var run_id := _intro_generation
	if _phase_number == 1 and not _opening_shown:
		await _play_announcement("INÍCIO")
		if run_id != _intro_generation:
			return
		_opening_shown = true
	var parts: PackedStringArray = []
	for value in values:
		parts.append(Constants.to_roman(int(value)))
	var roman_text := "  +  ".join(parts)
	round_edicts.text = roman_text
	await _play_announcement(roman_text, true)
	if run_id != _intro_generation:
		return
	round_edicts.visible = true


func _play_announcement(text_value: String, transfer_to_round_edicts := false) -> void:
	var run_id := _intro_generation
	var uses_roman_font := _is_roman_text(text_value)
	announcement_label.add_theme_font_override("font", JUPITER_FONT if uses_roman_font else DUNE_FONT)
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
	if transfer_to_round_edicts:
		round_edicts.visible = true
		round_edicts.modulate = Color(1, 1, 1, 0)
		round_edicts.position = _round_edicts_home_position - Vector2(160.0, 0.0)
		vanish.tween_property(round_edicts, "position", _round_edicts_home_position, 0.72).set_delay(0.66).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		vanish.tween_property(round_edicts, "modulate", Color.WHITE, 0.48).set_delay(0.72).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await vanish.finished
	if run_id != _intro_generation:
		return
	announcement.visible = false
	announcement_label.visible = true
	announcement_label.visible_ratio = 1.0
	announcement_halo.modulate.a = 1.0
	if transfer_to_round_edicts:
		round_edicts.position = _round_edicts_home_position
		round_edicts.modulate = Color.WHITE
	_clear_dust()


func _is_roman_text(text_value: String) -> bool:
	var compact := text_value.replace(" ", "").replace("+", "")
	if compact.is_empty():
		return false
	for character in compact:
		if character not in "IVXLCDM":
			return false
	return true


func show_failure(motivos: Array) -> void:
	result_label.text = "TENTE NOVAMENTE\n%s" % " ".join(motivos)
	result_label.add_theme_color_override("font_color", Color.WHITE)
	_show_result_panel()


func show_success() -> void:
	result_panel.visible = false
	await _play_announcement("FASE CONCLUÍDA")


func show_restart() -> void:
	result_panel.visible = false


func hide_tutorial_hint() -> void:
	tutorial_hint.visible = false


func _show_result_panel() -> void:
	result_panel.visible = true
	result_panel.modulate = Color(1, 1, 1, 0)
	result_panel.scale = Vector2(0.90, 0.90)
	result_panel.pivot_offset = result_panel.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_panel, "scale", Vector2.ONE, 0.32)
	tween.tween_property(result_panel, "modulate", Color.WHITE, 0.22)


func _clear_dust() -> void:
	if _dust_tween != null:
		_dust_tween.kill()
		_dust_tween = null
	if is_instance_valid(_dust_effect):
		_dust_effect.queue_free()
	_dust_effect = null
