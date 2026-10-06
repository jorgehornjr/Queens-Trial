extends Node3D
## Original red spectral emblem, attached to the animated hood's head bone.

const TEXTURE := preload("res://assets/textures/effects/priest_face_sigil.svg")
const SHADER := preload("res://shaders/priest_face_sigil.gdshader")
var attachment: BoneAttachment3D

func configure(skeleton: Skeleton3D) -> void:
	var head := skeleton.find_bone("Head")
	if head < 0:
		return
	attachment = BoneAttachment3D.new()
	attachment.name = "SpectralFace"
	attachment.bone_name = "Head"
	skeleton.add_child(attachment)
	# Author in skeleton rest coordinates, then convert into head-local space.
	var face_rest := Transform3D(Basis.IDENTITY, Vector3(0.0, 1.935, 0.205))
	var local := skeleton.get_bone_global_rest(head).affine_inverse() * face_rest
	for is_halo in [true, false]:
		var surface := MeshInstance3D.new()
		surface.name = "RedAura" if is_halo else "OriginalEmblem"
		surface.mesh = _curved_face()
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surface.transform = local
		if is_halo:
			surface.position += local.basis.z * 0.001
		var material := ShaderMaterial.new()
		material.shader = SHADER
		material.set_shader_parameter("sigil", TEXTURE)
		material.set_shader_parameter("halo", is_halo)
		material.render_priority = 1 if is_halo else 2
		surface.material_override = material
		attachment.add_child(surface)
	var light := OmniLight3D.new()
	light.name = "RedFaceLight"
	light.transform = local
	light.light_color = Color(1.0, 0.018, 0.003)
	light.light_energy = 0.10
	light.omni_range = 0.52
	light.omni_attenuation = 2.2
	attachment.add_child(light)

func _curved_face() -> ArrayMesh:
	var builder := SurfaceTool.new()
	builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 12
	var rows := 16
	for row in range(rows):
		for column in range(columns):
			for corner in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
				var uv := Vector2(float(column + corner.x) / columns, float(row + corner.y) / rows)
				var x := (uv.x - 0.5) * 0.190
				var y := (0.5 - uv.y) * 0.275
				# Bend towards the cheeks, with a slight forward tilt at the chin.
				var z := -0.027 * pow(absf(x) / 0.095, 2.0) - y * 0.06
				builder.set_uv(uv)
				builder.add_vertex(Vector3(x, y, z))
	builder.generate_normals()
	return builder.commit()
