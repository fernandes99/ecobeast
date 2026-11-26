# 03. Os calçados

- **Status:** concluída (falta aplicar a migration e o dono conferir)
- **Depende de:** [02](02-bottoms.md)

## Contexto

Hoje há 2 calçados, o Tênis e a Bota. O dono achou os dois "um pouco bugados, parece que falta um pixel de lado" e pediu para ajustar e trazer mais 2 opções, caprichadas.

O defeito: o pé do template tem, além dos pixels claros, 1 pixel de sombra no calcanhar, na mesma linha. O Tênis e a Bota só pintavam os pixels claros, e o calcanhar ficava com a cor da pele. Além disso, na vista da diagonal de cima a mão encosta na perna, na altura dela, e o calçado pintava a mão. E, de lado e nas diagonais, a perna de trás acaba em sombra, sem pixel claro de pé, e ficava sempre descalça (o dono apontou na prévia).

## Escopo

- O pé calçado certo no Tênis e na Bota, no adulto e na criança.
- Os calçados Galocha e Sapato, só no adulto.

## Fora do escopo

- A calça que pinta a mão na vista da diagonal de cima (a medida do quadril pega o contorno da mão), que já existia.

## Requisitos

- **RF-01:** O pé calçado (`_shoe`) são os pixels claros da altura das pernas que não sobem, ligados por pixels claros, até acima dela (o que sobe é a mão), mais os pixels de sombra ao lado deles na mesma linha (o calcanhar), mais o pé da perna de trás: o pixel mais baixo de cada coluna, quando é de sombra e fica 2 linhas ou mais abaixo do alto das pernas (1 na criança), onde a mão não chega. O cano (`_shaft`) são os pixels da perna logo acima do pé, até um número de linhas, parando no contorno.
- **RF-02:** O Tênis tem o pé claro, o calcanhar mais escuro e 1 linha de gola por cima. A Bota tem o pé escuro e o cano de 2 linhas, com a boca mais clara.
- **RF-03:** A migration `more_shoes` cria as peças 26 (`rain_boots`, "Galocha") e 27 (`dress_shoes`, "Sapato"), no lugar 3 (`shoes`), de todos os corpos e sem `hair_cut`. O seed (`appearance_parts.json`) tem as mesmas linhas.
- **RF-04:** Só no adulto (`ADULT_ONLY`), nas 5 vistas:
  - **Galocha:** de borracha, com o cano de 3 linhas, a boca no segundo tom, o brilho branco no primeiro pixel das 2 linhas de baixo do cano e o pé no segundo tom.
  - **Sapato:** baixo, só o pé, escuro (terceiro tom), com o calcanhar no mais escuro e o brilho (segundo tom) na ponta de cada pé.
- **RF-05:** As outras peças saem iguais do `make_wardrobe.gd`.

## Critérios de aceite

- [x] O Tênis e a Bota cobrem o calcanhar e não pintam a mão.
- [x] De lado e nas diagonais, as duas pernas aparecem calçadas.
- [x] A Galocha e o Sapato aparecem nas 5 vistas, parados e correndo.
- [x] As outras peças saem iguais.
- [ ] Na tela Aparência, há 4 calçados para escolher.

## Desenho técnico

- `client/assets/tamer/make_wardrobe.gd`: `_shoe`, `_shaft`, `_sneakers`, `_boots`, `_rain_boots` e `_dress_shoes`.
- `server/prisma/migrations/20270221000000_more_shoes/migration.sql`, `server/prisma/seed-data/appearance_parts.json` e `server/src/catalog/catalog-tables.spec.ts`.

## Verificação

```bash
cd server && npx prisma migrate deploy && npx vitest run src/catalog/catalog-tables.spec.ts
cd client && godot --headless -s res://assets/tamer/make_wardrobe.gd
```

E a prévia ampliada dos calçados, parados e correndo.

## Tarefas

- [x] O pé calçado, o Tênis e a Bota corrigidos e os 2 calçados novos no `make_wardrobe.gd`.
- [x] A migration, o seed e o teste.
- [ ] Aplicar a migration no banco.
