# Arcanjo — primeiro rig funcional

Preparado no Blender 5.2.2 em 01/10/2026 a partir do FBX fornecido pelo usuário. O modelo original permanece em Downloads; o mago, suas cenas e animações permanecem no projeto.

## Arquivos

- `archangel_rig.blend`: fonte editável, com as texturas 4K empacotadas.
- `../../../assets/models/characters/archangel/archangel_rig.glb`: exportação com skin e animações para Godot. Caminho a partir da raiz do projeto: `assets/models/characters/archangel/archangel_rig.glb`.
- `rig_report.json`: contagens de geometria, partes e ossos.
- `validation_report.json`: resultados das verificações de pesos, costuras e deformação.

O `.gdignore` mantém o Blender fora da importação automática do Godot. A versão de jogo utiliza o GLB.

## Organização

Oito objetos e oito materiais próprios: corpo, cabeça, asa esquerda, asa direita, espada, auréola, tecido frontal e tecido posterior. As texturas e coordenadas UV originais foram preservadas. A fonte possui dois conjuntos contínuos de penas; cada lado ganhou onze ossos para articulação e flexão das diferentes faixas, sem inventar cortes entre penas fundidas.

O esqueleto contém 81 ossos de deformação e dez controles de edição. Inclui coluna, pescoço, cabeça, braços, mãos/dedos, pernas, pés, pontas dos pés, asas, acessórios e tecido. Os controles `CTRL_Wing_L/R` movimentam as raízes das asas. Os sliders `arm_ik` e `leg_ik` no objeto `Archangel_Rig` alternam de FK (0) para IK (1); em IK, use os controles das mãos/pés e seus pole targets. As coleções de ossos organizam corpo, mãos, asas, acessórios e controles.

Há no máximo quatro influências por vértice, normalizadas. Vértices compartilhados nos cortes têm pesos iguais, inclusive nas poses animadas. O skin utiliza a mesma deformação linear do Godot, para evitar aprovar um resultado no Blender que fique diferente no motor.

A malha de trabalho tem 314.220 triângulos, contra 1.963.878 no original: redução de 84%. É uma malha triangular simplificada da escultura, não uma retopologia manual para animações extremas. Este primeiro rig foi ajustado e conferido para repouso, apresentação e poses moderadas; gestos amplos e animações definitivas ainda podem exigir refinamentos locais dos pesos.

## Animações de avaliação

- `breathing_idle`: respiração discreta e movimento contínuo das asas com atraso entre segmentos.
- `intro_presence`: presença serena, abertura das asas e pequeno movimento da cabeça, usada na cutscene de teste.
- `wing_flex_test`: movimento mais amplo para inspecionar as asas.
- `rig_pose_test`: pose de teste de braços, cabeça e pernas.

Os últimos dois clipes são provas do rig. Não foram preparados ciclos definitivos de caminhada, morte, strafe ou animações da fase 6. Na prévia da fase 1, o deslocamento continua usando a grade existente e o repouso do personagem.

## Testar no Godot

Abra `scenes/previews/archangel_rig_preview.tscn` e execute com F6. O seletor permite trocar as animações; o botão de ossos mostra o esqueleto exportado. Arraste com o botão direito para girar e use a roda para aproximar. O botão **Testar abertura e fase 1** abre o jogo com o arcanjo no lugar do mago apenas nessa sessão de teste.

Para abrir a cutscene diretamente, execute `scenes/previews/archangel_phase_one_preview.tscn` com F6. A cena principal de produção continua disponível com o mago original.

## Ferramentas e verificações

Scripts em `tools/archangel/`, executados com Blender em background:

1. `prepare_source.py`: extrai o arquivo fornecido, preserva as texturas, simplifica a malha e cria a base temporária em `.godot/qa`.
2. `segment_mesh.py`: classifica regiões usando conectividade/distâncias pela superfície e referências espaciais, com capturas coloridas para inspeção.
3. `build_rig.py`: cria ossos, pesos, controles, partes separadas e os clipes de avaliação; grava fonte e exportação. `-- --skip-render` omite somente as capturas de diagnóstico.
4. `export_rig.py`: reexporta a fonte depois de edições no Blender.
5. `validate_rig.py`: verifica pesos, costuras nas poses, controle das asas e rigidez da espada/auréola.

NumPy vem com o Blender; SciPy foi instalado somente em `.godot/qa/blender_modules`, sem alterar os pacotes do Blender. Instalação reproduzível no computador atual:

```powershell
python -m pip --python 'C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe' install --target .godot/qa/blender_modules --no-deps scipy
```

Verificação no motor: `godot --headless --path . --script tests/test_archangel_rig.gd`.

Capturas e amostras animadas: `godot --path . --script tests/capture_archangel_preview.gd`, em `.godot/qa`. A captura deve ser executada com renderizador gráfico.
