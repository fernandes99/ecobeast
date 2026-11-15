# 02. O bloqueio por variante

- **Status:** concluída (falta o dono conferir no editor)
- **Depende de:** [01](01-depth-order.md) e [free-objects/02](../free-objects/02-block-editing.md)

## Contexto

O bloqueio padrão é do tipo inteiro, e nos pacotes cada tamanho é uma variante do mesmo tipo ([README](README.md#contexto)).

## Escopo

- A coluna `variant` em `prop_type_blocks`, a regra das linhas de uma peça e a rota com a variante.
- Os padrões das pedras e das árvores grandes.
- O hexágono bloqueado só pelo centro.

## Fora do escopo

- A ferramenta Bloqueios ([03](03-blocks-tool.md)).

## Requisitos

- **RF-01:** Uma migration acrescenta `prop_type_blocks.variant` (padrão 0, `CHECK` de 0 a 99) e troca a chave única para (`prop_type_id`, `variant`, `position`). O catálogo traz a coluna.
- **RF-02:** As linhas de uma peça seguem a regra da [arquitetura](architecture.md#o-bloqueio-por-variante), no servidor e no jogo.
- **RF-03:** A rota `PUT /v1/editor/prop-types/:id/blocks` recebe `variant` (de 0 a 99, 0 se faltar) e troca só as linhas dela.
- **RF-04:** A mesma migration põe os padrões dos [pacotes](architecture.md#os-padrões-dos-pacotes), e o `seed-data` acompanha.
- **RF-05:** O servidor e o `IslandBlocks` contam o hexágono bloqueado pelo [centro](architecture.md#o-hexágono-bloqueado).
- **RF-06:** No cadeado da peça, "Salvar como do tipo" vira "Salvar para esta variante" e "Salvar para todas", e "Usar o do tipo" vira "Usar o padrão".

## Critérios de aceite

- [x] Uma pedra bege variante 1 bloqueia pelo padrão dela, e a variante 5 não bloqueia.
- [x] Salvar para a variante 2 não muda a variante 1, e salvar vazio para a 2 a faz voltar ao da variante 0.
- [x] Uma linha que só corta o canto de um hexágono não o bloqueia; uma que passa a 5 px do centro bloqueia.
- [x] Os prédios continuam bloqueando os hexágonos deles.
- [x] As suítes do servidor passam.

## Desenho técnico

**Criar:** `server/prisma/migrations/20261207000000_variant_blocks/migration.sql` `20261208000000_larger_tree_blocks/migration.sql` `20261209000000_tree_blocks_36/migration.sql` e `20261210000000_tree_blocks_variant_2/migration.sql`.

**Alterar:**
- `server/prisma/schema.prisma`, `seed-data/prop_type_blocks.json`.
- `server/src/domain/islands/blocked-hexes.ts`: a chave por variante, `CENTER_REACH` e a regra do centro.
- `server/src/islands/islands.service.ts` (`readTypeBlocks`), `server/src/editor/prop-types-editor.*`.
- `res://core/autoload/game_data.gd`, `res://core/data/catalog_schema.gd`, `res://core/data/catalog.gd`, `res://ui/components/island_blocks.gd`, `res://domain/models/exploration_map.gd` e o editor (`island_draft.gd`, `object_panel.gd`, `map_editor.gd`, `editor_api.gd`).

## Verificação

```bash
cd server && npx prisma migrate deploy && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

## Tarefas

- [x] A migration, os padrões e o `seed-data`.
- [x] O servidor: a regra das linhas, o centro e a rota.
- [x] O jogo e o editor.
- [x] Os testes.

## Resultado da verificação

Em 2026-11-15:

- **Banco:** a migration `20261207000000_variant_blocks` foi aplicada com `migrate deploy`, e o `migrate diff` contra o banco ficou vazio. Ela pôs 38 linhas padrão: as 11 árvores e as 8 pedras, nas variantes 1 e 2. As elipses das pedras ficaram de 27 a 50 px de largura.
- **Servidor:**
  - o lint e o typecheck passam;
  - a suíte de unidade passa, com 890 testes. Entraram testes para o centro e para a variante, em `blocked-hexes.spec.ts`, e os testes de `area-spawns`, `island-draft` e `catalog-tables` passaram à chave por variante;
  - a suíte e2e passa, com 571 testes. O `prop-types-editor.e2e-spec.ts` confere a rota com `variant`, a volta à variante 0 e o limite de 99.
- **Jogo sem janela:**
  - a Pedra bege 1 bloqueia e a 5 não;
  - o Refúgio vale para qualquer variante;
  - uma linha no canto de um hexágono não o bloqueia, e uma a 5 px do centro bloqueia;
  - no `ExplorationMap`, a variante 1 bloqueia e a 5 não.
- **Escolhas na implementação:**
  - Para as pedras, a largura vem dos 40% de baixo, e não das 6 linhas de baixo. Com 6 linhas, a base arredondada dava elipses estreitas demais, de uns 21 px numa pedra de 54.
  - O cadeado também ganhou "Salvar para esta variante" e "Salvar para todas".
- **O dobro nas árvores:** jogando, o dono viu o Domador ainda entrando embaixo da copa e pediu o bloqueio das árvores "até o dobro maior". A migration `20261208000000_larger_tree_blocks` troca as 22 elipses das árvores para 24 × 12 px e 20 × 10 px. Na ilha "Teste dos pacotes", com 61 hexágonos de terra, os hexágonos bloqueados passaram de 5 para 9. Depois, ele pediu para aumentar "outra vez o mesmo valor": a `20261209000000_tree_blocks_36` as troca para 36 × 18 px e 30 × 15 px, e os bloqueados passaram para 12. Por fim, a `20261210000000_tree_blocks_variant_2` deixa a variante 2 com 32 × 16 px, como o dono pediu.
- **Falta o dono:** salvar um padrão pelo editor aberto (F2).
