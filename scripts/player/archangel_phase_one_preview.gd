extends Node
## Standalone opening/phase-one trial; the production player scene is preserved.

const MAIN = preload("res://scenes/main/main.tscn")
const ARCHANGEL = preload("res://scenes/player/archangel_animated_model.tscn")


func _ready() -> void:
	var main := MAIN.instantiate()
	var player := main.get_node("World/Player") as GridPlayer
	var wizard := player.get_node("Model") as Node3D
	var old_rotation := wizard.rotation
	wizard.free()
	var angel := ARCHANGEL.instantiate() as Node3D
	angel.name = "Model"
	angel.rotation = old_rotation
	# Match the cinematic character framing without changing the opening camera.
	angel.scale = Vector3.ONE * 2.0
	player.add_child(angel)
	add_child(main)
