# 01. A regra do paredão

- **Status:** concluída (falta o dono conferir no jogo e no F2)
- **Depende de:** [terrain-height](../terrain-height/), [bridges](../bridges/), [giant-rocks](../giant-rocks/)

## Contexto

Veja o [README](README.md#contexto). Hoje a altura não entra no andar, e o Domador sobe qualquer paredão. Esta fase cria a regra, faz o mapa sorteado continuar todo alcançável com as alturas de hoje e mostra os paredões no F2, para o dono abrir as encostas de Liora.

Com as alturas de hoje do mapa sorteado (chão 1, Colina 2, Pedra 3, Montanha 4), só a Montanha encostada no chão plano vira paredão (3 níveis). A garantia de alcance desta fase abre encostas ali; a [fase 2](02-plateaus-water.md) usa a mesma garantia com os patamares.

## Escopo

- A regra no jogo: a busca, a reta do passo e quem usa as duas (o Domador, quem o segue e os NPCs).
- A regra no servidor: a garantia de alcance do mapa sorteado e o alcance das pedras gigantes.
- Os paredões na camada Bloqueios do F2.

## Fora do escopo

- Mudar as alturas do mapa sorteado (é a fase 2) e as das ilhas (o dono pinta).
- O teleporte de depuração (o mapa grande e a rota `PUT /v1/me/exploration/position`): continua indo a qualquer hexágono de terra.
- A ponte: liga as duas pontas como hoje, qualquer que seja a altura delas.

## Requisitos

**A regra**

- **RF-01:** Dois hexágonos vizinhos de terra se ligam a pé quando a diferença de altura entre eles é de até 2 (`MAX_CLIMB`). Com 3 ou mais, a borda entre eles é um paredão, e ninguém passa por ela, nem subindo nem descendo.
- **RF-02:** A busca de caminho (`ExplorationMap.path_to_any`) não atravessa paredão. Isso vale para o Domador, para quem o segue numa cena e para os NPCs que andam pela busca (`NpcSprite`).
- **RF-03:** A reta do passo (`ExplorationMap.is_clear`, e por ela o `clip_to_walls` e o `WalkRoute`) para antes de cruzar um paredão, como para antes de uma parede. Em cima do piso de uma ponte, a regra não vale: o piso tem a altura dele.
- **RF-04:** Tocar num hexágono sem caminho mostra a mensagem de hoje (`NO_PATH_TEXT`) e não anda.

**O mapa sorteado**

- **RF-05:** Depois das pontes e antes das pedras gigantes, o gerador confere o alcance a partir da chegada, pela regra do RF-01 e pelas pontes. Cada pedaço de terra fora dele ganha uma encosta (`openSlopes`):
  1. o caminho mais curto pela terra, sem a regra, de um hexágono alcançado até o pedaço;
  2. ao longo dele, os hexágonos mais baixos sobem até que cada passo tenha 1 ou 2 níveis, sorteados a cada passo;
  3. a conferência roda de novo, até tudo se alcançar.
- **RF-06:** A encosta só sobe hexágonos e nunca passa de 10. Quando ela sobe a margem de uma ponte, a outra margem sobe junto (`levelLinks`), para as duas pontas continuarem na mesma altura. Ela usa um sorteio próprio (`seed ^ SLOPES_SALT`), então o resto do mapa de uma seed não muda.
- **RF-07:** As pedras gigantes (`placeGiantRocks`) só bloqueiam onde não tiram terra do alcance, agora contando a regra do RF-01.

**O F2**

- **RF-08:** Com a camada Bloqueios ligada, o editor desenha cada borda de paredão entre dois hexágonos de terra como uma linha na cor de perigo do `UiPalette`, por cima do terreno. A linha muda junto quando a ferramenta Altura ou a Bioma pinta.

## Critérios de aceite

- [x] Em 60 seeds do mapa sorteado, toda a terra que se alcançava antes (pela água e pelas pontes) continua se alcançando, agora pela regra, menos os hexágonos das pedras gigantes.
- [x] Nesses mapas, nenhum hexágono desce de altura, e nenhum passa de 10 (conferido até a fase 2 trocar as alturas; depois, pelos critérios dela).
- [ ] Em Liora, tocar no platô do nível 7 perto do início (q −30 a −3, r −16 a 7) mostra a mensagem de sem caminho.
- [ ] Em Liora, andar em reta na direção de um paredão para rente a ele.
- [ ] No F2, a camada Bloqueios mostra os paredões de Liora, e eles somem ao pintar uma encosta.
- [x] O jogo abre sem janela, sem erro novo, e os testes do servidor passam.

## Desenho técnico

**Servidor** (`server/src/domain/exploration/`)

- `map-slopes.ts` (novo), com os testes em `map-slopes.spec.ts`:
  - `MAX_CLIMB = 2`, `climbable(a, b)` e `climbReach` (o alcance pela regra e pelas pontes). Ficam aqui, e não no `map-generator.ts`, porque o `map-rocks.ts` também os usa e o gerador importa o `map-rocks.ts`.
  - `openSlopes(cells, start, links, isWater, random)`, em que `links` liga as margens de cada ponte; depois de cada encosta, o `levelLinks` sobe a margem mais baixa de cada ponte até a outra.
  - `raiseAlong`: uma passada de ida e uma de volta pelo caminho. Em cada uma, um hexágono mais de 2 níveis abaixo do anterior sobe até o anterior menos 1 ou 2. As duas passadas bastam, porque só sobem.
  - Cada volta da garantia sobe pelo menos um hexágono, e nenhum passa de 10, então ela termina.
  - A terra que só o mar ou um lago separa da chegada já ficava fora antes ([coast-rivers](../coast-rivers/)). Ela continua fora: a busca da encosta não a alcança pela terra.
- `map-generator.ts`:
  - o `Cell` e o `ShapedTile` ganham `height`, preenchida pelo `terrainOf` depois do último `gatherMountains`;
  - o `generateMap` manda o `height` de cada hexágono.
- `map-rocks.ts`: o `reachable` passa a usar o `climbable`.

**Jogo**

- `client/domain/models/exploration_map.gd`:
  - `MAX_CLIMB` e `can_step(from, to)`;
  - a expansão do `path_to_any` (os vizinhos e os primeiros passos) confere o `can_step`;
  - o `is_clear` confere o `can_step` cada vez que a amostra muda de hexágono, fora do piso de uma ponte.
- `client/tools/map_editor/editor_canvas.gd`: desenha as bordas de paredão junto com os X da camada Bloqueios (`_show_blocks`). Os pontos da borda vêm dos cantos do hexágono do `HexMapView`, e só os hexágonos pintados são refeitos.

**Documentos**

- `client/CLAUDE.md` (a regra, no parágrafo das Ilhas) e esta spec.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```

Depois, no jogo:

1. Em Liora, os critérios de aceite.
2. Em Explorar zona, um mapa sorteado: a Montanha tem encostas, e o Domador sobe por elas.

## Tarefas

- [x] `MAX_CLIMB`, `climbable` e o `height` no `Cell`, com testes.
- [x] `openSlopes`, com testes (o caminho, as passadas, só subir, o sorteio próprio).
- [x] O `reachable` das pedras gigantes com a regra.
- [x] O teste das 60 seeds.
- [x] `can_step` no `path_to_any` e no `is_clear`.
- [x] Os paredões na camada Bloqueios do F2.
- [x] A verificação e os documentos.

## Resultado da verificação

Em 2026-11-21:

- O lint, o typecheck e os testes de unidade do servidor passaram (1101 testes), e os e2e passaram como antes. Eles rodaram junto com a [fase 2](02-plateaus-water.md#resultado-da-verificação).
- Uma cena temporária do jogo conferiu a regra numa faixa de hexágonos de alturas 1, 1, 2, 5, 5 e 3:
  - o `can_step` recusa o salto de 2 para 5;
  - a busca dá a volta pela linha de baixo;
  - a reta de 1 para 4 é recusada, e o `clip_to_walls` para no hexágono 2.
- O jogo abriu sem janela só com os avisos que já existiam (`hex_bridges`, `interior_npc`, `interior_tiles` e `minimap_image`).
- Falta o dono conferir em Liora e no F2.
