# Arquitetura

O desenho que as fases da [npc-tamers](README.md) compartilham. O que não aparece aqui segue a [board-battle/architecture.md](../board-battle/architecture.md) (o tabuleiro, a fila, a IA, as entradas) e a [biome-encounters/architecture.md](../biome-encounters/architecture.md) (o mapa, a exploração guardada, a conferência da posição).

## Fluxo

```text
Entrar em Explorar  →  POST /v1/me/exploration
                       gera o mapa, sorteia os 500 Ecobeasts e os 25 Domadores
                       devolve, de cada Domador, só id, hexágono, nome e fala (ids do catálogo)

Andar pelo mapa     →  nada vai para o servidor
Entrar no hexágono  →  o jogo trava o mapa e mostra "Lia: O que está fazendo aqui? ..." no log
de um Domador
Tocar no log        →  POST /v1/me/board-battle/tamer { q, r }
                       o servidor confere a posição, tira o Domador do mapa e abre a luta

Voltar da luta      →  vitória: o mapa, sem o Domador
                       derrota: o Hub; o servidor já apagou a exploração

Desafiar, no Hub    →  POST /v1/me/board-battle/challenge
                       sorteia um Domador na hora e abre a luta; no fim, volta ao Hub
```

## Catálogo

Duas tabelas novas no schema `ecobeasts`, editáveis pelo painel ([01](01-tamer-texts.md)):

| Tabela | Colunas | O que é |
| --- | --- | --- |
| `npc_tamer_names` | `id`, `name` | Os nomes que um Domador sorteado pode ter |
| `npc_tamer_greetings` | `id`, `text` | As falas do desafio, sem o nome na frente |

Elas entram no `GET /v1/catalog`, como as outras, e o jogo monta a linha `"{name}: {text}"`. O nome `npc_tamers` fica reservado para a equipe fixa, numa iniciativa futura.

## Domador sorteado

```ts
/** Um Domador no mapa ou do Desafiar. A equipe nasce junto, para o NPC não mudar entre o mapa e a luta. */
interface RolledTamer {
  id: number;            // único na exploração; 0 no Desafiar
  nameId: number;        // npc_tamer_names.id
  greetingId: number;    // npc_tamer_greetings.id
  size: 1 | 2 | 3;       // o tamanho da luta, e o da equipe dele
  team: { speciesId: number; level: number }[]; // length === size
}

interface MapTamer extends RolledTamer, HexCoord {
  debug?: boolean;       // posto pelo botão de depuração
}
```

As regras ficam em `server/src/domain/tamers/` ([02](02-tamer-rules.md)), puras, com o `Random` injetado, e reaproveitam o que a `biome-encounters` já tem em `server/src/domain/exploration/spawns.ts`: `encounterBiome`, `spawnWeight`, `wildLevel` e o `pickWeighted`, que passa a ser exportado.

### No mapa

`TAMER_CONFIG.count` vezes, num mapa já gerado:

1. **Hexágonos possíveis:** os de terra (o bioma do hexágono não é `wshallow` nem `wdeep`), a mais de `minStartDistance` hexágonos da largada e ainda sem Domador, cujo bioma de encontro tem pelo menos uma espécie com peso acima de 0. Sem nenhum, o sorteio para ali, e o mapa fica com menos Domadores.
2. **Hexágono:** um deles, com a mesma chance.
3. **Tamanho:** 1, 2 ou 3, pelos pesos de `sizeWeights`.
4. **Equipe:** para cada vaga, uma espécie pelo peso dela no bioma de encontro do hexágono (`spawnWeight`, com a média da equipe do jogador) e o nível pelo `wildLevel`. A mesma espécie pode repetir.
5. **Nome e fala:** um id de cada tabela, com a mesma chance.

### No Desafiar

O mesmo, sem hexágono: o peso de cada espécie é a soma dos pesos dela nos 7 biomas de encontro, e o `wildLevel` decide o nível. Sem nenhuma espécie com peso, não há desafiante, e a rota responde com erro.

### Constantes

Em `server/src/domain/tamers/tamer-config.ts`, `TAMER_CONFIG`, _a revisar_:

| Parâmetro | Valor | O que faz |
| --- | ---: | --- |
| `count` | 25 | Domadores por mapa |
| `minStartDistance` | 3 | Hexágonos livres de Domador em volta da largada |
| `sizeWeights` | `{1: 1, 2: 1, 3: 1}` | A chance de cada tamanho de luta |

Os testes têm uma configuração própria, como os do spawn.

## Luta contra Domador

O motor do tabuleiro é o mesmo. O `BattleState` ganha `opponent: 'wild' | 'tamer'`, `'wild'` por padrão, e o `startBoardBattle` o recebe nas opções. Com `'tamer'`:

| Regra | Como |
| --- | --- |
| Sem fuga | `canFlee: false`, que o motor já confere: "Não dá para fugir agora." |
| Sem Esfera | A captura é recusada antes de tudo: "Não dá para capturar o Ecobeast de outro Domador." |
| XP | `floor(xpYield × TAMER_XP_MULTIPLIER)`, com `TAMER_XP_MULTIPLIER = 1.5`, antes da divisão entre quem lutou |
| Moedas da vitória | A conta de hoje (`rollCoins`), por Ecobeast derrubado, com `TAMER_COINS_WIN_BASE = 60` |
| Moedas da derrota | A conta de hoje, com `TAMER_COINS_LOSS_BASE = 15`, sem passar das moedas do Domador |
| Vagas | O inimigo tem `size` vagas. O jogador tem `min(size, Ecobeasts de pé na equipe)` |

Os valores são _a revisar_ e ficam ao lado dos do selvagem: o multiplicador em `server/src/domain/progression/xp.ts` e as bases em `coins.ts`. Os eventos são os de hoje, e os resultados possíveis são só `victory` e `defeat`.

Exemplos de moedas (vitória por Ecobeast derrubado, derrota uma vez):

| Ecobeast do NPC | Em campo no fim | Vitória | Derrota |
| --- | --- | --- | --- |
| 5 | 5 | 30 a 90 | 7 a 22 |
| 10 | 10 | 30 a 90 | 7 a 22 |
| 10 | 5 | 60 a 180 | 15 a 45 |

Um 3×3 de nível 10 contra uma equipe de nível 10 paga de 90 a 270 moedas.

## Exploração no servidor

O `StoredExploration` ganha os Domadores:

```ts
interface StoredExploration {
  spawns: Map<number, MapSpawn>;
  tamers: Map<number, MapTamer>; // novo: sai daqui quando a luta começa
  position: HexCoord;
  positionAt: number;
}
```

O Domador sai do mapa quando a luta começa, como o selvagem: fechar o app no meio não dá uma segunda chance. A conferência da posição é a mesma do `takeSpawn` (`MIN_STEP_MS` por hexágono), e as duas passam a usar o mesmo código.

Na derrota contra um Domador do mapa, o fim da luta apaga a exploração do jogador (`ExplorationStore.delete`). A vitória mantém a exploração. A luta do Desafiar não mexe na exploração.

## Contrato

`POST /v1/me/exploration` ganha `tamers` no `map`, sem a equipe nem o tamanho:

```json
{
  "map": {
    "creatures": [{ "id": 1, "species_id": 7, "q": 3, "r": -2 }],
    "tamers": [{ "id": 1, "q": 8, "r": -5, "name_id": 4, "greeting_id": 2 }]
  }
}
```

Rotas novas no `BoardBattleController` ([03](03-tamer-api.md)):

| Rota | Corpo | O que faz |
| --- | --- | --- |
| `POST /v1/me/board-battle/tamer` | `{ q, r, god? }`, como `/board-battle/wild` | A luta contra o Domador do hexágono do jogador |
| `POST /v1/me/board-battle/challenge` | nenhum | A luta do Desafiar, contra um Domador sorteado na hora |
| `POST /v1/me/exploration/tamers` | `{ q, r, size }` | Só com `ENABLE_TEST_BATTLE`: põe um Domador do tamanho pedido no hexágono, com a equipe sorteada como a do Desafiar |

A resposta das lutas é a de hoje, `{battle, events, captured_to, spawn_id, progression}`, mais `tamer_id`: o Domador que saiu do mapa, ou `null`. O `battle` ganha `tamer: { name_id, source } | null`, com `source` `map` ou `challenge`, em todas as respostas da luta, inclusive as do `/board-battle/action`: o jogo dá nome ao adversário e sabe para onde voltar.

| Falha | Status | Mensagem |
| --- | --- | --- |
| Corpo inválido | 400 | "Posição inválida." |
| Sem exploração guardada | 404 | "Essa exploração acabou. Saia e entre de novo." |
| Posição impossível | 409 | "Você não chegou até aí." |
| Nenhum Domador no hexágono | 409 | "Nenhum Domador por aqui." |
| Procurar (`/board-battle/wild`) num hexágono com Domador | 409 | "Um Domador está esperando você aqui." |
| Nenhum desafiante possível (Desafiar) | 409 | "Nenhum Domador quer lutar agora." |
| Sem Domador, ou equipe sem HP | 409 | As mensagens de hoje |

## Jogo

- **Modelos:** `MapTamer` em `res://domain/models/` (id, `coord`, `name_id`, `greeting_id`), e o `ExplorationMap` ganha `tamers: Dictionary[int, MapTamer]` e `tamer_at(coord)`. O catálogo ganha `NpcTamerName` e `NpcTamerGreeting`, lidos pelo `GameData`. O `BoardBattleView` ganha `tamer_name_id` (0 sem Domador).
- **No mapa:** cada Domador perto do jogador é um `NpcTamerSprite`, com as folhas do `TamerSprite`, passeando no hexágono como o `CreatureSprite`. O passeio, que hoje só o `CreatureSprite` tem, sai para uma peça que os dois usam, sem mudar o comportamento dos Ecobeasts.
- **A fala:** ao chegar num hexágono com Domador, o mapa trava, e um painel no estilo do log da luta (`BattleTheme.LOG`) escreve a fala letra por letra. Tocar nele abre a luta.
- **A luta:** a tela `board_battle` recebe `tamer_coord` (mapa) ou `challenge: true` (Hub). Contra Domador, ela não mostra Fugir nem Esferas, e o narrador troca "Um Ruvo selvagem apareceu!" por "Lia enviou Ruvo!".
- **A volta:** derrota contra Domador do mapa leva ao Hub com `Router.go_to(&"hub")`. As outras voltas são o `Router.back()` de hoje.
