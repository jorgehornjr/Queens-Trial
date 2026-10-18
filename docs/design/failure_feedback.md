# Correção de erros e apresentação da balança

Implementação de 18/10/2026.

## Apresentação da fase 6

O controlador da balança aguarda a materialização terminar e o globo ficar
oculto antes de chamar o livro. A balança permanece visível por mais 0,55 s
antes da abertura do tutorial. Durante a transformação e a leitura, o estágio
continua em `TRANSITION`: movimento, cartas e cronômetro aguardam. Fechar o
livro libera a primeira rodada com os cinco segundos completos.

Reiniciar ou trocar de fase cancela a apresentação anterior. A pausa também
congela a transformação. Quando o capítulo já foi lido, a rodada começa
diretamente após a transformação, sem reapresentar o livro.

## Painel de correção

`scripts/ui/failure_feedback.gd` cria um painel central marfim, com texto
escuro, ação bordô, borda dourada e fundo escurecido. A explicação aparece
diretamente, sem título ou subtítulo, seguida da orientação e do botão. As fontes são
Jupiter Pro e Alegreya, já usadas no projeto. O conteúdo se ajusta à altura
necessária e a composição acompanha a resolução da janela.

A explicação permanece até a confirmação, sem reinício automático. O botão
fica bloqueado nos primeiros 0,4 s e o teclado ignora a repetição de teclas
mantidas, evitando que a ação que submeteu a resposta feche o aviso também.
Movimento e consulta do livro ficam bloqueados; Esc permite pausar e R mantém
o reinício explícito. Trocar de fase cancela o painel sem confirmar a tentativa.

As mensagens explicam o motivo concreto:

- Distância: numeral da carta, distância exigida e distância alcançada.
- Ataque: a casa final foi atingida; a orientação lembra linhas ou diagonais.
- Refúgio: os éditos foram cumpridos, mas faltou terminar na casa iluminada.
- Balança: pesos de cada lado em romanos e decimais, lado mais pesado e queda.
- Cartas: valores envolvidos e regra de ordem, associação ou decreto falso.

Vanilla, balança e Chaotic aguardam **Tentar novamente** antes de reiniciar.
Nas fases 7 e 8, **Continuar** preserva as cartas colocadas e libera os ajustes.
A morte ou queda ainda pode ocorrer ao fundo enquanto a correção é apresentada.

## Verificação

```powershell
python tools/run_checks.py --jobs 3
godot --path . --windowed --resolution 1280x720 --script tests/capture_failure_feedback.gd
```

As 19 verificações da suíte passaram. O teste `test_feedback_presentation`
cobre a transformação sem obstrução, pausa, sequência do livro, início do
cronômetro, cancelamento ao trocar de fase, confirmação pelo teclado,
proteção contra confirmação imediata e layout em 1280×720 e 1920×1080.
Os testes dos controladores verificam reinício manual e preservação da
resposta nas provas de cartas.

As capturas renderizadas ficam em `tmp/feedback_review/`: `correction_720.png`,
`correction_1080.png`, `globe_before_book.png`, `scales_before_book.png` e
`book_after_scales.png`. Foram inspecionadas as duas resoluções e a sequência
globo → balança → livro. A pasta de capturas é ignorada pelo Git.

O código anterior a esta alteração está em
`Deleted/feedback_presentation_2026-10-17/before_changes/`. O nome registra o
dia em que o trabalho começou; a verificação terminou em 18/10/2026.
