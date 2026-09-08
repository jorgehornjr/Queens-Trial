# Plano de gameplay e apresentação - fases 1 a 5

Este documento registra as decisões confirmadas para a próxima revisão do jogo e separa as recomendações de design que devem ser avaliadas antes da implementação.

## Escopo confirmado

- Revisar e tornar jogáveis as fases 1 a 5.
- Remover a Rainha do centro do tabuleiro e tornar a casa central uma casa comum: jogador, inimigos, ataques e safe spot podem utilizá-la.
- Manter o movimento do jogador discreto, uma casa por comando.
- Exibir sobre o jogador a quantidade de movimentos válidos restantes em numerais romanos: `IV`, `III`, `II`, `I`; ao chegar a zero, o indicador desaparece.
- Exibir em cada Torre e Bispo o numeral romano de seu deslocamento.
- Mover Torres e Bispos fisicamente da borda até a casa calculada, com um deslizamento curto e elegante.
- Resolver o ataque somente depois que todas as peças do par ativo terminarem o deslocamento.
- Torre ataca sua linha e coluna completas.
- Bispo ataca suas quatro diagonais completas.
- Criar um ataque vermelho com efeitos visuais próprios e claramente legíveis.
- Remover da HUD as coordenadas do jogador, as coordenadas do destino, o estado interno da máquina e as duas linhas técnicas de ordens.
- Não revelar a casa final dos inimigos, a zona de ataque antecipadamente ou uma rota recomendada.
- Manter o safe spot visível diretamente no tabuleiro, sem escrever sua linha e coluna na HUD.
- Na abertura de uma fase, apresentar os éditos no centro da tela. Fase 1 mostra um numeral; fases com dois éditos mostram uma composição como `II + IV`.
- Aplicar brilho, aparição cerimonial e dissolução em poeira estelar à apresentação dos éditos.
- Usar uma interface visualmente integrada ao cenário, com poucos elementos, preservando espaço para ícones que serão produzidos posteriormente no Illustrator.

## Sequência recomendada para cada édito

1. Apresentar no centro da tela o édito ou a composição completa da fase.
2. Dissolver a apresentação e manter apenas o numeral restante sobre o jogador e os numerais/direções das peças relevantes.
3. Liberar o controle do jogador.
4. A cada movimento válido, reduzir o numeral sobre o jogador.
5. Quando o contador terminar, ocultá-lo e bloquear o controle.
6. Destacar o par ativo.
7. Deslizar simultaneamente as duas peças do par até suas casas finais.
8. Fazer uma pausa de carga curta, entre 0,25 e 0,40 segundo.
9. Revelar e executar todas as linhas de ataque simultaneamente.
10. Resolver acerto, distância exigida e safe spot depois que o efeito visual terminar.
11. Iniciar o próximo édito ou apresentar o resultado da fase.

O numeral sobre o jogador representa comandos válidos restantes. A regra de sucesso continua usando a distância Manhattan entre a origem do édito e a posição final. Assim, voltar pelo próprio caminho consome o contador, mas pode resultar em distância final incorreta.

## Movimentação e dados das peças

Cada peça deve possuir dados explícitos, em vez de depender de um eixo central fixo:

- tipo: Torre ou Bispo;
- lado de origem: esquerda, direita, superior ou inferior;
- faixa fixa: linha ou coluna usada para atravessar o tabuleiro;
- direção de entrada;
- deslocamento em numeral romano;
- casa inicial externa e casa final calculada.

Recomendação: posicionar as duas peças de um par em faixas diferentes. Isso evita que duas peças com deslocamento `III` terminem sobre a mesma casa central e cria ataques mais interessantes. A configuração de cada fase deve ser validada por simulação para garantir pelo menos uma solução completa.

## Linguagem visual recomendada

### Numerais

- `Label3D` ou texto 3D sempre voltado para a câmera.
- Texto marfim com núcleo branco, contorno violeta e brilho azul suave.
- O numeral restante pulsa discretamente quando diminui.
- Ao desaparecer, fragmenta-se em partículas pequenas que sobem e perdem opacidade.

### Movimento das peças

- Deslizamento com aceleração e desaceleração suaves.
- Pequena elevação durante o trajeto e pouso com anel luminoso na casa final.
- Rastro estreito no chão durante o movimento, sem marcar antecipadamente todo o trajeto.
- As duas peças do par se movem ao mesmo tempo.

### Ataque

- Carga curta na base da peça e nas casas alinhadas.
- Primeiro pulso escuro carmesim, seguido por um feixe vermelho-branco.
- Torre: quatro braços ortogonais partindo da casa final.
- Bispo: quatro braços diagonais partindo da casa final.
- Cada casa atingida recebe um pulso próprio para manter a leitura da grade.
- Se o jogador for atingido, aplicar flash localizado e fragmentos vermelhos; evitar cobrir toda a tela.

### HUD mínima

- Identificação discreta da fase.
- Safe spot mostrado pelo próprio tabuleiro.
- Numeral restante sobre o jogador.
- Numerais e direções junto às peças.
- Mensagens de resultado e reinício em um painel pequeno e temático.
- Instruções de controle apenas na primeira fase ou em uma tela de pausa.

## Progressão recomendada das fases 1 a 5

| Fase | Conteúdo | O que ensina |
| --- | --- | --- |
| 1 | Um édito, sem inimigos | Movimento discreto, numeral romano e distância final |
| 2 | Dois éditos, sem inimigos | Origem reiniciada entre éditos, adição e chegada ao safe spot |
| 3 | Torres no primeiro édito | Previsão de linhas e colunas depois do deslocamento |
| 4 | Torres nos dois éditos | Planejamento de duas ondas consecutivas |
| 5 | Bispos no primeiro édito e Torres no segundo | Alternância entre leitura diagonal e ortogonal |

## Escopo matemático desta etapa

As fases 1 a 5 trabalharão somente numerais romanos, contagem de movimentos, adição dos dois éditos e distância na grade. Números primos e múltiplos ficam completamente fora desta implementação e poderão ser reavaliados em uma etapa posterior.

## Entrada das peças pela borda

- Toda peça nasce fora das 25 casas jogáveis.
- Cada configuração fixa define um ponto inicial externo e uma faixa de entrada.
- As flechas luminosas mostram primeiro o deslocamento da peça ao longo da borda.
- Depois de se alinhar à faixa correta, a peça entra no tabuleiro pelo lado em que está posicionada.
- O numeral romano informa quantas casas ela percorrerá para dentro da grade.
- Peça na esquerda entra para a direita; peça na direita entra para a esquerda; peça acima entra para baixo; peça abaixo entra para cima.
- Quando quatro peças estiverem presentes, somente o par ativo exibe as flechas pulsantes. O outro par permanece visível, com brilho reduzido, até seu édito.

## Divergências técnicas encontradas

- O controlador atual limita explicitamente a integração às fases 1 a 4.
- Torres e Bispos presentes no tabuleiro são objetos de prévia; o loop calcula posições e ataques sem criar, mover ou sincronizar as peças visuais.
- Apenas o resolvedor da Torre está conectado ao loop; o Bispo tem geometria calculada na grade, mas não participa da resolução da fase 5.
- Os ataques são arrays de coordenadas e não possuem apresentação visual.
- O centro continua ocupado pela Rainha no estado da grade, rejeitado como safe spot, rejeitado pela máquina de éditos e rejeitado pelo cálculo de deslocamento externo.
- A HUD revela coordenadas exatas do jogador e do destino e expõe estados técnicos que devem ser removidos.
- O par atual é processado como primeira peça e segunda peça instantaneamente, sem movimento visível nem espera pelo término das duas peças.
- A fase 5 não contém `edict_values`, portanto não pode ser construída pela implementação atual.
- Os arquivos antigos `fase1_primos.json` a `fase4_multiplos.json` não alimentam a campanha atual.

## Recomendação de implementação

Tratar o trabalho em quatro blocos verificáveis:

1. corrigir as regras da grade e definir dados completos e solucionáveis para as fases 1 a 5;
2. criar o ciclo visual dos pares, com spawn, numerais, movimento simultâneo e ataque;
3. substituir a HUD e criar a apresentação central dos éditos e o contador sobre o jogador;
4. ajustar ritmo, câmera, efeitos e feedback depois que as cinco fases estiverem jogáveis do começo ao fim.
