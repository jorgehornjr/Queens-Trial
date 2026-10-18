class_name CardTrialController
extends Node

const State = preload("res://scripts/gameplay/card_trial_state.gd")
const Table = preload("res://scripts/ui/card_trial_hud.gd")
const Passage = preload("res://scripts/environment/card_space_transition.gd")
var state: CardTrialState
var table: CardTrialHUD
var active := false
var selected_value := 0
var space_transition: CardSpaceTransition
var _generation := 0
var _feedback_pending := false
var _manager: PhaseManager
var _hud: GameHUD
var _audio: GameAudio

func _ready() -> void:
	_manager = get_node("../PhaseManager")
	_hud = get_node("../HUD")
	_audio = get_node("../GameAudio")
	space_transition = Passage.new() as CardSpaceTransition
	space_transition.name = "CardSpaceTransition"
	add_child(space_transition)
	table = Table.new() as CardTrialHUD
	table.name = "CardTrialTable"
	_hud.add_child(table)
	_hud.move_child(_hud.book_button, _hud.get_child_count() - 1)
	_hud.move_child(_hud.tutorial_book, _hud.get_child_count() - 1)
	table.submitted.connect(_submit)
	table.continued.connect(_continue)
	table.slot_clicked.connect(_slot_clicked)
	table.card_dropped.connect(_drop)
	table.hand.selected.connect(_select)
	table.hand.returned.connect(_return_to_hand)
	_manager.phase_started.connect(_phase_started)

func _phase_started(number: int, _data: Dictionary, phase_seed: int) -> void:
	_generation += 1
	_feedback_pending = false
	active = number in [7, 8]
	table.hide()
	selected_value = 0
	if not active:
		space_transition.leave_space()
		return
	state = State.new()
	state.begin(number, phase_seed)
	_present.call_deferred(_generation)

func _present(run_id: int) -> void:
	if run_id != _generation: return
	var arrived := await space_transition.enter_space()
	if not arrived or run_id != _generation: return
	table.show_round(state)
	table.canvas.modulate.a = 0.0
	var reveal := table.create_tween()
	reveal.tween_property(table.canvas, "modulate:a", 1.0, 0.65)

func _select(value: int) -> void:
	if not active or state.solved or _feedback_pending: return
	selected_value = value
	table.feedback.text = ""

func _drop(index: int, value: int) -> void:
	if not active or _feedback_pending or not state.place(index, value): return
	selected_value = 0
	table.feedback.text = ""
	table.refresh(state)

func _return_to_hand(value: int) -> void:
	if not active or _feedback_pending or not state.remove(state.slots.find(value)): return
	selected_value = 0
	table.feedback.text = ""
	table.refresh(state)

func _slot_clicked(index: int) -> void:
	if not active or state.solved or _feedback_pending: return
	if state.kind == CardTrialState.Kind.FALSE_DECREE:
		_resolve(state.choose_false(index))
	elif selected_value > 0:
		_drop(index, selected_value)
	elif state.remove(index):
		table.feedback.text = ""
		table.refresh(state)

func _submit() -> void:
	if not active or state.solved or _feedback_pending: return
	_resolve(state.check())

func _resolve(result: Dictionary) -> void:
	if result.correct:
		table.show_feedback(result)
		_audio.play_effect(&"round_success")
		return
	_feedback_pending = true
	var run_id := _generation
	_audio.play_effect(&"fail")
	await _hud.show_failure([result.message], "Continuar")
	if run_id != _generation: return
	_feedback_pending = false
	table.feedback.text = ""

func _continue() -> void:
	if not active and state != null and state.solved and state.phase_number == 8:
		_manager.restart_phase()
		return
	if not active or not state.solved: return
	selected_value = 0
	if state.next_round():
		table.show_round(state)
		return
	active = false
	table.show_transition()
	var run_id := _generation
	var completed_phase := state.phase_number
	_audio.play_effect(&"next_phase")
	await get_tree().create_timer(0.65, false).timeout
	if run_id == _generation:
		_manager.advance_phase()
		if completed_phase == 8: table.show_completed()

func _unhandled_input(event: InputEvent) -> void:
	if active and event.is_action_pressed("restart_phase"):
		_manager.restart_phase()
		get_viewport().set_input_as_handled()
