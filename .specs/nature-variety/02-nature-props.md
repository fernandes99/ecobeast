# 02. Os tipos de peça e os grupos do pincel

- **Status:** concluída (falta o dono usar)
- **Depende de:** [01](01-nature-art.md)

## Contexto

Um tipo de peça cujo slug está em `HexDecorations.KIND_ROWS` é desenhado pela folha de decorações (`PropArt`), sem arte própria. Os 17 primeiros tipos já são assim; os 6 do Deserto e da Neve e os 24 da [01](01-nature-art.md) ainda não são peças.

## Requisitos

- **RF-01:** A migration `nature_props` insere em `prop_types`, com 4 variantes cada:
  - 61 `cactus` "Cacto", 62 `sand_rock` "Pedra de arenito", 63 `snow_pine` "Pinheiro nevado", 64 `snow_rock` "Pedra com neve", 65 `snow_bush` "Arbusto nevado", 66 `snow_tuft` "Capim com geada";
  - 67 a 90, os 24 tipos da [01](01-nature-art.md#os-tipos), na ordem da tabela, com o nome dela.

  A carga inicial (`prop_types.json`) leva as mesmas linhas.
- **RF-02:** No pincel Vegetação (`VegetationPanel.GROUPS`), os tipos entram nos grupos de hoje, e os marcados com * começam desligados:
  - Árvores: `birch`, `oak`, `fir`, `snow_pine`*;
  - Arbustos: `berry_bush`, `thistle`, `winter_berry`*, `snow_bush`*, `tumbleweed`*, `cactus`*;
  - Gramas: `tall_grass`, `clover`, `dune_grass`*, `snow_tuft`*;
  - Flores: `wildflowers`, `yellow_flowers`, `mushrooms`, `desert_flower`*;
  - Pedras pequenas: `ice_shards`*;
  - Pedras médias: `lichen_rock`, `sand_rock`*, `snow_rock`*;
  - Pedras grandes: `slab`.

  Um grupo novo, "Galhos e troncos" (0,5 por hexágono), depois de "Pedras grandes", com `fallen_branch`, `dry_branch`, `log`, `stump`, `bleached_branch`*, `frozen_branch`*, `snow_log`*.

## Critérios de aceite

- [x] A ferramenta Peças mostra os 30 tipos novos, com a arte da folha (pelo `PropArt`, sem código novo).
- [x] As rotas do editor aceitam uma ilha com eles.
- [x] `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.

## Tarefas

- [x] A migration e a carga inicial.
- [x] Os grupos do pincel.

## Resultado da verificação

Em 2026-11-15:

- **A migration** foi aplicada no banco: os tipos 61 a 90.
- **Os testes do catálogo** (`catalog-tables.spec.ts`) contam 90 tipos e conferem os novos, com 4 variantes cada.
- **O pincel:** numa cena temporária (apagada), o `VegetationPanel` compila, tem 14 grupos e acha um tipo de peça no catálogo para cada slug deles.
- **As rotas do editor** aceitam os tipos novos pelo catálogo, sem código próprio; nenhum e2e novo foi escrito para isso.
- `npm run lint`, `npm run typecheck`, `npm test` e a suíte e2e passam.
- **Não conferido:** a ferramenta Peças e o pincel com o editor aberto.
