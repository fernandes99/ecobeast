# 02. A zona Coqueiral

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-beach-art.md), [biome-zones](../biome-zones/)

## Contexto

As zonas são linhas de `biome_zones`, distribuídas no mapa sorteado por `assignZones`, na ordem de `sort_order` e na proporção de `share`. O cliente acha a receita das plantas pelo slug da zona (`HexDecorations.recipe_of`), e a ferramenta Zona do F2 lê as zonas do catálogo.

## Requisitos

- **RF-01:** A migration `20270120000000_beach_zones` muda a Comum da Praia (zona 10) para `share` 75 e `sort_order` 2, e insere o Coqueiral (31, `beach_palms`, 25, ordem 1). A sequência de `biome_zones` fica em 32 ou mais: o id 32 foi da zona Algas mortas, que saiu antes do commit.
- **RF-02:** A receita `beach_palms` em `HexDecorations.RECIPES`, e o coqueiro novo no fim da `beach`, raro, como na tabela do [README](README.md#as-zonas-a-revisar). Os tipos de antes da `beach` ficam na mesma ordem, para o sorteio deles não mudar.
- **RF-03:** Ninguém nasce mais ou menos no Coqueiral.

## Critérios de aceite

- [x] O teste de `assignZones`: o Coqueiral fica com a parte dele da Praia, e o resto do mapa não muda numa seed.
- [ ] No mapa sorteado, a Praia tem manchas de coqueiros.
- [ ] A ferramenta Zona do F2 mostra o Coqueiral e pinta só na Praia.
- [x] `npm run lint`, `npm run typecheck` e `npm test`.
