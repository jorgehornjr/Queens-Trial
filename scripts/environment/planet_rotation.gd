class_name PlanetRotation
extends RefCounted

# Períodos siderais em horas. Inclinações acima de 90° já indicam giro retrógrado;
# inverter também a velocidade produziria uma segunda inversão.
const PROFILES := {
	"Mercury": {"hours": 58.6 * 24.0, "tilt": 0.1},
	"Venus": {"hours": 243.0 * 24.0, "tilt": 177.0},
	"Earth": {"hours": 23.0 + 56.0 / 60.0, "tilt": 23.4},
	"Mars": {"hours": 24.0 + 37.0 / 60.0, "tilt": 25.2},
	"Jupiter": {"hours": 9.0 + 55.0 / 60.0, "tilt": 3.1},
	"Saturn": {"hours": 10.0 + 33.0 / 60.0, "tilt": 26.7},
	"Uranus": {"hours": 17.0 + 14.0 / 60.0, "tilt": 97.8},
	"Neptune": {"hours": 16.0 + 6.0 / 60.0, "tilt": 28.3},
}

static func axis_for(id: String) -> Vector3:
	var tilt := deg_to_rad(float(PROFILES[id].tilt))
	return Vector3(sin(tilt), cos(tilt), 0.0)

static func speed_for(id: String, earth_turn_seconds: float, exact_ratios := false) -> float:
	var ratio := float(PROFILES.Earth.hours) / float(PROFILES[id].hours)
	# Compressão dos períodos para legibilidade da rotação dos planetas lentos.
	return 360.0 / maxf(earth_turn_seconds, 1.0) * pow(ratio, 1.0 if exact_ratios else 0.25)
