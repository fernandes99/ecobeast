# 05. Elemento Inseto

- **Status:** concluída
- **Depende de:** [02-core-tables](02-core-tables.md)

## Contexto

O dono quis um Elemento para Ecobeasts insetos, e o catálogo passa de 14 para 15 Elementos. O nome "Inseto" foi escolhido pelo dono, ciente de que a referência usa a mesma palavra: é um substantivo comum, e essa é uma decisão explícita, que não abre exceção para outros termos.

O dono aprovou a tabela de eficácia. A cor é _a revisar_.

## Escopo

Linhas novas no banco (schema `ecobeasts`), nas tabelas `elements` e `element_efficacy`.

## Fora do escopo

- Espécies e Técnicas de Inseto: o Elemento começa sem nenhuma das duas.
- O ícone em `res://assets/ui/elements/insect/`: sem ele, o `ElementBadge` mostra só o nome.
- `server/prisma/seed-data/`: é só a foto da carga inicial. Um banco recriado do zero não terá este Elemento.

## Requisitos

- **RF-01:** Uma linha em `elements`: `id` 15, `slug` `insect`, `name` Inseto, `color_hex` `#96B32E` e `is_rare` false.
- **RF-02:** Dez linhas em `element_efficacy`, seguindo o conceito de que insetos devoram plantas e escavam a terra, e sofrem com fogo, frio e luz:

| Atacante | Defensor | Multiplicador | Motivo                              |
| -------- | -------- | ------------- | ----------------------------------- |
| Inseto   | Flora    | 2             | Devora as plantas                   |
| Inseto   | Terra    | 2             | Escava e abre túneis                |
| Inseto   | Fogo     | 0,5           | Não chega perto da chama            |
| Inseto   | Metal    | 0,5           | Não atravessa o metal               |
| Inseto   | Luz      | 0,5           | Se perde atraído pela luz           |
| Fogo     | Inseto   | 2             | Queima as asas                      |
| Gelo     | Inseto   | 2             | O frio paralisa os insetos          |
| Luz      | Inseto   | 2             | Atrai e desorienta                  |
| Flora    | Inseto   | 0,5           | É o alimento dele                   |
| Terra    | Inseto   | 0,5           | É o lugar onde ele se esconde       |

## Critérios de aceite

- [x] `GET /v1/catalog` traz o Elemento 15 e as 10 linhas de eficácia.
- [x] O jogo abre com o servidor no ar, e o `CatalogValidator` não aponta erro.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless -d --path client --quit-after 240
```
