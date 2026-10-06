extends Node
## F6 opens the actual sixth encounter with the new model, skipping the intro.

const MAIN := preload("res://scenes/main/main.tscn")
@export var character_scene: PackedScene
var main: Node
var _request := 0
var _inspection_camera: Camera3D


func _ready() -> void:
	main = MAIN.instantiate()
	if character_scene != null:
		var player := main.get_node("World/Player")
		var previous := player.get_node("Model")
		player.remove_child(previous)
		previous.free()
		var model := character_scene.instantiate() as Node3D
		model.name = "Model"
		model.rotation_degrees = Vector3(0, 180, 0)
		model.scale = Vector3.ONE * 2.0
		player.add_child(model)
	main.opening_cutscene_enabled = false
	main.get_node("PhaseManager").initial_phase = 6
	main.get_node("PhaseManager").auto_start = true
	add_child(main)
	_inspection_camera = Camera3D.new()
	_inspection_camera.fov = 42
	main.get_node("World").add_child(_inspection_camera)
	_make_controls()


func _make_controls() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(24, 20)
	layer.add_child(panel)
	var label := Label.new()
	label.text = "Fandaniel • teste da fase 6"
	label.add_theme_font_size_override("font_size", 20)
	panel.add_child(label)
	var buttons := HBoxContainer.new()
	panel.add_child(buttons)
	for setup in [["1 · Queda esquerda", -1], ["2 · Queda direita", 1], ["3 · Jogar fase 6", 0]]:
		var button := Button.new()
		button.text = setup[0]
		button.pressed.connect(repeat_test.bind(int(setup[1])))
		buttons.add_child(button)
	var camera_button := Button.new()
	camera_button.text = "4 · Aproximar personagem"
	camera_button.pressed.connect(_toggle_camera)
	buttons.add_child(camera_button)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey:
		match event.physical_keycode:
			KEY_1: repeat_test(-1)
			KEY_2: repeat_test(1)
			KEY_3: repeat_test(0)
			KEY_4: _toggle_camera()


func _process(_delta: float) -> void:
	if _inspection_camera != null and _inspection_camera.current:
		var player := main.get_node("World/Player") as Node3D
		_inspection_camera.global_position = player.global_position + Vector3(7, 7, 17)
		_inspection_camera.look_at(player.global_position + Vector3.UP * 2.2)


func _toggle_camera() -> void:
	if _inspection_camera.current:
		main.get_node("World/BoardCamera/Camera3D").make_current()
	else:
		_inspection_camera.make_current()


func repeat_test(direction: int) -> void:
	_request += 1
	var request := _request
	var inspecting := _inspection_camera.current
	main.start_test_phase(6)
	if inspecting: _inspection_camera.make_current()
	if direction == 0: return
	var trial := main.get_node("BalanceTrialController") as BalanceTrialController
	while trial.stage != BalanceTrialController.Stage.DECISION:
		await get_tree().process_frame
		if request != _request: return
	trial._rounds = [[4, 1] if direction < 0 else [1, 4]]
	trial.round_index = 0
	trial._open_round()
	trial.remaining = 0.8
	var player := main.get_node("World/Player") as GridPlayer
	player.current_cell = Vector2i(2, 4)
	player.position = main.get_node("World/Board").grid_to_world(player.current_cell) + Vector3.UP * player.surface_offset
	player.get_node("Model").reset_platform_motion()
