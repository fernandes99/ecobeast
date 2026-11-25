# 01. Mais 5 rostos

- **Status:** concluída (falta o dono conferir na tela Aparência)
- **Depende de:** [tamer-appearance](../tamer-appearance/), [village-crowd/03](../village-crowd/03-child-template.md)

## Contexto

Hoje há 2 rostos: o Rosto 1 (olhos de 1 coluna e a bochecha rosada) e o Rosto 2 (olhos mais baixos, com sobrancelha, e sem bochecha). O dono pediu mais 3 e depois mais 2, a partir de uma imagem com dois exemplos de olhos fechados de alegria: um arco e um ^.

## Escopo

- Os rostos 3 a 7 no catálogo e as folhas deles, no adulto e na criança.

## Fora do escopo

- Boca, expressões que mudam na animação e rosto com paleta.

## Requisitos

- **RF-01:** A migration `more_faces` cria as peças 18 (`face_3`, "Rosto 3"), 19 (`face_4`, "Rosto 4") 20 (`face_5`, "Rosto 5"), 21 (`face_6`, "Rosto 6") e 22 (`face_7`, "Rosto 7"), no lugar 1 (`face`), de todos os corpos e sem `hair_cut`. O seed (`appearance_parts.json`) tem as mesmas linhas.
- **RF-02:** O `make_wardrobe.gd` desenha cada rosto a partir dos olhos e da bochecha do template, em `parts/face_<n>/` e `parts/face_<n>/child/`, nas 5 vistas:
  - **Rosto 3, olhos brilhantes:** cada olho ganha uma segunda coluna, para dentro do rosto, com o pixel de cima claro (o brilho), e a bochecha rosada.
  - **Rosto 4, sardas:** os olhos do Rosto 1 e, no lugar da bochecha, 2 sardas por lado (`#9a523a`), uma no pixel de dentro da bochecha e outra 1 pixel para fora e 1 acima.
  - **Rosto 5, olhos semicerrados:** só um traço de 2 pixels no pé de cada olho, e a bochecha rosada.
  - **Rosto 6, olhos fechados de alegria:** cada olho vira um arco (∩) de 3 pixels de largura e 2 de altura, nas 2 últimas linhas do olho, e a bochecha rosada.
  - **Rosto 7, olhos de risada:** cada olho vira um ^ de 3 pixels de largura e 2 de altura, no mesmo lugar, e a bochecha rosada.
  - Na criança, cujos olhos ficam a 2 pixels um do outro, o arco e o ^ ficam 1 pixel para fora, para não se encostarem.
- **RF-03:** As folhas de antes saem iguais do `make_wardrobe.gd`.

## Critérios de aceite

- [x] As folhas de antes saem iguais.
- [x] Os 5 rostos novos aparecem nas 5 vistas, no adulto e na criança, sem sair da cabeça.
- [ ] Na tela Aparência, os 7 rostos aparecem para escolher.

## Desenho técnico

- `server/prisma/migrations/20270219000000_more_faces/migration.sql`, `server/prisma/seed-data/appearance_parts.json` e `server/src/catalog/catalog-tables.spec.ts`.
- `client/assets/tamer/make_wardrobe.gd`: `_eyes`, `_blush`, `_skin` e os rostos `_face_3` a `_face_7`, com `_closed_eyes` para o arco e o ^.

## Verificação

```bash
cd server && npx prisma migrate deploy && npx vitest run src/catalog/catalog-tables.spec.ts
cd client && godot --headless -s res://assets/tamer/make_wardrobe.gd
```

E a prévia ampliada dos 7 rostos, no adulto e na criança.

## Tarefas

- [x] Os rostos no `make_wardrobe.gd`.
- [x] A migration, o seed e o teste.
- [x] Aplicar a migration no banco.
