# Provas de cartas — fases 7 e 8

Implementação inicial para avaliação na engine, com os números temporários de fase pedidos pelo autor. As vinte artes fornecidas em `assets/cards/1.jpg` a `20.jpg` são usadas sem alteração dos arquivos. Os PSDs permanecem como fontes de edição.

## Fase 7 — ordem crescente e decrescente

São duas rodadas, com seis espaços e uma carta fixa. A posição fixa é sorteada somente entre o segundo e o quinto espaços. Seu valor é escolhido a partir de uma sequência viável de seis cartas distintas; isso garante que sempre existe uma solução.

O jogador pode usar qualquer conjunto que forme uma sequência estritamente crescente ou decrescente respeitando a âncora. Não precisa adivinhar um conjunto oculto ou usar valores consecutivos. A primeira rodada é crescente e a segunda, decrescente.

A mão contém o deck I–XX embaralhado, com sobreposição no rodapé. Passar o mouse levanta a carta e aumenta discretamente sua escala. Cartas já colocadas, incluindo a fixa, saem da mão. As demais fecham os espaços com uma animação curta, preservando a ordem embaralhada e reduzindo a largura total do deck. A carta também sai durante um arraste; cancelar restaura sua posição na ordem original. É possível arrastar, ou clicar numa carta e depois num espaço. Clicar numa carta colocada ou arrastá-la de volta ao rodapé a devolve à mão; arrastar entre espaços ocupados troca as posições. A âncora permanece bloqueada.

Confirmar valida a sequência e apresenta uma correção curta quando necessário. Continuar abre a próxima rodada; ao terminar as duas, a campanha segue para a fase 8.

## Fase 8 — associação e decreto falso

A primeira rodada apresenta os alvos 14, 18 e 19, em Jupiter Pro, nos espaços decorados. O deck completo continua disponível e embaralhado. As cartas podem ser arrastadas para os respectivos espaços e a seleção é validada em Confirmar. Depois de preenchido, o número do espaço passa a ficar sobre a carta, preservando a leitura da correspondência.

A segunda rodada apresenta três cartas com um número comum acima de cada uma, sem arcos. Duas correspondências são verdadeiras e uma é falsa. O X vermelho aparece sobre qualquer carta sob o mouse, indicando a intenção de marcar aquela opção como falsa; não revela previamente qual é a resposta correta. A mão inferior é recolhida nessa rodada, concentrando a escolha nas três opções.

Selecionar uma opção correta como falsa apresenta feedback e permite outra tentativa. Selecionar a única correspondência falsa resolve a prova. Ao terminar, há uma tela de conclusão e Repetir fase; as fases 9 e 10 continuam reservadas e não são abertas automaticamente.

## Apresentação e integração

O personagem 3D fica oculto e sem movimento nas duas provas. Uma passagem de 4,8 segundos eleva e afasta a câmera enquanto uma nuvem estelar atravessa o enquadramento. No instante em que ela cobre a tela, tabuleiro, rainha, planetas e satélites são recolhidos. A nuvem se dissipa e revela somente a nébula e os brilhos VFX originais, nítidos, antes de apresentar as cartas. A passagem não se repete entre as duas fases de cartas. Sair destas provas restaura visibilidade e câmera; interromper a passagem cancela seus callbacks. O safe spot permanece oculto. A transição não altera `nebula_motion_speed`, `nebula_motion_strength` nem reinicia o relógio do panorama. A versão anterior animava a velocidade multiplicada pelo tempo acumulado, provocando saltos no azul; a nova versão move somente a câmera e a nuvem de passagem. A entrada das cartas dura 0,65 s. A fase 7 não abre o livro automaticamente.

O livro continua disponível por seu ícone ou N. Durante estas provas, ele abre diretamente a consulta de I–XX e pausa a interação. ESC mantém o menu de pausa, agora com as oito fases jogáveis; R reinicia uma prova ativa. Reiniciar conserva a semente da fase para permitir uma nova tentativa com a mesma configuração. A mão é embaralhada novamente entre as rodadas.

O shader `card_surface.gdshader` conserva o retângulo completo das frentes e estende o próprio papel do verso nos pequenos cantos arredondados presentes na imagem original. `card_paper.gdshaderinc` iguala o tom do papel claro e neutro para marfim, preservando tinta escura, pigmentos saturados e textura. A cor de origem foi medida individualmente nas vinte artes; `RomanCardAssets.PAPER_TONE_ENABLED` permite desativar a tentativa sem editar JPGs ou PSDs. A queima usa o mesmo ajuste, evitando saltos de cor. As cartas da balança também são quadradas. A balança agora sorteia duas cartas diferentes de VIII a XX ao abrir cada uma das três rodadas. O RNG é inicializado por sessão e continua avançando em reinícios, sem repetir uma lista fixa. Antes da terceira rodada, a pose inteira da balança é restaurada. Uma avaria de 1,65 s solta ambas as montagens de correntes e pratos, com o mesmo deslocamento vertical e deslocamentos laterais espelhados. O braço permanece sem rotação lateral; o modelo mantém essa pose por toda a rodada. Um ? maior e mais claro entra por opacidade e escala diante da balança. Cartas e relógio de cinco segundos só começam ao terminar a animação. A direção real do tabuleiro continua sendo calculada pelas cartas; a pesagem não oferece áudio direcional. R ou troca de fase cancelam a avaria e remontam as poses completas, descartando callbacks antigos. A validação mede a altura real dos pratos ao longo de todos os frames, além do valor de rotação. Concluir a terceira rodada entrega a fase 7.

## Fontes e verificação

- `scripts/ui/roman_card_assets.gd`: catálogo compartilhado das vinte imagens, tons medidos do papel e material de superfície.
- `scripts/gameplay/card_trial_state.gd`: valores, semente, âncora, rodadas, colocação e validação.
- `scripts/gameplay/card_trial_controller.gd`: ligação com campanha, áudio, pausa e transições.
- `scripts/ui/card_trial_hud.gd`, `card_trial_hand.gd` e `card_trial_slot.gd`: composição, hover, drag-and-drop, números e X.
- `data/phases/campaign.json`: definições temporárias das fases 7 e 8; as demais definições foram preservadas.
- `tests/test_card_trials.gd`: viabilidade de âncoras em oitenta sementes, arrastar real, associação, decreto, consulta, retorno ao tabuleiro e avanço entre as fases.
- `tests/capture_card_trials.gd`: capturas Forward+ em `docs/previews/card_trials/`.
- `tests/capture_card_palette.gd`: comparação do papel nas vinte cartas e verificação visual do verso quadrado.
- `tests/capture_card_space.gd`: sequência da passagem, com duração e cadência registradas para a prévia `space_transition.mp4`.

A mesa mostra somente o título da prova, cartas, números dos espaços, confirmação e feedback necessário após tentativas. Não há fase/rodada, instruções detalhadas, rótulo Fixa ou arcos.

Para testar rapidamente: F5, Selecionar fase e escolher Fase 7 ou Fase 8. Também é possível executar o projeto com `-- --phase=7` ou `-- --phase=8`.
