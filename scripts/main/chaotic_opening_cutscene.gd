class_name ChaoticOpeningCutscene
extends Node3D


signal finished
const Departure := preload("res://scripts/characters/queen_departure.gd")
const SURFACE := preload("res://shaders/queen_simulation_surface.gdshader")
const DUST := preload("res://shaders/simulation_reconstruction_dust.gdshader")
const VOICE_TIME := 3.1
const SWITCH_TIME := 6.6
const REBUILD_END := 11.4
const QUEEN_START := 7.0
const QUEEN_END := 13.6
const TOTAL_LENGTH := 28.5

@export_range(0.1,2.0,0.05) var duration_scale := 1.0
@onready var camera: Camera3D = $CinematicCamera
@onready var tiles: ColorRect = $Overlay/Tiles
@onready var fade: ColorRect = $Overlay/Fade
@onready var bars: Control = $Overlay/Bars
@onready var voice: AudioStreamPlayer = $Announcement
@onready var score: AudioStreamPlayer = $Score
@onready var reconstruction_sound: AudioStreamPlayer = $ReconstructionSound
var _main: Node
var _queen: Node3D
var _player: GridPlayer
var _model: Node3D
var _rig: BoardOrbitCamera
var _echo: QueenDeparture
var _grid: MeshInstance3D
var _grid_material: ShaderMaterial
var _materials: Array[Dictionary] = []
var _special_materials: Array[ShaderMaterial] = []
var _elapsed := 0.0
var _running := false
var _preparing := false
var _capturing := false
var _world_switched := false
var _voice_started := false
var _target_phase := 101
var _generation := 0
var _queen_was_processing := true
var _music_level := -12.0
var _head := Vector3.ZERO
var _handoff: Tween

func _ready() -> void:
	_main = get_parent()
	_queen = _main.get_node("World/Seraph")
	_player = _main.get_node("World/Player")
	_model = _player.get_node("Model")
	_rig = _main.get_node("World/BoardCamera")
	tiles.hide()
	bars.hide()
	fade.modulate.a = 0.0
	set_process(false)

func is_active() -> bool:
	return _running or _preparing

func cover_entry() -> void:

	fade.modulate.a = 1.0

func play(target_phase := 101) -> void:
	if is_active(): return
	if not PhaseManager.Savage.contains(target_phase) or not PhaseManager.can_start_phase(target_phase): return
	_generation += 1
	var run_id := _generation
	_target_phase = target_phase
	_preparing = true
	_music_level = _main.music.volume_db
	_main.game_audio.stop_effects()
	_player.set_input_enabled(false)
	_main.get_node("CardTrialController").active = false
	if _main.phase_manager.current_phase == 0:
		cover_entry()
		_main.music.stop()
		_begin_story()
		return
	_handoff = create_tween().set_parallel(true)
	_handoff.tween_property(_main.music,"volume_db",-65.0,0.65)
	_handoff.tween_property(fade,"modulate:a",1.0,0.35).set_delay(0.3)
	await _handoff.finished
	if run_id != _generation or not is_inside_tree(): return
	_main.music.stop()
	_begin_story()

func _begin_story() -> void:
	_preparing = false
	_running = true
	_elapsed = 0.0
	_capturing = false
	_world_switched = false
	_voice_started = false
	(tiles.material as ShaderMaterial).set_shader_parameter("progress",0.0)
	_main.get_node("SavageController").effects.set_active(false)
	_main.get_node("HUD").hide()
	var cards: CardTrialController = _main.get_node("CardTrialController")
	cards.active = false
	cards.table.hide()
	cards.space_transition.leave_space()
	var board: Board3D = _main.get_node("World/Board")
	board.rotation = Vector3.ZERO
	board.state.clear_dynamic_occupants()
	board.clear_tutorial_path()
	board.set_safe_spot_visible(false)
	_player.starting_cell = Vector2i(2,2)
	_player.reset_to_start()
	_player.set_input_enabled(false)
	_player.set_physics_process(false)
	_player.set_process_unhandled_input(false)
	_player.global_position += Vector3(0,0,-13.9)
	_player.show()
	_model.begin_cinematic_idle()
	_model.set_cinematic_look_up(0.55)
	_queen_was_processing = _queen.is_processing()
	_queen.set_process(false)
	_queen.set_balance_mode(false)
	_queen._snap_head_to_player()
	_queen.show()
	_head = _queen._skeleton.to_global(_queen._skeleton.get_bone_global_pose(_queen._skeleton.find_bone("head")).origin)
	_echo = Departure.new()
	_echo.name = "VanillaConstellation"
	add_child(_echo)
	_echo.configure(_queen)
	_echo.set_dissolve_age(40.0)
	_echo.restore()
	for index in range(_echo._motes.size()):
		var dust := _echo._motes[index]
		dust.shader = DUST
		dust.set_shader_parameter("source_texture",Departure.STARS)
		dust.set_shader_parameter("trails",index==1)
		dust.set_shader_parameter("simulation_progress",0.0)
		dust.set_shader_parameter("envelope",0.0)
	_queen.hide()
	_build_grid()
	_rig.begin_cinematic()
	bars.show()
	_update_camera(0.0)
	camera.make_current()
	score.pitch_scale = 1.0/duration_scale
	voice.pitch_scale = 1.0/duration_scale
	reconstruction_sound.pitch_scale = 1.0/duration_scale
	score.volume_db = _music_level+6.0
	voice.volume_db = -2.0+_main.game_audio.effects_volume_db
	reconstruction_sound.volume_db = -13.0+_main.game_audio.effects_volume_db
	score.play()
	set_process(true)

func _build_grid() -> void:
	_grid = MeshInstance3D.new()
	_grid.name = "SimulationLattice"
	var plane := PlaneMesh.new()
	plane.size = Vector2(39,39)
	_grid.mesh = plane
	_grid.position = _main.get_node("World/Board").global_position+Vector3.UP*0.065
	_grid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_grid_material = ShaderMaterial.new()
	_grid_material.shader = preload("res://shaders/simulation_grid.gdshader")
	_grid.material_override = _grid_material
	add_child(_grid)

func _process(delta: float) -> void:
	if not _running or _capturing: return
	_elapsed = minf(_elapsed+delta/duration_scale,TOTAL_LENGTH)
	_update_story(_elapsed)
	if _elapsed>=TOTAL_LENGTH: _finish()

func _update_story(t: float) -> void:
	_update_camera(t)
	if t>=VOICE_TIME and not _voice_started:
		_voice_started = true
		voice.play()
	if t>=SWITCH_TIME and not _world_switched:
		_world_switched = true
		if DisplayServer.get_name()=="headless": _activate_simulation()
		else:
			_capturing = true
			_capture_transition(_generation)
			return
	var progress := clampf((t-SWITCH_TIME)/(REBUILD_END-SWITCH_TIME),0.0,1.0)
	var queen_progress := smoothstep(QUEEN_START,QUEEN_END,t) if _world_switched else 0.0
	if _world_switched and not _capturing:
		(tiles.material as ShaderMaterial).set_shader_parameter("progress",progress)
		(tiles.material as ShaderMaterial).set_shader_parameter("effect_time",t-SWITCH_TIME)
		tiles.visible = t<REBUILD_END
		for entry in _materials: entry.material.set_shader_parameter("simulation_progress",queen_progress)
		for material in _special_materials: material.set_shader_parameter("simulation_progress",queen_progress)
		for dust in _echo._motes:
			dust.set_shader_parameter("simulation_progress",queen_progress)
			dust.set_shader_parameter("effect_time",t-QUEEN_START)
			dust.set_shader_parameter("envelope",smoothstep(QUEEN_START,QUEEN_START+0.3,t))
		var fire = _main.get_node("SavageController").effects._fire
		if is_instance_valid(fire): fire.visible = queen_progress>0.72
		if queen_progress>=1.0 and not _materials.is_empty(): _restore_materials()
	var echo_presence := 1.0-smoothstep(SWITCH_TIME,QUEEN_END,t)
	if is_instance_valid(_echo):
		_echo._nebula_material.set_shader_parameter("envelope",echo_presence)
		_echo._cluster_material.set_shader_parameter("envelope",echo_presence)
	_grid_material.set_shader_parameter("effect_time",t-3.0)
	_grid_material.set_shader_parameter("red_mix",progress)
	_grid_material.set_shader_parameter("envelope",smoothstep(4.4,6.3,t)*(1.0-smoothstep(12.5,15.0,t)))
	fade.modulate.a = maxf(1.0-smoothstep(0.0,1.2,t),smoothstep(TOTAL_LENGTH-0.6,TOTAL_LENGTH,t))
	score.volume_db = _music_level+6.0+linear_to_db(maxf(1.0-smoothstep(25.0,TOTAL_LENGTH,t),0.0001))

func _capture_transition(run_id: int) -> void:
	await RenderingServer.frame_post_draw
	if run_id != _generation or not _running: return
	var previous := ImageTexture.create_from_image(get_viewport().get_texture().get_image())
	(tiles.material as ShaderMaterial).set_shader_parameter("previous_frame",previous)
	_activate_simulation()
	tiles.show()
	_capturing = false

func _activate_simulation() -> void:
	_queen.show()
	_main.get_node("SavageController").effects.set_active(true)
	_main.get_node("SavageController").effects._fire.hide()


	for mesh: MeshInstance3D in _queen.get_node("Model").find_children("*","MeshInstance3D",true,false):
		if not mesh.is_visible_in_tree(): continue
		for surface in range(mesh.mesh.get_surface_count()):
			var original := mesh.get_active_material(surface)
			if original is StandardMaterial3D:
				var material := _echo._surface_material(original)
				material.shader = SURFACE
				material.set_shader_parameter("simulation_progress",0.0)
				_materials.append({"mesh":mesh,"surface":surface,"original":mesh.get_surface_override_material(surface),"material":material})
				mesh.set_surface_override_material(surface,material)
			elif original is ShaderMaterial:
				original.set_shader_parameter("simulation_progress",0.0)
				_special_materials.append(original)
	reconstruction_sound.play()

func _restore_materials() -> void:
	for entry in _materials:
		if is_instance_valid(entry.mesh): entry.mesh.set_surface_override_material(entry.surface,entry.original)
	_materials.clear()
	for material in _special_materials: material.set_shader_parameter("simulation_progress",1.0)
	_special_materials.clear()

func _shot(t: float,start: float,end: float,from: Vector3,to: Vector3,focus: Vector3,fov: float) -> void:
	camera.global_position = from.lerp(to,smoothstep(start,end,t))
	camera.look_at(focus,Vector3.UP)
	camera.fov = fov

func _update_camera(t: float) -> void:
	if t<SWITCH_TIME:
		_shot(t,0,SWITCH_TIME,Vector3(0,20,39),Vector3(0,21,36),Vector3(0,7,-18),60)
	elif t<QUEEN_END+0.5:
		_shot(t,0,1,Vector3(0,21,36),Vector3(0,21,36),Vector3(0,7,-18),60)
	elif t<22.0:
		_shot(t,QUEEN_END+0.5,22.0,_head+Vector3(-19,3,32),_head+Vector3(-15,4,29),_head+Vector3(0,2,0),49)
	else:
		_shot(t,22,TOTAL_LENGTH,Vector3(27,15,20),Vector3(23,16,22),Vector3(0,3,-16),53)

func _stop_audio() -> void:
	voice.stop()
	score.stop()
	reconstruction_sound.stop()

func _clear_geometry() -> void:
	_restore_materials()
	if is_instance_valid(_echo):
		_echo.queue_free()
		_echo = null
	if is_instance_valid(_grid):
		_grid.queue_free()
		_grid = null
	tiles.hide()
	(tiles.material as ShaderMaterial).set_shader_parameter("previous_frame",null)

func _finish() -> void:
	_running = false
	set_process(false)
	_clear_geometry()
	_stop_audio()
	_queen.set_process(_queen_was_processing)
	_model.stop_intro_looking()
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_rig.enter_gameplay(true)
	_rig.camera.make_current()
	bars.hide()
	_main.music.volume_db = _music_level
	_main.phase_manager.start_phase(_target_phase)
	_main.get_node("HUD").show()
	_handoff = create_tween()
	_handoff.tween_interval(0.12)
	_handoff.tween_property(fade,"modulate:a",0.0,0.65)
	_handoff.tween_callback(func(): finished.emit())

func cancel() -> void:
	_generation += 1
	_preparing = false
	_running = false
	_capturing = false
	if _handoff != null and _handoff.is_valid(): _handoff.kill()
	set_process(false)
	_stop_audio()
	_clear_geometry()
	_main.get_node("SavageController").effects.set_active(false)
	_queen.show()
	_queen.set_process(_queen_was_processing)
	_model.stop_intro_looking()
	_player.set_physics_process(true)
	_player.set_process_unhandled_input(true)
	_main.get_node("HUD").show()
	_main.music.volume_db = _music_level
	if not _main.music.playing: _main.music.play()
	_rig.enter_gameplay(true)
	_rig.camera.make_current()
	bars.hide()
	fade.modulate.a = 0.0
