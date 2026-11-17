# 01. A ilha casa e a ação Viagem

- **Status:** concluída
- **Depende de:** [islands](../islands/), [map-editor](../map-editor/), [free-objects/03](../free-objects/)

## Contexto

O jogo precisa saber qual ilha é a casa do jogador e onde ficam as viagens dela ([README](README.md#decisões)). Esta fase cria os dados e a forma de o dono escolher os dois no F2. O jogo ainda não muda de comportamento: isso é a [02](02-open-at-home.md).

## Escopo

- A coluna `islands.is_home` e a rota do editor que a liga.
- O `home` na lista das ilhas do jogador.
- O "Casa do jogador" no F2.
- O tipo de ação `travel` no catálogo.

## Fora do escopo

- Abrir o app na casa, o menu e a tela Viagem (fases 02 e 03).

## Requisitos

- **RF-01:** A migration `home_island` cria `islands.is_home BOOLEAN NOT NULL DEFAULT false` e o índice único parcial `islands_one_home` ([architecture](architecture.md#a-ilha-casa)).
- **RF-02:** `PUT /v1/editor/islands/:id/home` com `{ "home": true }` liga a casa na ilha e desliga a de qualquer outra, numa transação. Com `{ "home": false }`, desliga a dela. Responde a ilha do editor como o `GET /v1/editor/islands/:id`, que passa a ter `home: boolean`.
- **RF-03:** Ligar a casa numa ilha nunca publicada responde 400 "Publique a ilha antes de fazer dela a casa do jogador.". Ilha que não existe: o 404 das outras rotas do editor.
- **RF-04:** `GET /v1/me/islands` devolve `home: boolean` em cada ilha (`PlayerIslandDto`).
- **RF-05:** No F2, o cabeçalho da ilha aberta ganha a caixa "Casa do jogador", marcada quando a ilha é a casa. Marcar ou desmarcar chama a rota na hora, e o erro aparece na linha de mensagens do editor. A caixa fica desabilitada numa ilha nunca publicada, com a dica "Publique a ilha primeiro.".
- **RF-06:** `action_types` ganha a linha 5, `travel`, "Viagem", `#3FA7A0` _a revisar_, `open_screen`, no seed (`server/prisma/seed-data/action_types.json`) e numa migration de dados. O F2 já oferece todo tipo de ação nas construções, nas peças e nos NPCs, então ela aparece sozinha.
- **RF-07:** O `CatalogValidator` aceita o tipo novo sem mudança de regra. Antes da [03](03-travel-screen.md), encostar numa Viagem em Explorar não faz nada, como já acontece com uma ação sem tela em `ACTION_SCREENS`.

## Critérios de aceite

- [ ] Ligar a casa na ilha A e depois na B deixa só a B com `is_home`.
- [ ] Ligar a casa numa ilha só rascunho responde 400 com a mensagem do RF-03.
- [ ] `GET /v1/me/islands` mostra `home: true` só na casa.
- [ ] No F2, a caixa reflete a casa ao abrir a ilha e muda o banco ao clicar.
- [ ] Uma peça pode receber a ação Viagem no F2, e ela é salva e publicada.

## Desenho técnico

- `server/prisma/schema.prisma`: `Island.isHome Boolean @default(false) @map("is_home")`, com o comentário `/// Só uma: índice único parcial islands_one_home (migration home_island)`.
- `server/prisma/migrations/<data>_home_island/migration.sql`: a coluna, o índice e o `INSERT` da ação 5 (escrito à mão e aplicado com `npx prisma migrate deploy`, [referência](../../server/CLAUDE.md)).
- `server/src/editor/islands-editor.controller.ts`, `.service.ts`, `.dto.ts`: a rota `PUT :id/home`, o `home` na resposta.
- `server/src/islands/islands.service.ts`, `islands.dto.ts`: o `home` no `listPublished()`.
- `client/`: o `IslandSummary` ganha `home: bool`; o serviço do editor ganha `set_home(id, home)`; o cabeçalho do `map_editor.gd` ganha a caixa.
- Testes: unitários do serviço do editor (liga, troca, recusa rascunho) e o e2e da rota e da lista. O e2e de contagem de tabelas e linhas (`test/database.e2e-spec.ts`) ganha a linha nova de `action_types`.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
godot --headless --path client --quit-after 30
```

Manual: no F2, publicar uma ilha, marcar "Casa do jogador", conferir no painel do Supabase; pôr a ação Viagem numa peça.

## Tarefas

- [x] Migration, schema e seed.
- [x] Rota do editor e `home` na lista, com os testes.
- [x] O `IslandSummary`, o serviço do editor e a caixa no F2.
