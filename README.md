# Queen's Trial

Queen's Trial é um jogo de estratégia educacional desenvolvido em Godot. A apresentação acontece em uma arena 3D, enquanto regras, posições e validações usam uma grade lógica 2D de 5 x 5 casas.

## Prévia do arcanjo

O arcanjo permanece como versão de avaliação, com corpo e asas articulados, acessórios separados e texturas 4K. Abra `scenes/previews/archangel_rig_preview.tscn` e execute com `F6` para girar o modelo, mostrar os ossos e experimentar as animações. O botão **Testar abertura e fase 1** abre uma sessão com o arcanjo; também é possível executar diretamente `scenes/previews/archangel_phase_one_preview.tscn`.

A fonte editável está em `art/characters/archangel/archangel_rig.blend`. Organização, controles, preparação e verificações estão em [art/characters/archangel/README.md](art/characters/archangel/README.md).

## Fandaniel — personagem principal atual

**F5** abre a cena principal com a versão **Hooded Fandaniel** e sua roupa bordô original restaurada. O forro bege, os marrons, a malha, as UVs, os pesos e o esqueleto permanecem preservados. Na abertura, ele aparece pela fumaça e avança com `cbfm_swalk_loop`, a caminhada lenta de cena extraída do próprio FFXIV. A câmera acompanha os passos até a revelação da rainha, e o personagem termina na casa inicial da gameplay. Idle, Walking, Strafes e morte da gameplay mantêm os clipes existentes; as apresentações anteriores ficam arquivadas.

A chegada substitui o portal anterior e usa os modelos, texturas e curvas do **AscianTeleport**, adaptados ao Godot. O efeito começa no centro do corpo e o personagem aparece pela fumaça. O som é o recurso original `SE_Vfx_Monster_c0101_wrp01.scd`, convertido para WAV, sem síntese. O jogo funciona com os recursos convertidos incluídos no projeto, sem depender da instalação do FFXIV em tempo de execução.

A abertura dura 43 segundos e começa com dois planos suaves do cenário e do tabuleiro vazio, sem mostrar a rainha. O interior do capuz contém uma forma de rosto fechada e escura, acompanhando o osso da cabeça. A revelação preserva o mesmo shader e a escrita de profundidade durante toda a chegada. Depois de alguns passos, um modificador eleva discretamente a cabeça e o capuz antes do corte para a rainha, sobre a caminhada nativa.

Use `scenes/previews/fallen_priest_phase_six_preview.tscn` com **F6** para testar o personagem atual na balança. Fonte editável e detalhes: [art/characters/fandaniel/README.md](art/characters/fandaniel/README.md). Origem e adaptação do efeito: [art/effects/ascian_arrival/README.md](art/effects/ascian_arrival/README.md).

A trilha atual **O Chamado da Rainha** acrescenta oito segundos de cordas serenas ao arranjo aprovado, com destaque épico da rainha perto de 33 s e orquestra sustentada durante o movimento final da câmera. Os últimos 1,6 s se sobrepõem à música da gameplay com ganhos suaves. O Wind fornecido substitui o vento da balança, com recortes de 0,95 s e 2,3 s; o volume foi aumentado em 3 dB após a avaliação do usuário. O Candle acompanha os 1,65 s da queima. Fontes e preparação em `art/audio/opening_v2/` e `art/audio/user_presentation/`.

## Sacerdote — versão anterior preservada

O **Corrupted Fallen Priest Dark Fantasy** e suas fontes permanecem disponíveis para comparação. A fonte editável, os seis clipes anteriores com skin, o símbolo original e a capa física estão preservados em `art/characters/fallen_priest/` e na cena `scenes/player/fallen_priest_animated_model.tscn`.

O personagem usa os seis downloads do Mixamo: **Idle** contínuo, **Walking** com transições e viradas suaves, **Look Around**, **Standing React Death Forward**, **Left Strafe** e **Right Strafe**. Os Strafes repetem durante a inclinação; a recuperação mescla para Idle. A queda pela borda conserva os clipes específicos anteriores. Corpo, capuz, tecido frontal e capa física permanecem completos. Um símbolo original vermelho, com contorno luminoso e aura, acompanha a cabeça dentro do capuz.

O portal provisório tem camadas de fumaça em espiral, filamentos e fragmentos luminosos na borda, usando uma textura procedural pequena. A trilha original **O Limiar da Rainha** acompanha os 35 segundos da abertura: começa com cordas, sem os brilhos de harpa iniciais, e traz metais e coro no destaque da rainha, com auge próximo de 25 s durante o zoom out. As cartas usam um recorte tratado de 2,05 s da referência de American Horror Story indicada pelo usuário, sincronizado ao fogo e à pausa. A música de fundo do recorte é reduzida, sem síntese de novos estalos. Fontes e preparação em `art/audio/`, `tools/compose_priest_opening.py` e `tools/prepare_card_burn_reference.py`.

A capa usa o módulo compilado em `native/priest_cape/` no Windows x64, preservando a malha e os parâmetros físicos. A DLL já está incluída; não é necessário instalar ferramentas para jogar. O código GDScript permanece disponível para comparação. No teste da abertura em 1280 × 720, o cálculo passou de aproximadamente 10,3 ms para 0,48 ms; o tempo dos quadros no percentil 95 passou de 24,1 ms para cerca de 14 ms. Os resultados dependem do computador e da resolução.

Abra `scenes/previews/fallen_priest_phase_six_preview.tscn` e execute com **F6** para testar o **Corrupted Fallen Priest Dark Fantasy** diretamente na prova da balança. O personagem usa Mixamo no rig completo; a capa usa uma simulação física em tempo real. Use **1** para repetir a queda à esquerda, **2** para a direita, **3** para jogar as três rodadas e **4** para aproximar a câmera do personagem. WASD, R e Esc continuam disponíveis. Fonte Blender, detalhes e verificações: [art/characters/fallen_priest/README.md](art/characters/fallen_priest/README.md).

## Documentação

As regras de gameplay estão consolidadas em [docs/Queens Trial - Documentação Final.pdf](docs/Queens%20Trial%20-%20Documentação%20Final.pdf).

## Como executar

1. Clone esse repositório para seu desktop (Evite baixar como .zip).
2. Instale o Godot 4.7.
3. Importe a pasta que contém `project.godot`.
4. Execute o projeto com `F5` ou pelo botão de reprodução.
5. Aguarde a câmera de abertura e leia o livro. Clique nas páginas para folhear; clique fora do livro para fechá-lo e receber as cartas.
6. Use `W`, `A`, `S` e `D` para mover o jogador uma casa por pressionamento.

## Livro dos tutoriais

Cada fase apresenta somente sua novidade: **I**, um édito e movimento; **II**, dois éditos e o refúgio iluminado; **III**, alcance das torres; **IV**, ordem dos pares e flechas; **V**, diagonais dos bispos; **VI**, observação dos pesos da balança. O último capítulo faz perguntas para incentivar o raciocínio, sem indicar a posição vencedora.

O livro aprovado chega fechado, com tecido bordô, desenho dourado da rainha e da colisão de planetas e duas cantoneiras no lado direito. A capa mantém a textura original, sem brilho animado, aura ou partículas. As páginas usam papel marfim, ornamentos astronômicos e gravuras coloridas a nanquim e aquarela, com texto à esquerda e arte à direita. Os títulos usam **OPTI Engravers Old English** e o corpo usa **Alegreya**; as capitulares azuis são reaproveitadas das imagens aprovadas. O texto permanece editável no Godot. Em cada página, a tinta se revela aos poucos e a arte aparece em pinceladas largas, curvas e predominantemente verticais ao longo de cinco segundos, com bordas suaves. Ao fechar, a capa gira pela lombada, termina mostrando a frente e só então libera as cartas. O próximo capítulo reabre na página anterior e folheia automaticamente, acompanhado de um som discreto de papel. Reiniciar não repete capítulos lidos; uma leitura interrompida continua disponível.

A consulta de **Números romanos** é a primeira abertura do livro: **I–X à esquerda e XI–XX à direita**, em dez linhas alinhadas com a fonte **Jupiter Pro**, somente com título e tabela. Os tutoriais vêm depois. O capítulo das torres explica que o número acima de cada peça indica a mesma quantidade de casas nos dois trechos, pela linha e pela coluna. A gravura da balança tem braços de mesmo comprimento e suspensão no ponto central, segurada pela mão da rainha.

Durante a gameplay, o **ícone do livro no canto superior direito** ou **N** abre o tutorial da fase atual e pausa a prova. Clique na página esquerda para voltar e na direita para avançar; as setas do teclado também folheiam. Só é possível avançar até a última fase alcançada. Para consultar os números, volte pelas páginas até o começo. Clique fora do livro para fechar; **N** ou **Esc** também encerram a consulta. Na primeira leitura da fase seis, o relógio aguarda o fechamento. Os controladores de movimentos, éditos, ataques e balança não foram modificados; a correção futura da regra do safe spot continua pendente.

Para avaliar somente o livro, execute `scenes/previews/tutorial_book_preview.tscn` com **F6**: todos os capítulos ficam disponíveis para folhear, e **1–6** escolhem a fase. As artes ficam em `assets/ui/tutorial_book/`; prompts e notas em [art/tutorial_book/README.md](art/tutorial_book/README.md). Capturas reais em `docs/previews/tutorial_book/`. Verificações: `tests/test_tutorial_book.gd`, `tests/test_hud_integration.gd`, `tests/test_phase_playthrough.gd`, `tests/test_balance_trial.gd` e `tests/test_pause_phase_selector.gd`.

## Menu de pausa

**Esc** abre uma folha de papel marfim com bordas rasgadas, ocupando quase toda a tela com uma margem estreita. A arte tem contornos suaves e pigmentos de aquarela; a rainha ocupa o alto à direita e olha para o viajante no canto inferior esquerdo, com planetas e nébulas nos outros cantos. A logo original mantém todos os contornos e letras, com uma textura estática de tinta, separada do título **PAUSA**. Continuar, reiniciar, selecionar uma das seis fases e os atalhos usam **Jupiter Pro**, mostrando apenas os textos, sem retângulos ou bordas nos botões. O menu se ajusta à janela e preserva a pausa da música, dos efeitos e da prova.

Arte e prompt em [art/pause_menu/README.md](art/pause_menu/README.md). Capturas em `docs/previews/ui_polish/`; `tests/capture_ui_polish.gd` captura a página pintando, a consulta, o fechamento e o menu em 720p, com `-- --qa-1080` para 1080p ou `--qa-menu` para somente o ESC. O som original de papel e tecido está em `assets/audio/sfx/book/`, com preparação em `tools/create_book_foley.py`.

## Estrela do refúgio e orientação da fase 1

O safe spot usa o símbolo de lua crescente e duas estrelas fornecido pelo autor, preservando seu desenho em `assets/textures/guidance/sanctuary_reference.png`. O shader remove somente o fundo azul durante a renderização. A emissão dourada e a luz próxima aumentam e diminuem suavemente em ciclos de 2,8 s, mantendo o desenho rente ao piso. A luz não contribui para a névoa volumétrica. A fase 6 mantém o refúgio oculto.

Na fase 1, depois de a carta desaparecer, estrelas de cinco pontas acendem progressivamente ao longo de ondas regulares entre o viajante e o refúgio. Todas têm o mesmo tamanho, orientação e espaçamento; as ondas repetem a mesma amplitude e período sobre a rota das quatro casas. O jogador espera os 4,6 s da revelação e um breve assentamento antes de receber o controle; teclas pressionadas durante a orientação não gastam passos. ESC congela o desenho e retoma do mesmo ponto. Reiniciar ou mudar de fase cancela a animação anterior, que não pode liberar os controles da nova fase. O traço completo permanece até a resolução do édito.

Implementação em `scripts/gameplay/starred_guide.gd`, `shaders/sanctuary_symbol.gdshader`, `shaders/floor_star.gdshader` e `shaders/starred_trail.gdshader`. A estrela do caminho está em `assets/textures/guidance/path_star.svg`. Verificações em `tests/test_starred_guidance.gd`, `tests/test_hud_integration.gd`, `tests/test_phase_playthrough.gd` e `tests/test_balance_trial.gd`; capturas do menu, da rota e das duas intensidades do refúgio em `docs/previews/starred_guidance/`.

## Fase 6 — Julgamento da Balança

A conclusão da fase 5 abre a prova da balança. O globo de Astraía se dissolve e uma balança 3D se materializa acima das mãos da rainha. As cartas laterais permanecem visíveis e os pratos acompanham seus pesos: o maior número baixa aquele lado. Há cinco segundos para mover-se livremente pela grade, sem limite de passos e sem safe spot ou ataques das peças.

Após o prazo, o tabuleiro inclina 21° para o lado pesado. A gravidade projetada sobre a plataforma acelera o deslizamento de três casas, com poses próprias de apoio e perda de equilíbrio do sacerdote. Começar nas duas colunas do lado leve permite sobreviver; centro e lado pesado levam à queda pela borda e reinício automático. São três rodadas, usando somente as cartas 1–4. A câmera permanece frontal nessa prova para manter esquerda/direita coerentes com as cartas. `Esc` pausa também o relógio e a física; `R` reinicia toda a prova.

A fase 6 é o término jogável desta versão. Ao selecionar outra fase, a balança se dissolve e o globo retorna. As definições das fases 7–10 permanecem reservadas para implementação posterior. Para testar diretamente, abra `Esc`, escolha uma das fases 1–6 e pressione `Ir`; isso também funciona durante a abertura e inicia a fase escolhida do começo. Também é possível usar `godot --path . -- --phase=6`. Rodadas, tempo, ângulo e deslocamento ficam em `data/phases/campaign.json`.

A interface dessa prova mostra somente as duas cartas, centralizadas nos espaços laterais; os cinco segundos são contados internamente, sem título, contador ou textos de resultado. A balança permanece abaixo do queixo, preservando sua escala. A névoa azul original permanece em todas as fases; na fase seis, seus volumes usam coordenadas coerentes com a inclinação e acompanham parte da rotação com atraso suave, como uma nuvem suspensa. No deslizamento, um fluxo dourado rente ao piso e lampejos de pó estelar correm para o lado pesado, com vento estéreo nessa direção; uma camada de partículas douradas também atravessa a tela com pequenos rastros e brilhos, compartilhando direção e dissipação com o piso. Há também uma rajada suave ao pesar as cartas. Sair da fase seis restaura o comportamento anterior da névoa.

Verificações: `godot --headless --path . --script tests/test_balance_trial.gd`, `tests/test_pause_phase_selector.gd` e `tests/test_phase_playthrough.gd`. Capturas no renderizador Forward+ podem ser geradas com `godot --path . --script tests/capture_balance_preview.gd`; os PNGs incluem o seletor de fases e ficam em `.godot/qa/`.
