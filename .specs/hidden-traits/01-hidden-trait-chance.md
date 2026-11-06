# 01. A chance de nascer com o Traço oculto

- **Status:** concluída
- **Depende de:** [auth-google/02](../auth-google/02-player-rules.md) (a fábrica de criaturas no servidor)

## Contexto

Ver o [README](README.md). A criatura nova sai de `createCreature` (`server/src/domain/rules/creature-factory.ts`), com os dados que `loadCreatureBlueprint` (`server/src/player/creature-params.ts`) lê do banco. O inicial (`player.service.ts`) e o selvagem da luta (`battle-records.service.ts`) passam pelos dois.

## Requisitos

- **RF-01:** `createCreature` recebe, além dos Traços normais (`traitIds`), o Traço oculto da espécie (`hiddenTraitId`, ou `null` sem ele).
- **RF-02:** Com um Traço oculto, depois do Temperamento sai um sorteio: abaixo de `HIDDEN_TRAIT_CHANCE` (1/20), a criatura nasce com o oculto e o Traço normal não é sorteado; senão, o Traço normal é sorteado como antes. A ordem passa a ser: Genes, Temperamento, chance do oculto (só com ele), Traço normal (só sem o oculto) e gênero.
- **RF-03:** Sem Traço oculto, a sequência dos sorteios e o resultado são os de antes.
- **RF-04:** `loadCreatureBlueprint` lê todos os Traços da espécie: os normais vão para `traitIds`, o oculto para `hiddenTraitId`, e o mapa `traitSlugs` tem os dois, para a luta achar o slug do oculto.
- **RF-05:** Uma espécie só com o Traço oculto continua recusada, com a mensagem de hoje: ela precisa de um normal.

## Critérios de aceite

- [x] Os testes da fábrica mostram o oculto com o sorteio abaixo de 1/20 e o normal com 1/20 ou mais.
- [x] Os testes de antes da fábrica passam sem mudar.
- [x] A suíte do servidor (unitária e e2e) passa.

## Desenho técnico

- `server/src/domain/rules/creature-factory.ts`: `HIDDEN_TRAIT_CHANCE = 1 / 20`, exportada; `hiddenTraitId?: number | null` em `CreateCreatureParams`.
- `server/src/player/creature-params.ts`: sem o filtro `isHidden: false`; separa os normais e o oculto pela coluna `is_hidden`.
- A spec [auth-google/02](../auth-google/02-player-rules.md) ganha uma nota com a ordem nova dos sorteios.

## Verificação

- `npm test` e `npm run test:e2e` em `server/`.

## Tarefas

- [x] Testes da chance, vendo falhar.
- [x] `createCreature` e `loadCreatureBlueprint`.
- [x] Suíte do servidor.

## Resultado da verificação

Em 2026-11-06, os 5 testes novos da fábrica (a chance de 1/20, o oculto abaixo dela sem sortear o normal, o normal na chance ou acima, a sequência de antes sem oculto e a espécie só com o oculto recusada) falharam antes do código, 3 deles pela regra que faltava, e passaram depois. A checagem de tipos e o lint passaram, e a suíte do servidor deu 695 testes unitários e 384 e2e, todos passando.
