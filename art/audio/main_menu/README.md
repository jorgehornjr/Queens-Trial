# Entre Duas Órbitas

Trilha original de 2min28s para o menu principal. A referência de atmosfera é a tela de título de Endwalker enviada pelo autor: entrada cinematográfica, brilho na revelação e um motivo sereno que continua enquanto o menu permanece aberto. A composição usa melodia, harmonia e gravação próprias, sem amostras do vídeo.

Os primeiros 12 segundos acompanham a rotação: cordas e coro começam discretos, uma camada de ar cresce sob os astros e a harpa conduz a revelação. Um brilho cristalino aparece aos 7 segundos, junto da entrada da logo; metais e celesta sustentam o momento. Esses efeitos aparecem uma única vez.

A partir de 12 segundos, uma frase de 16 segundos em Mi menor/Sol maior se repete com harpa, piano, cordas, coro suave e respostas ocasionais de flauta. Há pequenas variações de dinâmica e instrumentação. A entrada dramática não retorna. O fade final começa em 136 s e a faixa termina em 148 s, sem repetição automática.

O jogo usa `assets/audio/music/menu_orbits.ogg`, com `loop=false`. Pular a apresentação leva o áudio a 12 s. Ao iniciar a campanha, o menu reduz seu volume durante a transição e libera o player.

A fonte editável é `menu_orbits.mid`, produzida por `tools/compose_menu_orbits.py`. A renderização utiliza o FluidSynth e o MuseScore General já existentes em `.godot/qa/audio_tools/`. A licença MIT e o inventário das amostras estão em `../priest_opening/MuseScore_General_License.md` e `MuseScore_General_Sample_Sources.csv`. As camadas de ar e brilho são sintetizadas pelo próprio script. As ferramentas e o soundfont não são necessários para executar o jogo.

`cue_sheet.json` registra os tempos. `verification_report.json` confirma duração, pico abaixo de clipping, continuidade do trecho central e término em silêncio. A prévia MP3 completa está em `docs/previews/main_menu/menu_orbits.mp3`; o vídeo `intro.mp4` inclui o áudio da engine.
