class_name EdictTimer
extends Node

## Cronômetro determinístico de 15s por édito. Não usa Engine.pause nem o
## Timer nativo do Godot — controla o próprio "running" via _process(delta),
## pra que o phase_loop_controller possa pausar/retomar sem afetar o resto
## da árvore (animações, tweens etc. continuam correndo normalmente).

signal tick(remaining: float)
signal expired()

var duration: float = 15.0
var remaining: float = 0.0
var running: bool = false
var _expired_emitted: bool = false


func start(seconds: float) -> void:
	duration = seconds
	remaining = seconds
	running = true
	_expired_emitted = false
	tick.emit(remaining)


func pause() -> void:
	running = false


func resume() -> void:
	if remaining > 0.0 and not _expired_emitted:
		running = true


func stop() -> void:
	running = false
	remaining = 0.0
	_expired_emitted = false


func _process(delta: float) -> void:
	if not running or _expired_emitted:
		return
	remaining = maxf(remaining - delta, 0.0)
	tick.emit(remaining)
	if remaining <= 0.0:
		running = false
		_expired_emitted = true
		expired.emit()
