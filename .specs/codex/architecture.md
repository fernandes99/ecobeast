# Arquitetura

O desenho que as fases da [codex](README.md) compartilham.

## Fluxo

```text
Luta começa, ou um         →  o servidor grava "visto" para cada espécie inimiga
inimigo entra em campo        que entrou em campo nessa resposta (creature_entered)

Captura dá certo           →  no fim da luta, junto com o Ecobeast capturado, a espécie
                              vira "capturada"; a resposta traz registered_species_ids
                              com ela, se for a primeira vez

Evolução aceita            →  a espécie nova vira "capturada"; a resposta de
                              /evolution traz registered_species_ids

Escolher o inicial         →  a espécie dele nasce "capturada", e os outros dois
                              iniciais da escolha nascem "vistos"

Abrir o Bestiário          →  GET /v1/me/codex
                              devolve as espécies conhecidas, com capturado ou não
```

## Tabela

Estado do jogador, no schema `ecobeasts`, ao lado de `inventory_items` ([01](01-codex-records.md)):

| Coluna | Tipo | O que é |
| --- | --- | --- |
| `player_id` | uuid, FK `players` (`CASCADE`) | O dono do registro |
| `species_id` | int, FK `species` (`RESTRICT`) | A espécie |
| `seen_at` | timestamptz | A primeira vez que o jogador a viu |
| `caught_at` | timestamptz, nulo | A primeira vez que ele a capturou; nulo se só viu |

- Chave primária `(player_id, species_id)`, índice em `species_id`.
- `CHECK (caught_at IS NULL OR caught_at >= seen_at)`.
- Sem linha, a espécie nunca foi vista. As datas nunca voltam: capturar de novo, ou ver de novo, não muda nada.
- No Prisma, `CodexEntry` (`@@map("codex_entries")`). Apagar o progresso apaga o Bestiário pela cascata.

A migração cria a tabela e registra, para cada jogador, as espécies dos Ecobeasts que ele tem hoje, com `seen_at` e `caught_at` iguais ao menor `caught_at` dos Ecobeasts dessa espécie. Os iniciais de `starter_options` que ele não tem entram como vistos, com `seen_at` igual ao `created_at` do jogador.

## Registrar no servidor

As escritas ficam num `CodexService` (`server/src/codex/`), usado pelos módulos da luta, da progressão e do jogador:

| Método | O que faz |
| --- | --- |
| `recordSeen(userId, speciesIds)` | Cria a linha de quem ainda não tem, com `seen_at` agora. Quem já tem não muda |
| `recordCaught(userId, speciesIds)` | Cria a linha de quem não tem, com as duas datas agora, e preenche `caught_at` de quem só tinha sido visto. Devolve as espécies que ficaram capturadas agora, sem repetir, na ordem recebida |

A captura e a Evolução gravam hoje com `$transaction([...])`, uma lista de escritas que não deixa ler antes de decidir. Por isso o capturado é uma escrita só, que entra na lista de quem chama: um `INSERT ... ON CONFLICT (player_id, species_id) DO UPDATE SET caught_at = now() WHERE codex_entries.caught_at IS NULL RETURNING species_id`, e as linhas devolvidas são as espécies novas. O código que já funciona continua com a mesma lista.

Os pontos que chamam:

| Momento | Onde | Espécies |
| --- | --- | --- |
| Toda resposta de luta no tabuleiro (as aberturas e o `/board-battle/action`) | `BoardBattleService`, antes de responder | As dos eventos `creature_entered` do lado `enemy` |
| Fim de luta com captura | `BattleRecordsService`, na mesma transação que cria o capturado | A dos capturados que foram gravados (`places`), e não a do `captured` da luta: sem equipe, o jogador foi apagado e ninguém é gravado |
| Evolução aceita | `ProgressionService.applyEvolution`, na mesma transação que troca a espécie | A espécie nova |
| Escolha do inicial | `PlayerService`, numa transação nova com a criação do Ecobeast, que hoje é uma escrita só. O registro usa `ON CONFLICT DO NOTHING`, para o segundo pedido simultâneo continuar caindo na chave única da vaga (`STARTER_TAKEN`) | Capturada: a do inicial. Vistas: as outras de `starter_options` |

O visto não pode atrapalhar a luta: ele é gravado depois de a vez ser guardada no `BattleStore`, e uma falha nele vai para o log do servidor sem mudar a resposta. A captura, a Evolução e o inicial gravam o registro na mesma transação, e uma falha desfaz tudo, como hoje.

## Contrato

`GET /v1/me/codex` (autenticada):

```json
{
  "entries": [
    { "species_id": 1, "caught": true },
    { "species_id": 4, "caught": false }
  ]
}
```

Só as espécies conhecidas, na ordem do `species_id`. O jogo cruza com o catálogo: espécie sem entrada é "???".

`DELETE /v1/me/codex` (autenticada, só com `ENABLE_TEST_BATTLE`; sem ela, 404 "Rota não encontrada."): apaga os registros do jogador e responde 204.

As respostas da luta no tabuleiro (`BoardBattleResponseDto`) e da Evolução (`EvolutionResponseDto`) ganham:

```json
{ "registered_species_ids": [4] }
```

São as espécies que ficaram capturadas pela primeira vez nessa resposta. Na luta, só a resposta do fim com captura traz alguma; as outras trazem `[]`. Na Evolução, a lista tem a espécie nova, ou fica vazia quando ela já estava capturada ou quando a Evolução foi cancelada.

## Jogo

- **Modelo:** `Codex` em `res://domain/models/codex.gd`, montado do `entries`, com `status(species_id)` devolvendo `UNKNOWN`, `SEEN` ou `CAUGHT`, e as contagens `seen_count()` (inclui os capturados) e `caught_count()`.
- **Serviços:** `Session.load_codex()` (`GET /v1/me/codex`) e, só em debug, `Session.debug_clear_codex()`. O `BoardTurn` e o `ProgressChoice` ganham `registered_species_ids: Array[int]`.
- **Tela:** `codex`, em `res://screens/codex/`, registrada no `Router` e aberta pelo card e pela aba Bestiário do Hub ([02](02-codex-screen.md)).
- **Aviso:** o `CodexRegisteredOverlay`, em `res://screens/codex/`, posto na cena da luta no tabuleiro ([03](03-codex-registered.md)).
- **Sombra:** o `CreaturePortrait` ganha `set_silhouette(on)`, que pinta a arte com uma cor só, nova em `UiPalette` (`SILHOUETTE`), mantendo o contorno. Um `modulate` não basta, porque multiplica e deixa ver o desenho por dentro: a arte usa um shader pequeno (`res://ui/components/silhouette.gdshader`) que troca a cor de cada pixel e mantém a transparência. Sem arte, a forma é desenhada em `SILHOUETTE`, sem a letra e sem as cores do Elemento. A grade, o detalhe e a linha evolutiva usam o mesmo.

## Textos

| Onde | Texto |
| --- | --- |
| Título da tela | Bestiário |
| Contagem | "Vistos" e "Capturados", com o número em cima |
| Número | `#%03d` do id |
| Nunca visto | ??? |
| Detalhe de um visto | "Capture um {nome} para ver os dados dele." |
| Blocos do detalhe | Descrição, Altura, Peso, Habitat, Linha evolutiva |
| Altura e peso | "1,0 m" e "32,0 kg", com uma casa e vírgula |
| Condição na linha evolutiva | "nv. {min_level}" embaixo da seta, na Evolução por nível; as outras sem texto |
| Aviso | "Novo registro no Bestiário!", e o botão "Continuar" |
| Debug | "Limpar Bestiário" |
