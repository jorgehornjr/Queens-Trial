extends Node3D

const SKINNED_MESH = preload("res://assets/models/characters/wizard/wizard_skinned_mesh.res")
const JOGGING_SCENE = preload("res://assets/models/characters/wizard/mixamo/jogging.fbx")
const DEATH_SCENE = preload("res://assets/models/characters/wizard/mixamo/standing_death_forward_01.fbx")


func _ready() -> void:
	var skeleton := find_child("Skeleton3D", true, false) as Skeleton3D
	var proxy := find_child("Object_4", true, false) as MeshInstance3D
	var animation_player := find_child("AnimationPlayer", true, false) as AnimationPlayer
	if skeleton == null or proxy == null or animation_player == null:
		push_error("O modelo animado do Wizard não encontrou o rig Mixamo completo.")
		return

	proxy.visible = false
	var textured_mesh := MeshInstance3D.new()
	textured_mesh.name = "TexturedWizard"
	textured_mesh.mesh = SKINNED_MESH
	textured_mesh.skin = proxy.skin
	textured_mesh.skeleton = NodePath("..")
	skeleton.add_child(textured_mesh)

	var library := animation_player.get_animation_library("")
	if library == null:
		library = AnimationLibrary.new()
		animation_player.add_animation_library("", library)
	if library.has_animation("mixamo_com"):
		library.rename_animation("mixamo_com", "breathing_idle")
	var idle := library.get_animation("breathing_idle")
	if idle != null:
		idle.loop_mode = Animation.LOOP_LINEAR

	_add_animation_from_scene(library, JOGGING_SCENE, "jogging", true, true)
	_add_animation_from_scene(library, DEATH_SCENE, "standing_death_forward_01", false, false)


func _add_animation_from_scene(
	library: AnimationLibrary,
	packed_scene: PackedScene,
	animation_name: StringName,
	loop: bool,
	remove_root_motion: bool
) -> void:
	var source_root := packed_scene.instantiate()
	var source_player := source_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if source_player == null:
		source_root.free()
		push_error("FBX Mixamo sem AnimationPlayer: %s" % animation_name)
		return
	var source_animation := source_player.get_animation("mixamo_com")
	if source_animation == null:
		source_root.free()
		push_error("FBX Mixamo sem ação principal: %s" % animation_name)
		return
	var animation := source_animation.duplicate(true) as Animation
	animation.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	if remove_root_motion:
		_lock_hips_horizontal_motion(animation)
	library.add_animation(animation_name, animation)
	source_root.free()


func _lock_hips_horizontal_motion(animation: Animation) -> void:
	for track_index in range(animation.get_track_count()):
		if animation.track_get_type(track_index) != Animation.TYPE_POSITION_3D:
			continue
		if "mixamorig_Hips" not in String(animation.track_get_path(track_index)):
			continue
		if animation.track_get_key_count(track_index) == 0:
			continue
		var anchor: Vector3 = animation.track_get_key_value(track_index, 0)
		for key_index in range(animation.track_get_key_count(track_index)):
			var value: Vector3 = animation.track_get_key_value(track_index, key_index)
			# Mixamo/Godot uses Y as vertical. Lock only the horizontal axes so
			# the jogging clip cannot drift away from the gameplay transform.
			value.x = anchor.x
			value.z = anchor.z
			animation.track_set_key_value(track_index, key_index, value)
