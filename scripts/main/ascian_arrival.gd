class_name AscianArrival
extends Node3D
## Arrival-only AVFX port: authored meshes, UVs, curves and original textures.

const LIFE := 160.0 / 30.0
const SHADER := preload("res://shaders/ascian_arrival.gdshader")
const RESOURCE_ROOT := "res://assets/effects/ascian_arrival/"
var definition: Dictionary
var _textures: Array[Texture2D] = []
var _models: Array[ArrayMesh] = []
var _instances: Array[Dictionary] = []
var _elapsed := LIFE
var _active := false
var aperture := 0.0

func _ready() -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string(RESOURCE_ROOT + "arrival.json"))
	for filename: String in definition.textures:
		_textures.append(load(RESOURCE_ROOT + filename) as Texture2D)
	for model: Dictionary in definition.models:
		_models.append(_source_mesh(model))
	_build_particles()
	stop()

func burst() -> void:
	_elapsed = 0.0
	_active = true
	visible = true
	set_process(true)
	_update_effect()

func set_age(age: float) -> void:
	set_process(false)
	_elapsed = maxf(0.0, age)
	if _elapsed >= LIFE:
		stop()
		return
	_update_effect()

func stop() -> void:
	_active = false
	aperture = 0.0
	visible = false
	set_process(false)

func _process(delta: float) -> void:
	if not _active: return
	set_age(_elapsed + delta)
	if _active: set_process(true)

func _build_particles() -> void:
	for emitter: Dictionary in definition.emitters:
		var interval := maxf(1.0, _curve(emitter.interval, 0.0, 1.0))
		var birth := 0.0
		while birth < float(emitter.life):
			if _curve(emitter.creation, birth, 1.0) < 0.01: break
			for item: Dictionary in emitter.items:
				if not bool(item.enabled): continue
				var part: Dictionary = definition.particles[int(item.particle)]
				var count := maxi(1, int(item.count))
				for clone in range(count):
					var mesh := MeshInstance3D.new()
					mesh.name = "Arrival_%d_%d_%d" % [int(item.particle), int(birth), clone]
					mesh.mesh = _disc_mesh() if int(part.type) == 12 else _models[int(part.model)]
					mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					var material := ShaderMaterial.new()
					material.shader = SHADER
					var texture_id := int(part.texture)
					material.set_shader_parameter("textured", texture_id >= 0)
					if texture_id >= 0: material.set_shader_parameter("source_texture", _textures[texture_id])
					var distortion_id := int(part.distortion)
					material.set_shader_parameter("distorted", distortion_id >= 0)
					if distortion_id >= 0: material.set_shader_parameter("distortion_texture", _textures[distortion_id])
					material.set_shader_parameter("color_to_alpha", bool(part.color_to_alpha))
					mesh.material_override = material
					add_child(mesh)
					_instances.append({"mesh": mesh, "material": material, "particle": part,
						"emitter": emitter, "birth": birth, "clone": clone, "count": count,
						"injection": _vector(item.injection), "life": float(item.override_life) if int(item.override_life) > 0 else float(part.life)})
			birth += interval

func _update_effect() -> void:
	var frame := _elapsed * 30.0
	aperture = smoothstep(0.0, 0.5, _elapsed) * (1.0 - smoothstep(3.4, LIFE, _elapsed))
	var camera := get_viewport().get_camera_3d()
	for instance: Dictionary in _instances:
		var age := frame - float(instance.birth)
		var mesh: MeshInstance3D = instance.mesh
		mesh.visible = age >= 0.0 and age < float(instance.life)
		if not mesh.visible: continue
		var part: Dictionary = instance.particle
		var material: ShaderMaterial = instance.material
		var color := _color(part.color.get("RGB", []), age)
		var alpha := _curve(part.color.get("A", []), age, 1.0) * _curve(part.color.get("SclA", []), age, 1.0)
		material.set_shader_parameter("particle_tint", Color(color.x, color.y, color.z, alpha))
		var scaling := _axes(part.scale, age, Vector3.ONE)
		# Injection angles govern emission direction, not the billboard's Euler
		# rotation. These point emitters have no authored launch velocity.
		var rotation := _axes(part.rotation, age, Vector3.ZERO)
		rotation.z += _curve(part.rotation.get("ZR", []), age, 0.0) * (float(instance.clone) / maxf(1.0, float(instance.count)) - 0.5)
		mesh.position = _axes(part.position, age, Vector3.ZERO) + _axes(instance.emitter.position, float(instance.birth), Vector3.ZERO)
		var orientation := Basis.IDENTITY
		if camera != null and int(part.billboard) in [6, 8]:
			orientation = global_basis.orthonormalized().inverse() * camera.global_basis.orthonormalized()
			if int(part.type) == 13: orientation *= Basis(Vector3.UP, -PI / 2.0)
			if int(part.billboard) == 8:
				var forward := to_local(camera.global_position) - mesh.position
				forward.y = 0.0
				if forward.length_squared() > 0.001: orientation = Basis.looking_at(-forward.normalized(), Vector3.UP)
		orientation *= Basis.from_euler(rotation)
		mesh.basis = orientation.scaled(Vector3(maxf(scaling.x, 0.001), maxf(scaling.y, 0.001), maxf(scaling.z, 0.001)))
		if not part.uv.is_empty():
			var uv: Dictionary = part.uv[0]
			var us := _axes(uv.scale, age, Vector3.ONE)
			var ut := _axes(uv.scroll, age, Vector3.ZERO)
			material.set_shader_parameter("uv_scale", Vector2(us.x, us.y))
			material.set_shader_parameter("uv_scroll", Vector2(ut.x, ut.y))
			if part.uv.size() > 1:
				var dist: Dictionary = part.uv[1]
				var ds := _axes(dist.scale, age, Vector3.ONE)
				var dt := _axes(dist.scroll, age, Vector3.ZERO)
				material.set_shader_parameter("distortion_scale", Vector2(ds.x, ds.y))
				material.set_shader_parameter("distortion_scroll", Vector2(dt.x, dt.y))

func _axes(curves: Dictionary, frame: float, fallback: Vector3) -> Vector3:
	var value := Vector3(_curve(curves.get("X", []), frame, fallback.x), _curve(curves.get("Y", []), frame, fallback.y), _curve(curves.get("Z", []), frame, fallback.z))
	match int(curves.get("connect", 0)):
		1: value.y = value.x; value.z = value.x
		2: value.y = value.x
		3: value.z = value.x
		4: value.x = value.y; value.z = value.y
		5: value.x = value.y
		6: value.z = value.y
		7: value.x = value.z; value.y = value.z
		8: value.x = value.z
		9: value.y = value.z
	return value

func _curve(keys: Array, frame: float, fallback: float) -> float:
	if keys.is_empty(): return fallback
	if frame <= float(keys[0][0]): return float(keys[0][4])
	for i in range(keys.size() - 1):
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		if frame > float(b[0]): continue
		var t := clampf((frame - float(a[0])) / maxf(1.0, float(b[0]) - float(a[0])), 0.0, 1.0)
		if int(a[1]) == 2: return float(a[4])
		if int(a[1]) == 0:
			var low := 0.0
			var high := 1.0
			for iteration in range(12):
				var middle := (low + high) * 0.5
				var x := _bezier(0.0, float(a[2]) * 0.5, 1.0 - float(a[3]) * 0.5, 1.0, middle)
				if x < t: low = middle
				else: high = middle
			t = (low + high) * 0.5
			return _bezier(float(a[4]), float(a[4]), float(b[4]), float(b[4]), t)
		return lerpf(float(a[4]), float(b[4]), t)
	return float(keys.back()[4])

func _color(keys: Array, frame: float) -> Vector3:
	if keys.is_empty(): return Vector3.ONE
	for i in range(keys.size() - 1):
		if frame > float(keys[i + 1][0]): continue
		var a: Array = keys[i]
		var b: Array = keys[i + 1]
		return Vector3(float(a[2]), float(a[3]), float(a[4])).lerp(Vector3(float(b[2]), float(b[3]), float(b[4])), clampf((frame-float(a[0])) / maxf(1.0, float(b[0])-float(a[0])), 0.0, 1.0))
	var last: Array = keys.back()
	return Vector3(float(last[2]), float(last[3]), float(last[4]))

func _bezier(a: float, b: float, c: float, d: float, t: float) -> float:
	var inverse := 1.0 - t
	return inverse * inverse * inverse * a + 3.0 * inverse * inverse * t * b + 3.0 * inverse * t * t * c + t * t * t * d

func _source_mesh(source: Dictionary) -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in source.indices:
		var vertex: Dictionary = source.vertices[int(index)]
		builder.set_uv(Vector2(float(vertex.uv[0]), float(vertex.uv[1])))
		builder.set_uv2(Vector2(float(vertex.uv2[0]), float(vertex.uv2[1])))
		builder.set_color(Color(float(vertex.color[0]), float(vertex.color[1]), float(vertex.color[2]), float(vertex.color[3])))
		builder.add_vertex(_vector(vertex.position))
	builder.generate_normals()
	return builder.commit()

func _disc_mesh() -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(64):
		for point in [Vector3.ZERO, Vector3(cos(float(i) * TAU / 64.0), sin(float(i) * TAU / 64.0), 0.0), Vector3(cos(float(i + 1) * TAU / 64.0), sin(float(i + 1) * TAU / 64.0), 0.0)]:
			builder.set_uv(Vector2(point.x, point.y) * 0.5 + Vector2.ONE * 0.5)
			builder.set_color(Color(1, 1, 1, 1.0 - point.length() * 0.75))
			builder.add_vertex(point)
	builder.generate_normals()
	return builder.commit()

func _vector(value: Variant) -> Vector3:
	if value is Vector3: return value
	return Vector3(float(value[0]), float(value[1]), float(value[2]))
