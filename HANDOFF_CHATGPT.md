# Handoff do projeto — Queens Trial

Use este arquivo como contexto inicial ao continuar o trabalho em outra conta do ChatGPT/Codex.

## Contexto rápido

- Repositório: `jorgehornjr/Queens-Trial`
- Branch remota atual: `main`
- Engine: Godot 4.7, renderer Forward Plus.
- Cena inicial: `res://scenes/main/main.tscn`.
- Projeto 3D de tabuleiro, com fases, éditos, peças, HUD e cenário espacial.
- O repositório usa Git LFS para alguns assets grandes, especialmente HDRs e alguns `.glb`.

## Estado confirmado em 28/09/2026

O diretório de trabalho estava limpo na `main` e o último commit era:

```text
fee53c3 devolver dependencias do ambiente
```

Esse commit, e o anterior `2ffe787 devolver itens deletados`, restauraram dependências apagadas acidentalmente quando foi feita uma tentativa de limpar assets do Godot. Ambos também existem na branch `devolver-itens-deletados`; a `main` está avançada até o mesmo commit.

Os commits preservaram a implementação do timer do Lorenzo, que entrou pelo merge PR #19.

## Como preparar um clone limpo para teste

No PowerShell, dentro do clone:

```powershell
git pull origin main
git lfs pull
```

Depois abra o projeto pelo Godot 4.7. Se o editor já estiver aberto, feche e abra novamente para ele reimportar os assets.

Para um teste rápido sem interface, a instalação usada neste computador é:

```powershell
& 'C:\Users\Steel\AppData\Local\Programs\Godot\4.7.2\godot.exe' --headless --path . --import
& 'C:\Users\Steel\AppData\Local\Programs\Godot\4.7.2\godot.exe' --headless --path . --quit-after 120
```

O projeto executou esses comandos sem o erro de dependência/JSON que ocorria antes.

## Restauração de assets feita

O commit de limpeza `737254a Remove assets de importacao acidentais` apagou mais do que os assets órfãos: removeu arquivos usados diretamente pelo cenário espacial.

Foram restaurados:

- Texturas, HDRs e o modelo da Terra usados por `scenes/environment/celestial_space.tscn`.
- `assets/environment/solar_system/preparation.json`, modelos `.glb` dos planetas e do buraco negro.
- Modelos das naves e `assets/environment/spacecraft/preparation.json`.
- Os respectivos arquivos `.import` desses assets.

O erro visto no console era causado por `scripts/environment/solar_system.gd`, linha 28: ele lê `assets/environment/solar_system/preparation.json`. Com o arquivo apagado, `JSON.parse_string()` retornava `null` e a atribuição para `Array` falhava.

Não foram restauradas as texturas duplicadas e órfãs do tabuleiro que haviam entrado junto com o timer.

## Sobre arquivos `.import`

Não adicione `*.import` ao `.gitignore` de forma global.

Em Godot 4, a pasta `.godot/` é cache e já deve ficar ignorada. Já arquivos como `imagem.png.import` guardam configurações de importação por asset (compressão, UID e caminhos). Alguns podem ser recriados pelo editor, mas ignorá-los todos pode fazer máquinas diferentes importarem assets com parâmetros diferentes.

Antes de remover qualquer `.import`, confirme se o arquivo-fonte correspondente existe e se é usado por cena/script. O problema anterior foi remover fontes `.hdr`, `.glb`, `.jpg`, `.png` e `.json`, não apenas cache.

## Timer do Lorenzo: estado e ponto pendente

Arquivos principais:

- `scripts/gameplay/edict_timer.gd`: cronômetro por édito.
- `scripts/gameplay/phase_loop_controller.gd`: instancia/controla o timer.
- `scripts/gameplay/edito_state_machine.gd`: diferencia fases por movimento e por tempo.
- `data/phases/campaign.json`: fases 6–10 usam `"resolution": "timer"` e 15 segundos por édito.

Ponto a verificar/corrigir: `phase_loop_controller.gd` chama `_hud.set_edict_timer(remaining)`, mas uma busca no projeto não encontrou o método `set_edict_timer` em `scripts/ui/hud.gd`. O código evita crash com `has_method`, porém o contador provavelmente não aparece no HUD. Testar visualmente as fases 6–10 e implementar o método/label caso ele realmente não exista.

O aviso amarelo `Integer division. Decimal part will be discarded.` é separado dos erros de assets e não impediu o carregamento do cenário; vale corrigir depois para manter o console limpo.

## Sugestão de prompt para a nova conta

> Estou continuando o projeto Godot 4.7 `Queens-Trial`. Leia primeiro o arquivo `HANDOFF_CHATGPT.md`, trabalhe a partir da branch `main`, preserve alterações existentes e não faça comandos destrutivos. Quero testar e corrigir o timer das fases 6–10, principalmente porque `phase_loop_controller.gd` chama `set_edict_timer`, mas o método não foi encontrado no HUD. Antes de editar, inspecione o estado do Git e explique o diagnóstico.

