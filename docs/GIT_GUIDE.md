# Guia de Git

Este guia define um fluxo leve para que integrantes da equipe sem experiência com Git consigam trabalhar em paralelo sem tornar o processo burocrático.

## Branches

- `main`: versão integrada e funcional do projeto.
- `feature/<descricao-curta>`: nova funcionalidade.
- `fix/<descricao-curta>`: correção de problema.
- `docs/<descricao-curta>`: alteração apenas de documentação.

Exemplos: `feature/grid-8x8`, `feature/numeros-primos`, `fix/movimento-torre`.

Evite desenvolver diretamente na `main` depois da configuração inicial. Atualize sua branch com frequência e abra uma pull request quando a tarefa estiver pronta para revisão.

## Commits

Faça commits pequenos, coerentes e com mensagem no imperativo. Exemplos:

- `Cria grid inicial 8x8`
- `Adiciona validação de números primos`
- `Corrige ameaça diagonal do bispo`
- `Documenta critérios da N1`

Não misture arte, refatoração ampla e uma nova mecânica no mesmo commit sem necessidade.

## Fluxo recomendado

1. Atualize a `main` local.
2. Crie uma branch para uma tarefa definida.
3. Implemente e teste localmente.
4. Revise os arquivos alterados e remova temporários.
5. Faça commits claros.
6. Envie a branch e abra uma pull request.
7. Peça revisão de ao menos um colega.
8. Após aprovação e teste, integre a alteração.

## Pull requests

A descrição deve informar:

- o que mudou;
- por que a mudança é necessária;
- como testar;
- capturas ou vídeo quando houver alteração visual;
- limitações ou trabalho futuro.

Antes de integrar, confirme que o projeto abre no Godot, não apresenta erros relevantes e que a cena ou fluxo alterado foi testado.

## Arquivos do Godot

- Versione `project.godot`, cenas, scripts, recursos e arquivos `.import` apenas quando aplicável à versão usada.
- Não versione a pasta `.godot/`, builds exportadas nem arquivos temporários.
- Alterações em cenas e recursos de texto podem gerar conflitos.
- Prefira cenas menores e componentes instanciados para reduzir conflitos.

## Conflitos

Não aceite automaticamente um dos lados de um conflito sem entender a diferença. Para cenas Godot, abra o arquivo resultante no editor depois da resolução e teste o fluxo afetado.

## Proteção de trabalho

Nunca sobrescreva ou descarte alterações de outro integrante. Se encontrar arquivos modificados que não pertencem à sua tarefa, pare e combine a integração com o responsável.
