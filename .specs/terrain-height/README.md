# terrain-height

A altura do terreno passa a ser um dado de cada hexágono, separado do bioma. Hoje o hexágono tem bioma e forma, e a altura sai dos dois: a Planície fica sempre no nível 1 e a Montanha sempre no 4. Com esta iniciativa, Colina e Montanha viram biomas como os outros, e qualquer bioma pode ficar em qualquer um dos 5 níveis. Assim dá para ter uma Planície alta, uma Montanha baixa e um lago no alto de um planalto.

A ideia é do dono, em 2026-11-11, vendo o editor de ilhas.

## Contexto

O que existe hoje:

- **O hexágono do mapa** tem `biome` (`temperate`, `boreal`, `stone`, `wshallow`, `wdeep`), `shape` (`flat`, `hill`, `mont`) e `variant`. É o mesmo formato no mapa sorteado de Explorar zona, nas ilhas e no editor ([wild-battle](../wild-battle/architecture.md), [map-editor](../map-editor/architecture.md)).
- **A altura não é guardada.** O cliente a calcula em `HexTile.level()` (`res://domain/models/hex_tile.gd`), e só usa o resultado no desenho ([wild-battle/05](../wild-battle/05-terrain-elevation.md)):

  | Hexágono | Nível | Altura da arte |
  | --- | --- | --- |
  | Água plana | 0 | 0 px |
  | Terra plana (Planície, Boreal) | 1 | 8 px |
  | Forma `hill` fora da pedra | 2 | 16 px |
  | Bioma `stone` com forma `flat` ou `hill` | 3 | 24 px |
  | Forma `mont`, em qualquer bioma | 4 | 32 px |

- **A forma também escolhe a textura:** `HexTile.surface()` devolve `hill` ou `mont` quando a forma não é plana. Então uma colina tem a mesma arte em qualquer bioma.
- **O catálogo já tem 7 biomas** (`biomes`: `temperate`, `boreal`, `stone`, `hill`, `mountain`, `wshallow`, `wdeep`), porque as taxas de encontro usam os 7. O servidor traduz a forma em bioma de encontro em `encounterBiome` (`server/src/domain/exploration/spawns.ts`, [biome-encounters](../biome-encounters/architecture.md)).
- **O editor** ([map-editor/03](../map-editor/03-terrain-tools.md)) tem a ferramenta Bioma, com os 5 biomas, e a ferramenta Forma, com Plano, Colina e Montanha.

## Objetivos

1. Colina e Montanha são biomas no mapa, na arte e no editor, como no catálogo.
2. Cada hexágono guarda a altura dele, de 0 a 4, e qualquer bioma aceita qualquer altura, inclusive a água.
3. No editor, a ferramenta Altura substitui a Forma e pinta um nível fixo.
4. Os mapas sorteados e as ilhas que já existem continuam com a mesma aparência de antes.

## Decisões

Do dono, em 2026-11-11:

| Decisão | Motivo |
| --- | --- |
| Colina e Montanha deixam de ser forma e passam a ser biomas, na lista de Biomas do editor | Pedido do dono: no mapa, a separação é de bioma e de altura, e não de bioma e de forma |
| A forma some. No lugar dela entra a altura, que se pinta em qualquer bioma | Pedido do dono: subir uma Planície ou uma Boreal, e fazer uma Montanha baixa |
| A altura é só visual. O Domador anda por qualquer nível, e a luta e os encontros não mudam | Pedido do dono: regras de altura serão planejadas depois |
| Continuam 5 níveis, de 0 a 4, de 8 em 8 px | Pedido do dono |
| A água pode ficar em qualquer nível | Pedido do dono: lago no alto de um planalto |
| A ferramenta Altura pinta um nível fixo, escolhido no painel, como a Forma faz hoje | Pedido do dono |

Escolhas do planejamento (corrigíveis; ao mudar uma, atualize aqui e na [01](01-terrain-height.md)):

| Decisão | Motivo |
| --- | --- |
| A altura fica guardada no servidor: coluna `height` em `island_tiles` e campo `height` em todo hexágono que a API manda | Quando a altura virar regra, o servidor já tem o dado. Hoje só o cliente a calcula |
| O nome no código é `height`, e não `level` | `level` já é o nível do Ecobeast em todo o projeto. Na tela, o editor escreve "Altura" |
| O bioma de encontro passa a ser o próprio bioma do hexágono, e a altura não conta | Já são os mesmos 7 biomas. Uma colina continua dando os Ecobeasts de colina |
| As ilhas salvas são convertidas pela tabela de hoje (forma `hill` vira bioma `hill`, forma `mont` vira bioma `mountain`, e a altura é a de `HexTile.level()`) | A ilha fica igual na tela, sem o dono retocar nada |
| O gerador continua usando a forma por dentro e só converte no fim | Uma seed gera o mesmo mapa de antes, com a mesma aparência e os mesmos encontros. Os testes da forma continuam valendo sobre a etapa de dentro |
| Depois da migration, um script recalcula o `content_hash` das ilhas | O hash inclui o formato do hexágono. Sem recalcular, toda ilha publicada apareceria como alterada até ser publicada de novo |
| A ferramenta Bioma troca só o bioma, a Altura troca só a altura, e Pôr hexágono usa os dois últimos escolhidos | Pedido de separar os dois, aplicado às três ferramentas |
| O paredão é escolhido pelo bioma: `cliff.png` na Pedra e na Montanha, `side.png` no resto, água incluída | Hoje ele sai do nível (3 e 4 usam `cliff.png`). Uma Planície alta com paredão de rocha ficaria estranha |
| A visão de cima do editor continua sem mostrar a altura | Ela é para ver a ilha inteira e pintar biomas de longe. Mostrar altura nela é outra entrega |

## Fora do escopo

- Qualquer regra de altura: bloquear subida, custo de andar, vantagem na luta, encontro por altura.
- Mais de 5 níveis, rampas e cachoeiras (a água alta ao lado de uma mais baixa mostra o paredão comum).
- Mudar o gerador: a quantidade e o formato das montanhas continuam como estão.
- Arte nova: as texturas `hill.png` e `mont.png` passam a ser as dos biomas Colina e Montanha.
- Mostrar a altura na visão de cima do editor.
- Pincel que sobe ou desce um nível por pincelada.

## Pré-requisitos

- [wild-battle](../wild-battle/), [biome-encounters](../biome-encounters/), [map-editor](../map-editor/) e [islands](../islands/) concluídas.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-terrain-height](01-terrain-height.md) | Servidor, jogo e editor: a altura em cada hexágono, Colina e Montanha como biomas e a ferramenta Altura | concluída |

É uma fase só porque o formato do hexágono muda no servidor e no jogo ao mesmo tempo: sem uma das metades, o jogo não abre o mapa.
