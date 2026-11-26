# 06. Menos peças

- **Status:** concluída (falta aplicar a migration e o dono conferir)
- **Depende de:** [05](05-wardrobe-editor.md)

## Contexto

Em 2026-11-26, depois de editar as folhas no F6, o dono pediu: "Remova a jaqueta, regata, e na parte de baixo mantenha apenas a calça e bermuda e saia. Remova o cabelo comprido."

## Escopo

- Sair do catálogo e do jogo: o cabelo Comprido (6, `hair_long`), a Jaqueta (11, `jacket`), a Regata (12, `tank_top`), a Saia longa (23, `long_skirt`), a Calça capri (24, `capri_pants`) e a Calça boca de sino (25, `flared_pants`).
- Ficam como partes de baixo só a Calça (13), a Bermuda (14) e a Saia (15); como parte de cima, só a Camiseta (10).

## Fora do escopo

- Desenhar peças no lugar das que saem.

## Requisitos

- **RF-01:** A migration `remove_parts` troca, em `player_appearance_parts` e em `npc_appearance_parts`, cada peça que sai pela mais parecida do mesmo lugar, com a mesma cor: o Comprido pelo Curto (3), a Jaqueta e a Regata pela Camiseta (10), a Saia longa pela Saia (15, também só do corpo Feminino) e as duas calças pela Calça (13). Depois apaga as 6 linhas de `appearance_parts`. Os ids não voltam a ser usados.
- **RF-02:** O seed (`appearance_parts.json`) perde as 6 linhas, e o teste do catálogo espera 21 peças, só a Saia presa a um corpo.
- **RF-03:** O `make_wardrobe.gd` deixa de desenhá-las (sai da lista `PARTS`, as funções de desenho somem e a `ADULT_ONLY` fica com a Galocha e o Sapato), as pastas `parts/<slug>/` são apagadas, e o `hand_drawn.json` perde a Saia longa e a Regata, que o dono tinha editado no F6.
- **RF-04:** Os testes e2e que vestiam o Comprido e a Regata passam a vestir o Rabo de cavalo (5) e a Camiseta (10).

## Critérios de aceite

- [ ] Depois do "Aplicar", a tela Aparência e o botão Aparência da ferramenta NPC do F2 não mostram as 6 peças.
- [ ] Quem as vestia aparece com a peça trocada, sem erro na tela "Erro nos dados do jogo".
- [ ] O F6 não lista as 6 peças.

## Desenho técnico

- `server/prisma/migrations/20270223000000_remove_parts/migration.sql`.
- `server/prisma/seed-data/appearance_parts.json`, `server/src/catalog/catalog-tables.spec.ts`, `server/test/player.e2e-spec.ts` e `server/test/npcs-editor.e2e-spec.ts`.
- `client/assets/tamer/make_wardrobe.gd`, `client/assets/tamer/hand_drawn.json` e as pastas apagadas em `client/assets/tamer/parts/`.

## Verificação

`npx vitest run src/catalog/catalog-tables.spec.ts` e os e2e `player` e `npcs-editor` passam; o `make_wardrobe.gd` passa no `--check-only` do Godot.

## Tarefas

- [x] A migration e o seed.
- [x] O `make_wardrobe.gd`, o `hand_drawn.json` e as pastas.
- [x] Os testes.
- [x] As specs e o `CLAUDE.md`.
