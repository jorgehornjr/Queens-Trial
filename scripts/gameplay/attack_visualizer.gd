class_name AttackVisualizer
extends Node3D

const RIFT_SHADER = preload("res://shaders/attack_rift.gdshader")
const SPARK_SHADER = preload("res://shaders/astral_spark.gdshader")
const SquareAura = preload("res://scripts/gameplay/square_aura.gd")
const QUEEN_GOLD := Color(0.82, 0.58, 0.21, 0.78)
const QUEEN_GOLD_HOT := Color(1.0, 0.86, 0.52, 1.0)

var _board: Board3D
var _active_markers: Array[Node3D] = []
var _tweens: Array[Tween] = []
var _generation := 0


func configure(board: Board3D) -> void:
	_board = board


func play_attack(cells: Array[Vector2i], origins: Array[Vector2i], attack_paths: Array = []) -> void:
	clear()
	var run_id := _generation
	if _board == null or cells.is_empty():
		await get_tree().create_timer(0.22).timeout
		return

	_create_attack_beams(cells, origins, attack_paths)
	for origin in origins:
		var burst := _create_impact_sparks(origin)
		add_child(burst)
		_active_markers.append(burst)

	var ordered := cells.duplicate()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return _nearest_distance(a, origins) < _nearest_distance(b, origins)
	)
	for index in range(ordered.size()):
		var marker := _create_cell_marker(ordered[index], index)
		_active_markers.append(marker)
		var delay := minf(float(_nearest_distance(ordered[index], origins)) * 0.075, 0.42)
		var tween := create_tween()
		_tweens.append(tween)
		tween.tween_interval(delay)
		tween.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(marker, "reveal", 1.0, 0.26)

	await get_tree().create_timer(1.0).timeout
	if run_id != _generation:
		return
	for marker in _active_markers:
		if not is_instance_valid(marker):
			continue
		var flare := create_tween()
		_tweens.append(flare)
		flare.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
		if marker.get_script() == SquareAura:
			flare.tween_property(marker, "reveal", 0.0, 0.48)
		else:
			var material := _marker_material(marker)
			if material != null:
				flare.tween_method(func(value: float): material.set_shader_parameter("reveal", value), 1.0, 0.0, 0.48)
			else:
				flare.kill()
	await get_tree().create_timer(0.52).timeout
	if run_id == _generation:
		clear()


func clear() -> void:
	_generation += 1
	for tween in _tweens:
		tween.kill()
	_tweens.clear()
	for marker in _active_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_active_markers.clear()


func _create_cell_marker(cell: Vector2i, index: int) -> Node3D:
	var marker := SquareAura.new()
	marker.name = "Attack_%d_%d" % [cell.x, cell.y]
	marker.position = _board.grid_to_world(cell) + Vector3(0.0, 0.205, 0.0)
	marker.reveal = 0.0
	marker.configure(_board.tile_size * 1.04, QUEEN_GOLD, 1.15, float(index) * 0.43, false, QUEEN_GOLD_HOT)
	add_child(marker)
	return marker


func _create_attack_beams(cells: Array[Vector2i], origins: Array[Vector2i], attack_paths: Array) -> void:
	var beam_index := 0
	for origin_index in range(origins.size()):
		var origin := origins[origin_index]
		var source_cells: Array = attack_paths[origin_index] if origin_index < attack_paths.size() else cells
		var furthest := {}
		for cell in source_cells:
			var delta: Vector2i = cell - origin
			if delta == Vector2i.ZERO:
				continue
			if delta.x != 0 and delta.y != 0 and absi(delta.x) != absi(delta.y):
				continue
			var direction := Vector2i(signi(delta.x), signi(delta.y))
			if not furthest.has(direction) or delta.length_squared() > (furthest[direction] as Vector2i).length_squared():
				furthest[direction] = delta
		for direction in furthest:
			var beam := _create_beam(origin, origin + furthest[direction], beam_index)
			add_child(beam)
			_active_markers.append(beam)
			beam_index += 1


func _create_beam(origin: Vector2i, end_cell: Vector2i, index: int) -> Node3D:
	var start_world := _board.grid_to_world(origin)
	var end_world := _board.grid_to_world(end_cell)
	var delta := end_world - start_world
	var length := Vector2(delta.x, delta.z).length()
	var marker := Node3D.new()
	marker.name = "AttackRay%d" % index
	marker.position = (start_world + end_world) * 0.5 + Vector3(0.0, 0.235, 0.0)
	marker.rotation.y = atan2(delta.x, delta.z)
	var plane := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.orientation = PlaneMesh.FACE_Y
	mesh.size = Vector2(_board.tile_size * 0.62, length + _board.tile_size * 0.90)
	var material := ShaderMaterial.new()
	material.shader = RIFT_SHADER
	material.set_shader_parameter("phase", float(index) * 0.27)
	material.set_shader_parameter("aspect", mesh.size.y / mesh.size.x)
	mesh.material = material
	var sweep := create_tween()
	_tweens.append(sweep)
	sweep.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sweep.tween_method(func(value: float): material.set_shader_parameter("progress", value), 0.0, 1.0, 0.65)
	plane.mesh = mesh
	plane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	marker.add_child(plane)
	return marker


func _create_impact_sparks(cell: Vector2i) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.name = "AttackImpact"
	particles.position = _board.grid_to_world(cell) + Vector3(0.0, 0.28, 0.0)
	particles.amount = 64
	particles.lifetime = 1.05
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.randomness = 0.65
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = _board.tile_size * 0.12
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 82.0
	process.initial_velocity_min = 2.2
	process.initial_velocity_max = 5.8
	process.gravity = Vector3(0.0, -7.0, 0.0)
	process.scale_min = 0.45
	process.scale_max = 1.25
	var gradient := Gradient.new()
	gradient.set_color(0, QUEEN_GOLD_HOT)
	gradient.set_color(1, Color(0.72, 0.36, 0.07, 0.0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = gradient
	process.color_ramp = ramp
	particles.process_material = process
	var spark := QuadMesh.new()
	spark.size = Vector2(0.28, 0.58)
	var spark_material := ShaderMaterial.new()
	spark_material.shader = SPARK_SHADER
	spark.material = spark_material
	particles.draw_pass_1 = spark
	particles.emitting = true
	return particles


func _marker_material(marker: Node3D) -> ShaderMaterial:
	if marker.get_child_count() == 0:
		return null
	var plane := marker.get_child(0) as MeshInstance3D
	if plane == null or plane.mesh == null:
		return null
	return plane.mesh.material as ShaderMaterial


func _nearest_distance(cell: Vector2i, origins: Array[Vector2i]) -> int:
	var nearest := 99
	for origin in origins:
		nearest = mini(nearest, absi(cell.x - origin.x) + absi(cell.y - origin.y))
	return nearest
