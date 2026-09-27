extends SceneTree

const HudScene = preload("res://scenes/ui/hud.tscn")
const HUDTimerModel = preload("res://scripts/ui/hud_timer.gd")
const HUDOrderDisplayModel = preload("res://scripts/ui/hud_order_display.gd")
const EdictTimerModel = preload("res://scripts/gameplay/edict_timer.gd")
const EditoStateMachineModel = preload("res://scripts/gameplay/edito_state_machine.gd")

var failures := PackedStringArray()


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_timer_component()
	await _test_timer_framerate_independence()
	await _test_timer_visibility_per_resolution()
	await _test_order_sequence_and_active_pair()
	await _test_hud_signal_connections()
	await _test_round_edicts_preservation()

	if failures.is_empty():
		print("OK: QT-N2-UI-001 validado (timer no HUD, avisos sem framerate, sequência de ordens e par ativo).")
		quit(0)
		return

	for failure in failures:
		printerr("FALHA: " + failure)
	quit(1)


func _test_timer_component() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame

	_expect(hud.timer_display != null, "HUD deve conter o componente TimerDisplay.")
	_expect(hud.order_display != null, "HUD deve conter o componente OrderDisplay.")
	_expect(hud.timer_display is HUDTimerModel, "TimerDisplay deve ser uma instância de HUDTimer.")
	_expect(hud.order_display is HUDOrderDisplayModel, "OrderDisplay deve ser uma instância de HUDOrderDisplay.")

	hud.free()
	await process_frame


func _test_timer_framerate_independence() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame

	var timer_ui := hud.timer_display
	timer_ui.configure_phase(true, 15.0)

	var warnings_received: Array[int] = []
	timer_ui.warning_triggered.connect(func(level: int, _rem: float): warnings_received.append(level))

	# Simulação com grande salto de tempo (ex: lag ou framerate baixo de 10fps: salto de 7s direto para 4.8s)
	timer_ui.set_time(7.0)
	_expect(warnings_received.is_empty(), "Com 7 segundos não deve haver aviso.")
	_expect(timer_ui.time_label.text == "7s", "Texto deve exibir 7s.")

	# Salto cruzando o limiar de 5s diretamente para 4.8s
	timer_ui.set_time(4.8)
	_expect(warnings_received.has(1), "Aviso nível 1 deve disparar ao cruzar 5s independentemente do salto/framerate.")
	_expect(timer_ui.time_label.text == "5s", "Com 4.8s arredondamento ceil deve exibir 5s.")

	# Salto cruzando o limiar crítico de 2.5s diretamente para 2.0s
	timer_ui.set_time(2.0)
	_expect(warnings_received.has(2), "Aviso crítico nível 2 deve disparar ao cruzar 2.5s independentemente do framerate.")

	# Expirando o tempo
	var expired_emitted := false
	timer_ui.timer_expired.connect(func(): expired_emitted = true)
	timer_ui.set_time(0.0)
	_expect(timer_ui.time_label.text == "0s", "Ao zerar, deve exibir 0s.")

	hud.free()
	await process_frame


func _test_timer_visibility_per_resolution() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame

	# Fases 1 a 5 (resolution: "moves", seconds_per_edict: 0)
	var phase1_data := {
		"number": 1,
		"resolution": "moves",
		"seconds_per_edict": 0,
		"edict_count": 1,
		"edict_values": [4]
	}
	hud.set_phase(1, phase1_data, 0)
	_expect(not hud.timer_display.visible, "O cronômetro deve ficar oculto nas fases com resolução por movimentos (1-5).")

	# Fases 6 a 10 (resolution: "timer", seconds_per_edict: 15)
	var phase6_data := {
		"number": 6,
		"resolution": "timer",
		"seconds_per_edict": 15,
		"edict_count": 2,
		"edict_values": [3, 4],
		"first_pair": ["bishop", "bishop"],
		"second_pair": ["rook", "rook"]
	}
	hud.set_phase(6, phase6_data, 0)
	_expect(hud.timer_display.visible, "O cronômetro deve ficar visível nas fases com resolução por tempo (6-10).")
	_expect(hud.timer_display.time_label.text == "15s", "O cronômetro deve iniciar exibindo 15s.")

	hud.free()
	await process_frame


func _test_order_sequence_and_active_pair() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame

	var phase4_data := {
		"number": 4,
		"resolution": "moves",
		"seconds_per_edict": 0,
		"edict_count": 2,
		"edict_values": [2, 4],
		"first_pair": ["rook", "rook"],
		"second_pair": ["rook", "rook"],
		"piece_waves": [
			[
				{"type": "rook", "side": "left", "edge_slot": 2, "move_value": 2},
				{"type": "rook", "side": "right", "edge_slot": 0, "move_value": 1}
			],
			[
				{"type": "rook", "side": "top", "edge_slot": 0, "move_value": 4},
				{"type": "rook", "side": "bottom", "edge_slot": 1, "move_value": 2}
			]
		]
	}

	hud.set_phase(4, phase4_data, 0)
	hud.order_display.visible = true

	var order_ui := hud.order_display
	# Ambas as ordens devem estar visíveis sem ambiguidade
	_expect(order_ui.order1_panel.visible, "Painel da 1ª ordem deve estar visível.")
	_expect(order_ui.order2_panel.visible, "Painel da 2ª ordem deve estar visível.")
	_expect(order_ui.order1_value.text == "II", "Valor da 1ª ordem deve ser II.")
	_expect(order_ui.order2_value.text == "IV", "Valor da 2ª ordem deve ser IV.")

	# Na 1ª ordem, ela deve estar ativa e com o par ativo horizontal
	_expect(order_ui.order1_status.text == "ATIVA", "1ª ordem deve iniciar com status ATIVA.")
	_expect(order_ui.order2_status.text == "A SEGUIR", "2ª ordem deve indicar A SEGUIR.")
	_expect(order_ui.active_pair_label.text.contains("Torre") and order_ui.active_pair_label.text.contains("Horizontal"),
		"Par ativo da 1ª ordem deve ser Torre • Horizontal.")

	# Avançando para a 2ª ordem
	order_ui.set_active_order(1)
	_expect(order_ui.order1_status.text == "CONCLUÍDA", "1ª ordem deve ser marcada como CONCLUÍDA.")
	_expect(order_ui.order2_status.text == "ATIVA", "2ª ordem deve ser marcada como ATIVA.")
	_expect(order_ui.active_pair_label.text.contains("Torre") and order_ui.active_pair_label.text.contains("Vertical"),
		"Par ativo da 2ª ordem deve ser Torre • Vertical.")

	hud.free()
	await process_frame


func _test_hud_signal_connections() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame

	var timer := EdictTimerModel.new()
	root.add_child(timer)
	var machine := EditoStateMachineModel.new()
	root.add_child(machine)

	hud.connect_gameplay_signals(machine, timer)

	# Testando propagação de tick de timer via sinal
	var phase6_data := {
		"number": 6,
		"resolution": "timer",
		"seconds_per_edict": 15,
		"edict_count": 2,
		"edict_values": [3, 4]
	}
	hud.set_phase(6, phase6_data, 0)
	timer.start(15.0)
	_expect(hud.timer_display.time_label.text == "15s", "Cronômetro deve refletir o sinal de início.")

	# Emite tick com 11.2s
	timer.tick.emit(11.2)
	_expect(hud.timer_display.time_label.text == "12s", "Cronômetro deve atualizar para 12s via sinal tick.")

	# Testando avanço de ordem via sinal da máquina
	machine.edito_iniciado.emit(1, 4)
	_expect(hud.order_display._active_order_index == 1, "OrderDisplay deve atualizar ordem ativa via sinal edito_iniciado.")

	timer.free()
	machine.free()
	hud.free()
	await process_frame


func _test_round_edicts_preservation() -> void:
	var hud := HudScene.instantiate() as GameHUD
	root.add_child(hud)
	await process_frame

	var reminder := hud.get_node("RoundEdicts") as Label
	_expect(reminder != null, "RoundEdicts deve existir para compatibilidade com testes legados.")
	_expect(is_equal_approx(reminder.anchor_left, 0.87) and is_equal_approx(reminder.anchor_top, 0.52),
		"RoundEdicts deve permanecer na posição 0.87, 0.52.")

	hud.free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
