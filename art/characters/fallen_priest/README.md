# Sacerdote — versão anterior preservada

Preparado a partir do modelo **Corrupted Fallen Priest Dark Fantasy** fornecido em Downloads. O arquivo baixado permanece intacto. Esta versão anterior, com os seis clipes do Adobe Mixamo adaptados ao rig completo, permanece disponível para comparação. O personagem principal atual é o Fandaniel com capuz, documentado em `../fandaniel/README.md`.

## Versão preservada com Mixamo

A cena `scenes/player/fallen_priest_animated_model.tscn` usa `assets/models/characters/fallen_priest/fallen_priest_mixamo.glb`, com fonte editável em `fallen_priest_mixamo.blend`. Corpo, capuz, tecidos, pesos e os 117 pontos da capa física foram preservados. O buraco no upload da Adobe era o recorte do tecido frontal, excluído junto com a capa para facilitar o auto-rig; ambos os tecidos estão presentes nesta versão completa.

| Nome interno | Download do Mixamo | Duração original |
| --- | --- | --- |
| `breathing_idle` | Idle | 3,3 s, contínuo |
| `walk` | Walking | 1,03 s, cíclico |
| `intro_arrival` | Look Around | 13,33 s |
| `standing_death` | Standing React Death Forward | 3,67 s |
| `left_slide` / `right_slide` | Left / Right Strafe | 0,67 s, cíclico |

O exportador acrescenta um quadro de margem a 30 FPS. Os ciclos não somam deslocamento horizontal à grade ou à física da balança. Walking e Idle usam transições suaves; a virada começa antes do deslocamento completo. A recuperação mescla o Strafe para Idle em 0,45 s. As quedas pela borda conservam `left_fall` e `right_fall` anteriores; os clipes antigos de recuperação estão arquivados, sem uso na gameplay.

`mixamo/animations/` guarda os seis FBX fornecidos. `mixamo/animation_import_report.json` registra hashes, durações e amostras. Reproduza com Blender em background, `--factory-startup --python tools/fallen_priest/import_mixamo.py`; os Downloads têm prioridade e as cópias arquivadas servem como alternativa.

O símbolo vetorial original em `assets/textures/effects/priest_face_sigil.svg` usa uma superfície curva, aura e luz vermelha, ligadas ao osso Head por `priest_face_sigil.gd`. As referências do FFXIV orientam o efeito e a cor; nenhum símbolo da referência foi copiado.

Verifique os clipes, o Idle contínuo, as viradas, a grade e a ligação do rosto com `tests/test_priest_mixamo.gd`. `tests/capture_priest_mixamo.gd` gera capturas das poses e do rosto em `.godot/qa`.

## Testar

Execute o projeto com **F5** para ver a abertura de 35 segundos e jogar com o sacerdote. A chegada usa Look Around na casa inicial, sem a caminhada robótica anterior. O teleporte procedural permanece provisório, conforme solicitado pelo usuário. A trilha começa sem os brilhos de harpa iniciais. `Esc` permite pular diretamente para qualquer fase implementada.

Abra `scenes/previews/fallen_priest_phase_six_preview.tscn` no Godot e execute **F6**. A cena abre diretamente a fase 6 com o sacerdote.

- **1** / botão **Queda esquerda**: coloca o personagem no centro e repete a queda para a esquerda.
- **2** / botão **Queda direita**: repete para a direita.
- **3** / botão **Jogar fase 6**: reinicia as três rodadas normais.
- **4** / botão **Aproximar personagem**: alterna a câmera normal e a câmera que acompanha o personagem de perto, inclusive durante a queda.
- **WASD**, **R**, **Esc**: movimento, reinício e pausa existentes.

Pelo terminal: `godot --path . scenes/previews/fallen_priest_phase_six_preview.tscn`.

## Fonte anterior preservada e rig

- `fallen_priest_rig.blend`: fonte editável, com imagens empacotadas e ações de animação.
- `assets/models/characters/fallen_priest/fallen_priest_rig.glb`: versão anterior, preservada como fonte.
- `assets/models/characters/fallen_priest/cape_cage.json`: posições e correspondência dos pontos físicos.
- `rig_report.json`: contagens e validação dos pesos.

A escultura foi simplificada para 155.374 triângulos, preservando UVs e mapas de cor, normal, metal e rugosidade. Corpo, capuz/cabeça, capa e tecido frontal são objetos separados. O esqueleto tem 22 ossos do corpo/tecido frontal e 117 ossos para deformar a capa. Cada vértice tem até quatro influências normalizadas. Os cortes compartilham pesos; as normais originais são preservadas para reduzir marcas nas junções. A parte superior da capa permanece ligada ao peito, sob os ombros.

Clipes próprios: `breathing_idle` (4,8 s), `walk` (1,1 s), `intro_arrival` (12,4 s), `standing_death` (2,6 s), `left_slide`/`right_slide` (2,4 s), `left_fall`/`right_fall` (1,7 s), `left_recover`/`right_recover` (1 s). Respiração e caminhada são cíclicas. Os demais terminam na pose final.

Na autoria, IK analítico de duas articulações mantém os pés em apoio e coloca as mãos no joelho ou no piso. O deslizamento baixa o quadril e sustenta uma meia ajoelhada; a queda começa nessa pose e solta os membros gradualmente. A morte dobra primeiro os joelhos e termina com o corpo próximo ao chão. O deslocamento real continua sob controle da grade e da física da balança, sem movimento de raiz duplicado. A abertura desloca o personagem visualmente e restaura sua posição antes de liberar a gameplay.

## Capa em tempo real

O script `scripts/player/priest_cape_physics.gd` resolve uma malha física 9 × 13 usando XPBD a 120 passos por segundo, com restrições de comprimento, cisalhamento e dobra. As duas primeiras fileiras acompanham o peito animado. Gravidade e arrasto do ar atuam em coordenadas globais; a aceleração do personagem, a inclinação e o vento direcional geram atraso, elevação e acomodação do tecido. As orientações dos ossos acompanham a superfície deformada.

Há colisões aproximadas com peito, quadril, capuz, braços e pernas, além do plano limitado do tabuleiro. A colisão com o tabuleiro é liberada na queda pela borda. O corpo continua tombando para o lado baixo após sair da plataforma. Reiniciar limpa a simulação, evitando puxar a capa desde a posição da queda anterior.

No Windows x64, o laço numérico roda no módulo compilado `native/priest_cape/`, incluído no projeto. O script continua preparando os pinos, colisores e ossos; os 117 pontos, as 12 iterações e todos os parâmetros físicos permanecem os mesmos. A versão GDScript pode ser forçada com `-- --cape-script`. Uma comparação de 180 passos com vento e movimento de ombros verificou diferença máxima inferior a 0,00002 unidade entre as versões. O custo médio da capa na abertura caiu de 10,3 ms para 0,48 ms em 1280 × 720.

É uma simulação de tecido para jogo sobre uma escultura simplificada. Não inclui colisão do tecido consigo mesmo nem retopologia manual; dobras extremas podem se cruzar em câmera muito próxima. A malha e os parâmetros da capa aprovados na primeira avaliação foram preservados ao integrar as novas animações do corpo.

## Reproduzir e verificar

Execute os scripts em `tools/fallen_priest/` no Blender em background, na ordem: `prepare_source.py`, `segment_mesh.py`, `build_rig.py`. SciPy usa a instalação existente em `.godot/qa/blender_modules`; NumPy vem com Blender. O material de trabalho fica em `.godot/qa`, sem alterar a fonte baixada.

`animate.py` reproduz a autoria anterior no GLB preservado; para atualizar as animações usadas atualmente no jogo, execute `import_mixamo.py`. `animation_report.json` registra as amostras dos clipes anteriores; `mixamo/animation_import_report.json` registra os atuais.

- `godot --headless --path . --script tests/test_fallen_priest_phase_six.gd`: rig, clipes, movimentos distintos da capa, comprimento, queda, reinício e recuperação das três rodadas.
- `godot --headless --path . --script tests/test_opening_cutscene.gd`: portal, primeiro passo, caminhada, câmeras e devolução do controle à fase 1.
- `godot --headless --path . --script tests/test_priest_ground_death.gd`: queda até o piso, duração, estabilidade da capa e reinício.
- `godot --headless --path . --script tests/test_balance_trial.gd`: regressão das regras e dos efeitos da balança com o sacerdote principal.
- `godot --headless --path . --script tests/test_cape_solver.gd`: equivalência física e preservação dos arrays do chamador no módulo nativo.
- `godot --headless --path . --script tests/test_card_burn_audio.gd`: início, pausa, cancelamento e troca de fase durante a queima.
- `godot --path . --script tests/profile_priest_performance.gd -- --label=local`: custo da capa e tempos de quadro durante a abertura real.
- `godot --path . --script tests/capture_fallen_priest.gd`: capturas da fase e das deformações, em `.godot/qa`.

- `godot --path . --script tests/capture_priest_full_presentation.gd`: capturas renderizadas da abertura e das poses, em `.godot/qa`.

As prévias do arcanjo e os arquivos do mago continuam disponíveis para comparação.
