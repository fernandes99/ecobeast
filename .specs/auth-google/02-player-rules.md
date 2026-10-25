# 02. Regras do inicial no servidor

- **Status:** rascunho
- **Depende de:** [backend-api](../backend-api/)

## Contexto

Hoje o inicial é gerado no Godot (`res://domain/rules/`: `CreatureFactory`, `StatCalculator`, `XpCurve`), com as regras de [onboarding/architecture.md](../onboarding/architecture.md). Com o jogador no servidor, quem gera a criatura é o NestJS. Esta fase reescreve essas regras em TypeScript, como funções puras (sem banco, sem Nest), testadas com valores conhecidos. A [03](03-player-api.md) as usa; o cliente as perde na [05](05-client-player.md).

## Escopo

- `src/domain/rules/`: `stat-calculator.ts`, `xp-curve.ts`, `creature-factory.ts`, com testes.

## Fora do escopo

- Banco e rotas ([03](03-player-api.md)).
- Regras novas (dano, captura, XP ganho em batalha): são do `battle-core` e da `progression`.

## Requisitos

- **RF-01:** `xp-curve.ts`: `totalXpForLevel(xpMultiplier: number, level: number): number` = `floor(xpMultiplier · level³)`.
- **RF-02:** `stat-calculator.ts`: `calculateStats(base, genes, training, level, temperament): StatBlock`, com `StatBlock = Record<StatSlug, number>`, `StatSlug` = `hp | attack | defense | sp_attack | sp_defense | speed` (os slugs da tabela `stats`) e `temperament = { increasedStat: StatSlug | null, decreasedStat: StatSlug | null }`:
  - HP = `floor((2·base + genes + floor(treino/4)) · nível / 100) + nível + 10`;
  - outros = `floor((floor((2·base + genes + floor(treino/4)) · nível / 100) + 5) · T)`, com T = 1,1 no stat aumentado, 0,9 no diminuído e 1,0 nos demais (temperamento neutro: aumentado igual ao diminuído, ou ambos nulos).
  - A multiplicação por T usa inteiros (`floor(x · 11 / 10)` e `floor(x · 9 / 10)`), para não depender de arredondamento de ponto flutuante.
- **RF-03:** `creature-factory.ts`: `createCreature(params, random): NewCreature`, onde `random: () => number` devolve um número em [0, 1) (em produção, `crypto.randomInt` adaptado; nos testes, uma sequência fixa). `params`: espécie (`id`, `genderRatio`, `baseStats`), `level`, o learnset (`skillId`, método `level_up` ou outro, `level`, na ordem por nível e depois pela ordem da tabela), o PP máximo de cada Técnica, os ids dos Traços **normais** da espécie, os Temperamentos (`id`, aumentado, diminuído) e o `xpMultiplier` da curva. `NewCreature`:
  - `genes`: 0–31 sorteados por stat, na ordem dos slugs;
  - `temperamentId`: sorteado entre todos; `traitId`: sorteado entre os normais;
  - `gender`: `none` se `genderRatio < 0`; senão `male` com probabilidade `genderRatio`, `female` no resto;
  - `skills`: as 4 últimas Técnicas aprendidas por `level_up` com nível ≤ `level`, em ordem, com PP cheio (`slot` 1 a 4);
  - `currentXp = totalXpForLevel(xpMultiplier, level)`; `stats` pelo RF-02 com Treino 0; `currentHp = stats.hp`;
  - `bond = 70`, `isPrismatic = false`, `trainingPoints` 0 em todos os stats.
- **RF-04:** As regras não importam nada do Nest, do Prisma nem de `node:` além de tipos; recebem tudo por parâmetro.

## Critérios de aceite

- [ ] `totalXpForLevel(1.0, 5) = 125`, `(0.8, 5) = 100`, `(1.25, 5) = 156`.
- [ ] Stats: base 39 de HP, Genes 31, Treino 0, nível 5 → 20; base 52 de ataque, Genes 0, nível 5 → 10 (neutro), 11 (aumentado), 9 (diminuído); Treino 252 soma `floor(252/4) = 63` antes da fórmula.
- [ ] Com uma sequência fixa de `random`, `createCreature` dá sempre a mesma criatura, e cada campo bate com o esperado na mão.
- [ ] Um learnset com 6 Técnicas até o nível 5 dá as 4 últimas; um com Técnica de método diferente de `level_up` não a inclui; `genderRatio = -1` dá `none`; Traço oculto nunca sai.
- [ ] `npm run lint`, `npm run typecheck` e `npm test` passam.

## Desenho técnico

**Criar**

- `server/src/domain/rules/stat-calculator.ts`, `xp-curve.ts`, `creature-factory.ts`, `types.ts` (`StatSlug`, `StatBlock`, `STAT_SLUGS`), cada um com `*.spec.ts`.

**Reaproveitar**

- As fórmulas e regras de `client/domain/rules/*.gd` e de [onboarding/architecture.md](../onboarding/architecture.md), que continuam sendo a referência até a [05](05-client-player.md).

## Verificação

```bash
cd server && npm test
```

## Tarefas

- [ ] Testes de `xp-curve` e `stat-calculator` com os valores dos critérios; rodar e ver falhar; implementar (RF-01, RF-02).
- [ ] Testes de `creature-factory` com `random` fixo; rodar e ver falhar; implementar (RF-03, RF-04).
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: regras do inicial no servidor`.
