extends Node3D

const CapePhysics := preload("res://scripts/player/priest_cape_physics.gd")
const FaceSigil := preload("res://scripts/player/priest_face_sigil.gd")
var animation_player: AnimationPlayer
var skeleton: Skeleton3D
var cape: Node3D
var slide_direction := 1
var airborne := false
var cinematic := false


func _ready() -> void:
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	skeleton = find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or animation_player == null:
		push_error("O sacerdote precisa do rig exportado do Blender.")
		return
	for clip in ["breathing_idle", "walk", "left_slide", "right_slide"]:
		animation_player.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	animation_player.play("breathing_idle")
	cape = CapePhysics.new()
	cape.name = "CapePhysics"
	add_child(cape)
	cape.configure(skeleton)
	var face := FaceSigil.new()
	face.name = "FaceSigil"
	add_child(face)
	face.configure(skeleton)


func begin_platform_slide(direction: int) -> void:
	slide_direction = direction
	airborne = false
	animation_player.speed_scale = 1.0
	animation_player.play("right_slide" if direction > 0 else "left_slide", 0.24)


func update_platform_motion(platform: Node3D, speed: float, strength: float) -> void:
	if cape == null: return
	cape.floor_transform = platform.global_transform
	cape.floor_half_extent = platform.tile_size * 2.5
	cape.floor_enabled = not airborne
	cape.wind = platform.global_basis.x * float(slide_direction) * (speed * 0.10 + 2.2) * strength + platform.global_basis.z * 0.8


func begin_platform_fall(direction: int) -> void:
	airborne = true
	if cape != null: cape.floor_enabled = false
	animation_player.play("right_fall" if direction > 0 else "left_fall", 0.20)


func recover_platform_slide() -> void:
	# Crossfade the continuously playing Mixamo strafe back to standing.
	animation_player.play("breathing_idle", 0.45)


func reset_platform_motion() -> void:
	airborne = false
	cinematic = false
	if animation_player != null: animation_player.speed_scale = 1.0
	if cape != null:
		cape.floor_enabled = true
		cape.reset_cloth()


func play_intro_looking(duration_scale := 1.0) -> void:
	cinematic = true
	animation_player.speed_scale = 1.0 / maxf(duration_scale, 0.01)
	animation_player.play("intro_arrival", 0.32)
	if cape != null: cape.reset_cloth()


func begin_cinematic_arrival(duration_scale: float) -> void:
	play_intro_looking(duration_scale)


func stop_intro_looking() -> void:
	cinematic = false
	animation_player.speed_scale = 1.0
	animation_player.play("breathing_idle", 0.35)


func prepare_ground_death() -> void:
	animation_player.speed_scale = 1.0
	if cape != null:
		cape.wind = Vector3.ZERO
		cape.floor_enabled = true
