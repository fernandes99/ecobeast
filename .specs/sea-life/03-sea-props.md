# 03. As peças soltas da água

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [01](01-sea-art.md), [nature-variety/02](../nature-variety/02-nature-props.md), [editor-ui/01](../editor-ui/01-prop-categories.md)

## Contexto

Um tipo de peça cujo slug está em `HexDecorations.KIND_ROWS` é desenhado pela folha de decorações (`PropArt`), sem arte própria.

## Requisitos

- **RF-01:** A migration `sea_props` insere a categoria 14 `sea` "Mar" em `prop_categories` e, nela, os tipos 139 a 151 em `prop_types`, na ordem da tabela da [01](01-sea-art.md#os-tipos), com o nome dela e 4 variantes.
- **RF-02:** O pincel Vegetação ganha o grupo "Mar" (1 por hexágono), no fim, com os 13 tipos; os 6 do lixo começam desligados.

## Critérios de aceite

- [ ] A ferramenta Peças mostra a categoria Mar com os 13 tipos.
- [ ] O pincel tem o grupo Mar.
- [x] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Tarefas

- [x] A migration, aplicada no banco.
- [x] O grupo do pincel.
