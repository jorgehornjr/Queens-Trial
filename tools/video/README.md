# Demonstração N2

Ferramentas de gravação, fora do caminho de execução do jogo. Não alteram as
regras da campanha e não salvam progresso no perfil do jogador.

## Gravar

Requer Godot 4.7, FFmpeg e FFprobe disponíveis no PATH. Na raiz do projeto:

```powershell
New-Item -ItemType Directory -Force tmp/n2_video
godot_console --path . --windowed --resolution 1920x1080 --disable-vsync --fixed-fps 30 --write-movie tmp/n2_video/queens_trial_raw.avi --script tools/video/record_n2.gd
python tools/video/edit_n2.py --output-dir "C:/Users/Steel/Videos/Queens Trial N2"
```

O diretor abre o menu real, inicia a abertura e percorre a campanha com eventos
de teclado e mouse. As cartas são arrastadas pelo mecanismo nativo da interface.
Somente a primeira prova é errada de propósito; o botão de correção permite
reiniciar a mesma tentativa. Os capítulos II e IV são tratados como já lidos
para evitar reapresentações; as provas continuam sendo resolvidas normalmente.

O MovieWriter do Godot captura o viewport e a mixagem original em Full HD,
30 fps, com som estéreo. O cursor e as legendas são sobreposições de gravação,
não recursos da interface entregue no jogo. Nenhuma parte da área de trabalho
é capturada. A renderização pode levar mais tempo que a duração do vídeo.

O bruto, os marcadores de cenas e os intermediários ficam em `tmp/n2_video/`,
ignorado pelo Git. Para validar as entradas sem renderizar, use:

```powershell
godot_console --headless --path . --fixed-fps 30 --script tools/video/record_n2.gd -- --dry-run
```

A simulação sobrescreve `timeline.json`; preserve o arquivo correspondente ao
bruto antes de realizar outra simulação. A montagem usa os marcadores do bruto
para selecionar os trechos, sem acelerar a imagem nem mudar o tom dos sons.
As transições de imagem e áudio duram nove quadros (0,3 s). O ajuste fino de
duração usa apenas os planos de ambientação iniciais, preservando a leitura
dos tutoriais e da explicação do erro.

## Saída

O arquivo `Queens_Trial_N2_1080p.mp4` usa H.264 High, YUV 4:2:0, som AAC estéreo
a 48 kHz e duração de 4min59s. O editor valida a resolução, os 8.970 quadros,
a duração inferior a cinco minutos e a presença da faixa de áudio.

O vídeo mostra objetivo e tutorial, um erro com explicação e correção,
progressão após acertos, torres, pares de ataques, bispos, transformação em
balança, comparação de pesos, ordenação crescente e decrescente, associação
de numerais, decreto falso, pausa e uma prévia do Chaotic. Os cálculos recebem
legendas breves; não há narração.
