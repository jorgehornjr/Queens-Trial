# O Limiar da Rainha

Composição original de 35 segundos para a abertura do sacerdote. O MIDI contém
onze pistas de instrumentos, com expressão, panorâmica e pequenos ajustes de
tempo e intensidade. O mapa `cue_sheet.json` relaciona as entradas musicais às
câmeras: entrada do sacerdote em 4,6 s; revelação em 18,8 s; declaração musical
da rainha em 22,1 s; auge no zoom out próximo de 25 s; cadência em 33,75 s.

O jogo reproduz somente `assets/audio/music/priest_opening.ogg`, sem repetição.
As notas de harpa anteriores à chegada foram removidas para eliminar o brilho
sonoro inicial; as cordas começam diretamente e os demais trechos permanecem.
A trilha da gameplay começa ao concluir os 35 segundos. Pausar a abertura pausa
também o áudio para manter a sincronização.

Para renderizar novamente, execute `tools/compose_priest_opening.py` com Python,
NumPy, SciPy e mido. O script espera ferramentas de autoria em
`.godot/qa/audio_tools/`: FluidSynth (binário Windows), `python_modules/` e o
soundfont oficial `MuseScore_General.sf3`. FFmpeg deve estar no PATH. Não é
necessário guardar essas ferramentas junto aos arquivos de execução do jogo.

O soundfont e seus instrumentos têm licença MIT. A licença e os créditos de
amostras estão nesta pasta. Não contém amostras da antiga intro nem de Final
Fantasy; o pedido de inspiração orientou a atmosfera e a instrumentação.
