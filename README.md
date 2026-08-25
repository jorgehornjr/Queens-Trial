# Queen's Trial

Queen's Trial é um jogo de estratégia educacional desenvolvido em Godot. A apresentação acontece em uma arena 3D, enquanto regras, posições e validações usam uma grade lógica 2D de 5 x 5 casas.

## Estado atual

Este repositório contém somente o scaffold técnico inicial do novo projeto:

- tabuleiro 3D gerado por código a partir de coordenadas `Vector2i`;
- casa central permanentemente reservada para a Rainha;
- safe spot visível;
- jogador com movimento discreto por WASD e animação por `Tween`;
- catálogo data-driven com a progressão das dez fases;
- gerenciador mínimo para iniciar e reiniciar fases, preservando a semente procedural;
- testes das regras fundamentais da grade e do catálogo.

Ainda não estão implementados o loop completo dos éditos, os ataques animados, a geração procedural das fases 7 e 9, o julgamento da Rainha ou a arte final.

## Fonte de verdade

As regras de gameplay estão consolidadas em [docs/Queens Trial - Especificacao Consolidada de Gameplay.docx](docs/Queens%20Trial%20-%20Especificacao%20Consolidada%20de%20Gameplay.docx). Outros documentos e protótipos anteriores não devem ser usados como requisito.

## Como executar

1. Instale o Godot 4.7 ou uma versão compatível.
2. Importe a pasta que contém `project.godot`.
3. Execute o projeto com `F6` ou pelo botão de reprodução.
4. Use `W`, `A`, `S` e `D` para mover o jogador uma casa por pressionamento.

O scaffold também pode ser iniciado pelo terminal:

```text
godot --path .
```

## Testes

Execute as verificações sem abrir a janela do jogo:

```text
godot --headless --path . --script res://tests/run_all.gd
```

## Planejamento no Trello

O quadro da equipe pode ser reconstruído e sincronizado pela API a partir do plano versionado em `tools/trello/board-plan.json`. As credenciais ficam somente no computador de quem executa o script.

Consulte [tools/trello/README.md](tools/trello/README.md) para conferir a prévia e aplicar o plano no Trello.

## Estrutura

```text
assets/              arte, áudio, materiais, modelos, texturas e efeitos
data/phases/         catálogo e futuras configurações das fases
docs/                especificação consolidada
scenes/              cenas organizadas por domínio
scripts/             lógica separada da apresentação
tests/               testes executáveis em modo headless
tools/trello/         plano e automação local do quadro da equipe
```

## Limite arquitetural

A grade lógica é a autoridade do estado. Cenas 3D apenas convertem casas em posições físicas e exibem o resultado; não devem decidir movimento por física, pathfinding ou IA.

Permanece pendente a decisão final sobre o que acontece com as peças depois do primeiro ataque. O scaffold oferece ocupação de casas, mas não assume automaticamente que as peças permanecerão na grade.
