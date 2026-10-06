# Priest para Mixamo

`priest_body_for_mixamo.zip` contém o OBJ, o MTL e a textura de cor para upload.
O Mixamo aceitou esse pacote após simplificar o material para usar apenas cor;
os mapas PBR adicionais causavam a mensagem de erro de mapeamento de esqueleto,
mesmo sem ossos no arquivo. `priest_body_for_mixamo.fbx` fica como alternativa.
Ambos contêm somente o corpo e o capuz, unidos, sem esqueleto ou animações.
A pose neutra em A afasta os braços 40 graus do casaco e preserva o tronco e o
capuz para facilitar a identificação das articulações pela Adobe.
O material de upload usa apenas a textura de cor e permanece opaco. Os mapas
PBR completos seguem no modelo original para o jogo.

Na marcação do Mixamo, foi usado **Use Symmetry** e **Standard Skeleton (65)**. Os
marcadores foram colocados no queixo, punhos, cotovelos, joelhos e virilha. As
mãos esculpidas têm os dedos agrupados. A tentativa com **No Fingers (25)**
voltou à etapa de marcadores; o esqueleto padrão concluiu o auto-rig e a prévia
automática foi verificada. O personagem `priest_body_for_mixamo` foi confirmado
na conta do Mixamo, ficando pronto para escolher as animações.

`priest_mixamo_rig_tpose.fbx` é a cópia baixada da Adobe, em FBX Binary e T-pose,
sem escolher um clipe da biblioteca. Foi reimportada no Blender e verificada:
33 ossos efetivamente exportados, uma malha com UVs, textura de cor incorporada,
articulações principais e todos os vértices com pesos de skinning. Essa cópia
permite recuperar o personagem no Mixamo e serve como referência para adaptar
os clipes ao rig completo do jogo.

`priest_mixamo_prepared.blend` guarda essa cópia e os objetos `CapeMesh` e
`TabardMesh` separados e ocultos. Eles ficam fora do FBX para o auto-rig da Adobe
conseguir identificar o corpo e os joelhos.

O rig completo do jogo continua em `../fallen_priest_rig.blend`. A malha da capa,
os 117 ossos, os pesos e `assets/models/characters/fallen_priest/cape_cage.json`
continuam sendo a fonte da física aprovada. Ao integrar as animações escolhidas,
retargetar os movimentos do corpo para `PriestRig`, mantendo os tecidos e os
ossos de capa/tecido frontal do jogo. A integração dos seis clipes escolhidos
está concluída em `../fallen_priest_mixamo.blend` e no GLB correspondente.
`animations/` guarda os FBX fornecidos, todos com skin. `import_mixamo.py`
adapta os movimentos sem substituir as malhas ou os pesos do rig completo.
`animation_import_report.json` registra hashes, durações e amostras.

Para guardar o personagem criado pela Adobe, baixar uma cópia em **FBX Binary**
com **With Skin**. Para os clipes adicionais do mesmo personagem, usar **Without
Skin**, **30 FPS** e **Keyframe Reduction: None**. Guardar todos os downloads do
Priest juntos; os arquivos de animação do mago antigo não são desse novo rig.

Reproduzir a preparação:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python tools/fallen_priest/prepare_mixamo.py
```

`preparation_report.json` registra a malha de upload, os pontos de referência e
os hashes dos arquivos originais verificados na exportação.
