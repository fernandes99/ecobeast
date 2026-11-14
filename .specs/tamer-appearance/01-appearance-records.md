# 01. A aparência no banco e no contrato

- **Status:** concluída
- **Depende de:** [auth-google](../auth-google/), [architecture.md](architecture.md)

## Contexto

Primeira fase da [tamer-appearance](README.md): o servidor passa a ter o catálogo de aparência e a guardar, conferir e entregar a aparência de cada jogador. O jogo ainda não a desenha (fase 2), mas já recebe o catálogo e o `appearance` do jogador.

## Escopo

- Os catálogos `body_types`, `appearance_slots`, `appearance_parts` e `palettes`, com o conteúdo mínimo do [architecture](architecture.md#o-catálogo): os 2 corpos, os 6 lugares, o rosto 1 e 1 paleta de cada tipo.
- `players.body_type_id`, `players.skin_palette_id` e a tabela `player_appearance_parts`, com o rosto 1 para quem já existe e para quem for criado.
- O `appearance` em toda resposta com `player` e a rota `PUT /v1/me/appearance`.
- O espelho dos catálogos no jogo (`catalog_schema.gd`) e a leitura do `appearance` no `Player`.

## Fora do escopo

- Desenhar o Domador em camadas e a tela Aparência (fases 2 e 3).
- O guarda-roupa inicial (fase 4).

## Requisitos

- **RF-01:** Os 4 catálogos entram no `GET /v1/catalog`, com `CHECK` no formato do `slug`, no `palette_kind`, no `kind`, no `hair_cut` e nas cores.
- **RF-02:** Quem já tem Domador e quem é criado pelo `POST /v1/me` fica com o corpo 1, a primeira paleta de pele e o rosto 1.
- **RF-03:** Toda resposta com `player` traz `appearance`, no formato do [architecture](architecture.md#o-contrato), com `parts` na ordem do `layer`.
- **RF-04:** `PUT /v1/me/appearance` troca a aparência inteira numa transação e devolve o `player`.
- **RF-05:** A rota recusa (`400`) cada erro da lista do architecture, com a mensagem dele, e não muda nada.
- **RF-06:** Sem Domador, a rota responde `409` "Crie seu Domador primeiro.".
- **RF-07:** "Apagar progresso" apaga as peças vestidas junto com o jogador.

## Critérios de aceite

- [x] O catálogo traz os 2 corpos, os 6 lugares, o rosto 1 e as 3 paletas.
- [x] Um Domador novo vem com a aparência padrão.
- [x] Trocar a aparência e ler `/v1/me` de novo devolve a aparência trocada.
- [x] Cada erro do RF-05 é recusado com a mensagem certa, e a aparência de antes continua.
- [x] O `/docs` mostra a rota nova, com o corpo e os erros.

## Desenho técnico

- `server/prisma/schema.prisma`: `BodyType` (`body_types`), `AppearanceSlot` (`appearance_slots`), `AppearancePart` (`appearance_parts`), `Palette` (`palettes`), `PlayerAppearancePart` (`player_appearance_parts`) e os 2 campos novos em `Player`.
- A migration `tamer_appearance`, escrita à mão e aplicada com `migrate deploy`: as tabelas, os `CHECK`, o conteúdo mínimo, as sequências e o rosto 1 para cada jogador que já existe. Os dados em `server/prisma/seed-data/` (`body_types.json`, `appearance_slots.json`, `appearance_parts.json`, `palettes.json`).
- A migration `tamer_appearance_palette_columns` renomeia as colunas de cor para `color1_hex` a `color4_hex`: a primeira as criou como `color_1_hex`, mas a conversão de nome do Prisma é mecânica (`color1Hex` vira `color1_hex`), e o teste do catálogo exige isso.
- `server/src/catalog/catalog-tables.ts`: as 4 tabelas.
- `server/src/domain/appearance/appearance.ts` (novo): a conferência pura `appearanceError(input, catalog)`, que devolve a mensagem do primeiro erro ou `null`, para testar sem banco.
- `server/src/player/`: o DTO `AppearanceDto` em `player.dto.ts` (no `PlayerDto` e no corpo da rota), o `appearance` no `player.mapper.ts`, a rota `PUT appearance` no `PlayerController` e, no `PlayerService`, a leitura da aparência, a criação com o rosto 1 e a troca.
- Jogo: `res://core/data/catalog_schema.gd`, com as 4 tabelas, e `res://domain/models/player.gd`, com `appearance: TamerAppearance` (`res://domain/models/tamer_appearance.gd`, novo, com `from_dict`).
- Specs: `.specs/game-data/architecture.md`, as tabelas novas.

## Verificação

- Testes de unidade do `appearanceError`: cada erro e uma aparência certa.
- E2e: o catálogo com as 4 tabelas, um Domador novo com a aparência padrão, a troca e a leitura de volta, cada erro e o `409` sem Domador.
- `npm run lint`, `typecheck`, `npm test` e `npm run test:e2e`.
- O jogo abre com o servidor no ar, sem erro no `CatalogValidator`.

## Tarefas

- [x] Modelos do Prisma e a migration, com o conteúdo mínimo.
- [x] As tabelas no catálogo e os testes do catálogo.
- [x] `appearanceError` e os testes de unidade.
- [x] DTO, rota e serviço, com os e2e.
- [x] O espelho no jogo e o `TamerAppearance`.
- [x] Atualizar `.specs/game-data/architecture.md`.
