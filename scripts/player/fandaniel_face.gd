extends Node3D

var attachment: BoneAttachment3D
var _shadow_material: StandardMaterial3D

func configure(skeleton: Skeleton3D) -> void:
	var head := skeleton.find_bone("j_kao")
	attachment = BoneAttachment3D.new()
	attachment.name = "HiddenHoodFace"
	attachment.bone_name = "j_kao"
	skeleton.add_child(attachment)


	var shadow := MeshInstance3D.new()
	shadow.name = "ShadowedFace"
	shadow.mesh = _shadow_head_mesh()
	shadow.transform = skeleton.get_bone_global_rest(head).affine_inverse()
	_shadow_material = StandardMaterial3D.new()
	_shadow_material.albedo_color = Color(0.009, 0.007, 0.012)
	_shadow_material.roughness = 1.0
	_shadow_material.metallic_specular = 0.0
	_shadow_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_HASH
	shadow.material_override = _shadow_material
	attachment.add_child(shadow)

func set_arrival_reveal(amount: float) -> void:
	_shadow_material.albedo_color.a = clampf(amount, 0.0, 1.0)

func _shadow_head_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for latitude in range(20):
		for longitude in range(32):
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var theta := PI * float(latitude + corner.x) / 20.0
				var phi := TAU * float(longitude + corner.y) / 32.0
				var y := cos(theta)
				var x := sin(theta) * cos(phi)
				var z := sin(theta) * sin(phi)
				var jaw := lerpf(0.72, 1.0, smoothstep(-1.0, 0.0, y))
				var nose := exp(-pow(x / 0.17, 2.0) - pow((y + 0.02) / 0.30, 2.0)) * 0.012
				var brow := exp(-pow((y - 0.28) / 0.13, 2.0)) * 0.003
				surface.add_vertex(Vector3(x * 0.079 * jaw, 1.585 + y * 0.120, 0.004 + z * 0.066 + (nose + brow) * maxf(z, 0.0)))
	surface.generate_normals()
	return surface.commit()
