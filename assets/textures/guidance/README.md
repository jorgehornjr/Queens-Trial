# Símbolos da orientação

`sanctuary_reference.png` é a imagem fornecida pelo usuário: lua crescente, estrela central e estrela menor no alto à direita. O arquivo permanece intacto. `sanctuary_symbol.gdshader` usa sua silhueta clara e filtra o fundo azul durante a renderização, preservando as proporções no piso.

`path_star.svg` é uma estrela de cinco pontas desenhada para o caminho. Todas as instâncias têm a mesma orientação, tamanho e distância entre centros. `starred_guide.gd` aplica uma onda senoidal de amplitude e período constantes ao longo da rota suavizada das quatro casas, com início e fim nos centros corretos.

O brilho do refúgio usa uma curva contínua de 2,8 s, controlando emissão, opacidade luminosa e luz de piso. A oscilação pausa junto com o jogo e não ilumina a névoa volumétrica. A fase 1 mantém os controles bloqueados até a última estrela terminar de acender.
