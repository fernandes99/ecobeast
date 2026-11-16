# 01. As regras do campo: Atordoado, marcas que mudam atributos, vários golpes e dano fixo

- **Status:** concluída
- **Depende de:** [board-battle](../board-battle/) (as marcas e o fim da vez)

## Contexto

O dono pediu Técnicas que mexem no campo da luta, com um estado novo de atordoamento e com a Precisão e a Evasão baixando em quem passa pelo campo afetado ([README](README.md#decisões)). Hoje uma marca no chão (`ground_effects`) só tira uma porcentagem do HP ou tenta aplicar um estado, depois de cada vez da fila, em quem está no hexágono. Os estados são regras no código (`server/src/domain/battle/status.ts`), uma por `slug`.

A Rajada de Penas, que o dono pediu depois, dá de 2 a 5 golpes de 15 de dano fixo. O catálogo já tem `skills.min_hits`, `skills.max_hits` e o efeito `fixed_damage` (com `value`), e o editor de Técnicas do F1 já os grava. Mas o motor ignora os golpes e não tem regra para o dano fixo (`server/src/domain/battle/actions.ts` e `effects.ts`).

Esta fase cria as regras no servidor e as duas marcas que as Técnicas da [03](03-puffcoo-line.md) vão usar. Nenhuma Técnica usa as marcas ainda, e o jogo só mostra as marcas novas na [02](02-field-screen.md).

## Escopo

- O estado Atordoado (`dazed`): o catálogo, a regra, a imunidade do Vento e o campo na vista da luta.
- A tabela `ground_effect_stats` e a regra da marca que muda atributos.
- As marcas Penas no ar e Redemoinho no catálogo.
- Os vários golpes (`min_hits` e `max_hits`) e o dano fixo (`fixed_damage`) no motor.
- A IA do tabuleiro com o Atordoado e com o dano fixo.

## Fora do escopo

- As Técnicas que criam as marcas, que entram na [03](03-puffcoo-line.md).
- Qualquer mudança no jogo (Godot), que fica para a [02](02-field-screen.md).
- Mudar o Chão em chamas ou a ordem do fim da vez para as marcas de dano e de estado.

## Requisitos

**Atordoado**

- **RF-01:** `status_conditions` ganha a linha `{ id: 9, slug: "dazed", name: "Atordoado", is_volatile: true }`, e `status_condition_immunities` ganha `{ status_condition_id: 9, element_id: 6 }`: o Vento não fica atordoado.
- **RF-02:** Aplicar `dazed` marca o Ecobeast como atordoado (`Combatant.isDazed`). Se ele já está atordoado, o efeito falha (`effect_failed`), como na confusão. Um Ecobeast imune também recebe o `effect_failed` de hoje.
- **RF-03:** Na vez dele, um Ecobeast atordoado não anda. Um pedido com `move` é recusado com 400 e a mensagem "Atordoado: não dá para andar nesta vez.", e nada muda na luta. Ele ainda pode usar uma Técnica ou um item, trocar, usar uma Esfera, fugir ou passar.
- **RF-04:** No fim da vez de quem está atordoado, antes de as marcas agirem, ele deixa de estar atordoado, com o evento `status_ended` (`status: "dazed"`). Isso vale mesmo se ele perdeu a vez por sono, congelamento, paralisia ou medo.
- **RF-05:** O Atordoado é volátil: sai ao desmaiar, ao sair do tabuleiro numa troca e no fim da luta (`clearVolatile`).
- **RF-06:** A vista de cada Ecobeast na luta ganha `dazed: boolean`, ao lado de `status` e `confused`.

**Marcas que mudam atributos**

- **RF-07:** A tabela nova `ground_effect_stats` guarda o que cada marca muda nos estágios:
  - colunas `ground_effect_id` (FK `ground_effects`), `stat_id` (FK `stats`) e `stages` (inteiro de −6 a 6, sem 0);
  - a chave é (`ground_effect_id`, `stat_id`);
  - vai para o catálogo (`GET /v1/catalog`) e para o painel do Supabase como as outras tabelas.
- **RF-08:** No fim da vez, as marcas agem na ordem de hoje. A parte de atributos de uma marca só age em **quem acabou de jogar**, se ele está de pé no hexágono marcado. Para cada linha de `ground_effect_stats`, ele recebe a mudança de estágio, com o limite de ±6 e o evento `stat_changed` de hoje. Quando o estágio já está no limite, nada acontece e não há evento. O dano e o estado da marca continuam agindo em todos que estão nela, depois de cada vez, como hoje.
- **RF-09:** O motor de batalha recebe as linhas de `ground_effect_stats` junto com a marca (`BattleGroundEffect.stats`, com o `slug` do atributo e os estágios).

**As marcas novas** (_a revisar_)

- **RF-10:** `ground_effects` ganha duas linhas:

  | id | slug | name | damage_percent | status_condition_id | color_hex | Atributos (`ground_effect_stats`) |
  | --- | --- | --- | --- | --- | --- | --- |
  | 2 | `feathers` | Penas no ar | — | — | `#D9EFE8` | Precisão −1, Evasão −1 |
  | 3 | `whirlwind` | Redemoinho | — | 9 (Atordoado) | `#7CC9B8` | — |

  Com o RF-04 e o RF-08, quem termina a vez no Redemoinho fica atordoado de novo e não consegue sair dele até a marca acabar, a não ser que seja de Vento. Quem para nas Penas no ar perde 1 de Precisão e 1 de Evasão a cada vez que termina ali.

**IA**

- **RF-11:** Um Ecobeast da IA que está atordoado não tenta andar: escolhe a Técnica ou espera de onde está. Para escolher o hexágono, a IA continua preferindo os hexágonos sem marca, como hoje, e isso inclui as marcas novas. A IA conta uma Técnica com `fixed_damage` como Técnica de dano, mesmo com poder 0, e estima o dano como `value` × a média de `min_hits` e `max_hits`.

**Vários golpes e dano fixo** (_a revisar_ o sorteio)

- **RF-12:** Uma Técnica com `max_hits` maior que 1 sorteia, para cada alvo, o número de golpes entre `min_hits` e `max_hits`, cada número com a mesma chance. O comportamento muda assim:
  - a Precisão é sorteada uma vez por alvo, e um erro anula todos os golpes nele;
  - cada golpe é um evento `damage`, com o crítico sorteado a cada golpe;
  - os golpes param quando o alvo desmaia;
  - depois do último golpe vem o evento novo `multi_hit`, com `side`, `position` (do alvo) e `hits` (quantos golpes acertaram);
  - os efeitos da Técnica agem uma vez, depois do último golpe, com o dano somado.

  Uma Técnica de um golpe só continua como hoje, sem `multi_hit`.
- **RF-13:** Numa Técnica com o efeito `fixed_damage`, cada golpe tira exatamente `value` de HP, no máximo o HP atual. Isso vale mesmo com poder 0, e o golpe:
  - ignora o Ataque, a Defesa, o crítico, a variação do dano e a vantagem de Elemento;
  - não acontece num alvo de Elemento imune ao da Técnica (multiplicador 0), que recebe o `no_effect` de hoje;
  - sai no evento `damage` com `multiplier: 1` e `is_critical: false`;
  - continua derrubando o alvo no primeiro golpe com o modo deus do jogador.

  O `fixed_damage` não age de novo entre os efeitos do fim do golpe (`applyEffects`).
- **RF-14:** `BattleSkill` ganha `minHits` e `maxHits`, carregados do catálogo pelo `battle-catalog.ts`. As Técnicas de hoje têm 1 e 1, então nada muda para elas.

## Critérios de aceite

- [x] Um teste mostra que um Ecobeast atordoado não anda (400 com a mensagem), age, e no fim da vez recebe o `status_ended` do `dazed`.
- [x] Um teste mostra que um Ecobeast de Vento recebe `effect_failed` ao ser atordoado.
- [x] Um teste mostra que, numa luta de 2×2 com dois Ecobeasts nas Penas no ar, cada um perde 1 de Precisão e 1 de Evasão só no fim da própria vez, e não a cada vez da fila.
- [x] Um teste mostra que quem termina a vez no Redemoinho está atordoado na vez seguinte, e que o Chão em chamas continua tirando HP de todos depois de cada vez.
- [x] Um teste mostra que a IA atordoada não manda `move`.
- [x] Um teste mostra que uma Técnica de 2 a 5 golpes com `fixed_damage` de 15:
  - gera de 2 a 5 eventos `damage` de 15 e o `multi_hit`;
  - para no golpe que derruba o alvo;
  - não gera nenhum golpe quando a Precisão erra.
- [x] Um teste mostra que o dano fixo ignora o crítico e a vantagem de Elemento, mas não a imunidade.
- [x] Um teste mostra que a IA escolhe uma Técnica de dano fixo de poder 0 como Técnica de dano.
- [x] `GET /v1/catalog` traz `ground_effect_stats` com as duas linhas das Penas no ar, os ground effects 2 e 3 e o status 9.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Desenho técnico

- **Banco:**
  - migration nova em `server/prisma/migrations/20261221000000_field_marks/`, com SQL à mão e `migrate deploy`. Ela cria `ground_effect_stats` e insere as linhas do RF-01 e do RF-10;
  - `server/prisma/schema.prisma` ganha o `GroundEffectStat` e as relações;
  - `server/prisma/seed-data/` atualiza `status_conditions.json`, `status_condition_immunities.json` e `ground_effects.json` e ganha `ground_effect_stats.json`. A tabela nova entra no `seed.ts` e no `seed-plan.ts`.
- **Catálogo:** a tabela entra em `server/src/catalog/catalog-tables.ts` (com o spec). `server/src/battle/battle-catalog.ts` carrega os atributos da marca para o `BattleGroundEffect.stats` (com o spec).
- **Motor:**
  - em `server/src/domain/battle/`: o `types.ts` ganha `Combatant.isDazed` e o `stats` do `BattleGroundEffect`; o `status.ts` cuida do `dazed` no `setStatus` e no `clearVolatile`;
  - em `server/src/domain/battle/`: o `actions.ts` cuida dos golpes e do dano fixo (RF-12 e RF-13) no `resolveSkill` e no `strike`; o `effects.ts` deixa o `fixed_damage` de fora do `applyEffects`; o `ai.ts` (`skillWeight`) e o filtro de Técnicas de dano do `board/board-ai.ts`, que hoje olha `power > 0`, cuidam do RF-11;
  - em `server/src/domain/board/`: o `board-engine.ts` recusa o `move` (RF-03) e tira o atordoamento no `endVez`, antes do `applyMarks` (RF-04), passando quem jogou ao `applyMarks`. O `marks.ts` ganha a parte dos atributos (RF-08), reaproveitando o `changeStage` de `domain/battle/effects.ts`. O `board-ai.ts` cuida do RF-11.
- **Vista:** `dazed` no `toView` de `server/src/battle/battle.mapper.ts` e no DTO da vista em `server/src/board-battle/board-battle.dto.ts` (Swagger). O `isDazed: false` entra onde o `isTrapped` é criado (`battle.mapper.ts` e `domain/battle/testing.ts`).
- **Testes:** `status.spec.ts`, `actions` (no `engine.spec.ts` ou num `actions.spec.ts` novo), `ai.spec.ts`, `board-engine.spec.ts`, `board-ai.spec.ts`, `battle-catalog.spec.ts` e a contagem de tabelas do `test/database.e2e-spec.ts`.
- **Documentos:**
  - no [board-battle/architecture.md](../board-battle/architecture.md#marcas-no-chão), a linha de `ground_effect_stats` e a regra de quem acabou de jogar;
  - no `GDD.md`, o Atordoado na lista de status voláteis e a regra dos vários golpes e do dano fixo;
  - no [board-battle/architecture.md](../board-battle/architecture.md), o evento `multi_hit` na lista de eventos;
  - no [glossary.md](../glossary.md), o Atordoado, se a lista de estados estiver lá.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

No painel F3 da luta ([board-battle/23](../board-battle/23-battle-effect-states.md)), as marcas novas já aparecem pelo `ground_effects`. Pôr o Redemoinho embaixo de um Ecobeast do jogador e conferir que ele não consegue andar na vez seguinte. O desenho fica para a [02](02-field-screen.md).

## Tarefas

- [x] Migration, schema e seed-data.
- [x] `ground_effect_stats` no catálogo e no motor.
- [x] O Atordoado: regra, andar recusado, fim na vez e vista.
- [x] A parte de atributos das marcas.
- [x] A IA atordoada.
- [x] Os vários golpes e o dano fixo, com a IA.
- [x] Testes de unidade e e2e.
- [x] `board-battle/architecture.md`, `GDD.md`, o README da iniciativa e as tabelas das specs.

Conferido por Claude: lint, typecheck, 974 testes de unidade e os e2e passam, e a migration foi aplicada no banco. O jogo ainda não desenha o Atordoado: isso é a [02](02-field-screen.md). Diferença do desenho: o `isImmune` e o `hasStatus` saíram do `status.ts` para a marca pular, sem evento, quem já tem o status ou é imune (antes, a marca só tentava em quem não tinha status principal, e um queimado nunca ficaria atordoado). Os testes de golpes e dano fixo ficaram num `actions.spec.ts` novo.
