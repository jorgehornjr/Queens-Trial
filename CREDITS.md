# Créditos e licenças

Inventário dos recursos e contribuições audiovisuais de Queen's Trial. Fontes editáveis e versões anteriores foram preservadas em `Deleted/project_cleanup_2026-10-17/`; os caminhos de autoria abaixo indicam sua localização original para recuperação.

## Direção de arte e produção audiovisual

**Jorge Horn** — composição do cenário, seleção e integração de assets, acabamento visual, iluminação, efeitos e seleção da trilha sonora.

## Fandaniel e chegada Ascian — versão atual

- **Modelo e símbolo do rosto:** recursos de Final Fantasy XIV / Square Enix, fornecidos pelo usuário através do mod **Fandaniel+Elidibus Enshroud**, de **Dekken**, opção **Hooded Fandaniel**. A malha e os pesos são preservados; o esqueleto base vem da instalação local do jogo.
- **Animações:** downloads do Adobe Mixamo fornecidos pelo usuário em FBX sem skin, com sufixo `(1)`, adaptados ao esqueleto original. As fontes sem skin estão no backup local, sob o caminho original `art/characters/fandaniel/animations/`.
- **Design e chegada atuais:** roupa bordô original restaurada a pedido de Jorge Horn. A chegada utiliza a caminhada cinematográfica lenta original do FFXIV, `cbfm_swalk_loop`, extraída de `event_swalk_loop.pap`, com amostragem por [XAT](https://github.com/Etheirys/XAT). Os clipes de apresentação anteriores ficam arquivados como referências.
- **Acabamento do rosto e olhar:** forma de rosto escura criada no Godot sob o capuz, com testa, nariz e queixo discretos; elevação suave da cabeça sobre a caminhada nativa antes da revelação da rainha. A abertura ganhou dois planos serenos do tabuleiro vazio.
- **Teleporte:** mod **Ascian and Ancient Teleport**, de **Dekken**, variante AscianTeleport. A chegada usa `pop_tlep1t1h.avfx`, seus modelos internos e quatro texturas originais do FFXIV. O áudio é `sound/vfx/monster7/SE_Vfx_Monster_c0101_wrp01.scd`, extraído da instalação local e decodificado para WAV. Adaptação ao Godot em `scripts/main/ascian_arrival.gd`.
- **Ferramentas de referência para formatos:** [Lumina](https://github.com/NotAdam/Lumina), [Dalamud VFXEditor](https://github.com/0ceal0t/Dalamud-VFXEditor), [Penumbra](https://github.com/xivdev/Penumbra) e [FFXIVModelConverter](https://github.com/AlexCSDev/FFXIVModelConverter). Os utilitários de autoria em `tools/ffxiv/` leem os arquivos do jogo sem instalar os mods nele.

## Céu e nébula

- **Pacote:** Space Nebula Skyboxes - Project Sample.
- **Publicador:** Arghanion's Puzzlebox.
- **Origem:** [página do pacote na Fab](https://www.fab.com/listings/05d67c91-26cc-4a28-90f1-ac8b66984f92).
- **Arquivos utilizados:** `assets/environment/fab_nebula/TC_Skybox_05.hdr`, `TC_Skybox_05_Alpha.hdr` e `TC_Flowmap.hdr`.
- **Adaptação e integração audiovisual:** Jorge Horn — aplicação dos mapas no céu do Godot, composição e ajuste dos efeitos de fluxo e realces.
- **Licença:** [Fab Standard License](https://www.fab.com/eula) — categoria Personal.

## Modelos celestes e veículos

| Recurso | Arquivo no projeto | Autor / publicador | Página | Licença |
| --- | --- | --- | --- | --- |
| Terra | `assets/environment/fab_nebula/earth.glb` | Sebastian Sosnowski | [Fab](https://www.fab.com/listings/cdcd9fd8-05a4-4600-96dc-30853eed223a) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Mercúrio | `assets/environment/solar_system/mercury.glb` | RecourseDesign | [Fab](https://www.fab.com/listings/d6293d72-5e36-4913-83eb-fa221e537f56) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Vênus | `assets/environment/solar_system/venus.glb` | RecourseDesign | [Fab](https://www.fab.com/listings/1702c7df-c054-491e-b802-4e8b9d5c2c34) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Lua | `assets/environment/solar_system/moon.glb` | Nestaeric | [Fab](https://www.fab.com/listings/31816bdd-afa5-4031-ba0e-795ab7b70838) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Marte | `assets/environment/solar_system/mars.glb` | Nestaeric | [Fab](https://www.fab.com/listings/1d170259-3427-4d87-a830-445e4c79e213) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Júpiter | `assets/environment/solar_system/jupiter.glb` | Nestaeric | [Fab](https://www.fab.com/listings/2444443a-b634-4e12-9d09-49580d66d7ec) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Saturno | `assets/environment/solar_system/saturn.glb` | Nestaeric | [Fab](https://www.fab.com/listings/683523da-2503-4de5-a273-3ec09ef21962) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Urano | `assets/environment/solar_system/uranus.glb` | Nestaeric | [Fab](https://www.fab.com/listings/5e6d83f4-bf61-436e-bed9-bb3507244563) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Netuno | `assets/environment/solar_system/neptune.glb` | Nestaeric | [Fab](https://www.fab.com/listings/4767d8ea-2ccb-41d8-b1e0-83ff46f23da1) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Sol | `assets/environment/solar_system/sun.glb` | Sebastian Sosnowski | [Fab](https://www.fab.com/listings/47617169-00e1-4856-8f53-bbbaea605ad5) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Buraco negro (2 instâncias) | `assets/environment/solar_system/black_hole.glb` | Nestaeric | [Fab](https://www.fab.com/listings/2c168db8-91b4-464a-8185-761331000e60) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Sci-Fi Space Station | `assets/environment/spacecraft/space_station.glb` | Helindu.Art | [Fab](https://www.fab.com/listings/4237db4c-394a-4770-9ea0-1af1fa1da1f6) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Basic Satellite (2 instâncias) | `assets/environment/spacecraft/basic_satellite.glb` | Extraordinaire Commercial Arts | [Fab](https://www.fab.com/listings/bcba7b7c-1516-4f9a-bfb9-0037cbea2a20) | [Fab Standard License](https://www.fab.com/eula) — categoria Personal. |
| Seraph | `assets/models/characters/seraph/seraph.glb` | SpatialNeglect | [SketchFab](https://sketchfab.com/3d-models/seraph-c7e798e782a74e3eb3a0b9fbb1ea89c5) | CC Attribution |
| Astraía | `assets/models/props/astraia/astraia_orb.scn` | Quentin Otani | [SketchFab](https://sketchfab.com/3d-models/astraia-c0f37ac567d34fa8881ed7a79b335c4d) | CC Attribution |

**Adaptação e integração audiovisual:** Jorge Horn — composição, escala, posicionamento, materiais e movimentos dos corpos celestes e veículos. As texturas extraídas dos modelos acompanham os créditos de seus respectivos criadores.

## Tabuleiro, peças e materiais

- **Medieval Balance Scales:** modelo `scales.glb` fornecido pelo autor do projeto a partir da pasta `Downloads/medieval-balance-scales`. A versão `assets/models/props/balance/balance.glb` preserva malha e texturas originais e separa base, braço e pratos para articulação; preparação reproduzível em `tools/prepare_balance.py`. Autoria e licença não informadas no pacote fornecido.
- **Left Strafe / Right Strafe — Adobe Mixamo:** animações fornecidas pelo autor do projeto, integradas ao esqueleto atual de Fandaniel; o deslocamento horizontal do quadril é removido para que a física da plataforma controle o deslizamento.

- **Tabuleiro — Jorge Horn:** modelagem no Blender, texturização e acabamento no Substance 3D Painter. A versão de execução está consolidada em `scenes/board/PaintedBoard.tscn`; os arquivos-fonte editáveis ficam no arquivo local recuperável `Deleted/`, fora do jogo e do Git.
- **Bispo e torre — Jorge Horn:** modelagem, texturização e preparação visual dos halos para rotação independente no Godot. Versões de execução em `assets/models/pieces/animated/bispo.glb` e `torre.glb`; os arquivos-fonte editáveis ficam no arquivo local recuperável `Deleted/`.
- **Materiais de biblioteca — Adobe Substance 3D Assets:** recursos disponibilizados pela Adobe e seus licenciantes, aplicados e ajustados por Jorge Horn no tabuleiro. Mapas finais em `assets/textures/board/painter`. Sujeitos aos [termos do Adobe Substance 3D Assets](https://www.adobe.com/go/substance3dassets).

## Texturas auxiliares

- `assets/environment/earth_clouds.png` e `star_glow.png`: texturas procedurais de nuvens e brilho estelar produzidas para o projeto, com direção e integração de Jorge Horn.

## Cartas e pergaminho

- **Menu principal:** composição 3D com Terra, Lua, piso e céu existentes. Abertura orbital, iluminação na borda dos astros e logo original em branco com halo suave. Integração e direção de Jorge Horn. Reutiliza `earth.glb`, `moon.glb`, `PaintedBoard.tscn`, `CinematicEarth`, `SolarBody`, `PlanetRotation` e o recurso de céu existente; autores dos assets estão nas seções correspondentes deste inventário. O ritmo visual se inspira na tela de título de Endwalker indicada pelo autor, sem copiar imagens, logo ou áudio da referência. Esta revisão não gera novas artes. As imagens da proposta pintada anterior permanecem arquivadas e não são usadas pelo menu atual.

- **Livro dos tutoriais:** capa de tecido bordô com cantoneiras, páginas marfim e seis gravuras coloridas a nanquim e aquarela em `assets/ui/tutorial_book/`, geradas com a ferramenta integrada da OpenAI sob direção de Jorge Horn. As propostas aprovadas estão em `art/tutorial_book/concepts_v3/`; a versão do jogo corrige a suspensão central e a simetria dos braços da balança. As capitulares são regiões das imagens aprovadas, sem alteração dos arquivos-fonte. Texto, tabela I–XX, folhear, fechamento pela lombada e revelação da tinta e das pinceladas são executados no Godot. Prompts da integração em `art/tutorial_book/implementation_prompts.json`; versões anteriores preservadas na mesma pasta.
- **Menu de pausa:** folha ilustrada com bordas rasgadas, rainha, viajante e universo, gerada pela ferramenta integrada da OpenAI sob direção de Jorge Horn. A versão ativa `assets/ui/pause_menu/illustrated_sheet_watercolor.png` suaviza o acabamento da arte aprovada e amplia seu papel central para a proporção 16:9. Prompts em `art/pause_menu/generation_prompt.json` e `softening_prompt.json`. A versão anterior permanece preservada. A logo original `assets/logo/QTlogo.png` mantém todos os contornos; sua textura discreta de tinta é aplicada no Godot.
- **Consulta de números e menu de pausa — Jupiter Pro:** utiliza `assets/fonts/jupiter_pro.otf`, fonte já incluída no projeto.
- **Refúgio e caminho estrelado:** símbolo de lua crescente e duas estrelas fornecido pelo autor do projeto, preservado em `assets/textures/guidance/sanctuary_reference.png`; o fundo azul é filtrado somente na renderização. A estrela regular de cinco pontas em `path_star.svg`, as ondas simétricas e a emissão pulsante são executadas por malhas e shaders nativos do Godot, sob direção de Jorge Horn. Não há véus ou partículas ascendentes.
- **Títulos do livro:** `assets/fonts/OPTIEngraversOldEnglish.otf`, fornecida pelo autor no pacote `engravers-old-english.zip` de Downloads. O pacote contém somente a fonte, sem documento de licença.
- **Corpo do livro — Alegreya:** Juan Pablo del Peral / Huerta Tipográfica, obtida do [repositório Google Fonts](https://github.com/google/fonts/tree/main/ofl/alegreya). Fonte variável em `assets/fonts/Alegreya-Variable.ttf`, SIL Open Font License 1.1 em `assets/fonts/ALEGREYA_LICENSE.txt`. Incluída no projeto; não depende de instalação no computador.

- **Frentes das cartas:** `assets/cards/1.jpg` a `20.jpg`, fornecidas por Jorge Horn, com os numerais I–XX. Os PSDs editáveis estão no backup local. As cartas preservam os cantos retos e recebem um ajuste de papel marfim na renderização, sem alterar os JPGs.
- **Provas de cartas 7 e 8:** interface procedural do Godot, com as vinte artes fornecidas, fundo desfocado, mão sobreposta, arrastar, carta fixa, ordenação, associação e decreto falso. Jupiter Pro nos títulos e nos alvos; os arcos e a marcação em X são desenhados em tempo real.
- **Versos e pergaminho:** gerados com a ferramenta de imagens da OpenAI sob direção de Jorge Horn. As cartas comuns usam o selo lunar claro em `assets/cards/back.png`; o modo Chaotic usa o encontro orbital bordô em `assets/cards/back_chaotic.png`. Ambas as artes têm cantos retos e composição vertical. Propostas e prompts em `docs/previews/card_backs/`. O pergaminho em `assets/ui/parchment.png` é a versão sem texto do conceito "Cosmologia Viva", criado a partir da composição de referência fornecida por Jorge Horn. A escrita e a animação são feitas no Godot.
- **Efeitos das cartas:** as frentes usam suas cores originais. A queima, as brasas e a fumaça são geradas em tempo real por shaders e scripts do Godot; o projeto `Burning Titles.aep` fornecido por Jorge Horn serviu como referência de movimento, sem ser incorporado ao jogo. O verso usa a arte original sem shader de iluminação.
- **Tipografia do tutorial:** Cormorant SC por Christian Thalmann / Cormorant Project Authors e Old Standard TT por Alexey Kryukov, obtidas do [repositório Google Fonts](https://github.com/google/fonts). Ambas usam a SIL Open Font License 1.1; cópias das licenças estão em `assets/fonts/CORMORANT_LICENSE.txt` e `assets/fonts/OLD_STANDARD_LICENSE.txt`.

## Efeitos sonoros da gameplay

- **Folhear e fechar o livro:** efeitos originais de papel e tecido em `assets/audio/sfx/book/`, produzidos com ruído filtrado, pequenos vincos e contato da capa; não usam gravações externas. Preparação reproduzível em `tools/create_book_foley.py`, com parâmetros e medições em `art/audio/book_foley/report.json`.

- **Áudios fornecidos para o projeto:** os cinco arquivos em `assets/audio/sfx/user/` são usados no ataque das peças, na falha, no acerto do primeiro édito, na conclusão da fase e em cada movimento do personagem.
- **Preparação:** o ataque foi cortado em 1,52 s para acompanhar o efeito visual; o silêncio final dos demais arquivos foi removido com um fade curto. Os originais continuam na pasta Downloads do autor.
- **Integração nas fases 1–5:** os cinco efeitos fornecidos acompanham a gameplay. A música baixa temporariamente durante o som de falha. O movimento das peças está sem efeito sonoro nesta versão.
- **Vento da fase 6:** recortes de `wind.mp3`, fornecido pelo usuário, em `assets/audio/sfx/balance/`. Duração de 0,95 s na descida dos pratos e 2,3 s na inclinação/deslizamento, com volume menor, fades suaves e balanço entre esquerda/direita. Preparação em `tools/prepare_user_presentation_audio.py`; as sínteses anteriores ficam arquivadas para comparação.
- **Queima das cartas:** `assets/audio/sfx/cards/paper_burn.wav`, recorte de 1,65 s de `candle.mp3`, fornecido pelo usuário, sincronizado ao fogo e à pausa. Preparação em `tools/prepare_user_presentation_audio.py`; origem, hashes e ganhos em `art/audio/user_presentation/`. O recorte anterior de American Horror Story foi arquivado no backup local, sem reprodução no jogo.
- **Pó estelar e névoa das bordas:** efeitos procedurais do Godot. O fluxo dourado no piso e os lampejos acompanham a inclinação; o trecho de 3:06–3:10 do vídeo de Sophia fornecido pelo autor foi usado como referência visual, sem copiar mídia do vídeo.

## Trilha sonora

### With Hearts Aligned — Chaotic

- **Arquivo:** `assets/audio/music/savage_with_hearts_aligned.ogg`.
- **Fonte fornecida pelo autor:** `51. With Hearts Aligned.flac`, último item adicionado a Downloads para esta implementação.
- **Título, artista e compositor nos metadados da fonte:** With Hearts Aligned; Masayoshi Soken.
- **Álbum nos metadados:** Endwalker: Final Fantasy XIV Original Soundtrack, 2022.
- **Preparação:** conversão integral para Vorbis qualidade 6, 334,421 segundos, com loop na engine. Fonte e hash em `art/audio/savage/README.md`.

### Entre Duas Órbitas — menu principal

- **Arquivo:** `assets/audio/music/menu_orbits.ogg`, composição original de 148 segundos sob direção de Jorge Horn. Entrada cinematográfica única, brilho sonoro aos 7 s e motivo contínuo de 16 s depois de 12 s; termina sem loop.
- **Autoria editável:** `art/audio/main_menu/menu_orbits.mid`, mapa de entradas e verificações na mesma pasta; composição, renderização e mixagem em `tools/compose_menu_orbits.py`.
- **Instrumentação:** harpa, piano, cordas, coro suave, flauta, trompas, celesta, tímpanos e prato. Ar orbital e brilho cristalino sintetizados pelo script. A referência de Endwalker orienta a atmosfera e a estrutura; a faixa não contém amostras ou transcrição da referência.
- **Instrumentos amostrados:** MuseScore General, renderizado com FluidSynth. Licença MIT e inventário das fontes em `art/audio/priest_opening/MuseScore_General_License.md` e `MuseScore_General_Sample_Sources.csv`.

### O Chamado da Rainha — abertura atual

- **Arquivo:** `assets/audio/music/priest_opening.ogg`, arranjo original de 43 segundos sob direção de Jorge Horn. O prelúdio de oito segundos acompanha os dois planos serenos e preserva a parte aprovada da rainha e a música do movimento final, com sobreposição de 1,6 s para a gameplay.
- **Autoria editável:** MIDI, mapa de entradas, versão de 35 segundos aprovada e verificações em `art/audio/opening_v2/`; geração e mixagem em `tools/compose_opening_v2.py` e `tools/extend_opening_atmosphere.py`. O arranjo anterior, O Limiar da Rainha, permanece arquivado em `art/audio/priest_opening/`.
- **Instrumentação:** cordas, harpa, trompas, metais graves, coro, sinos, tímpanos e prato orquestral. O maior crescendo acompanha o destaque e o zoom out da rainha entre 30,1 e 36 s.
- **Instrumentos amostrados:** [MuseScore General](https://musescore.org/en/handbook/3/soundfonts-and-sfz-files), por S. Christian Collins e colaboradores; licença MIT. A licença integral e a relação de fontes/créditos das amostras acompanham o MIDI. Renderização com FluidSynth; essas ferramentas não são necessárias para executar o jogo.

### Ascension

- **Arquivo:** `assets/audio/music/5.21 Ascension.ogg` — trilha atual.
- **Jogo:** Final Fantasy XVI.
- **Álbum:** FINAL FANTASY XVI Original Soundtrack.
- **Composição e arranjo:** Masayoshi Soken (arranjo com colaboração de Takafumi Imamura).
- **Artistas creditados no lançamento:** Masayoshi Soken.
- **Lançamento:** 19 de julho de 2023.
- **Fonograma:** ℗ 2023 SQUARE ENIX CO., LTD.
- **Licença para Queen's Trial:** autorização específica não comprovada.

Os créditos musicais identificam as obras e seus titulares, mas não representam autorização de uso. Projeto acadêmico sem fins de lançamento público.
