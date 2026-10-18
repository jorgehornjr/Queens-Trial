# Queen's Trial

Jogo de estratégia em Godot 4.7, com arena 3D e grade lógica de 5 × 5 casas.

## Executar

Abra `project.godot` no Godot 4.7 e pressione **F5**. O menu principal leva à abertura com Hooded Fandaniel, personagem atual. O jogo usa os recursos convertidos incluídos no projeto e não depende da instalação de Final Fantasy XIV.

**WASD** move uma casa por pressionamento; **R** reinicia a prova; **Esc** pausa e permite selecionar as oito fases ou um desafio Chaotic. Nas fases 1–6, o livro no canto superior direito ou **N** abre a consulta e pausa a prova. Para testar diretamente, use `godot --path . -- --phase=6`.

## Vanilla — fases 1–5

A casa inicial, o refúgio e os éditos variam ao entrar em uma fase. Os valores vão de **I a IV**, sem repetir o valor dentro do mesmo par. O sorteio prioriza combinações ainda não vistas, evita a mesma sequência em fases consecutivas e prefere inverter uma combinação antes de repetir sua ordem.

Não há cronômetro. A contagem de movimentos resolve cada édito; a distância final deve corresponder à carta. O último édito precisa terminar no refúgio, fora do ataque da onda atual. As fases mantêm sua progressão: movimento, dois éditos, torres, dois pares e bispos. O gerador valida rotas e ocupação e oferece pelo menos duas casas intermediárias possíveis nas fases de dois éditos, mantendo uma dificuldade menor que o Chaotic.

As estrelas da fase 1 acompanham a rota sorteada. A abertura termina na mesma casa usada pela primeira fase, sem reposicionar o personagem no fim da câmera. Reiniciar preserva o desafio e sua semente, para permitir outra tentativa do mesmo problema.

## Balança — fase 6

São três rodadas com dois pesos diferentes, sorteados de **VIII a XX**. Há cinco segundos para mover-se livremente antes da inclinação de 21° e do deslizamento de três casas. As duas colunas do lado leve permitem sobreviver. Na última rodada, os pratos se soltam, o braço fica nivelado e o **?** substitui a indicação visual; as cartas continuam determinando o lado pesado.

A balança é carregada e instanciada durante a preparação da cena. Seu shader é apresentado totalmente dissolvido antes da gameplay, evitando o carregamento e a construção do modelo na troca da fase 5 para a 6. A dissolução do globo e a materialização continuam com seus tempos originais.

A transformação inteira aparece antes do livro de tutorial. Depois que a balança se materializa, há uma breve pausa visual antes da leitura; as cartas e os cinco segundos da primeira rodada só começam ao fechar o livro.

Para testar o personagem atual nessa prova, execute `scenes/previews/fandaniel_phase_six_preview.tscn` com **F6**.

## Cartas — fases 7 e 8

As vinte artes de **I a XX** são usadas nas provas. A fase 7 tem ordenação crescente e decrescente, seis espaços e uma carta fixa. A fase 8 apresenta associação aos alvos 14, 18 e 19 e, depois, o decreto falso. A passagem pela nébula e a apresentação das cartas continuam em seus controladores próprios.

## Chaotic

Cinco desafios separados do Vanilla, acessíveis pelo seletor de pausa ou por `--phase=101` até `105`. Mantêm o cronômetro, os pares de ataques, a atmosfera vermelha, o fogo no vestido da rainha e a música **With Hearts Aligned**. Regras e soluções de QA em [docs/design/savage.md](docs/design/savage.md).

## Correção após erro

Um painel marfim no centro da tela explica o erro com letras grandes, valores envolvidos e uma orientação para a próxima tentativa. O fundo escurece e a correção permanece até o jogador escolher **Tentar novamente** ou pressionar **Enter**. Nas provas de cartas, **Continuar** devolve a resposta montada para que ela possa ser ajustada. A pausa continua disponível durante a leitura.

O painel atende Vanilla, balança, cartas e Chaotic. Detalhes e verificações em [docs/design/failure_feedback.md](docs/design/failure_feedback.md).

## Recursos e manutenção

O protagonista ativo é **Hooded Fandaniel**, com sua roupa bordô, caminhada cinematográfica do FFXIV, sombra sob o capuz e animações da gameplay. Modelos de mago, arcanjo e sacerdote anteriores, suas animações, capa nativa, efeitos substituídos, fontes editáveis e prévias foram retirados do projeto ativo.

O backup recuperável está em `Deleted/project_cleanup_2026-10-17/`, ignorado pelo Git e pelo Godot. O manifesto registra os caminhos originais, tamanhos e SHA-256. `before_changes/` preserva o código e a configuração anteriores a esta manutenção. Nada desta limpeza foi apagado permanentemente. As notas de autoria em `art/` e os créditos dos recursos atuais continuam disponíveis; para reexportar fontes, restaure primeiro os insumos correspondentes do backup.

Detalhes da limpeza e recuperação: [docs/maintenance/cleanup_2026-10-17.md](docs/maintenance/cleanup_2026-10-17.md). Créditos em [CREDITS.md](CREDITS.md).

## Verificação

```powershell
python tools/run_checks.py --jobs 3
```

A suíte cobre geração e soluções Vanilla, campanha com movimentos e ataques reais, abertura, Fandaniel, livro, HUD, correção de erros, áudio, pausa, balança, cartas, menu e Chaotic. Os logs ficam em `tmp/checks/`.

Para auditar dependências, incluindo texturas extraídas dos GLBs:

```powershell
godot --headless --path . --script tools/audit_resources.gd
python tools/audit_project.py
```

O relatório sugere candidatos para revisão; não move arquivos automaticamente. Para medir a passagem da balança com renderização, execute `tests/profile_balance_transition.gd`. Pré-visualizações geradas ficam fora do Git.
