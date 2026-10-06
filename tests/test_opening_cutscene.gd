extends SceneTree

var failures := PackedStringArray()

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
    main.get_node("OpeningCutscene").duration_scale = 0.3
    root.add_child(main)
    var music := main.get_node("Music") as AudioStreamPlayer
    _expect(not music.playing, "A música deve aguardar o primeiro quadro da abertura.")
    await process_frame
    await _until(func(): return music.playing)
    var cutscene := main.get_node("OpeningCutscene") as OpeningCutscene
    var player := main.get_node("World/Player") as GridPlayer
    var model := player.get_node("Model")
    var manager := main.get_node("PhaseManager") as PhaseManager
    var queen := main.get_node("World/Seraph") as Node3D
    var rig := main.get_node("World/BoardCamera") as BoardOrbitCamera
    var presentation := (main.get_node("HUD") as GameHUD).card_presentation
    _expect(cutscene._running and manager.current_phase == 0 and not player.input_enabled, "A abertura deve bloquear a grade até terminar.")
    _expect(not player.visible and not queen.visible and player.current_cell == Vector2i(2, 2), "A cena deve começar com o tabuleiro vazio.")
    _expect(model.animation_player.has_animation("intro_arrival") and model.animation_player.has_animation("standing_death"), "O personagem deve ter caminhada nativa de chegada e morte do Mixamo.")
    _expect(main.get_node("GameAudio")._voices.is_empty() and not cutscene.teleport_sound.playing, "O primeiro quadro deve começar sem efeitos sonoros adicionais.")
    _expect(is_equal_approx(cutscene._length / cutscene.duration_scale, OpeningCutscene.TOTAL_LENGTH), "A abertura deve incluir os dois planos serenos.")
    _expect(music.stream == load("res://assets/audio/music/priest_opening.ogg") and absf(music.stream.get_length()-OpeningCutscene.TOTAL_LENGTH)<0.1, "A composição deve cobrir toda a abertura estendida.")
    await _story(cutscene, OpeningCutscene.FIRST_ESTABLISHING_END * 0.5)
    _expect(not queen.visible and not player.visible and not cutscene.teleport.visible, "O primeiro plano deve mostrar o cenário sem a rainha ou o jogador.")
    await _story(cutscene, OpeningCutscene.EMPTY_BOARD_END - 0.5)
    _expect(not queen.visible and not player.visible and not cutscene.teleport.visible, "O segundo plano deve conservar o tabuleiro vazio e a rainha oculta.")
    await _story(cutscene, OpeningCutscene.PORTAL_START + 0.8)
    _expect(cutscene.teleport.visible and cutscene.teleport.aperture > 0.8 and not player.visible, "A fenda deve abrir antes do primeiro passo.")
    _expect(cutscene.teleport.definition.particles.size() == 5 and cutscene.teleport._models.size() == 2, "A chegada deve usar as cinco definições e os dois modelos do mod original.")
    _expect(cutscene.teleport.get_node_or_null("OpaqueRift") == null and cutscene.teleport_sound.stream == load("res://assets/audio/sfx/ascian_arrival.wav"), "A fenda e o som anteriores devem ser substituídos pela chegada Ascian.")
    await _story(cutscene, OpeningCutscene.ENTRY_START + 1.45)
    _expect(player.visible and model.animation_player.current_animation == "intro_arrival", "A chegada deve iniciar a caminhada lenta original do FFXIV.")
    _expect(model.animation_player.get_animation("intro_arrival").loop_mode == Animation.LOOP_LINEAR, "O ciclo de caminhada deve continuar durante todo o plano.")
    _expect(is_zero_approx(model.cinematic_gaze.lift), "O personagem deve começar a caminhada sem levantar o rosto imediatamente.")
    model.animation_player.seek(0.0, true)
    model.animation_player.advance(0.0)
    var skeleton := model.skeleton as Skeleton3D
    var first_arm := skeleton.get_bone_pose_rotation(skeleton.find_bone("j_ude_a_l"))
    model.animation_player.seek(0.8, true)
    model.animation_player.advance(0.0)
    var second_arm := skeleton.get_bone_pose_rotation(skeleton.find_bone("j_ude_a_l"))
    _expect(first_arm.angle_to(second_arm) > 0.04, "A caminhada deve movimentar os braços em vez de mantê-los presos ao tronco.")
    var first_z := player.global_position.z
    await _story(cutscene, OpeningCutscene.ENTRY_START + 6.2)
    _expect(player.global_position.z < first_z - 3.0 and not queen.visible, "O personagem deve avançar enquanto a câmera acompanha a caminhada.")
    _expect(cutscene._spawn_anchor.z < 19.0 and player.global_position.z >= cutscene._arrival_anchor.z, "A caminhada cinematográfica deve permanecer sobre o tabuleiro.")
    _expect(player.current_cell == Vector2i(2, 2), "A caminhada cinematográfica não deve mudar a casa lógica.")
    await _story(cutscene, OpeningCutscene.ENTRY_START + 9.0)
    _expect(model.cinematic_gaze.lift > 0.99 and not queen.visible, "Depois de alguns passos, o rosto deve levantar antes do corte para a rainha.")
    await _story(cutscene, OpeningCutscene.WALK_END + 0.2)
    _expect(player.global_position.distance_to(cutscene._arrival_anchor) < 0.01 and model.animation_player.current_animation == "breathing_idle", "A entrada deve terminar na casa central, em repouso.")
    await _story(cutscene, OpeningCutscene.QUEEN_REVEAL + 0.4)
    _expect(queen.visible and cutscene.cinematic_camera.global_position.x < -25.0, "A rainha deve aparecer no plano de revelação do mundo.")
    await _story(cutscene, OpeningCutscene.QUEEN_CLOSE + 0.4)
    var queen_head := cutscene._seraph_head_position(queen)
    _expect(cutscene.cinematic_camera.global_position.z > queen_head.z and absf(cutscene.cinematic_camera.global_position.x - queen_head.x) < 0.5, "O plano final deve começar diante do rosto da rainha.")
    await _story(cutscene, OpeningCutscene.TOTAL_LENGTH - 1.0)
    _expect(is_instance_valid(main._incoming_music) and main._incoming_music.playing and music.playing, "As duas trilhas devem se sobrepor durante o final da câmera, sem silêncio.")
    _expect(music.volume_db > -35.0 and main._incoming_music.volume_db > -35.0, "A passagem de música deve usar ganhos suaves, sem queda brusca.")
    await _until(func(): return manager.current_phase == 1 and (main.get_node("HUD") as GameHUD).tutorial_book.visible)
    _expect(not cutscene._running and not cutscene.teleport.visible and not model.cinematic, "A abertura deve encerrar o portal e devolver o personagem à gameplay.")
    _expect(root.get_camera_3d() == rig.camera and rig.gameplay_mode and not rig.cinematic_mode, "A câmera do tabuleiro deve assumir o controle no fim.")
    _expect(music.stream == load("res://assets/audio/music/5.21 Ascension.ogg") and music.playing, "A música do jogo deve começar depois da abertura.")
    _expect(is_equal_approx(music.volume_db, -12.0) and main._incoming_music == null, "A passagem deve terminar com uma única trilha no volume normal.")
    main.get_node("Music").stop()
    presentation.cancel()
    main.queue_free()
    await process_frame
    await process_frame
    for failure in failures: printerr("FALHA: " + failure)
    print("PRIEST_OPENING_FAILURES: ", failures.size())
    quit(0 if failures.is_empty() else 1)

func _story(cutscene: OpeningCutscene, seconds: float) -> bool:
    return await _until(func(): return cutscene._elapsed >= seconds * cutscene.duration_scale)

func _until(predicate: Callable) -> bool:
    var deadline := Time.get_ticks_msec() + 18000
    while Time.get_ticks_msec() < deadline:
        if predicate.call(): return true
        await process_frame
    failures.append("Tempo esgotado esperando a abertura.")
    return false

func _expect(condition: bool, message: String) -> void:
    if not condition: failures.append(message)
