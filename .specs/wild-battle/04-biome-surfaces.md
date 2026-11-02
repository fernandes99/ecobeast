# 04. Superfícies contínuas por bioma

- **Status:** concluída
- **Depende de:** [03-exploration-screen](03-exploration-screen.md)

## Contexto

Cada hexágono do mapa é um sprite próprio, e o resultado parece um tabuleiro: o desenho recomeça a cada hexágono. O dono quer o conceito visual do Sandwalkers, em que cada bioma é uma superfície contínua dividida pela grade, com pixel art de resolução melhor. A referência é uma imagem que ele mandou, sem as decorações dela.

Esta fase troca só o desenho. O gerador, o contrato, o andar e o toque continuam iguais. Geometria e arquivos estão em [architecture.md](architecture.md#superfícies).

## Escopo

- Sete texturas contínuas, a da lateral e a do contorno, em `res://assets/terrain/surfaces/`.
- A superfície de cada hexágono no `HexTile`.
- O `HexMapView`, que passa a desenhar malhas com a textura presa ao mapa.
- O dobro de resolução na arte.

## Fora do escopo

- Decorações: árvores, vegetação, montanhas e cavernas, que o dono vai separar à parte.
- Elevação, que veio depois, na [05](05-terrain-elevation.md).
- Qualquer mudança no servidor. Ele continua mandando `biome`, `shape` e `variant`.
- Encontros por bioma, que são da `biome-encounters`.
- Transições suaves entre biomas: a divisa é sempre a borda do hexágono.

## Requisitos

**Texturas**

- **RF-01:** Cada superfície é um PNG em `res://assets/terrain/surfaces/<superfície>.png`, que emenda consigo mesmo nas quatro bordas.
- **RF-02:** As superfícies são `temperate`, `boreal`, `stone`, `wshallow`, `wdeep`, `hill` e `mont`. Além delas, `side.png` é a lateral do bloco, e `contour.png` é o contorno.
- **RF-03:** Um bioma novo entra com um PNG novo, sem mudar código.

**Superfície de cada hexágono**

- **RF-04:** `HexTile.surface()` devolve `hill` para a forma `hill`, `mont` para a forma `mont`, e o bioma para as outras. Vale também para as ilhas, na água.

**Desenho**

- **RF-05:** A textura fica presa às coordenadas do mapa: o pixel `(x, y)` da arte mostra o pixel `(x mod largura, y mod altura)` da textura da superfície. Por isso ela não recomeça a cada hexágono.
- **RF-06:** Os hexágonos ficam encostados, e nenhum fundo aparece entre eles.
- **RF-07:** O contorno aparece em todos os hexágonos, por cima das superfícies, e fica visível dentro de um mesmo bioma.
- **RF-08:** A lateral aparece só nas bordas de baixo do mapa, onde falta o vizinho.
- **RF-09:** Uma textura que falta gera `push_error`, e o resto do mapa continua sendo desenhado.
- **RF-10:** O mapa continua em pixels inteiros, com filtro `NEAREST`. O botão de depuração continua cabendo o mapa inteiro, com filtro suave.

**O que não muda**

- **RF-11:** `surface_center`, `coord_at` e `pixel_scale` continuam com o mesmo sentido, e o toque em cada vizinho continua movendo o jogador para ele.

## Critérios de aceite

- [x] As 9 texturas existem, carregam e emendam nas quatro bordas.
- [x] `HexTile.surface()` devolve o esperado para plano, colina, montanha e ilha.
- [x] Fora das linhas do contorno, cada pixel da tela é o pixel da textura naquela coordenada do mapa, entre hexágonos vizinhos e entre mapas diferentes.
- [x] Nenhum fundo aparece entre os hexágonos.
- [x] O contorno aparece entre dois hexágonos do mesmo bioma.
- [x] A lateral aparece abaixo da borda do mapa, e não entre hexágonos vizinhos.
- [x] Um bioma sem textura gera erro no console, e os outros aparecem.
- [x] Em janelas de 360×640, 405×720, 412×915 e 720×1061, cada pixel da arte ocupa um bloco inteiro e igual de pixels reais.
- [x] Na tela real, contra um servidor de teste, tocar em cada um dos seis vizinhos move o jogador para ele, e andar mantém os pixels inteiros.
- [x] Depurar o mapa inteiro e voltar restaura escala, filtro e centro.
- [x] Um mapa de 10.000 hexágonos é montado sem travar a tela.
- [x] O projeto abre sem erros nem avisos de script.

## Desenho técnico

**Criar**

- `client/assets/terrain/surfaces/`: as 9 texturas, com os arquivos `.import`. Elas geram mipmaps, como os sprites, por causa do modo de depuração.

**Alterar**

- `client/domain/models/hex_tile.gd`: `surface() -> String` no lugar de `sprite_path()`.
- `client/ui/components/hex_map_view.gd`: uma malha por textura, em vez de um sprite por hexágono.
- `client/CLAUDE.md`: o caminho das texturas e dos sprites.
- `.specs/wild-battle/architecture.md`, `README.md`: geometria, arquivos e decisões.

Uma malha (`ArrayMesh`) é uma lista de triângulos que a placa de vídeo desenha de uma vez. Cada vértice diz onde fica na tela e qual ponto da textura mostra (o UV). Com o UV calculado pela posição no mapa, e não pelo hexágono, dois hexágonos vizinhos continuam a mesma textura. Com `texture_repeat` ligado, ela se repete sozinha depois da última coluna.

Um único nó continua desenhando tudo em `_draw`, agora com um `draw_mesh` por textura: a lateral primeiro, depois as superfícies e, por último, o contorno. O contorno é uma textura de 64×84 px que repete junto com a grade.

**Reaproveitar**

`ExplorationMap`, o cálculo de escala do `HexMapView` e a tela do mapa, que não muda.

## Verificação

Uma cena temporária monta mapas à mão e compara a tela com as texturas, pixel a pixel, nos quatro tamanhos. Outra abre a tela real pelo Hub contra um servidor de teste, com o gerador de verdade, e toca nos seis vizinhos. Uma amostra das capturas é aberta e revisada.

Passos do dono no editor (F5) e no celular:

1. Andar pelo mapa e conferir se os biomas parecem superfícies contínuas.
2. Conferir o tamanho dos hexágonos e a força do contorno.
3. Conferir se dá para distinguir colina e montanha do resto.

```bash
godot --headless -d --path client --quit-after 60
```

## Tarefas

- [x] Texturas no projeto (RF-01 a RF-03).
- [x] Verificação temporária; ver falhar.
- [x] `HexTile.surface()` (RF-04).
- [x] `HexMapView` (RF-05 a RF-11).
- [x] Remover os arquivos temporários; atualizar `architecture.md`, o README da iniciativa e o `client/CLAUDE.md`; marcar esta spec e a tabela do README como `concluída`.

## Decisões da implementação

- **`ART_SCALE` caiu de 3 para 2:** a arte dobrou, e 1,5 manteria o tamanho antigo. Com 2, o hexágono ocupa de 16% a 18% da largura da tela nos tamanhos conferidos, mais perto da imagem de referência. Fica a revisar pelo dono.
- **`surface()` substitui `sprite_path()`:** nenhum outro código usava o caminho do sprite.
- **Os 108 sprites antigos ficaram no projeto, sem uso:** apagá-los é decisão do dono.
- **`hill` e `mont` valem para qualquer bioma:** colina e montanha serão biomas nos encontros. O servidor segue mandando `biome` e `shape`, sem mudança, e a `biome-encounters` decide como usar isso. Hoje cerca de 40% da terra é colina ou montanha, e o ajuste é o `hillFrom`.
- **A elevação veio depois:** a [05](05-terrain-elevation.md) mudou a ordem de desenho, a lateral e o toque. O que está acima descreve esta fase.
- **Conferência da textura:** a verificação falhou antes do código, sem `surface()`, com a geometria antiga e sem lateral. Depois, passou nos quatro tamanhos, comparando a tela com as texturas nas posições do mapa, em dois mapas diferentes. Ficaram fora da comparação os pixels do contorno e uma faixa junto da borda de cada hexágono, onde o dono do pixel é ambíguo.
- **Conferência da tela real:** a verificação da [03](03-exploration-screen.md), adaptada, abriu o mapa pelo Hub contra um servidor de teste com o gerador de verdade, e passou com 67 de 67 itens em cada tamanho. Ela cobre os seis vizinhos, água, colina, montanha, borda, ida e volta da batalha e o modo de depuração. Das capturas, 7 foram abertas e revisadas. A textura final da montanha mudou depois dessa rodada, só nas fendas.
- **Desempenho:** 10.000 hexágonos são montados em cerca de 50 ms e desenhados em 0,28 ms por quadro, no computador de desenvolvimento. Nenhum celular foi testado.
- **As texturas são provisórias:** feitas por um script Python que não foi para o repositório, com ruído e carimbos, sem imagem de terceiros. Por isso não há questão de licença nelas.
- **Falta do dono:** jogar no editor e no celular, conferir o tamanho dos hexágonos e a força do contorno, e decidir se as texturas ficam.
