extends Node2D
## A mesma capa rígida abre e fecha sobre a lombada: 0 aberta, 1 fechada.

var paper: Texture2D
var front: Texture2D
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()


func _draw() -> void:
	if paper == null or front == null: return
	var angle := progress * PI
	var width := lerpf(800.0, 640.0, progress)
	var height := lerpf(1067.0, 960.0, progress)
	var top := 51.0 * progress
	var projection := -cos(angle) * width
	var lift := sin(angle) * 75.0
	var points := PackedVector2Array([
		Vector2(0, top), Vector2(projection, top - lift),
		Vector2(projection, top + height + lift * 0.15), Vector2(0, top + height),
	])
	var front_visible := progress >= 0.5
	var uv := PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	]) if front_visible else PackedVector2Array([
		Vector2(0.5, 0), Vector2(0, 0), Vector2(0, 1), Vector2(0.5, 1),
	])
	var shade := 1.0 - sin(angle) * 0.28
	draw_polygon(points, PackedColorArray([Color(shade, shade, shade)]), uv, front if front_visible else paper)
	var edge_alpha := pow(sin(angle), 18.0) * 0.65
	draw_line(points[0], points[3], Color(0.28, 0.12, 0.10, edge_alpha), 2.0, true)
