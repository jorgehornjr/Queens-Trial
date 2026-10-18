# Menu principal: abertura orbital

A composição usa somente recursos existentes do jogo. A referência de ritmo e luz é [a tela de título de Endwalker enviada pelo autor](https://www.youtube.com/watch?v=iBAinnyB7wY): recuo do planeta, luz no limbo, Lua em destaque e entrada posterior da logo. Nenhuma imagem ou áudio da referência é incorporado ao jogo. Rainha, viajante, peças e satélites não são carregados no menu.

`scripts/ui/main_menu_moon_world.gd` instancia o piso `scenes/board/PaintedBoard.tscn`, a Lua de `assets/environment/solar_system/moon.glb` e extrai somente `DistantEarth` e o recurso de céu de `celestial_space.tscn`. A cena solar nunca entra na árvore. Terra e Lua giram a 1,5 grau por segundo; a Lua conserva a face inicial de 240 graus. Nébula e estrelas mantêm o movimento original, com exposição menor para a composição do menu.

A apresentação dura 11,5 segundos. Entre 0,8 e 8,5 s, Terra e Lua percorrem uma meia-volta em pontos opostos de uma órbita comum, inclinada, de raio 51,26. O centro também recua de `(0, 13, -112)` até `(0, 13, -136)`. De 6,2 a 8,5 s, uma curva suave acrescenta 60 unidades à posição X da Terra, preservando o movimento aprovado e deslocando apenas a composição final. As superfícies continuam separadas por mais de 10 unidades, incluindo a atmosfera. A Terra termina em `(60, -5, -184)` e a Lua em `(0, 31, -88)`: a Terra fica à direita do observador, distante e atrás da Lua, com o topo próximo da metade dela na projeção da câmera.

A câmera sobe de `(0, 5, 16)` até `(0, 9, 24)`, com FOV final de 48 graus. A iluminação lunar cresce a partir de 5,8 s, a logo aparece de 7 a 9,6 s por opacidade e as opções entram em sequência. Os materiais e o céu são próprios dessa instância. Os parâmetros acrescentados aos shaders de Terra e Lua conservam os valores anteriores por padrão para a campanha.

`main_menu_lens.gdshader` desenha o brilho óptico na borda, voltando ao limbo da Lua ao concluir a rotação. `main_menu_grade.gdshader` faz a entrada do escuro e a vinheta. `main_menu_logo_glow.gdshader` utiliza a máscara alfa do PNG original para uma logo branca com um halo azul claro difuso e respiração muito discreta. Não acrescenta contorno escuro ou varredura. `main_menu_logo.gdshader` permanece arquivado. Não são usadas pinturas novas.

O menu principal oferece **Iniciar** e **Selecionar fase**, em Jupiter Pro, com letras pretas sem contorno ou sombra. Hover e foco aproximam as palavras em 10% e elevam-nas cinco unidades. Iniciar entrega a abertura existente. Selecionar fase abre um painel com oito opções, sem Sobre. ESC ou Voltar retornam ao menu; a seleção também continua no menu de pausa.

`MenuMusic` reproduz **Entre Duas Órbitas**, uma composição original de 148 s, com efeitos de entrada únicos e um motivo de harpa/piano contínuo. Não há loop da faixa. Pular a intro busca a posição de 12 s; A transição para a campanha reduz o volume durante 0,7 s. Fonte, MIDI, tempos e verificações em `art/audio/main_menu/` e `tools/compose_menu_orbits.py`.

Execute com F5. Enter, Espaço, ESC ou clique pulam apenas a apresentação. `tests/test_main_menu.gd` verifica a separação das superfícies em 101 pontos da animação, o arco lateral, a posição final à direita, o glow, os textos sem contorno, a duração e término do áudio, o salto da apresentação, os dois botões pretos e a seleção das oito fases, o hover e a entrega à campanha. `tests/capture_main_menu.gd` captura os estágios da abertura e o hover de Iniciar. A prévia com áudio está em `docs/previews/main_menu/intro.mp4`; o MP3 completo está em `menu_orbits.mp3` na mesma pasta.

As imagens e shaders pintados da proposta anterior permanecem arquivados, com os prompts em `generation_prompts.json`. Eles não são referenciados pelo menu atual.
