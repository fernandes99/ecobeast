# 02. Regras dos Domadores

- **Status:** concluída
- **Depende de:** [01-tamer-texts](01-tamer-texts.md), [architecture.md](architecture.md)

## Contexto

As regras ficam em `server/src/domain/`, puras e testadas, antes de qualquer rota. São duas partes: sortear os Domadores (os do mapa e o desafiante do Hub) e a luta contra um deles no motor do tabuleiro, que hoje só conhece selvagens.

O sorteio reaproveita o dos selvagens (`server/src/domain/exploration/spawns.ts`): o peso de cada espécie no bioma (`spawnWeight`), o nível (`wildLevel`) e o bioma de encontro de um hexágono (`encounterBiome`). O motor já tem o `canFlee` e já aceita vagas diferentes por lado.

## Escopo

- `rollMapTamers` e `rollChallenger`, com `TAMER_CONFIG`.
- `opponent: 'tamer'` no motor do tabuleiro: sem Esfera, sem fuga, XP de 1,5× e moedas com bases próprias.

## Fora do escopo

- Guardar os Domadores na exploração e as rotas: vem na [03](03-tamer-api.md).
- A IA do NPC: é a dos selvagens, sem mudança ([board-battle/architecture.md](../board-battle/architecture.md#a-vez-dos-selvagens)). Ela já joga cada Ecobeast do lado inimigo, com qualquer número de vagas.
- A luta antiga (`server/src/domain/battle/engine.ts`): ela não tem tela, e continua só com selvagens.

## Requisitos

### Sorteio

- **RF-01:** `rollMapTamers(tiles, start, species, teamAverage, texts, random, options)` devolve até `config.count` Domadores, seguindo [Domador sorteado, no mapa](architecture.md#no-mapa). `texts` traz os ids de nomes e de falas do catálogo.
- **RF-02:** nenhum Domador nasce num hexágono `wshallow` ou `wdeep`, a até `minStartDistance` hexágonos da largada, ou num hexágono que já tem Domador.
- **RF-03:** cada Ecobeast da equipe usa uma espécie com peso acima de 0 no bioma de encontro do hexágono, e o nível sai do `wildLevel` com o nível natural dela e a média da equipe.
- **RF-04:** sem hexágono possível, o sorteio devolve os que já nasceram, sem erro. Sem espécies, ou sem nomes ou falas, ele devolve uma lista vazia.
- **RF-05:** `rollChallenger(species, teamAverage, texts, random, options)` devolve um Domador sem hexágono, com `id` 0, em que o peso de cada espécie é a soma dos pesos nos 7 biomas de encontro. Sem nenhuma espécie com peso, ele devolve `null`.
- **RF-06:** os ids dos Domadores do mapa começam em 1 e são únicos no mapa.
- **RF-07:** o tamanho é sorteado por `config.sizeWeights`, e a equipe tem exatamente `size` Ecobeasts.

### Luta

- **RF-08:** `BattleState.opponent` é `'wild'` ou `'tamer'`, e o `startBoardBattle` o recebe em `BoardOptions`, com `'wild'` por padrão. Com `'tamer'`, o `canFlee` é sempre `false`.
- **RF-09:** contra Domador, toda ação `capture` é recusada com "Não dá para capturar o Ecobeast de outro Domador.", antes de conferir o item ou o alvo, e a vez não é gasta.
- **RF-10:** contra Domador, o XP de cada Ecobeast derrubado é `floor(xpYield × TAMER_XP_MULTIPLIER)`, com `TAMER_XP_MULTIPLIER = 1.5`, e a divisão entre quem lutou é a de hoje.
- **RF-11:** contra Domador, as moedas usam a conta de hoje com `TAMER_COINS_WIN_BASE = 60` na vitória, por Ecobeast derrubado, e `TAMER_COINS_LOSS_BASE = 15` na derrota. A derrota nunca tira mais do que o Domador tinha no começo.
- **RF-12:** contra selvagem, nada muda: as mesmas recusas, o mesmo XP e as mesmas moedas de hoje.
- **RF-13:** os eventos são os de hoje (`xp_gained`, `coins_gained`, `coins_lost`, `battle_ended`), e não há evento novo.
- **RF-14:** no tabuleiro, as moedas do fim contam quem estava em campo na última vez, inclusive quem acabou de cair. É a regra da [progression/05](../progression/05-wild-coins.md) (RF-01), que o tabuleiro descumpria na derrota: a vaga já vazia contava como nível 1, e um Ecobeast de nível 10 perdia para um selvagem de nível 10 cerca de 50 moedas em vez de 5.

## Critérios de aceite

- [x] Em 20 mapas gerados com `generateMap`, nenhum Domador está na água, perto da largada ou dividindo hexágono, e todos têm equipe do tamanho sorteado.
- [x] Com `sizeWeights` `{1: 0, 2: 0, 3: 1}`, todo Domador tem 3 Ecobeasts.
- [x] Um Domador num hexágono de colina só tem espécies com taxa em `hill`.
- [x] `rollChallenger` sem nenhuma taxa devolve `null`.
- [x] Uma Esfera contra um Ecobeast de Domador é recusada com a mensagem do RF-09, e a fuga com "Não dá para fugir agora.".
- [x] Contra Domador, o `xp_gained` é 1,5× o do mesmo Ecobeast selvagem, arredondado para baixo, e as moedas ficam nas faixas da [arquitetura](architecture.md#luta-contra-domador).
- [x] Os testes de hoje do motor e do spawn passam sem mudança.
- [x] `typecheck`, `lint` e `npm test` sem erros.

## Desenho técnico

Arquivos novos:

- `server/src/domain/tamers/tamer-config.ts`: `TamerConfig` e `TAMER_CONFIG` ([constantes](architecture.md#constantes)).
- `server/src/domain/tamers/tamers.ts`: `RolledTamer`, `MapTamer`, `TamerTexts` (`{ nameIds: number[]; greetingIds: number[] }`), `rollMapTamers` e `rollChallenger`. As opções vão num objeto: `{config, spawnConfig}`, e no `rollChallenger` também `size`, um tamanho fixo no lugar do sorteio, que a rota de depuração da [03](03-tamer-api.md) usa.
- `server/src/domain/tamers/tamers.spec.ts`: os testes do sorteio, com `Random` fixo e uma configuração de teste.

Arquivos alterados:

- `server/src/domain/exploration/spawns.ts`: exportar `pickWeighted`. O resto fica igual.
- `server/src/domain/battle/types.ts`: `BattleState.opponent`. O `makeState` dos testes (`testing.ts`, nas pastas `battle` e `board`) começa com `'wild'`.
- `server/src/domain/battle/capture.ts`: `TAMER_CREATURE = 'Não dá para capturar o Ecobeast de outro Domador.'`.
- `server/src/domain/progression/xp.ts`: `TAMER_XP_MULTIPLIER`. O `xpYield` continua puro, e o multiplicador entra em `awardXp` (`server/src/domain/battle/experience.ts`), pelo `state.opponent`.
- `server/src/domain/progression/coins.ts`: `TAMER_COINS_WIN_BASE` e `TAMER_COINS_LOSS_BASE`. `winCoins` e `lostCoins` recebem a base, com a do selvagem por padrão, e o `settleCoins` escolhe pelo `state.opponent`. O `settleCoins` também recebe quem estava em campo no fim (RF-14), que o `endVez` do tabuleiro guarda antes de quem caiu sair.
- `server/src/domain/board/tamer-battle.spec.ts`: os testes da luta contra Domador.
- `server/src/domain/board/board-engine.ts`: `BoardOptions.opponent`, o `canFlee` desligado contra Domador e a recusa no `captureRefusal`.
- `server/src/domain/battle/engine.ts`: só o `opponent: 'wild'` no estado, para o tipo fechar.
- `.specs/board-battle/architecture.md` e `.specs/progression/architecture.md`: uma linha cada, apontando para a luta contra Domador desta iniciativa.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
```

Feita em 2026-11-09: `typecheck` e `lint` sem erros, e os 717 testes unitários passaram, com 12 novos do sorteio e 8 da luta contra Domador. O critério dos mapas usa 20 mapas, e não 200, para os testes continuarem rápidos. O teste da derrota contra selvagem mostrou o erro do RF-14 (25 moedas tiradas em vez de 5) e passou depois da correção.

## Tarefas

- [x] Testes do sorteio, primeiro falhando.
- [x] `tamer-config.ts` e `tamers.ts`.
- [x] Testes do motor contra Domador: Esfera, fuga, XP, moedas e vagas diferentes por lado.
- [x] `opponent` no estado, no motor, no XP e nas moedas.
- [x] Atualizar as arquiteturas citadas, rodar a verificação e mudar o status aqui e no README.
