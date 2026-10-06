extends RefCounted
## The Priest's rig/cloth regression tests deliberately use its preserved scene.

static func replace(player: Node) -> void:
	var previous := player.get_node("Model")
	player.remove_child(previous)
	previous.free()
	var model := (load("res://scenes/player/fallen_priest_animated_model.tscn") as PackedScene).instantiate() as Node3D
	model.name = "Model"
	model.rotation_degrees = Vector3(0, 180, 0)
	model.scale = Vector3.ONE * 2.0
	player.add_child(model)
