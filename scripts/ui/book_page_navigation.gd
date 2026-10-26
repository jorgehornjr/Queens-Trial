extends Node2D

const INK := Color(0.58, 0.35, 0.12)
var _back := false
var _forward := false


func set_available(back: bool, forward: bool) -> void:
	if _back == back and _forward == forward: return
	_back = back
	_forward = forward
	queue_redraw()


func _draw() -> void:
	_arrow(Vector2(151, 955), -1.0, _back)
	_arrow(Vector2(1449, 955), 1.0, _forward)


func _arrow(center: Vector2, direction: float, enabled: bool) -> void:
	var color := Color(INK, 0.85 if enabled else 0.16)
	var tip := center + Vector2(direction * 20.0, 0)
	draw_polyline(PackedVector2Array([center + Vector2(-direction * 1.0, -12), tip, center + Vector2(-direction * 1.0, 12)]), color, 2.1, true)
