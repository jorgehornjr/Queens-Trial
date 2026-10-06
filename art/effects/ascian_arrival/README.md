# Ascian — chegada

Mod fornecido pelo usuário: **Ascian and Ancient Teleport.rar**, variante **Ascian/AscianTeleport.ttmp2**, autor **Dekken**. Somente `pop_tlep1t1h.avfx`, a chegada, é usado. As configurações de partida e preparação do teleporte não são acionadas.

O pacote contém o AVFX, mas referencia texturas e sons da instalação do FFXIV. O utilitário `tools/ffxiv/game_resources.py` extrai esses recursos em modo de leitura. `convert_resources.py` decodifica as texturas e o áudio MS-ADPCM; `prepare_arrival.py` preserva os modelos internos, UVs, cores por vértice, curvas de escala/cor/rotação e movimentos de UV em `assets/effects/ascian_arrival/arrival.json`.

O efeito é executado pelo Godot em `scripts/main/ascian_arrival.gd`, com ancoragem no centro do personagem (bind point 29). O personagem ganha visibilidade gradualmente dentro da fumaça. Os tipos de partículas Disc, Model e LightModel são adaptados ao Godot. A distorção das texturas é reproduzida no shader; não é uma execução do renderizador nativo do FFXIV, portanto iluminação, transparência e refração podem diferir.

Texturas originais: `smok_a0000.atex`, `aura073am.atex`, `dist_002f.atex` e `awl_swd03.atex`. A geometria inclui 240 e 198 vértices nos dois modelos do AVFX. O áudio da chegada é **SE_Vfx_Monster_c0101_wrp01.scd**, decodificado para `assets/audio/sfx/ascian_arrival.wav`, sem síntese ou troca do conteúdo.

`original_arrival.avfx`, `original_arrival.scd` e `source_report.json` preservam origem e recursos. O jogo usa os arquivos convertidos e não precisa consultar a instalação do FFXIV enquanto roda.

Verificação renderizada: `tests/capture_ascian_arrival.gd`. Prévia com som: Godot MovieWriter com `tests/capture_fandaniel_movie.gd`.
