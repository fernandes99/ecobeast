# 02. Técnicas e evolução no servidor

- **Status:** concluída
- **Depende de:** [01-xp-and-levels](01-xp-and-levels.md), [architecture.md](architecture.md)

## Contexto

Com a [01](01-xp-and-levels.md), a vitória sobe o nível, mas as Técnicas e a espécie não mudam. Esta fase faz o servidor ensinar as Técnicas liberadas, guardar as que precisam de escolha, oferecer a evolução e receber as escolhas do jogador. A tela vem na [04](04-evolution-and-skills-screens.md).

## Escopo

- As Técnicas liberadas entre o nível antigo e o novo: aprendidas se houver vaga, pendentes se não houver.
- A oferta de evolução por nível.
- O `ProgressionStore` com as escolhas pendentes.
- As rotas `POST /v1/me/creatures/:uid/evolution` e `POST /v1/me/creatures/:uid/skills`.

## Fora do escopo

- Gatilhos de evolução que não sejam `level`.
- Reaprender uma Técnica, as Técnicas `teachable` e o registro no Bestiário.
- Guardar as escolhas pendentes no banco.

## Requisitos

- **RF-01:** sem evolução oferecida, as Técnicas são as `level_up` da espécie em `level_before < level ≤ level_after`, na ordem do nível e depois do `skill_id`, sem as que o Ecobeast já conhece e sem repetição.
- **RF-02:** enquanto houver menos de 4 Técnicas, a próxima da lista é aprendida com o PP cheio e vai para `learned_skill_ids`. As que sobram vão para `pending_skill_ids`.
- **RF-03:** as Técnicas aprendidas com vaga são gravadas na mesma transação do fim da luta.
- **RF-04:** há oferta de evolução quando o Ecobeast subiu de nível e a espécie tem uma linha de `evolutions` com o gatilho `level` e `min_level ≤ level_after`. Com mais de uma linha, vale a de menor `id`.
- **RF-05:** com oferta, a `progression` traz `evolution: { species_id }` e as duas listas de Técnicas vazias.
- **RF-06:** o fim de cada vitória substitui as escolhas pendentes do jogador no `ProgressionStore` pelas da luta nova. Quem não tem nada pendente não entra.
- **RF-07:** `POST …/evolution` com `accept: true` troca a espécie e o Traço, recalcula os stats e sobe o HP atual o mesmo tanto que o máximo, com o resto do Ecobeast igual. Depois calcula as Técnicas com as linhas `evolution` da espécie nova e as `level_up` dela no intervalo, com as regras do RF-01 e do RF-02.
- **RF-08:** `POST …/evolution` com `accept: false` mantém a espécie e calcula as Técnicas da espécie antiga no intervalo.
- **RF-09:** a resposta da evolução traz `creature`, `learned_skill_ids` e `pending_skill_ids`. As aprendidas já estão gravadas, e as pendentes ficam no `ProgressionStore`.
- **RF-10:** `POST …/skills` com `forget_skill_id` troca a Técnica esquecida pela nova, na mesma vaga e com o PP cheio. Com `forget_skill_id: null`, nada muda. Nos dois casos, o `skill_id` sai das pendentes.
- **RF-11:** as falhas seguem a tabela do [contrato](architecture.md#contrato): 404 sem escolha pendente, 400 com uma Técnica que ele não conhece e 409 quando a evolução ainda não foi decidida.
- **RF-12:** uma Técnica pendente só pode ser escolhida pelo dono do Ecobeast. Outro jogador recebe o mesmo 404.
- **RF-13:** quem cancelou a evolução recebe a oferta de novo na próxima vitória em que subir de nível.

## Critérios de aceite

- [x] Um Ruvo com 2 Técnicas que passa por um nível com Técnica nova termina com 3, e ela vem em `learned_skill_ids`.
- [x] Um Ruvo com 4 Técnicas recebe a nova em `pending_skill_ids`, e as Técnicas dele não mudam até a escolha.
- [x] Escolher esquecer uma Técnica põe a nova na mesma vaga, com o PP cheio. `GET /v1/me` mostra a troca.
- [x] Escolher não aprender deixa as 4 Técnicas iguais. A mesma escolha de novo dá 404.
- [x] Um Ruvo que chega ao nível 16 recebe `evolution: { species_id: 2 }`. Aceitar o transforma em Ruvak com o mesmo apelido, nível, XP, Genes e Temperamento, os stats do Ruvak e a Técnica de evolução do Ruvak (aprendida ou pendente).
- [x] Cancelar mantém o Ruvo. Na próxima vitória em que ele subir de nível, a oferta volta.
- [x] Escolher uma Técnica de um Ecobeast com evolução não decidida dá 409.
- [x] Um `uid` de outro jogador dá 404.
- [x] Uma escolha da luta anterior dá 404 depois de uma nova vitória.

## Desenho técnico

- **Criar** `server/src/domain/progression/learnset.ts`:
  - `skillsBetween(learnset, levelBefore, levelAfter)`.
  - `evolutionSkills(learnset)`.
  - `learnNewSkills(known: number[], candidates: number[]): { learned: number[]; pending: number[] }`.
  - O formato da linha de `learnset` segue o `LearnsetEntry` de `server/src/domain/rules/creature-factory.ts`, com o método.
- **Criar** `server/src/domain/progression/evolution.ts`:
  - `evolutionOffer(speciesId, levelBefore, levelAfter, evolutions): number | null`.
  - `evolvedTraitId(oldRow, newSpeciesTraits): number`, pelas regras do [architecture.md](architecture.md#evolução).
  - Os testes ficam ao lado de cada arquivo.
- **Criar** `server/src/progression/`, com `progression.store.ts`, `progression.service.ts`, `progression.controller.ts`, `progression.dto.ts` e `progression.module.ts`. O módulo exporta o store, e o `BattleModule` o importa, como faz com o `ExplorationModule`.
- **Alterar** `server/src/battle/battle.service.ts`: no fim da vitória, calcula a oferta de evolução e, sem oferta, as Técnicas. Grava as aprendidas no `saveTeam` e preenche o store.
- O cálculo das Técnicas, o de stats e o de HP ficam em funções que o `BattleService` e o `ProgressionService` dividem, para as duas rotas não divergirem.
- **Alterar** `server/src/app.module.ts`: registra o `ProgressionModule`.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test
cd server && npm run test:e2e
```

E2e em `server/test/progression.e2e-spec.ts`, com cada critério de aceite acima. Para chegar perto do nível 16 sem vencer dezenas de lutas, o teste grava o `current_xp` e o `level` direto no banco antes da luta, como os outros e2e já fazem com o HP.

## Tarefas

- [x] `learnset.ts` e `evolution.ts`, com testes
- [x] `ProgressionStore`
- [x] Técnicas e oferta de evolução no fim da vitória
- [x] Rotas de evolução e de Técnica, com o DTO e a doc
- [x] E2e, e status e tabelas atualizados
