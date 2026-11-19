# 07. O Elemento Psíquico

- **Status:** concluída
- **Depende de:** [02-core-tables](02-core-tables.md)

## Contexto

Em 2026-11-19, o dono pediu para renomear o Elemento Mente para Psíquico. Ele sabe que o nome lembra o Pokémon, mas é uma palavra comum, que não copia nada de lá ([README](README.md#decisões)).

## Escopo

- A migração `20270107000000_psychic_element`, que troca o `name` do Elemento 10 para "Psíquico".
- O `GDD.md`, o `TELAS.md` e as specs que citavam o Mente.

## Requisitos

- **RF-01:** O Elemento 10 se chama "Psíquico" no banco e em todo texto do jogo. O slug `mind` continua o mesmo, porque o código e os efeitos das Técnicas (`cut_effects.gd`) usam o slug.
- **RF-02:** Nenhum outro texto do catálogo (Técnicas, espécies, Traços, itens e biomas) citava o Mente, então só o Elemento muda.
- **RF-03:** O `server/prisma/seed-data/elements.json` fica como está: ele é só a carga inicial.

## Critérios de aceite

- [x] `select name from ecobeasts.elements where id = 10` devolve "Psíquico".
- [ ] No F1, na aba Elementos, e no detalhe do Echofrost, o Elemento aparece como Psíquico.

## Verificação

```bash
cd server && npx prisma migrate deploy
```
