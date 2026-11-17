# 01. As vozes no catálogo

- **Status:** concluída
- **Depende de:** [island-npcs](../island-npcs/), [liora-intro/02](../liora-intro/02-person-npcs.md)

## Contexto

As vozes são dados de design. O NPC aponta para a dele, e o ritmo de cada voz se ajusta no painel do Supabase ([architecture](architecture.md#as-tabelas)). Esta fase põe as vozes no banco e no catálogo, e a rota com que o F2 da [03](03-voice-editor.md) troca a voz de um NPC. O jogo ainda não toca nada.

## Escopo

- A tabela `voices`, a coluna `npcs.voice_id` e a carga inicial.
- As vozes no `GET /v1/catalog`.
- A rota `PUT /v1/editor/npcs/:id/voice`.
- A leitura e a conferência das vozes no jogo.

## Fora do escopo

- Os sons e os bipes (fase 02).
- O campo Voz no F2 (fase 03).

## Requisitos

- **RF-01:** A migration `dialogue_voices` cria `voices` com as colunas e os `CHECK` da [architecture](architecture.md#as-tabelas) (`slug` em `^[a-z0-9_]+$`, `chars_per_second` de 20 a 90, `letters_per_blip` de 1 a 4, `pitch_variation` de 0 a 25), põe as 6 vozes e cria `npcs.voice_id` com `default 4`, a FK com `on delete restrict` e as vozes dos 6 NPCs de hoje. Ela segue o jeito das migrations do projeto: SQL à mão e `prisma migrate deploy`.
- **RF-02:** `seed-data/voices.json` tem as 6 vozes, e o `npcs.json` ganha o `voice_id` de cada NPC. `voices` entra em `CATALOG_TABLES` antes de `npcs`, e o `GET /v1/catalog` traz as duas.
- **RF-03:** `PUT /v1/editor/npcs/:id/voice` com `{ "voice_id": <int> }` troca a voz do NPC e devolve `{ "id", "voice_id" }`. A rota responde só a quem está em `MAP_EDITOR_USER_IDS`, como as outras de `/v1/editor`. NPC que não existe dá 404 "NPC não encontrado." (a mensagem da rota de aparência); voz que não existe dá 400 "Essa voz não existe.". Depois dela, o catálogo é liberado de novo, como na rota de aparência, e o próximo `GET /v1/catalog` já traz a voz nova.
- **RF-04:** No jogo, `GameData.get_voice(id: int) -> Dictionary` e `GameData.voice_by_slug(slug: String) -> Dictionary`. Uma voz que não existe devolve `{}`.
- **RF-05:** O `CatalogValidator` confere que `voices` tem as vozes `narration`, `tamer` e `medium`, e que todo `npcs.voice_id` aponta para uma voz que existe. Um erro abre a tela "Erro nos dados do jogo", como os outros.

## Critérios de aceite

- [x] `GET /v1/catalog` traz as 6 vozes e o `voice_id` de cada NPC.
- [x] O `PUT /v1/editor/npcs/3/voice` com a voz 4 troca a voz do avô, e o próximo catálogo já traz a mudança.
- [x] Voz 99 dá 400, NPC 999 dá 404, e quem não é do editor recebe 403.
- [x] Um catálogo sem a voz `narration` abre "Erro nos dados do jogo".
- [x] A suíte inteira do servidor passa, menos as 2 falhas que já existiam no `seed.e2e`.

## Desenho técnico

- **Criar:**
  - `server/prisma/migrations/<data>_dialogue_voices/migration.sql`
  - `server/prisma/seed-data/voices.json`
  - `server/test/npc-voice.e2e-spec.ts`, no grupo que escreve no catálogo (`CATALOG_WRITERS`), como o `home-island.e2e-spec.ts`
- **Alterar:**
  - `server/prisma/schema.prisma` (o `Voice` e o `Npc.voiceId`)
  - `server/prisma/seed-data/npcs.json`
  - `server/src/catalog/catalog-tables.ts` e o `catalog-tables.spec.ts` (as 6 vozes e a voz de cada NPC)
  - `server/src/editor/npcs-editor.controller.ts`, `.service.ts` e `.dto.ts`
  - `client/core/autoload/game_data.gd`
  - o `CatalogValidator`
  - `.specs/game-data/architecture.md` (a tabela nova)

## Notas da implementação

- A migration é a `20270101000000_dialogue_voices`. O Responsável do Refúgio fica com a Média pelo `default 4`, sem `UPDATE`.
- No jogo, além do `get_voice` e do `voice_by_slug`, o `GameData` tem o `npc_voice(npc_id)` (a voz do NPC do catálogo) e o `set_npc_voice`, que a [03](03-voice-editor.md) usa.
- O `database.e2e` conta uma tabela a mais (73, com o histórico de migrations).

## Verificação

- `npm test` e `npm run test:e2e` no `server/`.
- `godot --headless --path client --quit-after 30`, com a API local.

## Tarefas

- [x] A migration, o schema e a carga inicial.
- [x] O catálogo e o teste da carga inicial.
- [x] A rota do editor e o e2e.
- [x] A leitura e a conferência no jogo.
- [x] A `game-data/architecture.md`, o `server/CLAUDE.md` se citar as rotas do editor, e as tabelas das specs.
