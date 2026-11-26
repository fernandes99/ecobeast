# 02. Mais 3 partes de baixo

- **Status:** concluída; as 3 peças saíram do jogo na [fase 06](06-fewer-parts.md), a pedido do dono
- **Depende de:** [01](01-faces.md)

## Contexto

Hoje há 3 partes de baixo: a Calça, a Bermuda e a Saia (só do corpo Feminino). O dono pediu "mais 3 opções, tipo uma saia".

## Escopo

- As peças Saia longa, Calça capri e Calça boca de sino no catálogo e as folhas delas, só no adulto.

## Fora do escopo

- Peças que juntam a parte de cima e a de baixo (vestido, macacão).
- A folha da criança: o dono pediu as peças novas só no adulto, a partir desta fase.

## Requisitos

- **RF-01:** A migration `more_bottoms` cria as peças 23 (`long_skirt`, "Saia longa", só do corpo 2, como a Saia), 24 (`capri_pants`, "Calça capri") e 25 (`flared_pants`, "Calça boca de sino"), no lugar 2 (`bottom`) e sem `hair_cut`. O seed (`appearance_parts.json`) tem as mesmas linhas. 
- **RF-02:** O `make_wardrobe.gd` desenha cada peça só em `parts/<slug>/`, nas 5 vistas (a lista `ADULT_ONLY` não grava a pasta `child/`):
  - **Saia longa:** a Saia com 5 linhas, abrindo até 2 pixels de cada lado e parando acima dos pés.
  - **Calça capri:** a Calça até 2 linhas abaixo do alto das pernas, com a barra no tom mais escuro e 1 linha de canela à mostra.
  - **Calça boca de sino:** a Calça, com 1 pixel a mais para fora de cada perna nas 2 linhas de cima dos pés.
- **RF-03:** A aparência de um corpo de criança (o botão Aparência da ferramenta NPC do F2) só oferece as peças que têm a folha `child/`: o `TamerEditor._fits` confere a folha pelo `TamerSprite.frames_for`.
- **RF-04:** As folhas de antes saem iguais do `make_wardrobe.gd`.

## Critérios de aceite

- [x] As folhas de antes saem iguais.
- [x] As 3 peças aparecem nas 5 vistas, no adulto.
- [ ] Na tela Aparência, o corpo Feminino mostra as 6 partes de baixo e o Masculino 4.
- [ ] Na Aparência de um NPC criança, as 3 peças novas não aparecem.

## Desenho técnico

- `server/prisma/migrations/20270220000000_more_bottoms/migration.sql`, `server/prisma/seed-data/appearance_parts.json` e `server/src/catalog/catalog-tables.spec.ts`.
- `client/assets/tamer/make_wardrobe.gd`: `ADULT_ONLY`, `_skirt_layer` (a Saia e a Saia longa), `_capri_pants` e `_flared_pants`.
- `client/ui/components/tamer_editor.gd`: `_fits` esconde da criança a peça sem a folha `child/`.

## Verificação

```bash
cd server && npx prisma migrate deploy && npx vitest run src/catalog/catalog-tables.spec.ts
cd client && godot --headless -s res://assets/tamer/make_wardrobe.gd
```

E a prévia ampliada das partes de baixo, no adulto.

## Tarefas

- [x] As peças no `make_wardrobe.gd`.
- [x] A migration, o seed e o teste.
- [x] Aplicar a migration no banco.
