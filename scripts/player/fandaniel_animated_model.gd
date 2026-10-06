extends Node3D
## Original Hooded Fandaniel skin, native cinematic walk and Mixamo gameplay.

const Face := preload("res://scripts/player/fandaniel_face.gd")
const Gaze := preload("res://scripts/player/fandaniel_cinematic_gaze.gd")
const ARRIVAL_SKIN := preload("res://shaders/fandaniel_arrival_skin.gdshader")
const CINEMATIC_WALK_RATE := 0.8
const NATIVE_WALK_SPEED := 0.59937559
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var airborne := false
var cinematic := false
var slide_direction := 1
var _appearance: Array[ShaderMaterial] = []
var cinematic_gaze: SkeletonModifier3D
var _gaze_release: Tween

func _ready() -> void:
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	for clip in ["breathing_idle", "walk", "left_slide", "right_slide", "intro_arrival"]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation_player.play("breathing_idle")
	_collect_materials(self)
	var face := Face.new()
	face.name = "FandanielFace"
	add_child(face)
	face.configure(skeleton)
	cinematic_gaze = Gaze.new()
	cinematic_gaze.name = "CinematicGaze"
	skeleton.add_child(cinematic_gaze)

func begin_platform_slide(direction: int) -> void:
	slide_direction = direction
	airborne = false
	animation_player.speed_scale = 1.0
	animation_player.play("right_slide" if direction > 0 else "left_slide", 0.24)

func update_platform_motion(_platform: Node3D, _speed: float, _strength: float) -> void:
	pass

func begin_platform_fall(_direction: int) -> void:
	airborne = true
	animation_player.play("standing_death", 0.20)

func recover_platform_slide() -> void:
	animation_player.play("breathing_idle", 0.45)

func reset_platform_motion() -> void:
	airborne = false
	cinematic = false
	set_cinematic_look_up(0.0)
	animation_player.speed_scale = 1.0

func play_intro_looking(duration_scale := 1.0) -> void:
	if _gaze_release != null and _gaze_release.is_valid(): _gaze_release.kill()
	set_cinematic_look_up(0.0)
	cinematic = true
	animation_player.speed_scale = CINEMATIC_WALK_RATE / maxf(duration_scale, 0.01)
	animation_player.play("intro_arrival", 0.32)

func begin_cinematic_arrival(duration_scale: float) -> void:
	play_intro_looking(duration_scale)

func cinematic_walk_speed() -> float:
	return NATIVE_WALK_SPEED * CINEMATIC_WALK_RATE * scale.x

func stop_intro_looking() -> void:
	cinematic = false
	animation_player.speed_scale = 1.0
	animation_player.play("breathing_idle", 0.55)
	_gaze_release = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_gaze_release.tween_property(cinematic_gaze, "lift", 0.0, 0.75)

func set_cinematic_look_up(amount: float) -> void:
	if cinematic_gaze != null: cinematic_gaze.lift = clampf(amount, 0.0, 1.0)

func prepare_ground_death() -> void:
	animation_player.speed_scale = 1.0

func _collect_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		_prepare_throat_shadow(mesh)
		for index in range(mesh.mesh.get_surface_count()):
			var original := mesh.get_active_material(index) as StandardMaterial3D
			if original == null: continue
			var material := ShaderMaterial.new()
			material.shader = ARRIVAL_SKIN
			material.set_shader_parameter("base_color", original.albedo_texture)
			material.set_shader_parameter("normal_map", original.normal_texture)
			material.set_shader_parameter("normal_strength", original.normal_scale)
			material.set_shader_parameter("emission_map", original.emission_texture)
			material.set_shader_parameter("emission_tint", Vector3(original.emission.r, original.emission.g, original.emission.b) * original.emission_energy_multiplier)
			material.set_shader_parameter("tint", original.albedo_color)
			material.set_shader_parameter("throat_shadow_enabled", original.resource_name == "Fandaniel_d")
			# Keep the depth-writing pipeline throughout arrival: changing from
			# alpha blending to cutout mid-shot caused a sorting/opacity jump.
			mesh.set_surface_override_material(index, material)
			_appearance.append(material)
	for child in node.get_children(): _collect_materials(child)

func _prepare_throat_shadow(instance: MeshInstance3D) -> void:
	var source := instance.mesh as ArrayMesh
	if source == null: return
	var has_throat := false
	for surface in range(source.get_surface_count()):
		var material := instance.get_active_material(surface)
		if material != null and material.resource_name == "Fandaniel_d": has_throat = true
	if not has_throat: return
	var shaded := ArrayMesh.new()
	for surface in range(source.get_surface_count()):
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colors := PackedColorArray()
		for vertex in vertices:
			# Store the gradient at bind pose, so it moves with the original
			# skin weights instead of sliding over the neck as the head rises.
			var height := smoothstep(1.405, 1.480, vertex.y)
			var radius := Vector2(vertex.x, vertex.z - 0.015).length()
			var center := 1.0 - smoothstep(0.110, 0.145, radius)
			colors.append(Color(height * center, 1.0, 1.0, 1.0))
		arrays[Mesh.ARRAY_COLOR] = colors
		var flags := source.surface_get_format(surface) & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		shaded.add_surface_from_arrays(source.surface_get_primitive_type(surface), arrays, [], {}, flags)
		shaded.surface_set_material(surface, source.surface_get_material(surface))
	instance.mesh = shaded

func set_arrival_reveal(amount: float) -> void:
	for material in _appearance:
		material.set_shader_parameter("reveal", clampf(amount, 0.0, 1.0))
	var face := get_node_or_null("FandanielFace")
	if face != null: face.set_arrival_reveal(amount)
