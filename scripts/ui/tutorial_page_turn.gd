extends Node2D
## Uma folha subdividida dobra ao redor da lombada; a gravura viaja com ela.

var paper: Texture2D
var illustration: Texture2D
var illustration_rect := Rect2(59, 25, 616, 925)
var ink_material: ShaderMaterial:
	set(value):
		ink_material = value
		if is_instance_valid(_ink_layer): _ink_layer.material = value
var _ink_layer: Node2D
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()
		if is_instance_valid(_ink_layer): _ink_layer.queue_redraw()
var backwards := false
const WIDTH := 746.0
const HEIGHT := 975.0


class InkLayer extends Node2D:
	var page: Node2D
	func _draw() -> void:
		page._draw_ink(self)


func _ready() -> void:
	_ink_layer = InkLayer.new()
	_ink_layer.page = self
	_ink_layer.material = ink_material
	add_child(_ink_layer)


func _draw() -> void:
	if paper == null:
		return
	var angle := progress * PI
	var direction := -1.0 if backwards else 1.0
	var projected_width := cos(angle) * WIDTH * direction
	var curl := sin(angle) * 110.0
	var back := progress > 0.5
	# Narrow strips produce a curved leaf, rather than a flat disappearing card.
	for strip in range(36):
		var u0 := float(strip) / 36.0
		var u1 := float(strip + 1) / 36.0
		var x0 := u0 * projected_width
		var x1 := u1 * projected_width
		var lift0 := sin(u0 * PI * 0.85) * curl
		var lift1 := sin(u1 * PI * 0.85) * curl
		var points := PackedVector2Array([
			Vector2(x0, -lift0), Vector2(x1, -lift1),
			Vector2(x1, HEIGHT + lift1 * 0.25), Vector2(x0, HEIGHT + lift0 * 0.25),
		])
		var shade := 1.0 - sin(angle) * (0.13 + 0.24 * u0)
		var tint := Color(shade, shade, shade, 1.0)
		var uv0 := 0.5 + u0 * 0.465
		var uv1 := 0.5 + u1 * 0.465
		if back:
			uv0 = 0.5 - u0 * 0.465
			uv1 = 0.5 - u1 * 0.465
		draw_polygon(points, PackedColorArray([tint]), PackedVector2Array([
			Vector2(uv0, 0.025), Vector2(uv1, 0.025), Vector2(uv1, 0.97), Vector2(uv0, 0.97),
		]), paper)


func _draw_ink(canvas: Node2D) -> void:
	var angle := progress * PI
	var direction := -1.0 if backwards else 1.0
	var projected_width := cos(angle) * WIDTH * direction
	var curl := sin(angle) * 110.0
	# Pigment travels with the same fold, using the live-page print material.
	if progress <= 0.5 and illustration != null:
		for strip in range(28):
			var u0 := float(strip) / 28.0
			var u1 := float(strip + 1) / 28.0
			var page0 := (illustration_rect.position.x + u0 * illustration_rect.size.x) / WIDTH
			var page1 := (illustration_rect.position.x + u1 * illustration_rect.size.x) / WIDTH
			var lift0 := sin(page0 * PI * 0.85) * curl
			var lift1 := sin(page1 * PI * 0.85) * curl
			var points := PackedVector2Array([
				Vector2(page0 * projected_width, illustration_rect.position.y - lift0), Vector2(page1 * projected_width, illustration_rect.position.y - lift1),
				Vector2(page1 * projected_width, illustration_rect.end.y + lift1 * 0.25), Vector2(page0 * projected_width, illustration_rect.end.y + lift0 * 0.25),
			])
			canvas.draw_polygon(points, PackedColorArray([Color.WHITE]), PackedVector2Array([
				Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1),
			]), illustration)
