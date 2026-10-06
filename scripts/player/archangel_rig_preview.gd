extends Node3D
## Orbitable preview of the exported skeleton and the actual skinned geometry.

const LABELS = ["Repouso", "Presença", "Movimento das asas", "Teste das articulações"]
const CLIPS = ["breathing_idle", "intro_presence", "wing_flex_test", "rig_pose_test"]

@onready var model: ArchangelAnimatedModel = $Model
var camera: Camera3D
var bone_lines: MeshInstance3D
var bone_mesh := ImmediateMesh.new()
var yaw := 0.0
var pitch := 0.12
var distance := 4.8
var selected := 0


func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color(0.025, 0.028, 0.04)
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color(0.72, 0.78, 1.0)
	settings.ambient_light_energy = 0.7
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	for setup in [[Vector3(-3, 4, 4), 2.5, Color(1, 0.88, 0.67)], [Vector3(3, 2, 1), 1.8, Color(0.6, 0.75, 1)], [Vector3(0, 4, -3), 2.5, Color(1, 0.93, 0.78)]]:
		var light := OmniLight3D.new()
		light.position = setup[0]
		light.light_energy = setup[1]
		light.light_color = setup[2]
		light.omni_range = 12
		add_child(light)
	var ground := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.65
	cylinder.bottom_radius = 1.65
	cylinder.height = 0.06
	ground.mesh = cylinder
	ground.position.y = -0.04
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.035, 0.035, 0.05)
	floor_material.metallic = 0.6
	floor_material.roughness = 0.5
	ground.material_override = floor_material
	add_child(ground)
	camera = Camera3D.new()
	camera.fov = 38
	camera.current = true
	add_child(camera)
	bone_lines = MeshInstance3D.new()
	bone_lines.mesh = bone_mesh
	var bone_material := StandardMaterial3D.new()
	bone_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bone_material.albedo_color = Color(0.2, 1, 0.8)
	bone_material.no_depth_test = true
	bone_lines.material_override = bone_material
	bone_lines.visible = false
	add_child(bone_lines)
	_make_controls()
	_update_camera()


func _make_controls() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := VBoxContainer.new()
	panel.position = Vector2(28, 28)
	layer.add_child(panel)
	var label := Label.new()
	label.text = "Arcanjo · prévia do esqueleto"
	label.add_theme_color_override("font_color", Color(0.9, 0.78, 0.48))
	label.add_theme_font_size_override("font_size", 24)
	panel.add_child(label)
	var selector := OptionButton.new()
	for title in LABELS:
		selector.add_item(title)
	selector.item_selected.connect(_play_clip)
	panel.add_child(selector)
	var bones := CheckButton.new()
	bones.text = "Mostrar ossos"
	bones.toggled.connect(func(value: bool): bone_lines.visible = value)
	panel.add_child(bones)
	var button := Button.new()
	button.text = "Testar abertura e fase 1"
	button.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/previews/archangel_phase_one_preview.tscn"))
	panel.add_child(button)
	var help := Label.new()
	help.text = "Arraste com o botão direito para girar · Roda para aproximar"
	panel.add_child(help)


func _play_clip(index: int) -> void:
	selected = index
	var animation := model.animation_player.get_animation(CLIPS[index])
	animation.loop_mode = Animation.LOOP_LINEAR
	model.animation_player.play(CLIPS[index], 0.25)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		yaw -= event.relative.x * 0.007
		pitch = clampf(pitch + event.relative.y * 0.005, -0.55, 0.7)
		_update_camera()
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(2.5, distance - 0.25)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(9, distance + 0.25)
		_update_camera()


func _update_camera() -> void:
	camera.position = Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance + Vector3(0, 1.12, 0)
	camera.look_at(Vector3(0, 1.12, 0))


func _process(_delta: float) -> void:
	if not bone_lines.visible or model.skeleton == null:
		return
	var skeleton := model.skeleton
	bone_mesh.clear_surfaces()
	bone_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for index in skeleton.get_bone_count():
		var parent := skeleton.get_bone_parent(index)
		if parent < 0:
			continue
		bone_mesh.surface_add_vertex(skeleton.global_transform * skeleton.get_bone_global_pose(parent).origin)
		bone_mesh.surface_add_vertex(skeleton.global_transform * skeleton.get_bone_global_pose(index).origin)
	bone_mesh.surface_end()
