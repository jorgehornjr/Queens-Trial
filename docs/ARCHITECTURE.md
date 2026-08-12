# Arquitetura

## Princípios

- Godot 4 e GDScript.
- Cenas pequenas e reutilizáveis.
- Sistemas com responsabilidades claras.
- Fases definidas por dados.
- Comunicação por sinais quando reduzir acoplamento.
- Sem geração procedural obrigatória.
- Sem infraestrutura de CI/CD complexa.

## Sistemas principais

### GameManager

Controla o fluxo geral do jogo: inicialização, seleção e carregamento de fase, estados de pausa, vitória, derrota e progressão.

`scripts/core/`

### BoardManager

Mantém o estado do tabuleiro 8x8, converte posições entre grade e mundo, valida limites e ocupação, e coordena a navegação pelas casas.

`scripts/board/` e `scenes/board/`

### MathEngine

Centraliza regras matemáticas reutilizáveis, como identificação de números primos, cálculo e validação de múltiplos e regras ligadas à contagem de passos.

`scripts/math/`

### EnemySystem

Calcula áreas de ameaça e comportamentos dos inimigos inspirados em Torre, Bispo e Cavalo. O sistema consulta o estado do tabuleiro, mas não deve controlar a interface.

`scripts/enemies/`

### UIManager

Apresenta HUD, menus, instruções, diálogos, feedback matemático e estados de vitória ou derrota. Reage ao estado do jogo por métodos explícitos e sinais.

`scripts/ui/`, `scenes/ui/` e `ui/`

### AudioManager

Gerencia música, efeitos sonoros e volumes, evitando que cada cena mantenha sua própria lógica de áudio global.

`scripts/audio/`

## Fluxo de alto nível

1. `GameManager` solicita os dados da fase.
2. `BoardManager` constrói o estado inicial do tabuleiro.
3. `MathEngine` oferece as validações matemáticas exigidas pela fase.
4. `EnemySystem` calcula ameaças de acordo com os inimigos configurados.
5. O jogador realiza uma ação; o tabuleiro valida movimento e ocupação.
6. Os sistemas notificam mudanças por sinais.
7. `UIManager` e `AudioManager` apresentam o feedback.
8. `GameManager` resolve vitória, derrota ou avanço.

## Fases data-driven

Cada fase deve ser descrita em `data/phases/`, usando Resources do Godot (`.tres`) ou JSON.

Campos esperados:

- identificador, nome e ordem;
- objetivo e instruções;
- tamanho do tabuleiro (8x8 no escopo atual);
- posição inicial e condição de chegada;
- casas, valores matemáticos e safe spots;
- inimigos, tipos e posições;
- condições de vitória e derrota;
- referências opcionais para diálogo, arte e áudio.

O carregador deve validar dados ausentes e apresentar erros legíveis durante o desenvolvimento.

## Organização de cenas

- `scenes/main/`: entrada, fluxo geral e composição principal.
- `scenes/board/`: grade, casas e elementos visuais do tabuleiro.
- `scenes/gameplay/`: jogador e objetos interativos.
- `scenes/ui/`: menus, HUD, diálogos e feedback.
- `scenes/cutscenes/`: cenas narrativas e transições.

## Dependências

- `GameManager` orquestra os demais sistemas.
- `BoardManager` pode consultar `MathEngine` e `EnemySystem` por interfaces simples.
- `EnemySystem` recebe um retrato do tabuleiro ou consultas controladas.
- `UIManager` e `AudioManager` observam eventos e não decidem regras de gameplay.
