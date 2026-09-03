class_name CinematicSolarSystem
extends Node3D

const BODY_SCRIPT = preload("res://scripts/environment/solar_body.gd")
const ROTATION = preload("res://scripts/environment/planet_rotation.gd")
const SPACECRAFT = preload("res://scripts/environment/spacecraft.gd")
@export_range(60.0, 1200.0, 10.0) var earth_turn_seconds := 240.0
@export var exact_rotation_period_ratios := false
const ASSET_ROOT := "res://assets/environment/solar_system/"
const SUN_POSITION := Vector3(-18000, -4000, 10000)
# Distribuição cenográfica: ordem heliocêntrica com escalas de distância e tamanho independentes.
const LAYOUT := [
	{"id": "Sun", "asset": "sun", "position": SUN_POSITION, "radius": 5200.0, "speed": 0.18},
	{"id": "Mercury", "asset": "mercury", "position": Vector3(-12000, -1800, 3000), "radius": 430.0, "speed": 0.16},
	{"id": "Venus", "asset": "venus", "position": Vector3(-6000, -1400, -4000), "radius": 950.0, "speed": -0.12},
	{"id": "Moon", "asset": "moon", "position": Vector3(-110, -170, -1200), "radius": 300.0, "speed": 0.0},
	{"id": "Mars", "asset": "mars", "position": Vector3(8000, -1600, -13000), "radius": 740.0, "speed": 0.58},
	{"id": "Jupiter", "asset": "jupiter", "position": Vector3(21000, -5400, -4000), "radius": 3800.0, "speed": 1.05},
	{"id": "Saturn", "asset": "saturn", "position": Vector3(25000, -5000, 9000), "radius": 3100.0, "speed": 0.95},
	{"id": "Uranus", "asset": "uranus", "position": Vector3(4500, -6300, 51000), "radius": 2900.0, "speed": -0.65},
	{"id": "Neptune", "asset": "neptune", "position": Vector3(-33000, -6200, 58000), "radius": 2800.0, "speed": 0.68},
]

var bodies: Dictionary = {}
var missing_assets: PackedStringArray = []

func _ready() -> void:
	var report: Array = JSON.parse_string(FileAccess.get_file_as_string(ASSET_ROOT + "preparation.json"))
	var axes: Dictionary = {}
	for entry: Dictionary in report:
		axes[entry.name] = Vector3(entry.spin_axis[0], entry.spin_axis[1], entry.spin_axis[2])
	for data: Dictionary in LAYOUT:
		var path: String = ASSET_ROOT + data.asset + ".glb"
		if not ResourceLoader.exists(path):
			missing_assets.append(data.id)
			push_warning("Modelo ainda não fornecido para o sistema solar: " + data.id)
			continue
		var body := BODY_SCRIPT.new() as SolarBody
		body.name = data.id
		body.position = data.position
		body.emitter = data.id == "Sun"
		add_child(body)
		body.configure(load(path) as PackedScene, data.radius, SUN_POSITION, axes.get(data.asset, Vector3.UP), data.speed)
		if data.id == "Moon":
			# Orientação inicial da face próxima da Lua.
			body.model.rotation_degrees = Vector3(0, 240, 0)
			# Ritmo visual sincronizado com a Terra, sem simulação do período lunar real.
			body.spin_speed = ROTATION.speed_for("Earth", earth_turn_seconds, exact_rotation_period_ratios)
		if ROTATION.PROFILES.has(data.id):
			body.set_axial_rotation(ROTATION.axis_for(data.id), ROTATION.speed_for(data.id, earth_turn_seconds, exact_rotation_period_ratios))
		bodies[data.id] = body
	var earth := get_node("../DistantEarth") as CinematicEarth
	earth.set_axial_rotation(ROTATION.axis_for("Earth"), ROTATION.speed_for("Earth", earth_turn_seconds, exact_rotation_period_ratios))
	earth.illuminate_from(SUN_POSITION)
	bodies["Earth"] = earth
	# Buracos negros decorativos fora da região planetária.
	_add_black_hole("BlackHoleA", Vector3(52000, -10000, 54000), 9000.0, 0.36, Vector3(32, 0, -18))
	_add_black_hole("BlackHoleB", Vector3(-79000, -6500, -10000), 8000.0, -0.25, Vector3(25, 0, -48))
	_add_spacecraft("SpaceStation", "space_station", Vector3(-910, -95, -1550), 300.0, Vector3(25, 0, -12), 8)
	_add_spacecraft("SatelliteA", "basic_satellite", Vector3(850, -35, -1550), 45.0, Vector3(-55, -25, -18), 16)
	# Satélite em primeiro plano, no intervalo angular entre Urano e Netuno.
	_add_spacecraft("SatelliteB", "basic_satellite", Vector3(-425, -180, 1870), 65.0, Vector3(-30, 35, 25), 32)
	var orbital_fill := DirectionalLight3D.new()
	orbital_fill.name = "OrbitalFill"
	orbital_fill.light_cull_mask = 8 | 16 | 32
	orbital_fill.light_color = Color(0.62, 0.76, 1.0)
	orbital_fill.light_energy = 0.48
	orbital_fill.shadow_enabled = false
	add_child(orbital_fill)
	orbital_fill.look_at(Vector3(-0.3, -0.4, -1.0))

func _add_spacecraft(id: String, asset: String, location: Vector3, size: float, orientation: Vector3, layer: int) -> void:
	var craft := SPACECRAFT.new() as AmbientSpacecraft
	craft.name = id
	craft.position = location
	craft.rotation_degrees = orientation
	craft.is_station = id == "SpaceStation"
	craft.phase_offset = 2.4 if id == "SatelliteB" else 0.0
	add_child(craft)
	craft.configure(load("res://assets/environment/spacecraft/" + asset + ".glb") as PackedScene, size, SUN_POSITION, layer)

func _add_black_hole(id: String, location: Vector3, radius: float, speed: float, tilt: Vector3) -> void:
	var hole := BODY_SCRIPT.new() as SolarBody
	hole.name = id
	hole.position = location
	hole.accretion = true
	add_child(hole)
	hole.configure(load(ASSET_ROOT + "black_hole.glb") as PackedScene, radius, SUN_POSITION, Vector3.UP, speed)
	# Inclinação do conjunto; a rotação ocorre no plano local do disco.
	hole.rotation_degrees = tilt
