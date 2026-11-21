# 03. As peças soltas da Praia

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [01](01-beach-art.md), [editor-ui/01](../editor-ui/01-prop-categories.md)

## Contexto

Um tipo de peça cujo slug está em `HexDecorations.KIND_ROWS` é desenhado pela folha de decorações (`PropArt`), sem arte própria.

## Requisitos

- **RF-01:** A migration `20270120000001_beach_props` insere os tipos 152 (`coconut_palm`, Coqueiro) e 153 (`young_palm`, Coqueiro novo) em `prop_types`, com 4 variantes e a categoria 8 `beach` "Praia". A sequência de `prop_types` fica em 164 ou mais: os ids 154 a 164 foram dos tipos que saíram antes do commit e não se reaproveitam.
- **RF-02:** O pincel Vegetação ganha o grupo "Praia" (0,5 por hexágono), no fim, com os 2 tipos ligados.

## Critérios de aceite

- [ ] A ferramenta Peças mostra os 2 tipos na categoria Praia.
- [ ] O pincel tem o grupo Praia.
- [x] `npm run lint`, `npm run typecheck` e `npm test`.
