class_name RenderQuality
extends RefCounted

const PREPARED := &"render_quality_prepared"
const INTEGRATED_PIXELS := 1280.0 * 720.0

static func uses_integrated_graphics() -> bool:
	return RenderingServer.get_video_adapter_type() == RenderingDevice.DEVICE_TYPE_INTEGRATED_GPU


static func prepare(window: Window) -> void:
	if window.has_meta(PREPARED) or not uses_integrated_graphics(): return
	window.set_meta(PREPARED, true)
	window.size_changed.connect(_fit_integrated_resolution.bind(window))
	_fit_integrated_resolution(window)


static func _fit_integrated_resolution(window: Window) -> void:
	# Limita somente o cenário 3D; livros e interface mantêm a resolução da janela.
	var pixels := maxf(float(window.size.x) * float(window.size.y), 1.0)
	var scale := clampf(sqrt(INTEGRATED_PIXELS / pixels), 0.25, 1.0)
	window.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if scale < 1.0 else Viewport.SCALING_3D_MODE_BILINEAR
	window.scaling_3d_scale = scale


static func configure_environment(environment: Environment) -> void:
	if uses_integrated_graphics(): environment.ssil_enabled = false
