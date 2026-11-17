# 01. Os Marcos no servidor

- **Status:** concluída
- **Depende de:** [auth-google](../auth-google/), [fog-of-war/01](../fog-of-war/01-discovery-store.md) (o mesmo jeito de guardar estado do jogador numa tabela própria)

## Contexto

A história mora no cliente ([README](README.md#decisões)), mas o ponto onde o jogador parou precisa sobreviver a uma reinstalação. Esta fase cria o único dado da história no servidor: a lista de Marcos do jogador, que o servidor guarda sem saber o que significam ([architecture](architecture.md#o-servidor-os-marcos)). Nenhuma tela usa os Marcos ainda; o cliente só passa a lê-los.

## Escopo

- A tabela `player_story_marks`, com a migration.
- `player.story_marks` no `GET /v1/me` e nas respostas que devolvem o jogador.
- A rota `POST /v1/me/story/marks`.
- No cliente, `Player.story_marks` e `Session.add_story_marks`.
- Os termos Cena e Marco no glossário.

## Fora do escopo

- Desligar Marcos e qualquer rota de leitura além do `GET /v1/me`.
- Tocar cenas (fase 02).

## Requisitos

- **RF-01:** O modelo Prisma `PlayerStoryMark` (`@@map("player_story_marks")`, schema `ecobeasts`) tem `playerId` (`player_id`, uuid, FK `players` com `onDelete: Cascade`), `mark` (text) e `createdAt` (`created_at`, timestamptz(3), padrão `now()`), com chave `@@id([playerId, mark])`. A migration `20261224000000_story_marks` cria a tabela e um `CHECK` com a regra `^[a-z0-9_]{1,48}$` em `mark`, escrito à mão no SQL e comentado no campo com `/// CHECK ^[a-z0-9_]{1,48}$ (migration story_marks)`, como pede o `server/CLAUDE.md`. Nesta máquina o `migrate dev` trava: escreva o SQL inteiro à mão e aplique com `npx prisma migrate deploy`, depois `npx prisma generate`. Como as outras tabelas do schema `ecobeasts`, ela não fica na API automática do Supabase.
- **RF-02:** `PlayerDto` ganha `story_marks: string[]`, os Marcos do jogador em ordem alfabética, vazio para quem não tem nenhum. O `PLAYER_INCLUDE` passa a trazer os Marcos (`storyMarks`, ordenados por `mark`), e o `toPlayerDto` os põe em `story_marks`. Assim toda rota que devolve o jogador traz os Marcos.
- **RF-03:** `POST /v1/me/story/marks` (`StoryController`, `@Controller('me/story')`, com o `AuthGuard` e a tag `História` no Scalar) recebe `{ "marks": string[] }` e devolve `201` com `{ "story_marks": string[] }`, a lista inteira depois de ligar, em ordem alfabética. Ligar um Marco que o jogador já tem não é erro, nem repetir um Marco no mesmo pedido.
- **RF-04:** As recusas, nesta ordem de conferência:
  - `400` "Mande de 1 a 50 Marcos por vez." quando `marks` falta, não é lista, está vazia ou tem mais de 50 itens;
  - `400` "O Marco \"<valor>\" tem caracteres inválidos." para o primeiro item que não é texto ou foge de `^[a-z0-9_]{1,48}$` (o valor aparece como veio, cortado em 48 caracteres);
  - `409` "Crie seu Domador primeiro." sem Domador;
  - `400` "O Domador pode ter até 2.000 Marcos." quando os Marcos que ele já tem mais os novos (sem contar os repetidos) passam de 2.000. Nada é gravado.
- **RF-05:** A gravação é um `INSERT ... ON CONFLICT DO NOTHING` numa transação com a contagem, para dois pedidos ao mesmo tempo não passarem do limite.
- **RF-06:** `DELETE /v1/me` (apagar o progresso) leva os Marcos pela FK, sem código novo.
- **RF-07:** No cliente, `Player` (`res://domain/models/player.gd`) ganha `story_marks: Array[String]`, lido de `story_marks` pelo `ApiGameService` (`_player_result` e onde mais o jogador é montado). O `GameService` e o `ApiGameService` ganham `add_story_marks(marks: Array[String]) -> Result`, com `Result.data` sendo a lista nova; `Session.add_story_marks(marks: Array[String]) -> Result` chama o serviço e, no sucesso, troca `Session.player.story_marks` pela lista devolvida e emite `player_changed`.
- **RF-08:** O [glossary.md](../glossary.md) ganha as linhas Cena (`StoryScene`\*, `res://story/scenes/`) e Marco (`StoryMarks`\*, `player_story_marks`), com "—" na coluna Referência.

## Critérios de aceite

- [x] `GET /v1/me` de um Domador novo traz `"story_marks": []`.
- [x] `POST /v1/me/story/marks` com `["sabe_da_mira", "avo_chega"]` devolve `["avo_chega", "sabe_da_mira"]`, e mandar `["avo_chega"]` de novo devolve a mesma lista.
- [x] `"Avo Chega"`, `""` e um texto de 49 caracteres são recusados com a mensagem do RF-04, e nada é gravado.
- [x] 51 Marcos num pedido e o pedido que passaria de 2.000 são recusados.
- [x] Sem Domador, a rota responde `409`.
- [x] Apagar o progresso e criar o Domador de novo começa sem Marcos.
- [x] A rota aparece em `/docs`, na tag História, com as recusas descritas.
- [x] `npm test` e `npm run test:e2e` passam.

## Desenho técnico

- **Criar:**
  - `server/prisma/migrations/20261224000000_story_marks/migration.sql`
  - `server/src/story/story.module.ts`, `story.controller.ts`, `story.service.ts`, `story.dto.ts` (as constantes `MAX_MARKS_PER_CALL = 50`, `MAX_MARKS = 2000`, `MARK_PATTERN` e as mensagens)
  - `server/test/story-marks.e2e-spec.ts`
- **Alterar:**
  - `server/prisma/schema.prisma` (o modelo e a relação `storyMarks` em `Player`)
  - `server/src/player/player.mapper.ts` e `player.dto.ts`
  - `server/src/app.module.ts` (o `StoryModule`)
  - `client/domain/models/player.gd`, `client/core/services/game_service.gd`, `client/core/services/api_game_service.gd`, `client/core/autoload/session.gd`
  - `.specs/glossary.md`
- **Reutilizar:** o `DiscoveriesService` (`server/src/islands/discoveries.service.ts`) como modelo de serviço com `$executeRaw`, e o `test/island-discoveries.e2e-spec.ts` como modelo de e2e (tokens e Domador de teste).

## Verificação

```bash
cd server && npm test && npm run test:e2e -- story-marks player
godot --headless --path client --quit-after 30
```

Antes do commit, a suíte e2e inteira. No jogo: F5, entrar e conferir no console, pelo `print` temporário ou pelo depurador, que `Session.player.story_marks` é `[]`.

## Tarefas

- [x] O teste e2e com os critérios acima, falhando.
- [x] O modelo, a migration e o `migrate deploy`.
- [x] `story_marks` no `PlayerDto`.
- [x] O `StoryModule` com a rota e as recusas, até o e2e passar.
- [x] O cliente: `Player.story_marks`, o serviço e o `Session.add_story_marks`.
- [x] O glossário, o README da iniciativa e as tabelas das specs.

Conferido por Claude: os e2e `story-marks` (o vazio, a ordem, os repetidos, as 8 recusas, o limite de 2.000, o `409` e apagar o progresso) e o `player` passam, e a rota aparece em `/docs/openapi.json`. As conferências do RF-04 ficam no `checkMarks` do `StoryService`, e não num `ValidateBy` do DTO, para a mensagem dizer qual Marco está errado. A tabela não tem RLS, como as outras do schema `ecobeasts`, que a API automática do Supabase não enxerga.
