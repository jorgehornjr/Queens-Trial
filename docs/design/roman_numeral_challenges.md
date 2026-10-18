# Propostas de prática de números romanos — I a XX

Documento de design para avaliação. As novas fases abaixo ainda não estão implementadas no jogo. O tabuleiro atual e a futura expansão da balança permanecem como estão.

## Direção recomendada

Adicionar uma fase de cartas chamada **Constelação Fragmentada**, com dois tipos de rodada: colocar numerais em ordem e completar lacunas. Ela exige interpretar I–XX diretamente, sem depender do limite de deslocamento do tabuleiro ou de contas difíceis. Depois, introduzir **Tributo da Rainha**, uma prova de combinação de cartas com soma e subtração.

O cenário pode se afastar do tabuleiro por alguns instantes. As cartas ficam diante da galáxia; cada resposta correta acende uma estrela e recompõe uma constelação. A fase continua pertencendo ao universo do jogo e pode funcionar só com cliques nas cartas.

## Constelação Fragmentada

**Ordenação:** o jogador recebe cinco ou seis cartas abertas e escolhe do menor para o maior. Exemplo: `XIX, VI, XIV, IV, XI, IX` → `IV, VI, IX, XI, XIV, XIX`. Cada carta ocupa uma estrela da constelação. A ordem escolhida fica visível e pode ser revisada antes da confirmação.

**Lacunas:** uma constelação parcialmente formada mostra `XIII → ? → XV`. O jogador escolhe XIV entre cartas com formas próximas, como IV, XVI, XIX e IX. O objetivo é identificar o número, seu antecessor e seu sucessor.

**Progressão:** começar com pequenos grupos; misturar intervalos; chegar à reconstrução de I–XX em quatro grupos de cinco cartas ou, no desafio final, com o deck completo visível. Dar atenção a IV/VI, IX/XI, XIV/XVI e XVIII/XIX.

**O que pratica:** reconhecimento, valor, comparação, ordenação e relações entre numerais. Não precisa aumentar o tamanho do tabuleiro nem a distância que o personagem percorre.

## Tributo da Rainha

A rainha pede um valor, como XVIII. O jogador seleciona duas cartas cuja soma forma o tributo. `VI + XII`, `VIII + X` e `VII + XI` são respostas válidas. Aceitar todas as combinações corretas torna a escolha uma decisão de jogo, em vez de uma única resposta decorada.

Começar com seis a oito cartas, depois apresentar as vinte em um arranjo de quatro por cinco. A rodada mostra o alvo e a quantidade de cartas permitida. Depois da entrega, revelar `VI (6) + XII (12) = XVIII (18)`.

Variações futuras: completar `VII + ? = XVIII`, ou realizar uma subtração como `XVIII − IV = XIV`. As operações e o resultado devem permanecer claros na tela. Não misturar as quatro operações na primeira versão.

**O que pratica:** leitura de cada carta, decomposição de um valor, escolha de estratégias e operações básicas. É a opção mais interessante para usar muitas cartas simultaneamente depois que a leitura estiver mais firme.

Não exigir gastar todas as vinte cartas numa prova de soma limitada a 20: XX não teria um parceiro positivo. O deck inteiro pode estar disponível, com sobras, ou outras rodadas podem usar leitura e subtração. Se cartas forem consumidas entre entregas, gerar o próximo alvo a partir das cartas restantes e verificar que existe uma solução.

## Espelhos Celestes

Um lado apresenta valores comuns, como 4, 9, 14 e 19; o outro mostra cartas romanas. O jogador liga cada valor à representação correta. Manter ambos os lados visíveis, para que a dificuldade principal seja reconhecer os numerais, em vez de memorizar onde as cartas estavam escondidas.

É uma boa fase inicial ou um modo de apoio: quatro pares, depois seis, depois dez. Pode usar uma rodada com números altos antes de exigir operações. Evitar uma tela com quarenta elementos logo de início; o conjunto I–XX pode ser dividido em rodadas.

## O Decreto Falso

A rainha apresenta três afirmações, e o jogador identifica a incorreta. Exemplo: `XIV = 14`, `IX = 11`, `XIX = 19`. Ao escolher a segunda, a rodada revela `IX = 9; XI = 11`.

É uma revisão curta e diferente das outras provas, útil para as inversões mais comuns. Não seria a única nova fase: reconhecer uma afirmação errada oferece menos espaço de ação do que construir uma constelação ou combinar cartas.

## Operações e público

Eu começaria por leitura, ordem e lacunas. Soma e subtração entram depois. Multiplicação e divisão ficam como opção para turmas que já trabalham essas operações, com resultados inteiros de 1 a 20: `IV × V = XX` e `XVIII ÷ III = VI`.

Não gerar resultados zero, negativos ou fracionários para um deck I–XX. Evitar que a dificuldade de cálculo esconda se o aluno sabe interpretar o numeral. A primeira versão pode alternar desafios de leitura e contas simples, observando em qual tipo ele erra.

## Feedback e repetição

- Uma tentativa errada recebe uma correção curta ligada à carta escolhida: “IV representa 4; VI representa 6”. O aluno pode revisar e tentar novamente.
- A leitura correta aparece em algarismos comuns depois da resposta, não permanentemente sob todas as cartas.
- Reapresentar numerais confundidos em contextos diferentes: ordenar XIV, preencher uma lacuna com XIV e depois usá-lo numa entrega.
- O livro continua disponível como consulta. As primeiras rodadas podem ter mais apoio e as seguintes retirar pistas gradualmente.
- Começar sem cronômetro apertado. Fluência pode ser um desafio posterior, depois que o aluno compreende a regra.

Essas decisões adaptam princípios gerais de representações visuais, feedback corretivo e revisão cumulativa discutidos nos guias do [What Works Clearinghouse/IES](https://ies.ed.gov/ncee/wwc/PracticeGuide/2/Published) e de [representações e relações numéricas no ensino básico](https://ies.ed.gov/ncee/wwc/PracticeGuide/26). A mecânica específica de Queen’s Trial ainda precisa ser observada com os alunos; os guias não estudam estas fases nem números romanos especificamente.

## Primeira versão que eu construiria

Uma fase de Constelação Fragmentada com seis rodadas curtas: duas de ordenação, duas de lacunas e duas com numerais misturados de I–XX. Usar cartas sempre abertas, permitir corrigir a seleção antes de confirmar e dar feedback específico depois da tentativa. A balança fica com o papel de comparação e peso; o tabuleiro continua com deslocamentos pequenos; o Tributo acrescenta composição e cálculo numa etapa posterior.
