# island-villages: arquitetura

O desenho que as três fases compartilham. As decisões e o motivo de cada uma estão no [README](README.md).

## As camadas de um hexágono da ilha

| Camada | Onde mora | O que faz |
| --- | --- | --- |
| Terreno | `island_tiles.biome_id`, `height`, `variant` | Como hoje ([terrain-height](../terrain-height/README.md)) |
| Chão | `island_tiles.ground_type_id`, nulo | Uma trilha ou um piso por cima do terreno. Só visual |
| Objeto | `island_objects` e `island_object_tiles` | A arte de uma casa, uma árvore grande, um castelo, que ocupa 1 ou mais hexágonos. Cada hexágono do objeto bloqueia ou não a passagem |
| Ação | `island_actions` e `island_action_tiles` | O que acontece quando o Domador entra no hexágono, ou toca nele se ele for bloqueado. Substitui a construção |
| Área | `island_areas` | Os Ecobeasts que nascem ali, como hoje |

Um hexágono tem no máximo um chão, um objeto, uma ação e uma área.

## O catálogo

Tabelas novas e mudadas no schema `ecobeasts`, espelhadas em `res://core/data/catalog_schema.gd` e em `.specs/game-data/architecture.md`:

| Tabela | Colunas | Observações |
| --- | --- | --- |
| `ground_types` | `id`, `slug` (único), `name`, `kind` | `kind` em `trail` ou `floor` (`CHECK`) |
| `map_object_types` | `id`, `slug` (único), `name`, `variants` (≥ 1) | A arte fica em `res://assets/map_objects/<slug>/<variante>.png` |
| `map_object_type_tiles` | `object_type_id` (FK `CASCADE`), `dq`, `dr`, `blocks` (bool) | Chave `(object_type_id, dq, dr)`. O formato do objeto, em coordenadas axiais a partir do hexágono de apoio, que é sempre `(0, 0)`. `blocks` é o bloqueio padrão |
| `action_types` | `id`, `slug` (único), `name`, `color_hex`, `kind` | É a `building_types` renomeada, com os mesmos ids. `kind` em `open_screen` (`CHECK`); outros tipos entram depois |

Os slugs seguem o padrão `^[a-z0-9_]+$`, como os de `building_types` hoje.

### Os tipos de chão

_A revisar._

| id | slug | name | kind |
| --- | --- | --- | --- |
| 1 | `dirt_trail` | Trilha de terra | `trail` |
| 2 | `stone_trail` | Trilha de pedra | `trail` |
| 3 | `cobble_floor` | Praça de pedra | `floor` |
| 4 | `dirt_floor` | Chão de terra | `floor` |

### Os tipos de objeto

Os formatos são estes (o `(0, 0)` é o hexágono de apoio, onde o dono clica):

| Formato | Hexágonos `(dq, dr)` | Como fica |
| --- | --- | --- |
| um | `(0, 0)` | 1 hexágono |
| par | `(0, 0)`, `(1, 0)` | 2 lado a lado |
| triângulo | `(0, 0)`, `(1, 0)`, `(1, -1)` | 2 embaixo e 1 em cima, entre eles |

Os tipos depois da revisão da [03](03-map-objects.md#revisão-casas-árvores-pedras-e-hortas). A casa com horta (id 2), o castelo (4), a ponte (12) e o ninho (15) saíram, e o formato losango saiu com o castelo. A árvore (5) e a pedra (6) eram a árvore grande e a pedra grande, de 3 e 2 hexágonos:

| id | slug | name | Formato | Variantes | Bloqueio padrão |
| --- | --- | --- | --- | --- | --- |
| 1 | `house` | Casa | um | 9 modelos | bloqueia |
| 18 | `house_medium` | Casa média | par | 11 | os dois |
| 19 | `house_large` | Casa grande | triângulo | 10 | todos |
| 3 | `windmill` | Moinho | par | 3: telhado vermelho, laranja e verde, com as pás girando | os dois |
| 5 | `tree` | Árvore | um | 8: sozinhas, em grupo, no outono e floridas, balançando | bloqueia |
| 6 | `rock` | Pedra | um | 6: sozinhas, em grupo e com musgo | bloqueia |
| 7 | `garden` | Horta | um | 6: canteiros de abóbora, raízes, trigo, girassol, tubérculos e uma em crescimento | bloqueia |
| 8 | `fence` | Cerca | um | 2: madeira e pedra | bloqueia |
| 9 | `well` | Poço | um | 1 | bloqueia |
| 10 | `market_stall` | Barraca de feira | um | 3: toldo vermelho, verde e azul | bloqueia |
| 11 | `cart` | Carroça | um | 1 | bloqueia |
| 13 | `beast_stable` | Estábulo de Ecobeasts | par | 2: madeira e pedra | os dois |
| 16 | `trough` | Bebedouro | um | 1 | bloqueia |
| 17 | `rune_shrine` | Santuário de runas | um | 4: minério azul, de ouro, de prata e de carvão, com brilho | bloqueia |
| 20 | `plants` | Vegetação | um | 10: as plantas do terreno, com o vento | não bloqueia |

Depois da [04](04-plants-and-animations.md), a casa na árvore (14) saiu, e a Vegetação não tem sprite: as plantas dela saem do `HexMapView`, como as do bioma. Os objetos animados têm os quadros lado a lado no PNG da variante, cada um com a largura da célula, e o `MapObjectSprite` anda neles na velocidade do tipo. Um objeto é desenhado depois do chão da linha seguinte à da frente dele (por baixo das decorações e dos atores dela), para a arte que desce da borda, como a pá do moinho, não ser cortada; só com um hexágono da frente mais alto ele fica antes das decorações da frente da própria linha.

### Os tipos de ação

A `building_types` vira `action_types`, com os mesmos ids e cores:

| id | slug | name | kind | No jogo |
| --- | --- | --- | --- | --- |
| 1 | `refuge` | Refúgio | `open_screen` | abre `heal_station` |
| 2 | `shop` | Loja | `open_screen` | abre `shop` |
| 3 | `arena` | Arena | `open_screen` | nada, até a `arenas-league` |
| 4 | `house` | Casa | `open_screen` | nada |

A tela de cada `slug` continua no cliente (`ACTION_SCREENS`, hoje `BUILDING_SCREENS`, em `res://screens/exploration/exploration_screen.gd`). Uma ação `open_screen` sem tela ali não faz nada.

## As tabelas da ilha

| Tabela | Colunas | Observações |
| --- | --- | --- |
| `island_tiles` | ganha `ground_type_id` (FK `ground_types`, nulo, `RESTRICT`) | |
| `island_objects` | `id`, `island_map_id` (FK `CASCADE`), `object_type_id` (FK `RESTRICT`), `q`, `r`, `variant`, `mirrored` (bool) | `(q, r)` é o hexágono de apoio. `variant` de 1 a `variants` do tipo, conferida pela rota |
| `island_object_tiles` | `object_id` (FK `CASCADE`), `island_map_id`, `q`, `r`, `blocks` (bool) | Chave `(object_id, q, r)`, único `(island_map_id, q, r)`: dois objetos nunca dividem um hexágono |
| `island_actions` | é a `island_buildings` renomeada, com `action_type_id` | |
| `island_action_tiles` | é a `island_building_tiles` renomeada, com `action_id` | Único `(island_map_id, q, r)`, como hoje |

**Espelhar:** um objeto espelhado usa o formato refletido na vertical, `(dq, dr)` vira `(-dq - dr, dr)`, e a arte é desenhada invertida na horizontal. O bloqueio de cada hexágono segue o hexágono refletido.

## O contrato

O rascunho do editor (`/v1/editor/islands`) ganha `ground` em cada hexágono e `objects`, e troca `buildings` por `actions`:

```json
{
  "name": "Vila do Vale",
  "start": { "q": 0, "r": 0 },
  "tiles": [
    { "q": 0, "r": 0, "biome": "temperate", "height": 1, "variant": 2, "ground": "dirt_trail", "area": 1 }
  ],
  "objects": [
    {
      "object_type_id": 4,
      "q": 3, "r": 2, "variant": 1, "mirrored": false,
      "tiles": [
        { "q": 3, "r": 2, "blocks": false },
        { "q": 3, "r": 1, "blocks": true },
        { "q": 4, "r": 1, "blocks": true },
        { "q": 4, "r": 0, "blocks": true }
      ]
    }
  ],
  "actions": [{ "action_type_id": 1, "tiles": [{ "q": 3, "r": 2 }] }],
  "areas": []
}
```

- `ground` é o slug de um `ground_types`, ou ausente ou `null` sem chão.
- Os `tiles` de um objeto são os hexágonos que ele ocupa, cada um com o seu `blocks`. O editor os preenche com o formato do tipo, espelhado ou não, a partir de `(q, r)`. Depois de posto, o objeto guarda os próprios hexágonos: se o dono mudar o formato de um tipo no painel, os objetos já postos continuam valendo, e só os novos usam o formato novo.

O mapa de uma ilha em `POST /v1/me/exploration` traz o mesmo `ground` em cada hexágono, os mesmos `objects` e `actions` no lugar de `buildings`. O mapa sorteado manda `objects: []` e `actions: []`, e nenhum hexágono com `ground`.

### Conferências ao salvar (`400`)

Além das de hoje:

1. `ground` é um slug de `ground_types`.
2. Cada objeto tem um tipo que existe, a variante a partir de 1 e pelo menos 1 hexágono, entre eles o `(q, r)`. A variante acima de `variants` não é recusada, porque o dono pode diminuir `variants` no painel; o desenho usa a última variante que existe.
3. Todos os hexágonos de um objeto existem na ilha, e nenhum é de outro objeto.
4. As ações seguem as regras das construções de hoje, com "ação" no lugar de "construção" nas mensagens.

### Conferências ao publicar (`409`)

Além das de hoje (a chegada não fica na água nem numa ação): a chegada não fica num hexágono bloqueado.

## O bloqueio no servidor

- Um hexágono é bloqueado quando é de um objeto com `blocks` verdadeiro.
- `spawnAreas` (`server/src/domain/islands/area-spawns.ts`) tira das áreas os hexágonos de ação, como já faz com os de construção, e os bloqueados.
- `confirmPosition` não muda: a distância em linha reta nunca é maior que o caminho em volta de um bloqueio.

## O desenho no jogo

**Chão:** uma passada nova no `_build_row` do `HexMapView`, depois das superfícies e dos arremates e antes do contorno.

- **Trilha:** uma faixa da textura do tipo (`res://assets/terrain/grounds/<slug>.png`, com o ponto da textura preso à posição no mapa, como as superfícies).
  - A faixa vai do centro do hexágono até o meio de cada lado em que o vizinho tem chão, trilha ou piso, de qualquer tipo.
  - Sem vizinho ligado, ela é só um círculo no centro.
  - Entre dois lados ligados vizinhos, o canto fica cheio: três hexágonos com trilha, vizinhos entre si, formam uma mancha sem grama no meio, e um caminho de duas fileiras fica inteiro. Nas curvas abertas e no Y, o canto de dentro é arredondado.
  - A largura é de 22 px da arte, _a revisar_.
- **Piso:** cobre o hexágono inteiro com a textura do tipo. Nos lados em que o vizinho não tem chão, a borda fecha o piso. Num lado com trilha ligada, a borda só abre na largura da trilha; com piso ligado, não há borda.
- **Borda em pixel art:** a forma é medida no centro de cada pixel da arte, num shader (`res://ui/components/hex_grounds.gdshader`, o material das linhas de terreno), e por isso a borda sai em pixels inteiros, sem degradê. Ela tem 2 px da própria textura mais escura (74%), e a trilha tem por fora 1 px de sombra na grama. O `HexGrounds` monta o hexágono inteiro e manda, no `CUSTOM0` de cada vértice, o ponto a partir do centro, os lados ligados e o tipo; as outras malhas do terreno não têm `CUSTOM0`, chegam com zero e passam direto.
- **Altura:** a faixa e o piso sobem com a superfície. Dois hexágonos com chão se ligam em qualquer altura.
  - Quando o lado entre eles é um dos dois lados de baixo do mais alto (onde há paredão), a faixa continua pelo paredão até o pé dele, como o escorrido.
  - Nos outros lados não há paredão desenhado. A ponta do braço se entorta para encontrar a do vizinho na tela (`HexGrounds.arm_shift`): atrás de um vizinho mais alto, ela sobe até o lado de cima dele; nos lados retos, as duas se encontram no meio do degrau.
  - O piso, nesses lados, guarda a borda, para o degrau aparecer, e só abre para uma trilha que chega.
- **Decorações:** num hexágono de piso, nenhuma nasce. Num de trilha, só `tuft`, `dry_tuft`, `flowers`, `pebbles` e `moss`. É o filtro `allows_decoration` do `HexMapView`, que o tabuleiro já usa.

**Objetos:** cada objeto é um nó com a arte, filho do `HexMapView`.

- Ele entra na linha do hexágono mais à frente do formato (o maior `r`), por um encaixe novo: depois das decorações de trás dessa linha, antes dos atores e das decorações da frente.
- Assim, ele cobre o que está atrás e é coberto pelas linhas da frente.
- A arte sobe a altura do hexágono de apoio.
- Nos hexágonos de um objeto, nenhuma decoração sorteada nasce.

**Arte dos objetos:** um PNG por variante, em `res://assets/map_objects/<slug>/<variante>.png` (de 1 em diante). Se a variante de um objeto passar das que existem, vale a última que existe.

- **Largura:** simétrica em volta do ponto de apoio, e larga o bastante para cobrir da borda esquerda do hexágono mais à esquerda até a borda direita do mais à direita.
- **Altura:** varia por tipo.
- **Ponto de apoio:** o meio da borda de baixo da imagem fica no ponto mais baixo do formato, que é o canto de baixo dos hexágonos da linha da frente, centrado na média dos centros dos hexágonos.
- **Espelhado:** a imagem é invertida na horizontal em volta do ponto de apoio.

Tamanhos da arte de agora, na variante 1 (em pixels da arte, como as texturas do mapa). A largura é a do formato; a altura é a da arte, e muda entre as variantes de alguns tipos:

| Tipo | Tamanho | Tipo | Tamanho |
| --- | --- | --- | --- |
| `house` | 64×67 (até 64×103) | `market_stall` | 64×55 |
| `house_medium` | 128×77 (até 128×101) | `cart` | 64×45 |
| `house_large` | 128×113 (a 5: 128×232) | `beast_stable` | 128×79 |
| `windmill` | 128×110 (9 quadros) | `plants` | 64×53 (só a prévia) |
| `tree` | 64×49 (4 quadros) | `trough` | 64×35 |
| `rock` | 64×43 | `rune_shrine` | 64×66 (4 quadros) |
| `garden` | 64×52 | `fence` | 64×37 |
| `well` | 64×59 | | |

A altura pode mudar na arte final, desde que o pé continue no mesmo lugar. A escala é a do pacote Sunnyside em 1x: uma casa tem uns 48 px de largura num hexágono de 64, e o Domador tem 25 px de altura.

**Arte de agora:** gerada pelo próprio Godot, para gerar de novo quando quiser:

- `res://assets/map_objects/make_objects.gd` monta os objetos a partir do pacote Sunnyside World, que o dono tem na máquina e passa como argumento. Ele lê o tileset, os sprites e o mapa de exemplo do pacote (`Room1`, do GameMaker), onde as casas, o moinho e as barracas já estão montados peça por peça. A cor do telhado das variantes troca o bloco de cor do tileset, que repete as mesmas peças em azul, verde, laranja, vermelho e roxo. Peças que só existem num bloco de cor, como a cumeeira da casa grande, mudam de matiz nos outros. As árvores, as pedras e as hortas são compostas com os sprites e as peças do pacote, e a carroça, que ele não tem, é desenhada no estilo dele.
- `res://assets/terrain/grounds/make_grounds.gd` gera as texturas de chão.

Da pasta `client/`: `godot --headless -s res://assets/map_objects/make_objects.gd -- <pasta do pacote>`, a pasta que tem `Sunnyside_World_Assets` e `Sunnyside_World_Gamemaker`.

## No jogo, andar e agir

- `ExplorationMap` ganha `is_blocked(coord)`, `object_at(coord)` e `action_at(coord)`.
- **Tocar na arte de um objeto:** a arte de uma casa sobe por cima dos hexágonos de trás. Por isso, antes do `coord_at`, o toque confere a arte dos objetos, da linha da frente para a de trás, pelo retângulo da célula e pelo alfa do pixel. Se acertar um objeto, o toque vale para o hexágono dele vizinho ao Domador (o de ação, se houver mais de um; senão, o mais perto do ponto tocado). Se nenhum hexágono do objeto for vizinho, o toque não faz nada.
- **Tocar num vizinho livre:** o Domador anda. Ao chegar, se o hexágono é de uma ação e ele veio de fora dela, a ação acontece, como as construções hoje.
- **Tocar num vizinho bloqueado:**
  - se ele é de uma ação, ela acontece, sem andar;
  - se não é, nada acontece.
- **Ação `open_screen`:** abre a tela do slug com `Router.push`, como hoje.
- **Na tela:** as ações continuam com a cor e o nome por cima, como as construções hoje, para uma ilha sem objetos não perder a indicação. Tirar isso quando houver arte é decisão do dono.
