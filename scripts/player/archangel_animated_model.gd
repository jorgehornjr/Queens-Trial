class_name ArchangelAnimatedModel
extends Node3D
## First-pass original rig. The wizard remains available in its original scene.

var animation_player: AnimationPlayer
var skeleton: Skeleton3D


func _ready() -> void:
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	if animation_player == null or skeleton == null:
		push_error("O arcanjo precisa do esqueleto e das animações exportadas do Blender.")
		return
	for clip in ["breathing_idle", "wing_flex_test"]:
		var animation := animation_player.get_animation(clip)
		if animation != null:
			animation.loop_mode = Animation.LOOP_LINEAR
	animation_player.play("breathing_idle")


func play_intro_looking() -> void:
	# Match the opening's interface, with a composed wing opening and head turn.
	if animation_player != null:
		animation_player.play("intro_presence", 0.35)


func stop_intro_looking() -> void:
	if animation_player != null:
		animation_player.play("breathing_idle", 0.35)
