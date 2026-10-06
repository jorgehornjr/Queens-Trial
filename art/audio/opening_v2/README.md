# O Chamado da Rainha

Novo arranjo original de 35 s para a abertura. Mantém o motivo de metais da rainha aprovado pelo usuário, com uma nova apresentação de violas e violoncelo para a chegada confiante do protagonista. A revelação cresce em 18,8 s; metais, coro e tímpanos assumem em 22,1 s; o maior trecho ocorre perto de 25 s.

A expressão e a harmonia continuam sustentadas depois do auge, durante o restante da câmera. Não há o fade longo nem o colapso de volume da versão anterior. O Godot sobrepõe a música da gameplay nos últimos 1,6 s, usando ganhos de potência constante para evitar um vazio sonoro.

`opening_v2.mid` é a fonte editável. `cue_sheet.json` registra os planos; `verification_report.json` registra duração, picos, nível do trecho final e posição do auge. O jogo usa `assets/audio/music/priest_opening.ogg` por compatibilidade com a cena existente. A versão anterior está arquivada em `../priest_opening/legacy_opening.ogg`.

Autoria reproduzível: `tools/compose_opening_v2.py`, com as bibliotecas e o FluidSynth existentes em `.godot/qa/audio_tools/`. O MuseScore General e suas amostras usam a licença MIT já arquivada em `../priest_opening/`.
