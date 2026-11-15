# free-objects: arquitetura

## As camadas de uma ilha, depois da iniciativa

| Camada | Onde fica | Preso a | Bloqueia |
| --- | --- | --- | --- |
| Terreno | `island_tiles` | hexágono | não |
| Ações de chão | `island_actions`, `island_action_tiles` | hexágonos | não; acontecem ao entrar |
| **Peças soltas** | `island_props`, `island_prop_blocks` | um ponto em pixels | pelas linhas de bloqueio, se tiverem |
| Paredes | `island_walls` | pontos em pixels | pela linha |

Os objetos de grade (`island_objects`, `island_object_tiles`, `map_object_types`, `map_object_type_tiles`) saem na fase 4.

## A linha de bloqueio

Uma **linha de bloqueio** é uma lista de pontos com a marca `closed`:

- **Os pontos:** pixels inteiros da arte, no chão plano, a partir do pé da peça.
- **A marca `closed`:** a linha fechada liga o último ponto ao primeiro.
- **Os limites:**
  - cada linha tem de 2 a 64 pontos, e uma fechada tem pelo menos 3;
  - uma peça tem no máximo 8 linhas;
  - cada coordenada fica entre −512 e 512.
- **O espelho:** numa peça espelhada, o `x` de cada ponto troca de sinal.

Uma linha bloqueia como uma parede invisível: o Domador não chega a menos de `WALL_REACH` (3 px) dela.

**De onde vêm as linhas de uma peça:**

- **Do tipo:** com `custom_block` falso, a peça usa as linhas do tipo (`prop_type_blocks`). Mudar as do tipo muda essa peça em todas as ilhas, na próxima abertura, porque elas vêm do catálogo.
- **Da própria peça:** com `custom_block` verdadeiro, ela usa as suas (`island_prop_blocks`). Uma lista vazia quer dizer que a peça não bloqueia.

## O catálogo: `prop_type_blocks` (fase 1)

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `prop_type_id` | int | FK `prop_types`, apaga junto |
| `position` | int | a ordem no tipo, de 0 em diante, única por tipo |
| `closed` | bool | |
| `points` | `integer[]` | `x0, y0, x1, y1, …`; `CHECK` de tamanho par, entre 4 e 128 |

- O `GET /v1/catalog` manda a tabela, e o `catalog_schema.gd`, o `CatalogValidator` e o `.specs/game-data/architecture.md` a espelham.
- Nenhum tipo de hoje começa com linhas. Os prédios ganham as deles na fase 4.

**A rota do tipo** (fase 2):

- **O que faz:** `PUT /v1/editor/prop-types/:id/blocks`, com `{ "blocks": [{ "closed": true, "points": [...] }] }`, troca as linhas do tipo numa transação e libera o catálogo novo, como as rotas de `/v1/editor/skills` ([skill-editor](../skill-editor/)).
- **Quem pode:** só quem está em `MAP_EDITOR_USER_IDS`.
- **Os limites:** os mesmos da linha.
- **A resposta:** as linhas gravadas e a lista das ilhas, rascunho ou publicada, cuja chegada passou a ficar num hexágono bloqueado.
- **A rota não recusa:** a ilha continua jogável, porque o Domador pode se afastar de uma linha rente e a chegada só tira o nascimento dali. O editor mostra a lista depois de salvar, para o dono mover a chegada, e o próximo salvar daquela ilha a recusa até isso.

## A peça na ilha (fases 1 e 3)

**`island_props` ganha duas colunas:**

- `custom_block` (`boolean NOT NULL DEFAULT false`);
- `action_type_id` (`int NULL`, FK `action_types`, sem deixar apagar o tipo em uso), na fase 3.

**`island_prop_blocks`:**

| Coluna | Tipo | Regra |
| --- | --- | --- |
| `id` | int | chave |
| `island_prop_id` | int | FK `island_props`, apaga junto |
| `position` | int | única por peça |
| `closed` | bool | |
| `points` | `integer[]` | como em `prop_type_blocks` |

**O contrato:** o rascunho do editor e o mapa de Explorar numa ilha. Os dois campos novos só aparecem quando valem:

```json
{ "prop_type_id": 22, "q": 3, "r": -1, "dx": -7, "dy": 4, "variant": 1, "mirrored": false,
  "block": [{ "closed": true, "points": [-40, -6, 40, -6, 40, 10, -40, 10] }],
  "action_type_id": 1 }
```

- **`block`:** só nas peças ajustadas, e `[]` é uma peça ajustada sem bloqueio.
- **`action_type_id`:** só quando a peça tem ação.
- **O `content_hash`:** leva os dois só quando eles aparecem, então uma ilha sem eles tem o hash de antes.
- **O servidor confere:**
  - os limites da linha;
  - que a ação existe;
  - que uma ilha tem no máximo 500 peças com ação (`MAX_PROP_ACTIONS`);
  - que uma ilha tem no máximo 2.000 peças que bloqueiam, pelas linhas delas ou pelas do tipo (`MAX_BLOCKING_PROPS`, como o `MAX_WALLS`). O limite segura o custo do `blockedKeys`, que roda a cada início de exploração, e do índice do cliente. A fase 1 mede o `blockedKeys` numa ilha cheia (2.000 peças e 2.000 paredes) e anota o tempo.
- **Os pontos de bloqueio** não precisam cair na ilha: o que fica fora dela não bloqueia nada que exista.

## Os hexágonos bloqueados no servidor (fase 1)

O `blockedKeys` passa a ser o conjunto dos hexágonos da ilha que alguma linha de bloqueio toca, de uma peça (a do tipo ou a dela) ou de uma parede.

- **Uma linha toca um hexágono** quando algum ponto do caminho dela cai nele. O caminho é percorrido em passos de 1 px, pelo `gridCoord` do chão plano, a mesma conta das fatias do `HexWalls`.
- **Uma linha fechada** também toca os hexágonos cujo centro plano fica dentro dela.
- **A conta fica num lugar só:** `server/src/domain/islands/blocked-hexes.ts`. O cliente tem uma cópia (`IslandBlocks.blocked_hexes`), que só o editor usa para mostrar os hexágonos.
- **Onde vale:** nas duas regras de hoje.
  - A chegada não fica num hexágono bloqueado.
  - As áreas não fazem nascer Ecobeasts num hexágono bloqueado (`spawnAreas`).
- **As ilhas que já existem:** com as paredes entrando na conta, uma chegada ao lado de uma cerca pode deixar de valer no próximo salvar. A fase 1 procura no banco as ilhas com a chegada num hexágono que passaria a ser bloqueado e mostra a lista ao dono antes de entregar.

## No jogo (fases 1 e 3)

**O bloqueio:**
- O índice de trechos do `ExplorationMap` (hoje só das paredes) recebe também as linhas das peças, já no chão plano: `flat_center(q, r) + (dx, dy) + ponto`, com o espelho.
- O `crosses_wall`, a busca de caminho, a rota do `WalkRoute` e quem vaga continuam como estão e passam a respeitar as peças sem regra nova.

**O toque na arte:**
- **Antes:** só a arte de um objeto pegava o toque.
- **Agora:** a arte das peças com bloqueio ou com ação pega o toque, pelo retângulo e pelo alfa do pixel, como o `MapObjectSprite.hits`. Ganha a peça da frente, a do pé mais embaixo.
- As peças sem bloqueio nem ação deixam o toque passar para o chão, como hoje.

**A caminhada até a peça (fase 3):**
- **O caminho:** tocar numa peça com bloqueio leva o Domador pelo caminho mais curto até ela, como tocar numa cerca, e ele para a `WALL_REACH` da linha. Desde a [prop-depth-blocks/04](../prop-depth-blocks/04-tap-through.md), só a peça com ação pega o toque; na peça só com bloqueio, o toque vai para o chão.
- **A ação:** se a peça tem ação, ela acontece quando o Domador termina essa caminhada encostado: a até `TOUCH_REACH` (8 px) de uma linha dela.
  - Se ele já está encostado quando toca, a ação acontece sem andar.
  - Uma peça com ação e sem bloqueio leva o Domador até o pé, e a ação acontece na chegada.
  - Um toque em outro lugar no meio do caminho troca o destino, e a ação não acontece.
- **O padrão:** é o mesmo de tocar num NPC de longe ([island-npcs](../island-npcs/)).

**O desenho:** a peça entra na faixa de profundidade do pé, como as outras. A arte alta sobe por cima das linhas de trás, que são desenhadas antes. A fase 4 confere numa imagem que a base dos prédios não é cortada pelo chão da linha da frente.

## No editor (fases 2 e 3)

**A camada Bloqueios:** uma chave no painel Camadas, ligada por padrão.
- Desenha todas as linhas de bloqueio, tracejadas como a parede invisível: numa cor as do tipo e noutra as ajustadas.
- Pinta de leve os hexágonos que o servidor vai contar como bloqueados, pelo `IslandBlocks`.

**O bloqueio de uma peça:** com uma peça escolhida na ferramenta Peças, a `ObjectBar` ganha o botão Bloqueio, que liga o modo de edição.

| Gesto | O que faz |
| --- | --- |
| Arrastar um ponto | Move o ponto |
| Clique num trecho | Põe um ponto ali |
| Botão direito ou Delete num ponto | Apaga o ponto. Uma linha com menos pontos do que precisa some |
| "Nova linha" | Desenha uma linha a cliques: Enter termina, e clicar no primeiro ponto termina e fecha |
| "Fechar" ou "Abrir" | Troca o `closed` da linha escolhida |
| Esc | Sai do modo |

- **O ajuste:** qualquer mudança deixa a peça ajustada.
- **"Usar o do tipo":** volta a peça para as linhas do tipo.
- **"Salvar como do tipo":** pergunta antes, porque muda todas as ilhas e não se desfaz. Depois, chama a rota do tipo, e a peça volta a usar as linhas do tipo, agora iguais às dela.
- **O desfazer:** cada mudança na peça é um passo do desfazer (`EditorHistory`, com as peças de antes e de depois). Salvar no tipo não entra no histórico.
- **A ação** (fase 3): a `ObjectBar` ganha uma lista de ações (`action_types`, mais "Nenhuma").
- **O Carimbo:** guarda e põe o bloqueio ajustado e a ação de cada peça.

## A conversão (fase 4)

Uma migration em SQL escrito à mão, conferida antes no banco real, como a `free_fences_conversion`.

1. **Os tipos:** cada tipo de `map_object_types` vira um tipo de `prop_types`, com o mesmo `slug`, `name` e `variants` e ids novos de 22 em diante, na ordem do id antigo.
   - A arte muda de `assets/map_objects/<slug>/` para `assets/props/<slug>/`, e o `make_town.gd` passa a gravar lá.
   - O pé das duas é o meio da borda de baixo, então a arte não muda.
2. **O bloqueio dos tipos:** uma linha fechada no contorno dos hexágonos do formato que bloqueavam, 4 px para dentro, a partir do pé. A fase 4 calcula esses pontos e os escreve na migration.
   - **Por que 4 px para dentro:** uma linha bem na borda faz o `gridCoord` cair às vezes no hexágono vizinho, e o anel em volta de cada prédio passaria a contar como bloqueado. A chegada ao lado do Refúgio deixaria de valer, e os Ecobeasts perderiam lugar para nascer.
   - **A conferência:** a fase 4 confere que nenhum hexágono fora do formato fica bloqueado.
3. **As peças:**
   - **O pé:** cada objeto vira uma peça com o pé no mesmo ponto de hoje (o `MapObjectSprite.foot_of`). O hexágono do pé é o que o `grid_coord` dá para ele, e o `(dx, dy)` sai desse hexágono. Esse ponto pode cair no hexágono da linha da frente.
   - **O espelho e a variante:** ficam os mesmos.
   - **O bloqueio:** a peça fica sem ajuste. Um objeto cujos `blocks` diferem do padrão do tipo ganha as suas linhas.
   - **Antes de entregar:** a fase 4 lista os casos em que a altura do hexágono do pé difere da do hexágono de apoio, porque a arte subiria outra altura, e decide com o dono.
4. **As ações:**
   - Uma ação cujos hexágonos ficavam embaixo de um objeto passa para a peça dele.
   - Os hexágonos de ação embaixo de um objeto saem da ação, e uma ação sem nenhum hexágono sai.
   - Com duas ações embaixo do mesmo objeto, a peça fica com a que tinha mais hexágonos ali.
5. **As decorações:** os hexágonos dos objetos ficam com a marca `bare`, porque não tinham decorações sorteadas.
6. **A limpeza:** saem as quatro tabelas dos objetos, o `MapObject`, o `MapObjectSprite`, o `set_objects`, o `ExplorationMap.is_blocked` e o `object_at`, a parte de grade do `ObjectPanel` e a parte de objetos do `Stamp`.
   - Um carimbo antigo, com `objects`, converte os objetos ao ser lido, pela mesma regra.
   - **Sem compatibilidade:** o catálogo perde as tabelas dos objetos, e o mapa perde o `objects`, de uma vez. Um APK de antes da fase 4 deixa de abrir as ilhas, e o dono aceitou isso em 2026-11-15.
7. **O `content_hash`:** não é recalculado, porque o rascunho e a publicada mudam igual.
