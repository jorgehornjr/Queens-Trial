extends SceneTree
const Constants = preload("res://scripts/core/game_constants.gd")
const BoardStateModel = preload("res://scripts/board/board_state.gd")
const Catalog = preload("res://scripts/data/phase_catalog.gd")
const PhaseManagerModel = preload("res://scripts/gameplay/fase_manager.gd")
const CameraRig = preload("res://scripts/camera/board_orbit_camera.gd")
const RookResolverModel = preload("res://scripts/pieces/rook_resolver.gd")
const AttackEventModel = preload("res://scripts/gameplay/attack_event.gd")
var failures := PackedStringArray()
func _initialize() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	_test_board_state()
	_test_attack_geometry()
	_test_campaign_catalog()
	_test_fase1_dados_completos()
	_test_fase2_dados_completos()
	_test_external_piece_spawn_points()
	_test_painter_board_materials()
	_test_player_visual()
	_test_untextured_piece_halos()
	await _test_board_camera()
	_test_celestial_environment()
	_test_solar_system()
	_test_forward_plus_configuration()
	_test_input_map()
	_test_procedural_seed_is_preserved()
	_test_rook_resolution()
	_test_attack_event()
	if failures.is_empty():
		print("OK: scaffold validado (grade, ataques e campanha).")
		quit(0)
		return
	for failure in failures:
		printerr("FALHA: %s" % failure)
	quit(1)
func _test_board_state() -> void:
	var state = BoardStateModel.new()
	_expect(state.is_inside(Vector2i(0, 0)), "A origem deve pertencer à grade.")
	_expect(state.is_inside(Vector2i(4, 4)), "A última casa deve pertencer à grade.")
	_expect(not state.is_inside(Vector2i(5, 4)), "Coluna 5 deve ficar fora da grade 5 x 5.")
	_expect(not state.can_player_enter(Constants.QUEEN_CELL), "A casa da Rainha deve ser bloqueada.")
	_expect(state.manhattan_distance(Vector2i(0, 0), Vector2i(3, 2)) == 5, "A distância deve ser Manhattan.")
	_expect(not state.set_safe_spot(Constants.QUEEN_CELL), "A casa central não pode ser safe spot.")
func _test_attack_geometry() -> void:
	var state = BoardStateModel.new()
	var rook_cells: Array[Vector2i] = state.rook_attack_cells(Vector2i(2, 0))
	_expect(rook_cells.size() == 8, "A Torre deve atacar oito casas em uma grade 5 x 5.")
	_expect(rook_cells.has(Vector2i(2, 4)), "A Torre deve atacar através da Rainha.")
	var bishop_cells: Array[Vector2i] = state.bishop_attack_cells(Vector2i(0, 0))
	_expect(bishop_cells.size() == 4, "O Bispo no canto deve atacar quatro casas.")
	_expect(bishop_cells.has(Vector2i(3, 3)), "O Bispo deve atacar através da Rainha.")
func _test_campaign_catalog() -> void:
	var campaign := Catalog.load_campaign()
	var catalog_errors := Catalog.validate_campaign(campaign)
	_expect(catalog_errors.is_empty(), "O catálogo deve reproduzir a progressão consolidada.")
	_expect(Catalog.find_phase(campaign, 1).get("edict_count") == 1, "A fase 1 deve usar um único édito.")
	_expect(Catalog.find_phase(campaign, 6).get("seconds_per_edict") == 15, "A fase 6 deve introduzir 15 segundos por édito.")
	_expect(Catalog.find_phase(campaign, 7).get("configuration") == "procedural", "A fase 7 deve ser procedural.")
	_expect(Catalog.find_phase(campaign, 9).get("configuration") == "procedural", "A fase 9 deve ser procedural.")
func _test_fase1_dados_completos() -> void:
	# Caso feliz: a fase 1 carrega com todos os dados esperados,
	# batendo com a especificação consolidada do jogo.
	var campaign := Catalog.load_campaign()
	var fase1 := Catalog.find_phase(campaign, 1)

	_expect(not fase1.is_empty(), "A fase 1 deve existir no catálogo.")
	_expect(int(fase1.get("number", -1)) == 1, "O número da fase 1 deve ser 1.")
	_expect(String(fase1.get("resolution", "")) == "moves", "A fase 1 deve usar resolução por movimentos, não por tempo.")
	_expect(int(fase1.get("edict_count", -1)) == 1, "A fase 1 deve ter exatamente um édito.")
	_expect(int(fase1.get("seconds_per_edict", -1)) == 0, "A fase 1 não deve ter limite de tempo por édito.")
	_expect((fase1.get("first_pair", null) as Array).is_empty(), "A fase 1 não deve ter peças no primeiro par (ainda é tutorial).")
	_expect((fase1.get("second_pair", null) as Array).is_empty(), "A fase 1 não deve ter peças no segundo par.")
	_expect(String(fase1.get("pair_order", "")) == "horizontal_first", "A ordem dos pares da fase 1 deve ser horizontal_first.")
	_expect(String(fase1.get("configuration", "")) == "fixed", "A fase 1 deve ser configuração fixa, não procedural.")

	# Caso de falha: um caminho de catálogo inexistente não deve
	# retornar um valor padrão disfarçado (sem fallback).
	var catalogo_invalido := Catalog.load_campaign("res://data/phases/arquivo_que_nao_existe.json")
	_expect(catalogo_invalido.is_empty(), "Um caminho de catálogo inválido deve retornar vazio, nunca um valor padrão disfarçado.")
func _test_fase2_dados_completos() -> void:
	# Caso feliz: a fase 2 carrega com os dados previstos na especificação
	# (dois éditos, ainda sem peças — introduz o safe spot).
	var campaign := Catalog.load_campaign()
	var fase2 := Catalog.find_phase(campaign, 2)

	_expect(not fase2.is_empty(), "A fase 2 deve existir no catálogo.")
	_expect(int(fase2.get("number", -1)) == 2, "O número da fase 2 deve ser 2.")
	_expect(String(fase2.get("resolution", "")) == "moves", "A fase 2 deve usar resolução por movimentos, não por tempo.")
	_expect(int(fase2.get("edict_count", -1)) == 2, "A fase 2 deve ter dois éditos (solução prevista pela especificação).")
	_expect(int(fase2.get("seconds_per_edict", -1)) == 0, "A fase 2 não deve ter limite de tempo por édito.")
	_expect((fase2.get("first_pair", null) as Array).is_empty(), "A fase 2 ainda não deve ter peças no primeiro par.")
	_expect((fase2.get("second_pair", null) as Array).is_empty(), "A fase 2 ainda não deve ter peças no segundo par.")
	_expect(String(fase2.get("pair_order", "")) == "horizontal_first", "A ordem dos pares da fase 2 deve ser horizontal_first.")
	_expect(String(fase2.get("configuration", "")) == "fixed", "A fase 2 deve ser configuração fixa, não procedural.")

	# Caso de falha: mesma garantia de "sem fallback" aplicada à fase 2.
	var catalogo_invalido := Catalog.load_campaign("res://data/phases/arquivo_que_nao_existe.json")
	_expect(catalogo_invalido.is_empty(), "Um caminho de catálogo inválido deve retornar vazio, nunca um valor padrão disfarçado.")


func _test_external_piece_spawn_points() -> void:
	var board_scene := load("res://scenes/board/Board.tscn") as PackedScene
	var board := board_scene.instantiate() as Board3D
	root.add_child(board)
	_expect(is_equal_approx(board.tile_size, 7.6), "As casas do tabuleiro monumental devem usar 7,6 unidades.")
	for corner_name in [&"NorthWest", &"NorthEast", &"SouthEast", &"SouthWest"]:
		var marker := board.get_spawn_marker(corner_name)
		_expect(marker != null, "O canto externo '%s' deve possuir um ponto de spawn." % corner_name)
		if marker != null:
			_expect(
				absf(marker.position.x) > 14.0 and absf(marker.position.z) > 14.0,
				"O spawn '%s' deve permanecer fora da grade jogável." % corner_name
			)
	_expect(board.get_node_or_null("PreviewPieces/Rook") != null, "A prévia da Torre deve estar montada na arena.")
	_expect(board.get_node_or_null("PreviewPieces/Bishop") != null, "A prévia do Bispo deve estar montada na arena.")
	_expect(board.find_child("BoardSurface", true, false) != null, "A superfície simples do tabuleiro deve estar carregada.")
	_expect(board.find_children("Casa_C*", "MeshInstance3D", true, false).size() == 25, "O tabuleiro sem estrela deve preservar as 25 casas separadas.")
	board.free()


func _test_painter_board_materials() -> void:
	var board := (load("res://scenes/board/Board.tscn") as PackedScene).instantiate() as Board3D
	root.add_child(board)
	var meshes := board.board_visual.find_children("*", "MeshInstance3D", true, false)
	_expect(meshes.size() == 36, "O modelo do Painter deve manter 36 malhas, sem duplicatas.")
	var materials: Dictionary = {}
	var widened_bars := 0
	for mesh: MeshInstance3D in meshes:
		_expect(mesh.is_inside_tree(), "As malhas pintadas devem entrar corretamente na árvore.")
		for surface in mesh.mesh.get_surface_count():
			var material := mesh.get_active_material(surface) as StandardMaterial3D
			_expect(material != null, "Cada superfície pintada deve usar StandardMaterial3D.")
			if material == null:
				continue
			materials[material.resource_name] = true
			for channel in ["albedo_texture", "metallic_texture", "roughness_texture", "normal_texture"]:
				var texture := material.get(channel) as Texture2D
				_expect(texture != null, "Mapa obrigatório ausente: " + channel)
				if texture != null:
					_expect(texture.resource_path.begins_with("res://assets/textures/board/painter/" + material.resource_name + "_"), "Os mapas devem corresponder ao Texture Set original.")
			_expect(material.normal_texture.resource_path.ends_with("_Normal_OpenGL.png"), "O tabuleiro deve usar a normal combinada OpenGL.")
			_expect(material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED, "O tabuleiro deve permanecer opaco.")
			_expect(material.uv1_scale.is_equal_approx(Vector3.ONE), "O tiling já exportado não deve ser aplicado duas vezes.")
			_expect(is_equal_approx(material.metallic, 1.0) and is_equal_approx(material.roughness, 1.0), "Metal e rugosidade devem preservar os valores dos mapas sem atenuação.")
		if String(mesh.name).begins_with("Casa_C"):
			var cell := Vector2i(String(mesh.name).substr(6, 2).to_int() - 1, String(mesh.name).substr(10, 2).to_int() - 1)
			var center: Vector3 = mesh.global_transform * mesh.get_aabb().get_center()
			var expected := board.grid_to_world(cell)
			_expect(absf(center.x - expected.x) < 0.01 and absf(center.z - expected.z) < 0.01, "A casa pintada deve continuar alinhada à grade: " + String(mesh.name))
		if String(mesh.name).begins_with("Divisoria_"):
			var size := mesh.get_aabb().size * mesh.scale
			if minf(size.x, size.z) < 1.0:
				widened_bars += 1
				_expect(is_equal_approx(minf(size.x, size.z), 0.28), "As barras douradas devem cobrir os vãos de 0,20.")
	_expect(widened_bars == 8, "As oito divisórias internas devem ser engrossadas.")
	var mist := board.get_node("LevitationMist") as FogVolume
	_expect(mist != null and mist.position.y < -1.0, "A névoa deve ficar abaixo do tabuleiro.")
	_expect(mist.is_in_group("presentation_only"), "A névoa não deve ampliar o enquadramento da câmera.")
	_expect(mist.get_children().size() == 1, "A névoa deve usar um único volume de filamentos, sem planos sobrepostos.")
	var nebula := mist.get_node("NebulaVolume") as MeshInstance3D
	_expect(nebula.mesh is BoxMesh, "O suporte dos filamentos deve ter volume, não ser uma superfície plana.")
	var nebula_material := nebula.material_override as ShaderMaterial
	_expect(nebula_material.shader.resource_path.ends_with("board_nebula_volume.gdshader"), "A névoa deve integrar a densidade 3D ao longo da visão.")
	_expect(nebula_material.get_shader_parameter("cloud_noise") is NoiseTexture3D, "A densidade deve ser definida por ruído 3D contínuo.")
	_expect(nebula.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "O volume decorativo não deve lançar sombras sólidas.")
	_expect(nebula.position.y + mist.position.y + (nebula.mesh as BoxMesh).size.y * 0.5 < 0.0, "O volume inteiro deve permanecer abaixo das casas.")
	_expect(materials.size() == 27, "Os 27 conjuntos exportados devem estar conectados.")
	_expect(ResourceLoader.exists("res://assets/models/board/queens_trial_board_no_star.glb"), "O visual anterior deve permanecer preservado.")
	board.free()

func _test_player_visual() -> void:
	var player := (load("res://scenes/player/player.tscn") as PackedScene).instantiate() as GridPlayer
	_expect(player != null, "A cena do jogador deve continuar instanciável.")
	if player == null:
		return
	_expect(player.get_node_or_null("Placeholder/Orb") is MeshInstance3D, "O jogador deve usar o marcador esférico provisório.")
	_expect(player.get_node_or_null("Visual") == null, "O marcador não deve instanciar o animador antigo.")
	_expect(player.find_children("*", "AnimationPlayer", true, false).is_empty(), "O marcador não deve possuir animações de personagem.")
	_expect(not ResourceLoader.exists("res://scenes/player/traveler_player.tscn"), "O viajante antigo deve estar fora do projeto ativo.")
	player.free()


func _test_untextured_piece_halos() -> void:
	for piece_name in ["rook", "bishop"]:
		var piece := (load("res://scenes/pieces/" + piece_name + ".tscn") as PackedScene).instantiate()
		root.add_child(piece)
		var animator := piece.get_node("Visual") as PieceVisualAnimator
		_expect(animator.halo_pivot != null, "A peça deve ter um pivô independente para o halo: " + piece_name)
		var body := animator.find_children("Body*", "MeshInstance3D", true, false)
		_expect(not body.is_empty(), "O corpo deve estar separado do halo: " + piece_name)
		var body_transforms: Array[Transform3D] = []
		for mesh: MeshInstance3D in body:
			body_transforms.append(mesh.transform)
		for mesh: MeshInstance3D in animator.find_children("*", "MeshInstance3D", true, false):
			for surface in mesh.mesh.get_surface_count():
				var material := mesh.get_active_material(surface) as StandardMaterial3D
				_expect(material == null or (material.albedo_texture == null and material.normal_texture == null),
					"As peças devem usar o visual neutro sem texturas, preservando a geometria.")
		if animator.halo_pivot != null:
			var before := animator.halo_pivot.transform
			animator._process(1.0)
			_expect(not animator.halo_pivot.basis.is_equal_approx(before.basis), "O halo deve girar com o tempo.")
			_expect(animator.halo_pivot.position.is_equal_approx(before.origin), "O centro do halo deve permanecer no lugar.")
			for i in body.size():
				_expect(body[i].transform.is_equal_approx(body_transforms[i]), "A rotação do halo não deve girar o corpo da peça.")
		piece.free()


func _test_board_camera() -> void:
	var main := (load("res://scenes/main/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var rig := main.get_node("World/BoardCamera") as CameraRig
	_expect(main.get_node_or_null("HUD/BottomPanel") == null, "A faixa inferior de instruções deve ser removida.")
	_expect(main.get_node_or_null("World/Board/Markers/SafeSpotMarker") == null, "O círculo visual do safe spot deve ser removido.")
	var music := main.get_node("Music") as AudioStreamPlayer
	_expect(music.stream is AudioStreamOggVorbis and music.stream.loop and music.autoplay,
		"A trilha deve iniciar automaticamente e repetir em OGG.")
	_expect(music.playing and music.stream.get_length() > 60.0, "A faixa completa deve estar em reprodução.")
	var moon := main.get_node("World/CelestialSpace/SolarSystem/Moon") as SolarBody
	_expect(moon.position.is_equal_approx(Vector3(-110, -170, -1200)) and is_equal_approx(moon.body_radius, 300.0),
		"A posição e a escala aprovadas da Lua devem permanecer iguais.")
	_expect(moon.model.basis.orthonormalized().is_equal_approx(Basis(Vector3.UP, deg_to_rad(240))),
		"A Lua deve mostrar os mares da face próxima à câmera inicial.")
	var player := main.get_node("World/Player") as GridPlayer
	_expect(rig != null, "A arena deve possuir a câmera orbital de tabuleiro.")
	if rig != null:
		rig.set_process(false)
		_expect(not rig.gameplay_mode and is_equal_approx(rig._active_elevation, 18.0), "O jogo deve abrir com a vista de apresentação mais baixa.")
		_expect((main.get_node("PhaseManager") as PhaseManager).current_phase == 0, "A prévia não deve iniciar a fase automaticamente.")
		rig.enter_gameplay(true)
		rig.update_framing(0.0, true)
		var initial_position := rig.camera.global_position
		player.position += Vector3(7.6, 0.0, 0.0)
		player.rotation.y += PI / 2.0
		rig.update_framing(0.1)
		_expect(rig.camera.global_position.is_equal_approx(initial_position), "A câmera não deve seguir a posição ou rotação do jogador.")
		var original_size := root.size
		for viewport_size in [Vector2i(1920, 1080), Vector2i(1280, 1024), Vector2i(2560, 1080), Vector2i(800, 1200)]:
			root.size = viewport_size
			await process_frame
			for angle in range(-180, 180, 15):
				rig.yaw_degrees = float(angle)
				rig.zoom_ratio = 1.0
				rig.update_framing(0.0, true)
				var planet := main.get_node("World/CelestialSpace/DistantEarth") as Node3D
				var planet_radius := planet.scale.x * 5.10
				var planet_distance := rig.camera.global_position.distance_to(planet.global_position)
				_expect(planet_distance > planet_radius + 10.0, "A órbita não deve entrar na Terra gigante.")
				_expect(planet_distance + planet_radius < rig.camera.far, "A Terra não deve ser cortada pelo plano distante.")
				for point in rig.framing_points:
					var screen := rig.camera.unproject_position(point) / root.get_visible_rect().size
					_expect(not rig.camera.is_position_behind(point) and screen.x >= 0.04 and screen.x <= 0.96 and screen.y >= 0.09 and screen.y <= 0.87,
						"Tabuleiro cortado: ângulo=%s, viewport=%s, ponto=%s" % [angle, viewport_size, screen])
		root.size = original_size
		rig.yaw_degrees = 0.0
		rig.zoom_ratio = -5.0
		rig.update_framing(0.0, true)
		_expect(is_equal_approx(rig.zoom_ratio, 1.0), "A aproximação deve parar no enquadramento completo.")
		rig.zoom_ratio = 20.0
		rig.update_framing(0.0, true)
		_expect(is_equal_approx(rig.zoom_ratio, rig.max_zoom_ratio), "O afastamento deve respeitar o limite.")
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP
		wheel.pressed = true
		rig._unhandled_input(wheel)
		_expect(rig.zoom_ratio < rig.max_zoom_ratio, "O scroll para cima deve aproximar.")
		# Simulação do arrasto sem capturar o cursor do sistema.
		rig._dragging = true
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(0, 150)
		rig._unhandled_input(motion)
		_expect(is_zero_approx(rig.yaw_degrees), "Arrasto vertical não deve mover a câmera.")
		motion.relative = Vector2(150, 0)
		rig._unhandled_input(motion)
		_expect(not is_zero_approx(rig.yaw_degrees), "Arrasto horizontal deve orbitar.")
		rig._dragging = false
		rig.update_framing(0.1)
		_expect(is_equal_approx(rig.camera.global_rotation.x, deg_to_rad(-rig.elevation_degrees)), "A inclinação da câmera deve ser fixa.")
	var forward_directions: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
	for sector in 4:
		var yaw := float(sector) * PI / 2.0
		var forward := forward_directions[sector]
		for offset in [-0.6, 0.0, 0.6]:
			_expect(GridPlayer.camera_direction_for_action(yaw + offset, &"move_up") == forward, "W deve acompanhar o quadrante da câmera.")
			_expect(GridPlayer.camera_direction_for_action(yaw + offset, &"move_down") == -forward, "S deve ser o oposto de W.")
			_expect(GridPlayer.camera_direction_for_action(yaw + offset, &"move_left") == Vector2i(forward.y, -forward.x), "A deve ir para a esquerda da câmera.")
			_expect(GridPlayer.camera_direction_for_action(yaw + offset, &"move_right") == Vector2i(-forward.y, forward.x), "D deve ir para a direita da câmera.")
	_expect(GridPlayer.camera_direction_for_action(PI / 4.0, &"move_up") == Vector2i.LEFT, "A diagonal exata deve desempatar de forma determinística.")
	main.free()


func _test_celestial_environment() -> void:
	var space_scene := load("res://scenes/environment/celestial_space.tscn") as PackedScene
	var space := space_scene.instantiate() as CelestialSpace
	root.add_child(space)
	var distant_earth := space.get_node_or_null("DistantEarth") as Node3D
	_expect(distant_earth != null and distant_earth.visible, "A Terra importada deve estar visível no cenário.")
	if distant_earth != null:
		_expect(distant_earth.get_node_or_null("Model") != null, "A Terra deve usar o modelo GLB fornecido.")
		_expect(distant_earth.position.x > 0.0 and distant_earth.position.z < -150.0, "A Terra deve estar distante e à direita na vista inicial.")
		_expect(distant_earth.scale.x >= 40.0, "A Terra deve manter escala colossal, não voltar a ser um pequeno globo.")
		_expect(distant_earth.position.length() - distant_earth.scale.x * 5.1 > 500.0, "Deve haver espaço livre entre a Terra e a arena.")
		_expect(not distant_earth.get_node("Atmosphere").visible, "A camada atmosférica extra deve ficar desativada.")
		var model := distant_earth.get_node("Model") as Node3D
		var model_rotation := model.rotation.y
		var sun_basis: Basis = distant_earth.get_node("PlanetSun").global_basis
		distant_earth._process(10.0)
		_expect(not is_equal_approx(model.rotation.y, model_rotation), "O globo deve girar lentamente.")
		_expect(distant_earth.get_node("PlanetSun").global_basis.is_equal_approx(sun_basis), "O sol não deve girar junto com o planeta.")
		var planet_sun := distant_earth.get_node("PlanetSun") as DirectionalLight3D
		_expect(planet_sun.light_cull_mask == 2, "A luz cinematográfica do planeta não deve iluminar o tabuleiro.")
		var surface_material: ShaderMaterial
		for mesh: MeshInstance3D in distant_earth.get_node("Model").find_children("*", "MeshInstance3D", true, false):
			_expect(mesh.layers == 2, "O planeta deve usar uma camada de iluminação própria.")
			var material := mesh.get_surface_override_material(0)
			if material is ShaderMaterial and material.shader == CinematicEarth.SURFACE_SHADER:
				surface_material = material
			else:
				_expect(material is ShaderMaterial and material.shader == CinematicEarth.CLOUD_SHADER, "As nuvens devem usar transparência com borda suavizada, sem casca escura.")
		_expect(surface_material != null, "A superfície deve usar o material com transição dia/noite.")
		if surface_material != null:
			for map in [&"surface_map", &"relief_map", &"roughness_map", &"city_map"]:
				var texture := surface_material.get_shader_parameter(map) as Texture2D
				_expect(texture != null and texture.get_width() == 8192, "O mapa %s deve preservar os detalhes 8K do asset." % map)
	_expect(space.get_node_or_null("Earth/EarthSurface") != null, "A Terra 3D deve existir no cenário.")
	_expect(space.get_node_or_null("Earth/EarthAtmosphere") != null, "A Terra deve possuir atmosfera separada.")
	var stars := space.get_node_or_null("StarField") as MultiMeshInstance3D
	if stars != null and stars.multimesh == null:
		space.call("_build_star_field")
	_expect(stars != null and stars.multimesh != null, "O campo de estrelas 3D deve ser construído.")
	if stars != null and stars.multimesh != null:
		_expect(stars.multimesh.instance_count >= 500, "O campo estelar deve manter profundidade visual suficiente.")
	var world_environment := space.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_expect(world_environment != null and world_environment.environment != null, "O panorama celeste deve possuir um WorldEnvironment.")
	if world_environment != null and world_environment.environment != null:
		_expect(world_environment.environment.background_mode == Environment.BG_SKY, "O fundo deve usar um panorama de céu 360 graus.")
		var orientation_before := world_environment.environment.sky_rotation.y
		space._advance_sky(10.0)
		_expect(not is_equal_approx(world_environment.environment.sky_rotation.y, orientation_before), "O céu deve ter uma deriva lenta.")
		_expect(absf(space.sky_degrees_per_second) <= 0.1, "A deriva deve ser sutil, sem girar o céu rapidamente.")
		space.sky_drift_enabled = false
		orientation_before = world_environment.environment.sky_rotation.y
		space._advance_sky(10.0)
		_expect(is_equal_approx(world_environment.environment.sky_rotation.y, orientation_before), "Deve ser possível desativar a deriva do céu.")
		var cinematic := world_environment.environment.sky.sky_material as ShaderMaterial
		_expect(cinematic != null, "A nébula deve usar um shader animado, não apenas rotação do panorama.")
		if cinematic != null:
			for texture_name in [&"panorama", &"nebula_mask", &"flow_reference"]:
				_expect(cinematic.get_shader_parameter(texture_name) is Texture2D, "O mapa '%s' deve estar conectado." % texture_name)
			space.set_effect_time(12.0)
			_expect(float(cinematic.get_shader_parameter("sparkle_density")) >= 0.40, "O céu deve manter alta densidade de lampejos frequentes.")
			_expect(is_equal_approx(float(cinematic.get_shader_parameter("effect_time")), 12.0), "O relógio deve avançar a animação e os lampejos.")
			space.nebula_motion_enabled = false
			space.sparkles_enabled = false
			space.set_effect_time(13.0)
			_expect(not bool(cinematic.get_shader_parameter("motion_enabled")), "Deve ser possível desligar o fluxo.")
			_expect(not bool(cinematic.get_shader_parameter("sparkles_enabled")), "Deve ser possível desligar os lampejos.")
			_expect(world_environment.environment.sky.process_mode == Sky.PROCESS_MODE_REALTIME, "A iluminação do céu animado deve usar atualização em tempo real.")
		_expect(is_zero_approx(world_environment.environment.glow_bloom), "O glow não deve clarear indiscriminadamente o tabuleiro.")
	space.free()


func _test_solar_system() -> void:
	var space := (load("res://scenes/environment/celestial_space.tscn") as PackedScene).instantiate()
	root.add_child(space)
	var system := space.get_node("SolarSystem") as CinematicSolarSystem
	var earth := space.get_node("DistantEarth") as CinematicEarth
	_expect(system != null, "O panorama deve incluir o sistema solar.")
	var previous_distance := 0.0
	for id in ["Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"]:
		if not system.bodies.has(id):
			_expect(false, "Corpo obrigatório ausente: " + id)
			continue
		var body := system.bodies[id] as Node3D
		var distance := body.global_position.distance_to(system.SUN_POSITION)
		_expect(distance > previous_distance, "A distância ao Sol deve respeitar a ordem dos planetas: " + id)
		previous_distance = distance
	_expect(earth.global_position.length() > 7000.0, "A Terra deve ficar mais ao fundo, liberando o primeiro plano.")
	var moon := system.bodies["Moon"] as SolarBody
	_expect(system.missing_assets.is_empty(), "Todos os planetas fornecidos devem estar presentes.")
	var saturn := system.bodies.get("Saturn") as SolarBody
	_expect(saturn != null and saturn.rings.size() == 1, "Saturno deve ter sua superfície e um anel contínuo independente.")
	var moon_material := moon.surfaces[0].get_active_material(0) as ShaderMaterial
	_expect(moon_material.shader == SolarBody.LUNAR_SHADER, "A Lua deve usar os realces brancos localizados na superfície.")
	_expect(moon.surfaces.size() == 1 and moon.rings.is_empty(), "O brilho lunar não deve criar uma casca ou aura extra.")
	var moon_angular_radius := moon.body_radius / moon.global_position.length()
	var earth_angular_radius := earth.scale.x * 5.0 / earth.global_position.length()
	_expect(moon_angular_radius > earth_angular_radius, "A Lua deve ser o destaque aparente, embora menor que a Terra.")
	_expect(moon.global_position.distance_to(earth.global_position) < 7000.0, "A Lua deve pertencer à vizinhança da Terra.")
	_expect(is_equal_approx(moon.spin_speed, PlanetRotation.speed_for("Earth", system.earth_turn_seconds)), "A Lua deve ter o mesmo ritmo visual da Terra.")
	var initial_moon_position := moon.position
	var initial_moon_basis := moon.surfaces[0].basis
	moon._process(system.earth_turn_seconds / 4.0)
	_expect(not moon.surfaces[0].basis.is_equal_approx(initial_moon_basis), "A Lua deve girar em torno do próprio eixo.")
	_expect(moon.position.is_equal_approx(initial_moon_position), "A rotação lunar não deve mover o planeta.")
	_expect((moon.surfaces[0].get_active_material(0) as ShaderMaterial) == moon_material, "O shader de brilho deve acompanhar todos os lados da Lua.")
	_expect(earth.sun_direction.is_equal_approx((system.SUN_POSITION - earth.global_position).normalized()), "A Terra deve receber luz na direção do Sol da cena.")
	for id in PlanetRotation.PROFILES:
		var axis := PlanetRotation.axis_for(id)
		var tilt := rad_to_deg(acos(clampf(axis.y, -1.0, 1.0)))
		_expect(absf(tilt - float(PlanetRotation.PROFILES[id].tilt)) < 0.005, "A inclinação deve seguir a tabela: " + id)
		_expect((axis.y < 0.0) == (id in ["Venus", "Uranus"]), "Somente Vênus e Urano devem girar retrógrados: " + id)
		_expect(PlanetRotation.speed_for(id, 240.0) > 0.0, "Não inverter o sinal duas vezes ao inclinar o eixo.")
		if not system.bodies.has(id):
			continue
		var planet := system.bodies[id] as Node3D
		var before_position := planet.global_position
		var visual := planet.get_node("Model") as Node3D
		var source_axis := Vector3.UP if id == "Earth" else (planet as SolarBody).spin_axis
		var actual_axis := (visual.global_basis * source_axis).normalized()
		_expect(actual_axis.is_equal_approx(axis), "O eixo visual deve corresponder ao eixo físico: " + id)
		var initial_surface := visual.basis if id == "Earth" else (planet as SolarBody).surfaces[0].basis
		planet._process(15.0)
		var final_surface := visual.basis if id == "Earth" else (planet as SolarBody).surfaces[0].basis
		_expect(not initial_surface.is_equal_approx(final_surface), "Todos os planetas devem girar visivelmente: " + id)
		_expect(planet.global_position.is_equal_approx(before_position), "A rotação não deve alterar as posições aprovadas: " + id)
	_expect(PlanetRotation.speed_for("Jupiter", 240.0) > PlanetRotation.speed_for("Earth", 240.0), "Júpiter deve girar mais rápido que a Terra.")
	_expect(PlanetRotation.speed_for("Mercury", 240.0) > PlanetRotation.speed_for("Venus", 240.0), "Vênus deve ser o planeta mais lento.")
	for id in system.bodies:
		var body := system.bodies[id] as Node3D
		if body is not SolarBody:
			continue
		_expect(body.global_position.length() - body.body_radius > 500.0, "Nenhum corpo deve invadir a arena: " + id)
		_expect(body.global_position.length() + body.body_radius * 4.0 < 120000.0, "O corpo e seus anéis devem caber no plano distante: " + id)
		for mesh in body.surfaces:
			var mat := mesh.get_active_material(0) as ShaderMaterial
			_expect(mat != null and mat.get_shader_parameter("surface_map") is Texture2D, "Material deve ter textura válida: " + id)
			_expect(mesh.layers == 4 and mesh.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Planetas distantes não devem gerar sombras caras na arena.")
		for ring in body.rings:
			var before: Basis = ring.basis
			var normal: Vector3 = ring.basis * body.spin_axis
			body._process(30.0)
			_expect(not ring.basis.is_equal_approx(before), "Os anéis devem girar: " + id)
			_expect((ring.basis * body.spin_axis).is_equal_approx(normal), "A rotação deve preservar o plano dos anéis: " + id)
	for id in ["BlackHoleA", "BlackHoleB"]:
		var hole := system.get_node(id) as SolarBody
		_expect(hole.accretion and hole.position.length() > 70000.0, "Os dois buracos negros devem ficar fora da vizinhança planetária.")
		_expect(hole.model != null and not hole.surfaces.is_empty(), "Os buracos negros devem usar o modelo fornecido.")
		var initial: Basis = hole.surfaces[0].basis
		hole._process(15.0)
		_expect(not hole.surfaces[0].basis.is_equal_approx(initial), "O disco de acreção deve ter movimento lento.")
	var report: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/environment/solar_system/preparation.json"))
	for entry: Dictionary in report:
		_expect(entry.output_vertices < 100000, "Cada novo asset deve ficar abaixo de 100 mil vértices: " + String(entry.name))
	var craft_count := 0
	for child in system.get_children():
		if child is AmbientSpacecraft:
			craft_count += 1
	_expect(craft_count == 3, "O cenário deve ter uma estação e exatamente dois satélites.")
	var station := system.get_node("SpaceStation") as AmbientSpacecraft
	_expect(is_equal_approx(station.position.x, -910.0), "A estação deve ser movida um pouco à esquerda.")
	var satellite_a := system.get_node("SatelliteA") as AmbientSpacecraft
	_expect(is_equal_approx(satellite_a.rotation_degrees.x, -55.0), "O satélite próximo da Terra deve expor os painéis à vista inicial.")
	var satellite_b := system.get_node("SatelliteB") as AmbientSpacecraft
	var satellite_angle := atan2(satellite_b.position.x, satellite_b.position.z)
	var uranus_position: Vector3 = system.bodies["Uranus"].position
	var neptune_position: Vector3 = system.bodies["Neptune"].position
	_expect(satellite_angle > atan2(neptune_position.x, neptune_position.z) and satellite_angle < atan2(uranus_position.x, uranus_position.z), "O segundo satélite deve ocupar o intervalo visual entre Urano e Netuno.")
	_expect(station.is_station and station.position.x < -500.0 and station.position.z < -1000.0, "A estação deve ficar à esquerda da vista inicial e longe da arena.")
	_expect(station.habitat_ring != null and station.hull != null, "O anel da estação deve ser uma malha separada do casco.")
	var hull_before := station.hull.global_transform
	var ring_before := station.habitat_ring.basis
	var ring_center := station.habitat_ring.global_position
	station._process(25.0)
	_expect(station.hull.global_transform.is_equal_approx(hull_before), "A animação não deve girar a estação inteira.")
	_expect(not station.habitat_ring.basis.is_equal_approx(ring_before), "O anel deve girar independentemente.")
	_expect(station.habitat_ring.global_position.is_equal_approx(ring_center), "O anel deve girar no próprio eixo, sem orbitar fora da estação.")
	for id in ["SatelliteA", "SatelliteB"]:
		var satellite := system.get_node(id) as AmbientSpacecraft
		var start_position := satellite.position
		var start_basis := satellite.model.basis
		satellite._process(20.0)
		_expect(not satellite.position.is_equal_approx(start_position) and not satellite.model.basis.is_equal_approx(start_basis), "O satélite deve ter deriva e mudança de orientação: " + id)
		for step in 20:
			satellite._process(120.0)
			_expect(satellite.position.distance_to(satellite.anchor) < 25.0, "A deriva deve permanecer limitada, sem fugir do enquadramento.")
		var key := satellite.get_node("SolarLight") as DirectionalLight3D
		_expect((key.light_cull_mask & 1) == 0 and not key.shadow_enabled, "Luzes orbitais não devem afetar o tabuleiro nem criar sombras caras.")
	var sun := system.bodies["Sun"] as SolarBody
	_expect((sun.surfaces[0].get_active_material(0) as ShaderMaterial).shader == SolarBody.SURFACE_SHADER, "O Sol deve voltar à textura original sem fotosfera procedural.")
	space.free()


func _test_forward_plus_configuration() -> void:
	_expect(
		String(ProjectSettings.get_setting("rendering/renderer/rendering_method")) == "forward_plus",
		"O projeto desktop deve usar o renderizador Forward+.",
	)
	_expect(
		String(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")) == "mobile",
		"O override mobile deve usar o renderizador Mobile.",
	)


func _test_input_map() -> void:
	for action in ["move_up", "move_left", "move_down", "move_right", "restart_phase"]:
		_expect(InputMap.has_action(action), "A ação de entrada '%s' deve existir." % action)
func _test_procedural_seed_is_preserved() -> void:
	var manager = PhaseManagerModel.new()
	manager.auto_start = false
	manager.campaign = Catalog.load_campaign()
	manager.start_phase(7, 240826)
	manager.restart_phase()
	_expect(manager.current_seed == 240826, "Reiniciar uma fase procedural deve preservar a semente.")
	manager.free()


func _test_rook_resolution() -> void:
	var state = BoardStateModel.new()
	var hit_result := RookResolverModel.resolve_pair(
		state,
		[Vector2i(2, 0), Vector2i(0, 4)],
		Vector2i(2, 3),
	)
	_expect(hit_result["player_hit"], "Jogador na coluna da Torre (2,0) deve ser atingido.")

	var miss_result := RookResolverModel.resolve_pair(
		state,
		[Vector2i(0, 0)],
		Vector2i(1, 3),
	)
	_expect(not miss_result["player_hit"], "Jogador fora da linha/coluna da Torre não deve ser atingido.")

	var single_rook := RookResolverModel.resolve_pair(
		state,
		[Vector2i(0, 0)],
		Vector2i(4, 4),
	)
	_expect(single_rook["attacked_cells"].size() == 8, "Uma Torre sozinha deve gerar oito casas atacadas na grade 5x5.")


func _test_attack_event() -> void:
	var event := AttackEventModel.new()
	var cells: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 3)]

	var hit := event.resolve(cells, Vector2i(2, 3), Vector2i(4, 0))
	_expect(hit["player_hit"], "Jogador na lista de casas atacadas deve ser marcado como atingido.")
	_expect(not hit["success"], "Ser atingido nunca deve contar como sucesso, mesmo fora do safe spot.")

	var safe := event.resolve(cells, Vector2i(4, 0), Vector2i(4, 0))
	_expect(safe["reached_safe_spot"], "Jogador na casa do safe spot deve ser reconhecido.")
	_expect(safe["success"], "Chegar ao safe spot sem ser atingido deve contar como sucesso.")

	var hit_on_safe_spot := event.resolve(cells, Vector2i(2, 3), Vector2i(2, 3))
	_expect(not hit_on_safe_spot["success"], "Safe spot coberto por ataque não deve contar como sucesso.")
	event.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
