class_name HUDTimer
extends PanelContainer

## Componente de cronômetro do HUD conectado por sinais ao EdictTimer.
## Exibe o tempo restante de forma contínua e determinística.
## Os avisos visuais de urgência dependem exclusivamente do tempo decorrido
## (segundos numéricos), sem qualquer dependência da taxa de quadros (framerate).

signal time_updated(remaining: float, duration: float)
signal warning_triggered(level: int, remaining: float)
signal timer_expired()

const DUNE_FONT: FontFile = preload("res://assets/fonts/dune_rise.otf")
const JUPITER_FONT: FontFile = preload("res://assets/fonts/jupiter_pro.otf")

const WARNING_THRESHOLD: float = 5.0
const CRITICAL_THRESHOLD: float = 2.5

const COLOR_NORMAL_BORDER := Color(0.38, 0.61, 1.0, 0.72)
const COLOR_NORMAL_TEXT := Color(1.0, 1.0, 1.0, 1.0)
const COLOR_NORMAL_BAR := Color(0.38, 0.65, 1.0, 0.95)

const COLOR_WARNING_BORDER := Color(0.96, 0.72, 0.22, 0.90)
const COLOR_WARNING_TEXT := Color(0.98, 0.88, 0.55, 1.0)
const COLOR_WARNING_BAR := Color(0.96, 0.72, 0.22, 0.95)

const COLOR_CRITICAL_BORDER := Color(0.96, 0.32, 0.32, 0.95)
const COLOR_CRITICAL_TEXT := Color(1.0, 0.60, 0.60, 1.0)
const COLOR_CRITICAL_BAR := Color(0.96, 0.32, 0.32, 0.95)

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar

var duration: float = 15.0
var remaining: float = 0.0
var is_timed_phase: bool = false
var _warning_level: int = 0
var _pulse_tween: Tween
var _panel_style: StyleBoxFlat
var _bar_fill_style: StyleBoxFlat


func _ready() -> void:
	_setup_styles()
	visible = false


func _setup_styles() -> void:
	var existing = get_theme_stylebox("panel")
	if existing is StyleBoxFlat:
		_panel_style = existing.duplicate()
	else:
		_panel_style = StyleBoxFlat.new()
		_panel_style.bg_color = Color(0.02, 0.035, 0.11, 0.85)
		_panel_style.border_width_left = 1
		_panel_style.border_width_top = 1
		_panel_style.border_width_right = 1
		_panel_style.border_width_bottom = 1
		_panel_style.border_color = COLOR_NORMAL_BORDER
		_panel_style.corner_radius_top_left = 14
		_panel_style.corner_radius_top_right = 14
		_panel_style.corner_radius_bottom_right = 14
		_panel_style.corner_radius_bottom_left = 14
		_panel_style.shadow_color = Color(0.05, 0.18, 0.65, 0.40)
		_panel_style.shadow_size = 10
		_panel_style.content_margin_left = 16.0
		_panel_style.content_margin_right = 16.0
		_panel_style.content_margin_top = 8.0
		_panel_style.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", _panel_style)

	# Garante fill style próprio para que a cor possa ser alterada em runtime.
	_bar_fill_style = StyleBoxFlat.new()
	_bar_fill_style.bg_color = COLOR_NORMAL_BAR
	_bar_fill_style.corner_radius_top_left = 2
	_bar_fill_style.corner_radius_top_right = 2
	_bar_fill_style.corner_radius_bottom_right = 2
	_bar_fill_style.corner_radius_bottom_left = 2
	if progress_bar != null:
		progress_bar.add_theme_stylebox_override("fill", _bar_fill_style)

	if title_label != null:
		title_label.add_theme_font_override("font", JUPITER_FONT)
		title_label.add_theme_font_size_override("font_size", 13)
		title_label.add_theme_color_override("font_color", Color(0.72, 0.82, 1.0, 0.9))

	if time_label != null:
		time_label.add_theme_font_override("font", DUNE_FONT)
		time_label.add_theme_font_size_override("font_size", 26)
		time_label.add_theme_color_override("font_color", COLOR_NORMAL_TEXT)


## Configura o modo de resolução da fase e inicializa o cronômetro.
func configure_phase(is_timed: bool, seconds_per_edict: float = 15.0) -> void:
	is_timed_phase = is_timed
	duration = maxf(seconds_per_edict, 1.0)
	remaining = duration
	_warning_level = 0
	_apply_visual_state(0)
	if not is_timed_phase:
		visible = false
	else:
		visible = true
		_update_display(remaining)


## Conecta aos sinais emitidos pelo EdictTimer determinístico.
func connect_to_timer(edict_timer: Node) -> void:
	if edict_timer == null:
		return
	if edict_timer.has_signal("tick") and not edict_timer.tick.is_connected(set_time):
		edict_timer.tick.connect(set_time)
	if edict_timer.has_signal("expired") and not edict_timer.expired.is_connected(_on_timer_expired):
		edict_timer.expired.connect(_on_timer_expired)


## Chamado a cada tick com o tempo restante em segundos.
func set_time(seconds_left: float, custom_duration: float = -1.0) -> void:
	if not is_timed_phase:
		return
	if custom_duration > 0.0:
		duration = custom_duration
	remaining = maxf(seconds_left, 0.0)
	visible = true
	_update_display(remaining)
	_evaluate_warnings(remaining)
	time_updated.emit(remaining, duration)


func _update_display(time_value: float) -> void:
	var display_seconds := ceili(time_value)
	if time_label != null:
		time_label.text = "%ds" % display_seconds

	if progress_bar != null:
		progress_bar.max_value = duration
		progress_bar.value = time_value


## Avalia os limiares de aviso estritamente por segundos (independente de framerate).
func _evaluate_warnings(time_value: float) -> void:
	var new_level := 0
	if time_value <= 0.0:
		new_level = 2
	elif time_value <= CRITICAL_THRESHOLD:
		new_level = 2
	elif time_value <= WARNING_THRESHOLD:
		new_level = 1

	if new_level != _warning_level:
		_warning_level = new_level
		_apply_visual_state(_warning_level)
		warning_triggered.emit(_warning_level, time_value)


func _apply_visual_state(level: int) -> void:
	var border_color: Color
	var text_color: Color
	var bar_color: Color

	match level:
		1:
			border_color = COLOR_WARNING_BORDER
			text_color = COLOR_WARNING_TEXT
			bar_color = COLOR_WARNING_BAR
			_trigger_pulse(1.06, 0.22)
		2:
			border_color = COLOR_CRITICAL_BORDER
			text_color = COLOR_CRITICAL_TEXT
			bar_color = COLOR_CRITICAL_BAR
			_trigger_pulse(1.10, 0.16)
		_:
			border_color = COLOR_NORMAL_BORDER
			text_color = COLOR_NORMAL_TEXT
			bar_color = COLOR_NORMAL_BAR

	if _panel_style != null:
		_panel_style.border_color = border_color
	if time_label != null:
		time_label.add_theme_color_override("font_color", text_color)
	if progress_bar != null and _bar_fill_style != null:
		_bar_fill_style.bg_color = bar_color
		progress_bar.add_theme_stylebox_override("fill", _bar_fill_style)


func _trigger_pulse(peak_scale: float, half_duration: float) -> void:
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE * peak_scale, half_duration)
	_pulse_tween.set_ease(Tween.EASE_IN)
	_pulse_tween.tween_property(self, "scale", Vector2.ONE, half_duration)


func _on_timer_expired() -> void:
	if not is_timed_phase:
		return
	remaining = 0.0
	_update_display(0.0)
	_apply_visual_state(2)
	timer_expired.emit()


func hide_timer() -> void:
	visible = false
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	scale = Vector2.ONE
