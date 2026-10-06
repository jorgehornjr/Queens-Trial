class_name StarredGuide
extends Node3D
## Estrelas regulares seguem ondas simétricas sobre a rota lógica da fase.

signal finished(completed: bool)

const STAR_SHADER = preload("res://shaders/floor_star.gdshader")
const STAR_GLYPH = preload("res://assets/textures/guidance/path_star.svg")
const TRAIL_SHADER = preload("res://shaders/starred_trail.gdshader")
const DURATION := 4.6

var reveal := 0.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		for material in _materials:
			material.set_shader_parameter("reveal", reveal)
var playing := false
var points := PackedVector3Array()
var _materials: Array[ShaderMaterial] = []
var _tween: Tween


func configure(waypoints: PackedVector3Array, tile_size: float) -> void:
	var centerline := PackedVector3Array()
	for segment in range(waypoints.size() - 1):
		var a := waypoints[maxi(0, segment - 1)]
		var b := waypoints[segment]
		var c := waypoints[segment + 1]
		var d := waypoints[mini(waypoints.size() - 1, segment + 2)]
		for sample in range(48):
			var t := float(sample) / 48.0
			centerline.append(0.5 * ((2.0 * b) + (-a + c) * t + (2.0 * a - 5.0 * b + 4.0 * c - d) * t * t + (-a + 3.0 * b - 3.0 * c + d) * t * t * t))
	centerline.append(waypoints[-1])
	var lengths := _distances(centerline)
	var total := maxf(lengths[-1], 0.001)
	var waves := maxf(1.0, roundf(total / tile_size))
	points.clear()
	for index in range(centerline.size()):
		var tangent := (centerline[mini(index + 1, centerline.size() - 1)] - centerline[maxi(index - 1, 0)]).normalized()
		var normal := tangent.cross(Vector3.UP)
		var phase := lengths[index] / total * TAU * waves
		points.append(centerline[index] + normal * sin(phase) * tile_size * 0.20)
	points[0] = waypoints[0]
	points[-1] = waypoints[-1]
	var distances := _distances(points)
	var length := maxf(distances[-1], 0.001)
	_build_ribbon(distances, length, tile_size)
	_build_stars(distances, length, tile_size)


func _distances(path: PackedVector3Array) -> PackedFloat32Array:
	var lengths := PackedFloat32Array([0.0])
	for index in range(1, path.size()):
		lengths.append(lengths[-1] + path[index].distance_to(path[index - 1]))
	return lengths

func play() -> void:
	playing = true
	reveal = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "reveal", 1.0, DURATION).set_trans(Tween.TRANS_LINEAR)
	_tween.tween_interval(0.18)
	_tween.finished.connect(_complete)


func _complete() -> void:
	playing = false
	_tween = null
	finished.emit(true)


func cancel() -> void:
	if _tween != null and _tween.is_valid(): _tween.kill()
	_tween = null
	if playing:
		playing = false
		finished.emit(false)


func _exit_tree() -> void:
	cancel()


func _build_stars(distances: PackedFloat32Array, length: float, tile_size: float) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var at := tile_size * 0.15
	var index := 1
	var half := tile_size * 0.115
	var right := Vector3.RIGHT * half
	var forward := Vector3.BACK * half
	while at < length:
		while index < distances.size() - 1 and distances[index] < at:
			index += 1
		var blend := (at - distances[index - 1]) / maxf(distances[index] - distances[index - 1], 0.001)
		var center := points[index - 1].lerp(points[index], blend)
		var corners := [center - right - forward, center + right - forward, center + right + forward, center - right + forward]
		var corner_uvs := [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]
		var arrival := 0.035 + at / length * 0.89
		for corner in [0, 1, 2, 0, 2, 3]:
			vertices.append(corners[corner])
			uvs.append(corner_uvs[corner])
			colors.append(Color(1, 1, 1, arrival))
		at += tile_size * 0.29
	var material := ShaderMaterial.new()
	material.shader = STAR_SHADER
	material.set_shader_parameter("glyph", STAR_GLYPH)
	_add_mesh("GuidingStars", vertices, uvs, colors, material)

func _build_ribbon(distances: PackedFloat32Array, length: float, tile_size: float) -> void:
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for index in range(points.size() - 1):
		var tangent := (points[mini(index + 2, points.size() - 1)] - points[maxi(index - 1, 0)]).normalized()
		var side := tangent.cross(Vector3.UP) * tile_size * 0.028
		var corners := [points[index] - side, points[index] + side, points[index + 1] + side, points[index + 1] - side]
		var corner_uvs := [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]
		for corner in [0, 1, 2, 0, 2, 3]:
			vertices.append(corners[corner])
			uvs.append(corner_uvs[corner])
			var along := index if corner < 2 else index + 1
			colors.append(Color(1, 1, 1, 0.035 + distances[along] / length * 0.89))
	var material := ShaderMaterial.new()
	material.shader = TRAIL_SHADER
	_add_mesh("CurvedStarlight", vertices, uvs, colors, material)


func _add_mesh(mesh_name: String, vertices: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, material: ShaderMaterial) -> void:
	_materials.append(material)
	material.set_shader_parameter("reveal", reveal)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(instance)
