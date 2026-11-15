# bridges: arquitetura

## O catálogo: `bridge_types` (fases 1 e 5)

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave estável |
| `slug` | text | único |
| `name` | text | o nome no editor |

Ficam 2 estilos: 4 `rope_bridge` (Ponte de corda) e 5 `wood_bridge` (Ponte de madeira). A fase 1 criou 8; a 5 apagou os outros 6 (ids 1, 2, 3, 6, 7 e 8), sem renumerar. O `seed-data` tem `bridge_types.json`, e o catálogo (`GET /v1/catalog`) manda a tabela.

## A arte (fases 1 e 5)

Cada estilo tem uma pasta `client/assets/bridges/<slug>/`, recortada da folha `Bridges.png` do pacote pelo `client/assets/bridges/make_bridges.py`:

| Arquivo | O que é |
| --- | --- |
| `top_start.png`, `top_middle.png`, `top_end.png` | A vista de cima, com a ponte em pé: a cabeceira de cima, o trecho que se repete e a cabeceira de baixo |
| `side_back_start.png`, `side_back_middle.png`, `side_back_end.png` | A vista de lado, com a ponte deitada: o corrimão de trás e o piso, da cabeceira da esquerda à da direita |
| `side_front_start.png`, `side_front_middle.png`, `side_front_end.png` | O corrimão da frente, na mesma grade da vista de lado, já na altura dele |

Na ponte de madeira, as peças soltas do pacote têm um vão entre a cabeceira e o meio, sem piso. O script tira essas linhas (e colunas, na vista de lado), para a cabeceira emendar no piso. Na ponte de corda o vão entre as pranchas é do desenho, e fica.

O pacote não traz um meio que se repete: cada peça do meio é um vão inteiro. O script escolhe dentro dela o trecho de 16 a 64 px que emenda melhor consigo mesmo; o começo é o que vem antes dele, e o fim começa um número inteiro de trechos depois, para a emenda cair no mesmo ponto.

As medidas da arte ficam no `HexBridges` (um JSON solto não entra no build do Android):
- `TOP`: a largura da vista de cima e quantas colunas de cada lado são o corrimão (madeira 29 e 6, corda 26 e 5);
- `BACK_RAIL`: quantas linhas de cima da vista de lado são o corrimão de trás (madeira 12, corda 14).

O `client/assets/bridges/CREDITOS.md` diz de onde vem a arte e a licença da craftpix.net.

## As pontes no banco: `island_bridges` (fases 1 e 5)

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `island_map_id` | int | FK `island_maps`, `ON DELETE CASCADE` |
| `bridge_type_id` | int | FK `bridge_types` |
| `position` | int | a ordem na ilha, de 0 em diante, única por mapa |
| `points` | `integer[]` | `x0, y0, x1, y1`, as duas pontas, em pixels do chão plano a partir do centro plano do hexágono (0, 0), como `island_walls.points`; `CHECK` de exatamente 4 números |
| `width` | int | a largura da ponte em pixels, de 16 a 64, 28 por padrão (fase 5) |

**Contrato** (editor e Explorar numa ilha), na ordem de `position`:

```json
"bridges": [{ "type": "wood_bridge", "points": [12, -40, 140, 20], "width": 28 }]
```

- **O servidor confere:**
  - o tipo existe;
  - as duas pontas caem em hexágonos da ilha que não são água;
  - as pontas ficam a pelo menos 16 px uma da outra;
  - a largura, quando vem, é um inteiro de 16 a 64 (sem ela, 28);
  - a ilha tem no máximo 500 pontes (`MAX_BRIDGES`).
- O `content_hash` leva as pontes, na ordem, com a largura. Uma ilha sem pontes tem o hash de antes.
- O mapa sorteado não tem pontes.

**No cliente:** `MapBridge` (`domain/models/`), com `type`, `width` e as duas pontas no chão plano (somando o `MapTrail.ORIGIN`), e `ExplorationMap.bridges`.

## O piso

Cada ponte é um corredor reto: os pontos a menos de `HexBridges.deck_reach` do trecho entre as pontas, sem passar delas. Até 75°, é a metade da largura menos 3 px; mais em pé, a metade da largura menos o corrimão e 1 px.

**A altura do piso** num ponto do corredor mistura a elevação (`LEVEL_HEIGHTS`) do hexágono de cada ponta pela fração do caminho entre elas, arredondada para pixels inteiros. Com as duas pontas na mesma altura, o piso é plano.

## O desenho (fases 2, 5, 6 e 7)

O `HexBridges` (`ui/components/`) monta cada ponte já na altura do piso:

- **Até 75° da horizontal da tela** (`STANDING_ANGLE`), e de 105° a 180° ([07](07-standing-rails.md)):
  - **o piso** é a vista de cima girada no ângulo da ponte, só o miolo. Cada pixel acha a linha da arte pela posição ao longo da ponte (a cabeceira, o trecho que se repete e a outra cabeceira) e a coluna pela distância até o eixo, com o miolo repetido pela largura. A imagem é cortada em fatias de 1 px de altura;
  - **os dois corrimãos** ficam em pé nas bordas, como a cerca: colunas de 1 px do meio do corrimão da vista de lado (`BACK_RAIL` linhas de cima da `side_back`; na frente, as linhas usadas da `side_front`), uma por passo da borda, e o poste da cabeceira inteiro e em pé nas pontas e a cada `POST_GAP`.
- **Mais em pé que isso:** linha a linha, a vista de cima, com o meio da linha no ponto do trecho; a largura repete (ou tira) as colunas do miolo do piso, e ficam os corrimãos e as 3 colunas sombreadas de cada lado (`DECK_EDGE`).
- **A ordem:** cada fatia do piso tem o pé na linha dela mais a altura do piso, e cada coluna de corrimão e poste tem o pé na borda. Tudo entra na linha do mapa desse pé (`floor(y / 42)`) e na faixa dele, como os atores ([prop-depth-blocks](../prop-depth-blocks/architecture.md#a-ordem-de-desenho)). Por isso o chão das linhas da frente não cobre a ponte.
  - O corrimão de trás fica atrás de quem anda no piso; o da frente entra 6 px mais abaixo (`FRONT_LEAD`), na frente dele.
- **No `HexMapView`:** as pontes ficam por pedaço de linhas (`_bridges_by_chunk`), e o `set_bridges(bridges, changed)` remonta os pedaços que elas tocam. As fatias ficam guardadas por ponte (até 128), porque o editor refaz o índice a cada pincelada. As decorações naturais do bioma embaixo do piso não aparecem (`_under_bridge`).
- **No editor:** a ponte aparece como no jogo. A visão de cima (`IslandOverview`) mostra o corredor como uma faixa da largura dela.

## O andar (fase 4)

**Um ponto bloqueado** é um ponto num hexágono de água fora do corredor de qualquer ponte.

**`ExplorationMap.is_clear(from, to) -> bool`** junta as duas regras: o segmento não cruza parede (`crosses_wall`) e nenhum ponto dele, de 2 em 2 px, está bloqueado. Quem já está num ponto bloqueado (a chegada antiga, uma ilha salva antes) pode sair dele. O `WalkRoute` e quem vaga passam a usar o `is_clear`.

**A busca de caminho** (`path_to_any`):
- não entra num hexágono de água;
- ganha uma ligação a mais por ponte, entre o hexágono de uma ponta e o da outra. Quando o caminho usa a ligação, o `WalkRoute` passa pelas duas pontas: do centro do hexágono até a ponta, pelo piso até a outra ponta, e dali ao centro do outro hexágono. Uma ponta que não alcança o centro do hexágono dela em reta não gera ligação.

**O toque:**
- **Num ponto do piso:** os objetivos são os hexágonos das duas pontas. A rota chega por uma ponta e segue pelo piso até o ponto tocado.
- **Na água fora do piso:** o Domador vai até o hexágono de terra mais perto e para rente à água, como numa cerca (`clip_to_walls`, que passa a cortar também na água).

**A altura do Domador:** em cima do piso, ele usa a altura do piso no ponto do pé, e não a do hexágono de água embaixo (`_rise_at`, `surface_center`).

**Quem vaga** (os Ecobeasts e os Domadores NPC, dentro do próprio hexágono) não muda: um Ecobeast de água continua vagando na água dele (revisto na fase 4). **Os NPC das ilhas que passeiam** não usam as pontes: eles vão de centro em centro (`path_to_any(..., use_bridges = false)`).

**O Procurar:** enfrenta um Ecobeast do hexágono do Domador; sem nenhum ali, o de um hexágono de água vizinho, o mais perto do pé. O cliente manda a coordenada desse hexágono, e o servidor confere como hoje (o tempo desde a última posição).

**A chegada do mapa sorteado:** o `startOf` escolhe o hexágono de terra plana mais perto do meio e, sem nenhum, o de terra mais perto. Nunca a água.

**Os NPC das ilhas:** o servidor recusa um NPC, ou um hexágono de passeio dele, na água ("O NPC não pode ficar na água.").
