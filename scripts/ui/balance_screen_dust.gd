class_name BalanceScreenDust
extends Control
## Foreground glints drift with the same gust that carries the player.

const DUST_COUNT := 210
var flow_direction := 0
var strength := 0.0:
	set(value):
		strength = clampf(value, 0.0, 1.0)
		visible = strength > 0.001 and flow_direction != 0
var _motes: Array[Vector4] = []
var _phases: PackedFloat32Array = []
var _glint: ImageTexture
var _elapsed := 0.0
var _emitting := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	var sprite := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in range(64):
		for x in range(64):
			var p := (Vector2(x, y) - Vector2(31.5, 31.5)) / 31.5
			var halo := exp(-p.length_squared() * 12.0) * 0.22
			var core := exp(-p.length_squared() * 180.0)
			var rays := exp(-absf(p.x) * 85.0) * exp(-absf(p.y) * 5.0)
			rays += exp(-absf(p.y) * 85.0) * exp(-absf(p.x) * 5.0)
			sprite.set_pixel(x, y, Color(1.0, 0.77, 0.32, minf(halo + core + rays * 0.42, 1.0)))
	_glint = ImageTexture.create_from_image(sprite)
	clear()


func start(direction: int) -> void:
	flow_direction = direction
	_elapsed = 0.0
	_emitting = true
	_motes.clear()
	_phases.clear()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for index in range(DUST_COUNT):
		var depth := rng.randf()
		_motes.append(Vector4(rng.randf(), rng.randf(), lerpf(0.16, 0.58, depth), lerpf(16.0, 54.0, depth)))
		_phases.append(rng.randf_range(0.0, TAU))
	set_process(true)


func fade() -> void:
	_emitting = false


func clear() -> void:
	flow_direction = 0
	strength = 0.0
	_emitting = false
	_motes.clear()
	_phases.clear()
	set_process(false)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	for index in range(_motes.size()):
		var mote := _motes[index]
		mote.x += float(flow_direction) * mote.z * delta
		if _emitting:
			mote.x = wrapf(mote.x, -0.04, 1.04)
		_motes[index] = mote
	queue_redraw()
	if not _emitting and strength <= 0.001:
		set_process(false)


func _draw() -> void:
	if strength <= 0.001 or _glint == null:
		return
	var fit := minf(size.x / 1920.0, size.y / 1080.0)
	for index in range(_motes.size()):
		var mote := _motes[index]
		var phase := _phases[index]
		var center := Vector2(mote.x * size.x, (mote.y + sin(_elapsed * 1.9 + phase) * 0.012) * size.y)
		var edges := smoothstep(-0.01, 0.05, mote.x) * (1.0 - smoothstep(0.95, 1.01, mote.x))
		var alpha := strength * edges * (0.62 + 0.30 * sin(_elapsed * 5.0 + phase))
		var diameter := mote.w * fit
		var tint := Color(1.0, 0.91, 0.67, alpha)
		# A short tapered wake gives the tiny points a readable direction.
		var tail := Vector2(float(-flow_direction) * diameter * 1.8, 0.0)
		for segment in range(3):
			var from := center + tail * float(segment) / 3.0
			var to := center + tail * float(segment + 1) / 3.0
			draw_line(from, to, Color(1.0, 0.7, 0.23, alpha * 0.15 * (1.0 - float(segment) / 3.0)), maxf(0.8, fit), true)
		draw_texture_rect(_glint, Rect2(center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter), false, tint)
