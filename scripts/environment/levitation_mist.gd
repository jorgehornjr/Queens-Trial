extends Node3D
## The standalone board editor has no WorldEnvironment. Keep the raymarched
## preview there; create the volumetric component only in the running world.

@export var fog_material: ShaderMaterial
@export var fog_size := Vector3(72, 14, 72)

func _ready() -> void:
	var volume := FogVolume.new()
	volume.name = "VolumetricMist"
	volume.size = fog_size
	volume.material = fog_material
	add_child(volume)
