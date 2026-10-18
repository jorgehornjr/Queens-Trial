extends Node3D
## Instance-local atmosphere and internal embers on the queen's skinned fabric.
const ClothFire = preload("res://scripts/environment/skinned_cloth_fire.gd")
var active := false
var _main: Node
var _space: CelestialSpace
var _mist: Node3D
var _skeleton: Skeleton3D
var _fire: SkinnedClothFire
var _rest_colors: Dictionary = {}
var _satellite_visibility: Dictionary = {}
var _fog_colors: Dictionary = {}
var _ambient := Color.WHITE
var _time := 0.0

func configure(main: Node) -> void:
	_main = main
	_space = main.get_node("World/CelestialSpace")
	_mist = main.get_node("World/Board/LevitationMist")
	_skeleton = main.get_node("World/Seraph")._skeleton
	_ambient = _space._environment.ambient_light_color
	for parameter in ["violet","ice_blue"]:
		_fog_colors[parameter] = _mist.fog_material.get_shader_parameter(parameter)
	for path in ["World/AccentLight","World/FillLight","World/UnderglowLight","World/Seraph/CharacterFill"]:
		var light: Light3D = main.get_node(path)
		_rest_colors[light] = light.light_color
	set_process(false)

func set_active(enabled: bool) -> void:
	if active == enabled: return
	active = enabled
	_space._sky_material.set_shader_parameter("inferno_mix",1.0 if enabled else 0.0)
	_mist._nebula_material.set_shader_parameter("inferno_mix",1.0 if enabled else 0.0)
	_mist.fog_material.set_shader_parameter("violet",Color(0.55,0.007,0.025) if enabled else _fog_colors.violet)
	_mist.fog_material.set_shader_parameter("ice_blue",Color(1.0,0.075,0.025) if enabled else _fog_colors.ice_blue)
	_space._environment.ambient_light_color = Color(0.68,0.18,0.13) if enabled else _ambient
	for light: Light3D in _rest_colors:
		light.light_color = Color(1.0,0.11,0.035) if enabled else _rest_colors[light]
	if enabled:
		for node: Node3D in _space.get_node("SolarSystem").get_children():
			if node.name == "SpaceStation" or String(node.name).begins_with("Satellite"):
				_satellite_visibility[node] = node.visible
				node.hide()
		_fire = ClothFire.new() as SkinnedClothFire
		_fire.name = "BurningVestments"
		add_child(_fire)
		var dress := _main.get_node("World/Seraph").find_child("Dress",true,false) as MeshInstance3D
		_fire.configure(dress,_skeleton)
	else:
		if is_instance_valid(_fire):
			# Restore the fabric synchronously before another encounter can activate.
			remove_child(_fire)
			_fire.queue_free()
		_fire = null
		for node: Node3D in _satellite_visibility:
			if is_instance_valid(node): node.visible = _satellite_visibility[node]
		_satellite_visibility.clear()
	set_process(enabled)

func _process(delta: float) -> void:
	_time += delta
