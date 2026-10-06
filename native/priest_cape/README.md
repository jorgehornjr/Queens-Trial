# Capa: cálculo nativo

A DLL incluída executa apenas o cálculo numérico da capa. O Godot continua
responsável pelos ossos, animações, pausas, colisores e desenho do personagem.
Não é necessário instalar compilador nem mudar configurações para jogar no
Windows x64 com Godot padrão (precisão simples).

O cage de 117 pontos, os 18 pontos presos ao manto, os passos de 120 Hz,
as 12 iterações, gravidade, arrasto, elasticidade e colisões são os mesmos da
simulação original. O módulo usa a interface C de GDExtension 4.4, verificada
no Godot 4.7.2. O cabeçalho oficial em `vendor/` inclui sua licença MIT.

Para recompilar com Zig 0.14.1 ou um compilador Zig compatível:

```powershell
./native/priest_cape/build.ps1 -ZigPath "C:/caminho/zig.exe"
```

O código GDScript continua disponível. `-- --cape-script` força essa versão
para comparação. Para outras plataformas, compile uma biblioteca equivalente
e adicione a entrada na configuração `.gdextension`; a DLL incluída é Windows.
O jogo usa o cálculo GDScript quando a classe nativa não está registrada.

Os arrays são copiados por escrita pelo Godot; cada chamada devolve um novo
estado sem alterar os bytes guardados pelo chamador. Todos os limites e índices
de links são conferidos antes do acesso às coordenadas. O formato interno usa
float32 e vetores com três/quatro componentes, exclusivamente na interface
entre `priest_cape_physics.gd` e este módulo:

- Estado: três uint32 (pontos, pinos, links); links `(a,b,rest,compliance)`;
  posições e posições anteriores.
- Quadro: uint32 (colisores); oito float32 (vento, gravidade, escala, piso ativo,
  extensão e altura); duas matrizes 3x4 (piso e inversa); pinos; esferas.

Verificação física: `tests/test_fallen_priest_phase_six.gd`,
`tests/test_priest_ground_death.gd` e `tests/test_cape_solver.gd`.
Medição com a abertura real: `tests/profile_priest_performance.gd`.
