# Arquitetura do mapa

## Superfícies

O mapa é uma superfície contínua por bioma, dividida pela grade. Os hexágonos ficam encostados, com a ponta para cima, e a arte tem o dobro da resolução dos sprites antigos, mantendo as proporções deles. O mapa já teve um vão de 2 px, pedido pelo dono, que ele mesmo tirou: o vão impedia a superfície contínua.

| Medida                     | Valor    |
| -------------------------- | -------- |
| Largura do hexágono        | 64 px    |
| Altura do hexágono         | 58 px    |
| Inclinação                 | 16 px    |
| Borda vertical             | 26 px    |
| Lateral na borda do mapa   | 26 px    |
| Centro da superfície       | (32, 29) |
| Passo horizontal           | 64 px    |
| Passo vertical             | 42 px    |
| Deslocamento de cada linha | 32 px    |

Os cantos, a partir do canto do hexágono, em sentido horário: (32, 0), (64, 16), (64, 42), (32, 58), (0, 42) e (0, 16).

**Arquivos:** `res://assets/terrain/surfaces/<superfície>.png`. Eles podem ter qualquer tamanho, mas precisam emendar consigo mesmos nas quatro bordas, porque a textura se repete. Ao trocar uma imagem pelo mesmo nome, o `.import` continua com `mipmaps/generate=true`. Um arquivo novo precisa dessa opção, por causa do modo de depuração.

| Arquivo                                             | Aparece em                                       |
| --------------------------------------------------- | ------------------------------------------------ |
| `temperate`, `boreal`, `stone`, `hill`, `mountain`, `wshallow`, `wdeep` | Hexágonos desse bioma, em qualquer altura |
| `side`                                              | Paredão e lateral dos biomas fora de `cliff`, água incluída |
| `cliff`                                             | Paredão e lateral de `stone` e `mountain`        |
| `contour`                                           | Contorno, por cima de todos os hexágonos         |
| `highlight`                                         | [Destaque](#destaque-do-hexágono-atual) do hexágono atual |

Um bioma novo entra com um PNG novo, sem mudar código: o nome do arquivo é o slug do bioma ([terrain-height](../terrain-height/README.md)). Até a terrain-height, a forma `hill` e a `mont` tinham a textura delas em qualquer bioma; a `mont.png` virou `mountain.png`. `contour.png` tem 64×84 px, o período da grade em duas linhas, com linhas de 1 px em degraus de 2 por 1. Ele só vale para esses passos.

**Desenho:** o `HexMapView` monta uma malha por textura e desenha [linha por linha](#decorações). O ponto da textura (UV) é a posição no mapa, antes da altura, dividida pelo tamanho da textura, por isso ela não recomeça a cada hexágono. As texturas atuais foram geradas por código, são provisórias, e o dono pode trocá-las.

**Sprites antigos:** os 108 PNGs de 32×48 continuam em `res://assets/terrain/`, sem uso, até o dono decidir o que fazer com eles. Os nomes são `<biome>_<shape>_<NN>.png`.

## Elevação

O mapa tem cinco níveis, de 0 a 4, com alturas de 0, 8, 16, 24 e 32 px. Desde a [terrain-height](../terrain-height/README.md), o nível é o `height` que o servidor manda em cada hexágono (`HexTile.height`), e qualquer bioma pode ter qualquer nível, a água também. O gerador põe a água no 0, `temperate` e `boreal` no 1, `hill` no 2 (no 3 dentro da região de pedra), `stone` no 3 e `mountain` no 4. As alturas em pixels ficam em `LEVEL_HEIGHTS`, no `HexMapView`.

Um hexágono sobe a altura do nível dele, com superfície e contorno. A textura continua presa à posição antes da altura, para os vizinhos do mesmo nível seguirem contínuos.

**Paredão:** sob cada uma das duas bordas de baixo, o paredão aparece se o vizinho daquele lado for mais baixo, e tem a altura da diferença, então termina exatamente na borda de cima dele. Sem vizinho, na borda do mapa, ele desce a altura do nível mais 26 px. A coluna da textura segue a posição no mapa, e a linha 0 é a borda de cima. A face da direita é escurecida pela cor do vértice. O paredão de `stone` e `mountain` usa `cliff`, e o dos outros biomas, `side` (`HexMapView.face_texture`). As duas têm 512×64 px.

**Ordem de desenho:** de trás para a frente, [linha por linha](#decorações). Um terreno só cobre o que está atrás dele, porque o paredão termina na borda do vizinho da frente, sem invadi-lo.

**Toque:** `coord_at` procura do nível mais alto para o mais baixo a superfície que contém o ponto, com o hexágono exato. Em um paredão, nenhuma superfície contém o ponto, e vale o dono dele. `surface_center` já devolve o centro na altura do hexágono, e por isso a câmera sobe e desce sozinha.

## Decorações

Plantas e rochas são só enfeite: não mudam terreno, encontro nem movimento. Por isso saem do cliente, em `HexDecorations.decorations_of(tile, map_seed)`, a partir da seed do mapa e da coordenada, sem mudar o contrato. A mesma seed repete as mesmas decorações.

**Arquivo:** `res://assets/terrain/decorations/decorations.png`, uma folha de 192×1088 px, com células de 48×64 px e a base da decoração no ponto (24, 60) da célula. Plantas e rochas ficam na mesma folha porque cada plano de uma linha desenha todas numa malha só, ordenadas juntas. Cada linha é um tipo, sempre com 4 variantes. Para trocar a arte, basta pintar por cima na mesma célula. Um tipo novo pede uma linha na folha e uma entrada em `KIND_ROWS`, `KIND_RADIUS` e `RECIPES`.

| Linha | Tipo        | Linha | Tipo         |
| ----- | ----------- | ----- | ------------ |
| 0     | `tree`      | 9     | `moss`       |
| 1     | `pine`      | 10    | `pebbles`    |
| 2     | `bush`      | 11    | `rock`       |
| 3     | `dark_bush` | 12    | `mossy_rock` |
| 4     | `tuft`      | 13    | `brown_rock` |
| 5     | `flowers`   | 14    | `boulder`    |
| 6     | `fern`      | 15    | `rock_pile`  |
| 7     | `dry_shrub` | 16    | `spire`      |
| 8     | `dry_tuft`  |       |              |

**Receitas** (`RECIPES`, _a revisar_): cada superfície lista tipos, com a chance de aparecer no hexágono e o mínimo e o máximo de plantas.

| Superfície  | Decorações                                            |
| ----------- | ----------------------------------------------------- |
| `temperate` | `tree`, `rock`, `bush`, `flowers`, `pebbles`, `tuft`  |
| `boreal`    | `pine`, `mossy_rock`, `dark_bush`, `fern`, `pebbles`  |
| `hill`      | `rock`, `dry_shrub`, `pebbles`, `dry_tuft`            |
| `stone`     | `spire`, `boulder`, `rock_pile`, `moss`               |
| `mountain`  | `brown_rock`, `moss`                                  |
| Água        | nenhuma                                               |

`KIND_RADIUS` é o espaço de cada tipo no chão e também a distância mínima do centro do hexágono, onde o jogador fica.

**Desenho:** cada linha do mapa tem três `HexRowView`, e as linhas ficam em ordem, de trás para a frente. O primeiro desenha paredões, superfícies, [arremates](#arremates), contorno e o [destaque](#destaque-do-hexágono-atual). Os outros dois desenham as decorações da linha, uma malha para cada [plano](#planos-de-profundidade), com a folha como textura e o [vento](#vento) como material. Assim, quem está na frente sempre cobre quem está atrás, seja terreno ou decoração, em qualquer combinação de alturas. Dentro de uma linha, cada hexágono fica na sua coluna, e nada se sobrepõe além das decorações.

**Linhas sob demanda:** os nós das linhas nascem todos em `set_map`, mas as malhas só são montadas quando a linha chega a `ROW_MARGIN` linhas da tela. Criar as malhas do mapa inteiro de uma vez levava 700 ms no computador de desenvolvimento.

## Destaque do hexágono atual

`highlight.png` tem o tamanho do hexágono, 64×58 px: um contorno branco de 2 px por dentro da borda e uma sombra escura que enfraquece até 15 px para o meio, em pontilhado. `HexMapView.set_current(coord)` guarda a textura e a posição na linha do hexágono, na altura dele, e redesenha só as duas linhas envolvidas. Nenhuma malha é remontada.

O nó do chão desenha o destaque depois das malhas dele, e as decorações ficam nos nós seguintes. Assim, as decorações do hexágono e tudo que está nas linhas da frente cobrem o destaque, como cobririam o chão.

A tela chama `set_current` ao abrir o mapa e no início de cada passo.

## Domador

`TamerSprite` é um `SheetSprite`, um `AnimatedSprite2D` filho do `HexMapView`, na [profundidade](#planos-de-profundidade) da linha dele. O Domador fica parado no centro da tela, e quem se move é o mapa: `_move_map` desconta o movimento do mapa da posição dele. A posição do nó é o ponto entre os pés, e como ele herda a escala do mapa, um pixel da folha vale um pixel da arte.

`assets/tamer/idle.png` e `run.png` têm células de 32×32 px, uma coluna por quadro e cinco linhas, todas olhando para a direita. O número de colunas vem da largura da imagem.

| Linha | Olhando para        | Vizinhos                  |
| ----- | ------------------- | ------------------------- |
| 0     | Frente              | Nenhum: é o início do mapa |
| 1     | Diagonal, para baixo | `(0, 1)` e `(-1, 1)`      |
| 2     | Lado                | `(1, 0)` e `(-1, 0)`      |
| 3     | Diagonal, para cima | `(1, -1)` e `(0, -1)`     |
| 4     | Costas              | Nenhum                    |

Os vizinhos da esquerda, `(-1, 1)`, `(-1, 0)` e `(0, -1)`, usam `flip_h`. As animações se chamam `idle_<linha>` e `run_<linha>`.

No passo, a tela chama `face(vizinho)` e `play_run()`, e `play_idle()` ao chegar.

**Rota ([14](14-tap-to-walk.md)):** o toque num hexágono distante vira uma lista de passos, calculada no cliente por `ExplorationMap.path_to_any`, uma busca em largura pelos vizinhos livres. A tela anda a lista com o mesmo passo, sem `play_idle()` entre eles, e só olha o fim: um Domador NPC para a caminhada na hora, um toque novo troca o destino ao fim do passo, e a ação só abre no último hexágono. Num bloqueado, o destino são os livres ao lado dele (`free_sides`). Enquanto anda, cada passo que falta tem um `RouteMark` no chão da linha dele (`set_ground_overlay`), e o destino, um anel. `STEP_SECONDS` é o próprio `TamerSprite.RUN_SECONDS`, para cada hexágono ser um ciclo inteiro da corrida.

No modo de depuração do mapa inteiro, `_fit_view` desconta a escala do mapa, com `art_scale()`, porque na escala do mapa ele sumiria.

## Planos de profundidade

Em 2D, quem vem depois na árvore de nós é desenhado por cima. Cada linha do mapa tem três `HexRowView`, um logo depois do outro: `_rows`, com o chão e o destaque; `_back_rows`, com as decorações da metade de cima dos hexágonos; e `_front_rows`, com as da metade de baixo, de `offset.y >= 0`.

`set_actor_row(actor, row)` usa `move_child` para pôr um filho do mapa entre as duas partes das decorações da linha. Ele fica por cima da linha e das linhas de trás, e por baixo das decorações da frente e das linhas seguintes, inclusive do terreno delas.

No passo, o plano muda antes de sair quando a linha aumenta, porque a linha nova cobriria os pés, e ao chegar quando a linha diminui, porque a linha de onde ele veio cobriria.

A divisa é a metade do hexágono porque o Domador para no centro. Um personagem que pare em outro ponto do hexágono vai precisar de mais partes por linha.

## Vento

As plantas balançam com o vento, e rochas, `pebbles` e `moss` ficam paradas. Quem move é o shader `client/ui/components/plant_wind.gdshader`: a cada pixel, ele calcula quantos pixels da arte aquela linha da planta anda, sempre um número inteiro, e lê a folha nesse ponto deslocado. Por isso a pixel art nunca borra, e nenhuma malha é remontada. Nada do vento roda em GDScript: a hora vem de `TIME`, no próprio shader.

Cada vértice de uma decoração leva quatro valores em `CUSTOM0`: o ponto de apoio no mapa (`x`, `y`), quanto o topo anda (`z`) e a altura da planta (`w`). O `z` é negativo na planta espelhada, porque a textura dela corre ao contrário. Assim, todas vão para o mesmo lado. Os dois últimos vêm de `HexDecorations.KIND_SWAY`; um tipo fora da tabela tem `z` zero e fica parado.

**A conta:** `pixels = arredondar(strength × z × balanço × rajada × subida²)`.

- `balanço` é uma onda de −1 a 1, com período `sway_period` e comprimento `sway_length`, na direção `direction`.
- `rajada` vai de 0,5 a 1, com uma onda mais lenta e mais longa, `gust_period` e `gust_length`.
- `subida` é a altura da linha na planta, de 0 no apoio a 1 no topo. Ao quadrado, ela deixa tronco e sombra parados e concentra o movimento no topo.

A fase das duas ondas vem do ponto de apoio, e não do pixel, para a planta inteira ficar na mesma fase. É isso que faz plantas próximas andarem quase juntas e a onda atravessar o mapa.

O máximo de cada tipo precisa ser menor que a folga dele na célula, ou a planta seria cortada ou mostraria a célula vizinha. Hoje a menor folga é de 6 px, e o maior balanço é de 2 px.

O material é um só, `_wind_material`, em todos os nós de decorações. O `strength` é o ajuste geral da força: zero desliga o vento. Os outros parâmetros ficam no início do shader.

## Menu de depuração

Só em build de debug, os controles do mapa mostram o botão "Debug", que abre um painel no topo da tela, por cima do mapa, deixando livres o Domador e os vizinhos dele. Ele reúne o mapa inteiro e o spawn de Ecobeasts, para validar as folhas de cada um sem depender de encontro nem de batalha.

A lista tem todos os Ecobeasts do catálogo. `CreatureSprite.has_sheets(slug)` procura `assets/creatures/<slug>/explore/idle.png` e `walk.png` (a pasta `explore/` veio na [board-battle/07](../board-battle/07-battle-sprites.md)), e quem não tem as duas fica desativado. Por isso um Ecobeast com folhas novas aparece ativo sem mudar código. As folhas vêm da skill `creature-sprites`.

`SheetSprite` é a base com as folhas e as direções, usada pelo `TamerSprite` e pelo `CreatureSprite`. O Domador vira para um vizinho do hexágono, com `face`. O Ecobeast vira para qualquer direção do mapa, com `face_toward`, que escolhe a linha da [tabela](#domador) pelo ângulo do movimento e usa `flip_h` para a esquerda.

O Ecobeast é um filho do `HexMapView`, com a posição em pixels da arte, como as decorações. Ele não precisa acompanhar o mapa, ao contrário do Domador, que fica parado na tela. `wander_in(coord, center)` sorteia pontos no mesmo limite das decorações, e a cada quadro `_process` anda até o ponto ou espera. Ele nunca muda de hexágono.

Ele usa `set_actor_row` com a linha do hexágono, então a [profundidade](#planos-de-profundidade) dele é a da linha inteira, e não a do ponto em que está. Dentro do mesmo hexágono, ele pode aparecer na frente de uma planta que deveria cobri-lo. Dois personagens na mesma linha ficam na ordem em que chegaram a ela.

É só enfeite: o servidor não sabe que ele existe, e ele some ao sair da tela do mapa.

**Escala:** o tamanho de um Ecobeast no mapa vem da altura do catálogo. O Domador tem 1,70 m e 25 pixels, então um Ecobeast tem `height_m × 25 / 1,70` pixels: o Ruvo, com 0,50 m, tem 7. A célula de 32×32 não muda, e a verificação da skill `creature-sprites` confere a altura.

## Arremates

Duas superfícies vizinhas diferentes têm um arremate na divisa: um recorte irregular, dentro de um dos dois hexágonos, que esconde a linha reta. A exceção é a divisa entre `wshallow` e `wdeep`, que fica reta. Como as decorações, é só enfeite e sai do cliente, em `HexTransitions.transitions_of(tile, map)`, sem mudar o contrato.

**Quem recebe:** `SURFACE_ORDER`, de quem recebe para quem avança, é `temperate`, `boreal`, `hill`, `stone` e `mountain`. O hexágono mais baixo nessa lista recebe o material do vizinho, e o outro fica como está. A água não está na lista: ela recebe `foam` de qualquer terra, em qualquer altura. Uma superfície que não está na lista não avança sobre ninguém, e um bioma novo funciona sem arremate até entrar nela.

**Arquivo:** `res://assets/terrain/transitions/transitions.png`, uma folha de 384×1044 px, com células de 64×58 px, do tamanho do hexágono. Cada coluna é uma borda, em sentido horário, a partir da de cima à direita, a mesma ordem de `HexTransitions.NEIGHBORS`. Cada material ocupa 3 linhas, uma por variante, na ordem de `MATERIAL_ROWS`.

| Material                 | Recorte                                  |
| ------------------------ | ---------------------------------------- |
| `foam`                   | Faixa translúcida com crista fina, em ondas |
| `temperate`, `boreal`    | Pontas curtas de grama                   |
| `hill`                   | Solo irregular                           |
| `stone`, `mountain`      | Blocos baixos                            |

O recorte é discreto de propósito: sem linha nem sombra, e a borda da terra se desfaz em pontilhado. Nenhum pixel fica a mais de 9 px da borda do hexágono. Os recortes afinam nos cantos, e por isso duas bordas seguidas viram dois lóbulos, em vez de se cruzarem. Para trocar a arte, basta pintar por cima na mesma célula. A variante sai de `hash([map_seed, coord, borda])`.

**Desenho:** uma malha por linha do mapa, depois das superfícies e antes do contorno, para a grade continuar visível. A textura é a da folha, não a contínua do bioma: como o recorte é estreito e tem borda própria, a emenda não aparece.

**Vizinho da frente mais alto:** ele cobre a borda de baixo do hexágono. A terra não recebe arremate nessa borda, porque a borda de cima do vizinho já fecha a divisa. A água recebe, e a espuma sobe a diferença de altura, para encostar na borda visível do vizinho. Com um vizinho muito mais alto, ela pode chegar ao centro, mas aí o próprio vizinho já cobre essa parte.

**Escorrido:** em um paredão, o bioma de cima desce pela face: musgo em tufos e fios em `temperate` e `boreal`, e areia em lóbulos com grãos soltos em `hill`. Pedra, montanha e água não escorrem. O arquivo é `res://assets/terrain/transitions/drips.png`, uma folha de 128×96 px, com células de 32×16 px, a largura de uma borda. As colunas são 4 variantes, e cada material de `DRIP_ROWS` tem duas linhas: a curta, que cabe em um paredão de 8 px, e a comprida, a partir de 16 px. A malha vem logo depois dos paredões, com a mesma inclinação, a linha 0 colada na superfície e a mesma cor de vértice da face. Ela é cortada na altura do paredão, então nunca passa do pé dele.

## Coordenadas

Coordenadas axiais `(q, r)`. Os seis vizinhos de uma posição são `(q+1, r)`, `(q-1, r)`, `(q, r+1)`, `(q, r-1)`, `(q+1, r-1)` e `(q-1, r+1)`.

O canto do hexágono, em pixels da arte, fica em `x = 64 * q + 32 * r` e `y = 42 * r`. O resultado é sempre inteiro. O centro da superfície soma `(32, 29)`.

## Contrato

`POST /v1/me/exploration`, sem corpo, responde `201`:

```json
{
  "map": {
    "seed": 1234567,
    "start": { "q": 0, "r": 1 },
    "tiles": [{ "q": 0, "r": 0, "biome": "temperate", "height": 1, "variant": 4 }]
  }
}
```

`biome` é um dos 7 biomas e `height` vai de 0 a 4. `variant` vai de 1 a 3 em `hill` e `mountain` e de 1 a 6 nos outros (o cliente guarda o valor, mas as superfícies não o usam). Falha: `409` "Crie seu Domador primeiro." O `map` também traz `creatures`, os Ecobeasts do mapa, descritos na [biome-encounters](../biome-encounters/architecture.md#contrato).

## Gerador

Uma função pura em `server/src/domain/exploration/`: `generateMap(seed, config)`. Toda a aleatoriedade vem de um gerador com seed, nesta ordem fixa:

1. **Recorte.** A região cresce a partir de `(0, 0)`: entre as posições vizinhas à região, entra a de menor `distância + ruído × edgeRoughness`, até `tileCount`. O resultado é conectado, sem posições repetidas, com a quantidade exata e borda irregular.
2. **Campos.** Quatro ruídos independentes dão elevação, umidade, pedra e crista. A crista é `1 - |2 × ruído - 1|`, que fica alta ao longo de linhas compridas: é dela que saem as cadeias de montanhas. Cada campo vira percentil dentro do mapa, de 0 a 1, para a proporção dos terrenos não depender da sorte.
3. **Água.** Elevação abaixo de `waterFraction` é água; a parte mais baixa dela, `deepFraction`, é `wdeep`, e o resto é `wshallow`. `wdeep` encostado em terra vira `wshallow`.
4. **Terra.** Na ordem, a primeira regra que valer:

| Condição                                                     | Bioma       |
| ------------------------------------------------------------ | ----------- |
| campo de pedra entre os `stoneFraction` mais altos           | `stone`     |
| umidade acima de `wetLimit`                                  | `boreal`    |
| resto                                                        | `temperate` |

5. **Forma.** Na terra, crista acima de `mountainFrom` é `mont`, acima de `hillFrom` é `hill`, e o resto é `flat`. Assim a forma não depende do bioma: todo bioma de terra tem plano, colina e montanha, e a montanha de base cinza só existe dentro da região de pedra. Na água, `islandChance` dá `hill` ou `mont`; o resto é `flat`.
6. **Limpeza.** `mont` de terra sem vizinho `mont` vira `hill`, até não sobrar nenhum. Depois, por `cleanupPasses` vezes, um bioma de terra sem vizinho igual assume o bioma de terra mais comum entre os vizinhos.
7. **Variante.** Em `flat`, `detailChance` escolhe entre 4 e 6, e o resto entre 1 e 3. Nas outras formas, entre 1 e 3.
8. **Início.** A posição de terra plana mais perto de `(0, 0)`.
9. **Conversão** ([terrain-height](../terrain-height/01-terrain-height.md)). Cada hexágono troca a forma por bioma e altura (`terrainOf`): `mont` vira `mountain` na altura 4, `hill` vira `hill` na 2 (na 3 sobre `stone`), `stone` fica na 3, a terra comum na 1 e a água na 0. A etapa de antes da conversão é `generateShapedMap`, que os testes conferem.

Os parâmetros ficam juntos em `DEFAULT_MAP_CONFIG`, em `server/src/domain/exploration/map-config.ts`. O dono os ajusta direto nesse arquivo, _a revisar_:

| Parâmetro       | Valor  | Parâmetro       | Valor |
| --------------- | ------ | --------------- | ----- |
| `tileCount`     | 10000  | `stoneFraction` | 0,15  |
| `edgeRoughness` | 200    | `hillFrom`      | 0,6   |
| `noiseScale`    | 0,05   | `mountainFrom`  | 0,95  |
| `waterFraction` | 0,2    | `islandChance`  | 0,05  |
| `deepFraction`  | 0,5    | `detailChance`  | 0,2   |
| `wetLimit`      | 0,5    | `cleanupPasses` | 3     |

Os testes do gerador têm uma configuração própria, fixa, para esses ajustes não os reprovarem. Com a configuração do jogo, um teste só confere que o mapa é válido.

## Pixels inteiros

A tela lógica do jogo tem 720×1280 e é escalada para a janela por `canvas_items`, em geral por um número quebrado. O mapa compensa isso: `pixels = max(1, round(escala_da_janela × ART_SCALE))` é quantos pixels reais cada pixel da arte ocupa, e o nó do mapa recebe a escala `pixels / escala_da_janela`, **calculada em cada eixo**. A tela lógica tem tamanho inteiro, então a escala da janela difere um pouco entre X e Y (0,8295 e 0,8289 numa janela de 720×1061), e a diferença se acumula ao longo do mapa. `ART_SCALE` é 2, _a revisar_. O nó usa filtro `NEAREST`, e a posição dele é sempre arredondada para um pixel real, inclusive durante o passo. A exceção é o botão de depuração que mostra o mapa inteiro: reduzido, o mapa usa filtro suave com mipmaps, que as texturas geram na importação.
