# Chaotic

Modo independente da campanha, com IDs **101–105**, implementado em
`scripts/gameplay/savage_controller.gd`. O controlador Vanilla e suas regras
permanecem separados.

## Jogar

- ESC: opções **Chaotic I–V**, seguidas de **Ir**.
- CLI: `godot --path . -- --phase=101` (até `105`).
- **WASD** movimenta; **R** reinicia o desafio atual; **ESC** pausa.

O acesso direto está temporariamente liberado por
`PhaseManager.SAVAGE_TEST_ACCESS = true`. Para a versão final, altere para
`false`: somente a conclusão de **todas** as fases jogáveis da campanha libera
Chaotic. O progresso é registrado ao concluir uma fase, em
`user://campaign_progress.cfg`; visitar uma fase pelo seletor não a conclui.
Novas fases da campanha devem atualizar `LAST_PLAYABLE_PHASE`.

## Mecânica

Cada desafio sorteia apenas a posição de chegada do jogador; a composição das
peças, os dois éditos e o refúgio são previamente definidos. Nenhuma posição
inicial correta é fornecida. Primeiro vêm a apresentação **Chaotic** e as
**duas cartas do jogador**, com a mesma revelação e queima usadas na campanha.
Somente depois começa a preparação livre de **10 segundos**.

São quatro peças ao todo: **dois pares**, com dois ataques sucessivos, e
**uma única peça em cada lado** do tabuleiro. Cada peça mostra seu próprio
numeral. Somente o par que vai atacar mostra a faixa original de três setas
neon animadas, agora vermelhas; o outro par aguarda sem flechas. Ao terminar a
primeira onda, suas anotações são ocultadas e o próximo par ganha suas flechas.
Não há rótulos
“Édito I/II” nas peças, título persistente, legenda do timer ou números extras
no rodapé. O jogador lê os seus próprios éditos nas cartas.

Ao fim da preparação, a casa realmente escolhida vira a origem do primeiro
édito. Cada édito tem **15 segundos de execução**. A distância é a soma das
diferenças absolutas de linha e coluna até sua origem; andar e voltar não soma
distância. O jogador pode corrigir seu trajeto dentro do raio permitido. O
limite impede ultrapassar o valor do édito. No vencimento, um passo já iniciado
termina sua animação antes do julgamento.

As peças realizam seus dois trechos, usando seu número tanto na borda quanto
na entrada. Torres atacam linhas e colunas; bispos atacam diagonais. Ataques
atravessam outras peças, como no jogo atual. As casas ocupadas pela primeira
onda bloqueiam o movimento da segunda. É preciso cumprir o primeiro édito e
sobreviver ao ataque; depois cumprir o segundo, sobreviver e terminar no
refúgio. O deslocamento do segundo édito é medido a partir da primeira casa de
resolução. Os valores individuais ficam entre I e IV, com soma máxima VII.

A conclusão usa `GameHUD.show_success()` e a mesma mensagem **FASE CONCLUÍDA**,
Jupiter Pro, tamanho e dissolução da campanha. As falhas usam o mesmo painel
`GameHUD.show_failure()` e as mesmas frases sobre distância, ataque e safe spot.

A referência para preparação e leitura antecipada foi o
[simulador Super Chess de VaanRatsbane](https://vaanratsbane.itch.io/drs-super-chess),
com a explicação de Queen's Edict do
[guia de Late Night](https://drslnshortguide.crd.co/).
O simulador interativo retornou HTTP 429 durante a pesquisa; a página pública e
o guia foram consultados. O efeito de ataque e o tabuleiro continuam próprios
de Queen's Trial.

## Dificuldade verificada

| Desafio | Éditos | Peças, primeira/segunda onda | Casas ameaçadas na primeira onda | Casas intermediárias válidas |
|---|---|---|---|---|
| I | II + IV | 2 / 2 | 12 / 25 | 2 |
| II | III + III | 2 / 2 | 13 / 25 | 2 |
| III | IV + II | 2 / 2 | 16 / 25 | 1 |
| IV | III + IV | 2 / 2 | 16 / 25 | 1 |
| V | IV + III | 2 / 2 | 16 / 25 | 1 |

`tools/build_savage_challenges.py` gera as configurações usando uma semente
fixa e busca exaustiva. `SavageCatalog` revalida, em GDScript, movimentos,
limites, colisões e rotas. Todas as configurações admitem solução. Rotas e
contagens para QA estão em `savage_solutions.json`; não são exibidas ao jogador.

## Visual e áudio

A abertura mostra **Chaotic** em Jupiter Pro. No restante da prova, o canto
superior direito mostra somente o número do timer. Não há livro; as duas cartas
aparecem antes da preparação, com o verso bordô de encontro orbital exclusivo
do Chaotic. A campanha usa o selo lunar claro; todos os cantos são retos.
As provas de cartas 7/8 também não oferecem livro
ou N. Estação espacial e todos os satélites ficam ocultos somente no Chaotic,
com restauração ao sair. Lua, Terra e os outros planetas permanecem.
A nébula do cenário e os dois componentes da névoa sob o tabuleiro recebem
vermelho sem alterar o relógio, o ruído ou a geometria. Ao sair, cores, música
e luzes originais são restauradas.

A combustão interna segue o início da
[referência de Surin](https://www.youtube.com/watch?v=iCr5H86zfU0), consultada
somente até 18 segundos. Um material opaco conserva as texturas e normais do
vestido e acrescenta manchas carbonizadas, fissuras emissivas e pulsação local
de calor. O ruído fica ancorado nas UVs do tecido, acompanhando a deformação do
corpo. Dentro das áreas queimadas, o calor se agita, reacende e esfria em ritmos
locais, mudando do vermelho para laranja e âmbar; as manchas carbonizadas
permanecem ancoradas. A cobertura vai da barra aos ombros, com um desvanecimento
abaixo da parte superior do pescoço. Não há volumes externos de chama ou planos
de fumaça.

As pequenas brasas flutuantes nascem de **192 amostras da malha deformada do
vestido**, recalculadas pelos pesos e poses reais do esqueleto. São 128 partículas,
um pouco maiores que na primeira versão. Elas giram,
sobem suavemente e perdem a luminosidade antes de desaparecer. Duas luzes
quentes discretas acompanham o tronco. Face e coroa não recebem o material de
combustão. Os materiais originais são restaurados ao sair, e a pausa congela
o efeito junto com o jogo.

Os numerais de **Vanilla e Chaotic** usam texto 2D projetado sobre as peças,
Jupiter Pro, tamanho uniforme e contraste discreto. Isso evita mipmaps,
iluminação e distância da câmera alterando a espessura e tamanho dos glifos.

Som fornecido: **51. With Hearts Aligned.flac**, último item
adicionado a Downloads, convertido para OGG Vorbis. A música continua entre
os cinco desafios e nas tentativas; o loop evita silêncio ao permanecer ali.

## Verificação

`tests/test_savage.gd` executa os cinco desafios com teclas reais, além de
comparar os dois solucionadores, verificar pausa, reinício durante ataques,
spawn aleatório, erro de distância, conclusão, desbloqueio e saída do modo.
Os testes usam progresso isolado e não desbloqueiam o jogo do usuário.

Capturas Forward+ em `docs/previews/savage/`, geradas por
`tests/capture_savage.gd`. Regressões: `tests/run_all.gd`,
`tests/test_phase_playthrough.gd`, `tests/test_card_trials.gd`,
`tests/test_main_menu.gd`, `tests/test_pause_phase_selector.gd`.
