# Hooded Fandaniel

Versão original do mod **Fandaniel+Elidibus Enshroud.pmp**, autor **Dekken**, opção **Hooded Fandaniel**, fornecida pelo usuário. Fonte de geometria: `chara/equipment/e8100/model/c0101e8100_top.mdl`; esqueleto: `chara/human/c0101/skeleton/base/b0001/skl_c0101b0001.sklb` da instalação local do FFXIV. Os arquivos instalados são lidos, sem importar o mod para o jogo.

O modelo tem duas malhas, 5.341 vértices, 6.045 triângulos e 106 ossos. Geometria, UVs, hierarquia e pesos são preservados. A tabela de cores dos materiais CharacterLegacy e os mapas originais são convertidos para os materiais do Godot. A iluminação e a resposta especular são adaptadas ao renderizador; o desenho não foi redesenhado. O símbolo do rosto usa as texturas originais `asi_s006a0f`, `asi_s006c0f` e `asi_s006d0f`, espelhadas como no recurso original, ligadas ao osso `j_kao`.

O tecido bordô original foi restaurado a pedido do usuário. As texturas de cor coincidem com as cópias em `original_materials/`. A paleta preserva couro marrom, forro bege e ornamentos; a geometria e os pesos seguem originais.

O interior do capuz agora contém um rosto fechado e escuro criado em `scripts/player/fandaniel_face.gd`, com testa, nariz e queixo discretos, ligado ao mesmo osso do símbolo. A forma bloqueia o cenário atrás da máscara sem usar o rosto humano do Fandaniel. A chegada usa `shaders/fandaniel_arrival_skin.gdshader`, preservando os mapas originais e a máscara de recorte, com revelação gradual e escrita de profundidade; não troca de modo de transparência ao terminar.

A sombra continua sobre a parte superior da gola com um gradiente suave acima do colar, preservando suas dobras. A máscara é armazenada nas cores dos vértices da cópia de malha usada no Godot e segue os pesos originais do pescoço e do tronco, inclusive ao elevar a cabeça. As texturas e a geometria da fonte permanecem intactas.

A chegada atual usa a animação original **cbfm_swalk_loop**, do arquivo `chara/human/c0101/animation/a0001/bt_common/event/event_swalk_loop.pap`. É a variante lenta de caminhada cinematográfica humana do jogo; não foi identificada como exclusiva dos Ascians. O ciclo nativo tem 2 s e é reproduzido a 80% da velocidade na abertura, com a câmera acompanhando o personagem até a rainha aparecer. A caminhada começa dentro da fumaça, permanece sobre o tabuleiro e termina na casa inicial, sem alterar a grade lógica. Os braços, mãos, dedos, torso e pernas vêm da amostragem original do Havok, aplicada ao mesmo esqueleto do modelo.

Após 5,5 segundos de caminhada, o olhar começa a subir durante três segundos: quatro graus no pescoço e oito na cabeça. `fandaniel_cinematic_gaze.gd` aplica esse movimento depois da animação nativa, sem alterar o ciclo importado. O capuz e o símbolo acompanham a cabeça; a elevação retorna suavemente ao repouso após o corte para a rainha. A abertura completa tem 43 segundos, incluindo os dois planos iniciais sem personagens.

`native_animations/` guarda os FBX amostrados e os hashes dos PAP originais. `extract_native_walks.py` lê os arquivos instalados e usa o exportador nativo do [XAT](https://github.com/Etheirys/XAT) para amostrar os movimentos. `import_native_walks.py` aplica os deltas de skin do esqueleto original, compensando somente a convenção de eixos do FBX/Blender. O deslocamento cinematográfico é calculado a partir da velocidade dos pés e da escala do personagem. A roupa preta e as apresentações anteriores permanecem apenas como versões de referência, sem uso na cena principal.

| Download sem skin | Nome interno | Duração |
| --- | --- | --- |
| Idle(1).fbx | breathing_idle | 8,33 s |
| Walking(1).fbx | walk | 1,03 s |
| FFXIV: cbfm_swalk_loop | intro_arrival | 2 s, cíclico |
| FFXIV: cbfm_walk_loop | ffxiv_cinematic_walk | 1,07 s, comparação |
| Standing React Death Forward(1).fbx | standing_death | 3,67 s |
| Left Strafe(1).fbx | left_slide | 0,67 s |
| Right Strafe(1).fbx | right_slide | 0,67 s |

Somente os movimentos são transferidos dos FBX. A skin do sacerdote anterior não é usada. O deslocamento horizontal dos ciclos é removido para preservar a grade e o deslizamento da balança. A túnica mantém as cadeias originais do esqueleto; elas recebem acompanhamento dos passos e acomodação na morte. Não usa a capa XPBD do sacerdote anterior.

## Arquivos

- `fandaniel_mixamo.blend`: fonte editável, com texturas empacotadas e clipes.
- `source/model.json`: geometria, UVs, pesos e esqueleto extraídos para reprodução.
- `animations/`: os seis downloads originais sem skin.
- `rig_report.json` e `material_report.json`: origem, hashes, amostras de poses e materiais.
- `assets/models/characters/fandaniel/fandaniel_mixamo.glb`: modelo usado no jogo.

## Autoria e verificação

`tools/ffxiv/game_resources.py` lê os SqPack/TTMP sem escrever na instalação. `parse_model.py` converte a geometria MDL v6 e o XML de referência do esqueleto Havok. A conversão do SKLB para XML usa NotAssetCc, distribuído com FFXIVModelConverter, em `.godot/qa/ffxiv/tools/`. `prepare_fandaniel_materials.py` prepara as tabelas de cores e o rosto. Execute `build_fandaniel.py` no Blender com `--background --factory-startup` para reproduzir o GLB usando o JSON e os FBX arquivados.

- `godot --headless --path . --script tests/test_fandaniel.gd`: clipes, durações, Idle, viradas, grade, Strafes, morte e reinício.
- `tests/test_opening_cutscene.gd`: caminhada nativa, braços em movimento, câmera, percurso sobre o tabuleiro, áudio e devolução do controle.
- `tests/test_phase_playthrough.gd` e `tests/test_balance_trial.gd`: fases 1–6.
- `tests/capture_fandaniel.gd`: capturas das seis animações e do rosto.

Os testes específicos da capa e do rig anterior continuam destinados à cena do sacerdote preservada, com 139 ossos. O modelo atual usa seu próprio esqueleto de 106 ossos.
