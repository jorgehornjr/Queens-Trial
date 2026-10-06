# Queima das cartas: referência anterior preservada

A versão atual usa Candle, fornecido pelo usuário, com recorte de 1,65 s. Consulte `../user_presentation/README.md`. O recorte de AHS abaixo permanece arquivado em `legacy_ahs.wav`; não é reproduzido pelo jogo.

O usuário rejeitou a primeira síntese de fogo e pediu um teste com o áudio da
cena do livro na [abertura de AHS 13 publicada pela FX](https://www.youtube.com/watch?v=o7MXJvhDEQY).
A cena visual aparece aproximadamente entre 25,8 e 27,1 segundos. O recorte
utilizado começa em **25,82 s** e termina em **27,87 s**, cobrindo o ataque e
a cauda do som, com duração total de **2,05 s**.

`assets/audio/sfx/cards/paper_burn.wav` é o recorte com tratamento leve: estimativa
espectral do fundo a partir das cenas adjacentes, atenuação suave dos componentes
repetitivos/harmônicos, corte de subgrave abaixo de 65 Hz e fades de 8/75 ms.
O mesmo ganho espectral atua nos dois canais, preservando a imagem estéreo;
o filtro de subgrave usa fase zero. Não foram acrescentados estalos ou camadas
de fogo sintetizados. Pico de entrega: 0,72; estéreo, 48 kHz, PCM 16 bits.

**Limite:** efeito e trilha estão misturados no vídeo. O tratamento reduz o
fundo, mas não equivale a obter a pista isolada da produção. Foi escolhida a
versão leve para evitar os artefatos metálicos de uma remoção agressiva.

Reprodução do preparo:

```powershell
python tools/prepare_card_burn_reference.py --source caminho/audio_da_referencia.wav
```

O script requer NumPy/SciPy nas dependências de autoria em
`.godot/qa/audio_tools/python_modules/`. O áudio-fonte deve estar em estéreo,
48 kHz, com o mesmo início do vídeo indicado. A fonte longa fica no cache de QA;
somente o recorte curto tratado entra no jogo. As variantes de comparação ficam
em `.godot/qa/card_burn_reference/`: `reference_excerpt.wav`,
`treated_light.wav` e `treated_stronger.wav`.

Os créditos da FX/American Horror Story identificam a origem do fonograma;
não representam autorização de uso. A síntese antiga fica arquivada apenas
no cache, como `rejected_synthetic.wav`, e o gerador antigo deixou de escrever
no arquivo usado pelo jogo.
