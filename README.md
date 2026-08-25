# Queen's Trial

Queen's Trial é um jogo de estratégia educacional desenvolvido em Godot. A apresentação acontece em uma arena 3D, enquanto regras, posições e validações usam uma grade lógica 2D de 5 x 5 casas.

## Estado atual

- tabuleiro 3D gerado por código a partir de coordenadas `Vector2i`;
- casa central permanentemente reservada para a Rainha;
- safe spot visível;
- jogador com movimento discreto por WASD e animação por `Tween`;
- catálogo data-driven com a progressão das dez fases;
- gerenciador mínimo para iniciar e reiniciar fases, preservando a semente procedural;
- testes das regras fundamentais da grade e do catálogo.

Ainda não estão implementados o loop completo dos éditos, os ataques animados, a geração procedural das fases 7 e 9, o julgamento da Rainha ou a arte final.

## Documentação

As regras de gameplay estão consolidadas em [docs/Queens Trial - Documentação Final.pdf](docs/Queens%20Trial%20-%20Documentação%20Final.pdf).

## Como executar

1. Instale o Godot 4.7.
2. Importe a pasta que contém `project.godot`.
3. Execute o projeto com `F6` ou pelo botão de reprodução.
4. Use `W`, `A`, `S` e `D` para mover o jogador uma casa por pressionamento.

## Estrutura

```text
assets/              arte, áudio, materiais, modelos, texturas e efeitos
data/phases/         catálogo e futuras configurações das fases
docs/                especificação consolidada
scenes/              cenas organizadas por domínio
scripts/             lógica separada da apresentação
tests/               testes executáveis em modo headless
```