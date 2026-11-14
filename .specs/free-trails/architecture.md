# free-trails: arquitetura

## As camadas de chão de uma ilha

| Camada | Onde fica | Preso a | Desenho |
| --- | --- | --- | --- |
| Chão por hexágono | `island_tiles.ground_type_id` (de hoje) | hexágono | na máscara, com a forma de hoje |
| **Traços** | `island_trails` (fase 3) | pontos em pixels do chão plano | na máscara, como uma linha |

Nenhuma das duas muda regra. O servidor só guarda, confere e devolve.

## O catálogo: `ground_types`

A coluna nova `hardness` (`smallint NOT NULL`, `CHECK hardness BETWEEN 1 AND 3`), na migration da [01](01-ground-types.md), que também põe os tipos novos:

| id | slug | name | kind | hardness |
| --- | --- | --- | --- | --- |
| 1 | `dirt_trail` | Trilha de terra | trail | 1 |
| 2 | `stone_trail` | Trilha de pedra | trail | 3 |
| 3 | `cobble_floor` | Praça de pedra | floor | 3 |
| 4 | `dirt_floor` | Chão de terra | floor | 1 |
| 5 | `gravel_trail` | Cascalho | trail | 2 |
| 6 | `stepping_stones` | Pisantes | trail | 3 |
| 7 | `sand_trail` | Areia batida | trail | 1 |
| 8 | `worn_trail` | Trilha gasta | trail | 1 |

A arte de cada tipo é `client/assets/terrain/grounds/<slug>.png`, 512×512, emendando nas quatro bordas, gerada pelo `make_grounds.gd`. Nos Pisantes, a grama entre as lajes é transparente: ali aparece a superfície do bioma.

## Os traços no banco: `island_trails` (fase 3)

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `island_map_id` | int | FK `island_maps`, `ON DELETE CASCADE` |
| `ground_type_id` | int | FK `ground_types` |
| `position` | int | a ordem de desenho na ilha, de 0 em diante, única por mapa |
| `width` | smallint | `CHECK width BETWEEN 8 AND 64` |
| `points` | `integer[]` | `x0, y0, x1, y1, …`, em pixels inteiros da arte, no chão plano, a partir do centro plano do hexágono (0, 0); `CHECK` de tamanho par, entre 4 e 512 |

**Contrato** (editor e Explorar numa ilha), na ordem de `position`:

```json
"trails": [{ "ground": "gravel_trail", "width": 22, "points": [12, -40, 30, -8, 31, 40] }]
```

O `ground` é o `slug`, como no hexágono. O servidor confere: o tipo existe; a largura; de 2 a 256 pontos; todo ponto cai num hexágono da ilha; no máximo 500 traços (`MAX_TRAILS`). O `content_hash` leva os traços, na ordem, e uma ilha sem traços tem o hash de antes.

**No cliente:** `MapTrail` (`domain/models/`), com `ground`, `width` e `points` (`PackedVector2Array`), e `ExplorationMap.trails`.

## A máscara de chão (fase 2)

O chão inteiro de uma ilha, dos hexágonos e dos traços, é desenhado primeiro numa **máscara**: uma imagem do chão plano (sem a altura) em que cada ponto guarda o id do tipo (`ground_types.id`, 0 sem chão) no canal vermelho.

- **Páginas:** a máscara é dividida em páginas de 2048×2048 pixels da arte, cada uma com metade da resolução (1 texel = 2×2 pixels da arte, 1024×1024 texels) e mais uma margem de 32 texels de cada lado, que repete o vizinho. Só existem as páginas com algum chão. Se a meia resolução deixar a borda feia, a fase 2 pode usar a inteira, e o motivo vai na spec.
- **Desenho da página:** um `SubViewport` por página (`GroundMask`, filho do `HexMapView`), com fundo transparente, sem 3D e sem suavização, posto em `UPDATE_ONCE` a cada mudança. A textura dele (`ViewportTexture`) é a máscara, sem cópia: o Godot desenha o `SubViewport` antes da tela no mesmo quadro, então o mapa nunca espera a máscara, nem ao abrir nem ao pintar no editor. Cada página ocupa cerca de 4,7 MB (RGBA8), e só existem as com chão (revisto na fase 2: a cópia para uma imagem de um canal, de 1,2 MB, pedia esperar um quadro e ler a placa de vídeo a cada mudança). Ele desenha, nesta ordem, cada um na cor `Color8(id, 0, 0, 255)`:
  1. as **trilhas por hexágono**, com a forma de hoje: a faixa de 22 px do centro até 1,5× o meio de cada lado com chão vizinho, o canto cheio entre dois lados ligados vizinhos e o círculo quando sozinha;
  2. os **pisos por hexágono**, o hexágono inteiro;
  3. os **traços**, do `position` menor para o maior, cada um como uma `Line2D` com juntas e pontas redondas, na largura dele, passando pelos pontos suavizados (uma curva de Catmull-Rom pelos pontos guardados).
- **Leitura:** a página entra no shader do terreno como `TEXTURE` da malha de chão (abaixo) e é lida com `texelFetch`, nunca filtrada. Antes de confiar no id, a fase 2 confere que a cor sai exata do `SubViewport` (sem conversão de cor).
- **Sem janela:** com `--headless`, o Godot não desenha nada, e o `SubViewport` não gera imagem. Os testes da máscara rodam com janela, por poucos quadros (`godot --path client` com a cena temporária e `--quit-after`).

## O desenho no terreno (fase 2)

O `HexMapView` monta, em cada linha, uma **malha de chão** sobre os hexágonos de terra que o chão toca (com chão próprio, com um vizinho de chão ou cortados por um traço), no lugar das malhas do `HexGrounds` de hoje. Ela entra no `_add_terrain` depois das transições e antes do contorno, como hoje, e por isso vai junto para o corte de altura e a janela do Domador.

- **Cada hexágono** é um leque de 6 triângulos na tela, já na altura, com a página do centro plano dele. **Os paredões da frente** repetem, em cada coluna, o ponto do lado em cima dela, com a sombra do lado: o caminho desce reto até o pé, como hoje.
- **Os dados de cada vértice:** o ponto no chão plano (em pixels da arte), o centro plano do hexágono, os lados com degrau sem paredão (6 bits, para a borda do degrau) e o código 3 (chão pela máscara). A textura do tipo é escolhida pelo shader.
- **O shader** (`hex_grounds.gdshader`, que continua sendo o material das linhas de terreno), em cada pixel da arte:
  1. **A borda irregular:** lê a máscara num ponto torto (o ponto mais um desvio de até 3 px, de um ruído preso ao mapa), e não no ponto exato.
  2. **Sem chão** ali: se há chão a 1 ou 2 px, é a sombra na grama; senão, o pixel some.
  3. **Com chão:** se há um ponto sem chão a 2 px, é a borda escura (como hoje, 2 px da textura mais escura).
  4. **A emenda:** procura, em 3 anéis de 5 px (até 15 px), um tipo diferente com dureza maior (ou igual, com o id maior). Se acha, um ruído preso ao mapa solta pedaços do mais duro: de 4 px e quase todos perto da divisa, de 2 px e raros longe dela, cada um com 1 px de sombra embaixo. Assim as pedras do mais duro se soltam sobre o mais mole, sem borda escura entre os dois. (Revisto na fase 2: com 6 px, a emenda quase não aparecia.)
  5. **A cor:** a textura do tipo, de uma `Texture2DArray` com todas as texturas de chão (uniforme), no ponto plano, presa ao mapa. Onde ela é transparente (os Pisantes), o pixel some e aparece o bioma, mesmo que haja outro chão embaixo: a máscara guarda só o tipo de cima. Na emenda, um pixel do tipo mais duro que cairia num transparente dele fica com o tipo de baixo, para a emenda não abrir buracos de grama. A borda escura do passo 3 só vale nos pixels que não são transparentes.
  6. **O degrau:** perto de um lado marcado como degrau, a borda escura, como o piso faz hoje.
  7. A janela do Domador (`reveal_rect`) continua no fim.
- **A dureza** de cada id chega ao shader numa uniforme (`hardness[32]`), lida do catálogo.
- **O custo:** no máximo 29 leituras da máscara por pixel (o ponto torto, 4 em volta para a borda e a sombra, e 8 direções em 3 distâncias para a emenda). O renderer do projeto é o Mobile; a fase 2 mediu num PC. Se pesar num celular, a distância até a emenda passa a ser calculada uma vez, num segundo canal da página.

O `HexGrounds` perde a forma por hexágono (`add_tile`, `arm_shift`, `Batch`) e passa a montar a máscara e a malha. Os ids, as texturas e a dureza vêm do catálogo (`GameData.get_rows("ground_types")`).

## As decorações sorteadas

Uma decoração segue o chão embaixo do pé dela: o traço mais novo que passa no ponto (pela distância à linha suavizada, só nos hexágonos que algum traço corta) ou, sem traço, o chão do hexágono (`HexGrounds.ground_at`). Na trilha, só as pequenas (`HexGrounds.TRAIL_DECORATIONS`); no piso, nenhuma. O hexágono com a marca `bare` continua sem nenhuma.

## O editor

- **Mudar o chão de um hexágono** redesenha as páginas que tocam nele e nos vizinhos, além do `update_tiles` de hoje.
- **Mudar um traço** (fase 4) redesenha as páginas da caixa dele, antes e depois, e faz `update_tiles` nos hexágonos que ele cortava e corta, para a malha de chão e as decorações (`HexMapView.set_trails`). Enquanto o traço é desenhado, só o pedaço novo (os 3 últimos pontos) refaz os hexágonos.
- **A visão de cima** (`IslandOverview`) mostra o chão do hexágono como hoje e os traços como linhas na cor média da textura, na largura deles.
