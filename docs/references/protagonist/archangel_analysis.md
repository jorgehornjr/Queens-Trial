# Análise do Corrupted Archangel

Inspeção realizada em 30/09/2026, antes de substituir o protagonista.

Fonte local: `C:\Users\Steel\Downloads\corrupted-archangel-six-wings-boss\source\Zyklus7_Zeile4.zip`.

## Estrutura verificada no FBX

- FBX binário 7400, contendo um objeto Mesh, uma Geometry e um Material.
- 981.894 vértices e 1.963.878 triângulos.
- Nenhum esqueleto, skin, pesos ou animações no arquivo. A importação no Godot confirmou uma MeshInstance3D, uma superfície e ausência de skin.
- Um material compartilhado, com mapas de cor, normal, rugosidade e metalicidade, todos com resolução 4096 × 4096. Há também uma imagem auxiliar combinada `rm` no arquivo compactado.
- A conectividade dos índices contém quatro componentes: 969.681, 12.207, 3 e 3 vértices. Portanto, a malha não é completamente contínua, mas quase toda a geometria está conectada. Não há seis objetos ou materiais independentes correspondentes às asas.

## Implicações

Materiais separados permitiriam editar a aparência de corpo e asas individualmente, mas não substituem um rig. Para animar asas e corpo, será necessário preparar ossos e pesos ou uma deformação procedural apropriada. As animações do protagonista atual não podem ser aplicadas diretamente a este FBX estático.

A densidade da malha é alta para um protagonista em tempo real. Convém otimizar antes da integração definitiva e preservar as texturas e a silhueta durante essa preparação.

## Prévia

O modelo foi aberto no Godot com os mapas externos aplicados manualmente. O carregamento direto de texturas embutidas do FBX apresentou erros; usar os JPEGs externos permitiu conferir a aparência.

Capturas locais, geradas apenas para inspeção:

- `.godot/qa/archangel_front.png`
- `.godot/qa/archangel_back.png`

Scripts e análise numérica temporários estão em `.godot/qa`. Nenhuma cena, modelo ou animação do protagonista foi substituída nesta inspeção. O Wizard permanece intacto.

## Preparação posterior — 01/10/2026

Uma versão derivada ganhou esqueleto próprio, oito partes/materiais separados e clipes de avaliação. A fonte editável e os detalhes ficam em [art/characters/archangel/README.md](../../../art/characters/archangel/README.md). O arquivo recebido continua intacto e a prévia no Godot usa cenas próprias para testar a abertura e a fase 1.
