extends SceneTree
## Export Godot's imported resource dependencies, including extracted GLB textures.

func _initialize() -> void:
	var dependencies := {}
	_scan("res://assets", dependencies)
	var file := FileAccess.open("res://tmp/import_dependencies.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(dependencies, "\t"))
	print("Dependências importadas: ", dependencies.size())
	quit()

func _scan(path: String, result: Dictionary) -> void:
	for directory in DirAccess.get_directories_at(path):
		_scan(path.path_join(directory), result)
	for filename in DirAccess.get_files_at(path):
		if filename.get_extension() not in ["glb", "gltf", "obj", "tres", "tscn", "scn", "res"]: continue
		var resource := path.path_join(filename)
		var paths: Array = []
		for dependency in ResourceLoader.get_dependencies(resource):
			paths.append(dependency.get_slice("::", dependency.get_slice_count("::") - 1))
		result[resource.trim_prefix("res://")] = paths
