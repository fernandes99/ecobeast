# 05. Rotas do catálogo

- **Status:** rascunho
- **Depende de:** [04-species-api](04-species-api.md)

## Contexto

As peças comuns (paginação, referência, id ou slug, erros, limite de chamadas) e as rotas de espécies existem desde a [04](04-species-api.md). Esta fase aplica o mesmo padrão aos demais recursos do catálogo e cria a lista de iniciais. Assim todo o catálogo fica navegável pela API e pela Scalar.

## Escopo

- Lista paginada e detalhe de: `skills`, `elements`, `traits`, `temperaments`, `stats`, `growth-rates`, `rarities`, `status-conditions`, `skill-categories`, `skill-targets`, `skill-learn-methods`, `effect-types` e `evolution-triggers`.
- `GET /v1/starters`.

## Fora do escopo

- Rotas próprias para tabelas de junção (`element_efficacy`, `species_elements`…): elas aparecem dentro dos recursos.
- O catálogo inteiro numa chamada ([06](06-catalog-bundle.md)).

## Requisitos

- **RF-01:** Todo recurso abaixo tem `GET /v1/<recurso>`, com a lista paginada de referências em ordem de `id` (como em [04](04-species-api.md), RF-01 a RF-03), e `GET /v1/<recurso>/{idOrSlug}`, com `404` "<Recurso> não encontrado: <param>" quando não existe. O nome do recurso na mensagem vai em pt-BR: "Técnica", "Elemento", "Traço", "Temperamento", "Stat", "Curva de XP", "Raridade", "Status", "Categoria de Técnica", "Alvo de Técnica", "Método de aprendizado", "Tipo de efeito" e "Gatilho de Ascensão".
- **RF-02:** Detalhes com mais que `id`, `slug` e `name`:
  - `skills`: `description`, `element`, `category` (de `skill_category_id`), `target` (de `skill_target_id`), `power`, `accuracy`, `max_pp`, `priority`, `crit_stage`, `makes_contact`, `min_hits`, `max_hits` e `effects`. Cada efeito é `{ sort_order, effect_type, chance, target, status_condition, stat, stages, percent, value, weather_id, min_turns }`, em ordem de `sort_order`; as referências ausentes são `null`.
  - `elements`: `color_hex`, `is_rare` e `efficacy: { attacking: [{ element, multiplier }], defending: [{ element, multiplier }] }`. São as linhas de `element_efficacy` em que ele é atacante e defensor, por `id` do outro Elemento. O que não aparece vale 1. Tem também `immune_to_status: [status]` (de `status_condition_immunities`).
  - `traits`: `description` e `species: [{ species, slot, is_hidden }]`, por espécie.
  - `temperaments`: `increased_stat`, `decreased_stat`.
  - `stats`: `short_name`, `is_battle_only`.
  - `growth-rates`: `xp_multiplier`.
  - `rarities`: `sort_order`.
  - `status-conditions`: `is_volatile` e `immune_elements: [element]`.
  - `skill-categories`, `skill-targets`, `skill-learn-methods`, `effect-types`, `evolution-triggers`: só `id`, `slug` e `name`.
- **RF-03:** As referências usam o nome da rota do recurso citado (`/v1/skill-categories/2`, `/v1/growth-rates/1`).
- **RF-04:** `GET /v1/starters` devolve `{ results: [{ sort_order, species }] }` em ordem de `sort_order`, sem paginação.
- **RF-05:** Os recursos que têm só `id`, `slug` e `name` podem compartilhar uma implementação. Mesmo assim, cada um tem a sua tag, as suas rotas e os seus exemplos na Scalar, com descrições em pt-BR, como em [04](04-species-api.md) RF-10.

## Critérios de aceite

- [ ] Para cada um dos 13 recursos, `GET /v1/<recurso>` devolve `count` igual ao número de linhas da tabela, e o detalhe do primeiro `id` devolve `200` por id e por slug.
- [ ] `GET /v1/elements/fire` tem `efficacy.attacking` com `flora` e `multiplier` 2. (Linha da tabela de efetividade do GDD.)
- [ ] `GET /v1/skills/1` tem `element`, `category` e `target` como referências, e `effects` como lista, possivelmente vazia.
- [ ] Uma Técnica com efeito `modify_stat` mostra `stat` e `stages` preenchidos e `status_condition` igual a `null`.
- [ ] `GET /v1/starters` devolve as espécies 1, 4 e 7, nessa ordem.
- [ ] `GET /v1/skills/9999` devolve `404` "Técnica não encontrada: 9999".
- [ ] Todas as rotas aparecem na Scalar, cada recurso na sua tag.
- [ ] `npm run lint`, `npm run typecheck`, `npm test` e `npm run test:e2e` passam.

## Desenho técnico

**Criar**

- `server/src/catalog/<recurso>/` para `skills`, `elements`, `traits`, `temperaments`, `stats`, `growth-rates`, `rarities`, `status-conditions` e `starters` (module, controller, service, `dto/`).
- `server/src/catalog/lookups/`: a implementação compartilhada dos recursos só com `id`, `slug` e `name` (RF-05).
- `server/test/catalog.e2e-spec.ts`. As contagens são comparadas com `prisma.<model>.count()`, e não com números fixos, para continuar valendo quando o dono acrescentar linhas.

**Alterar**

- `server/src/app.module.ts`: os módulos novos.

**Reaproveitar**

- `page`, `ref`, `parseIdOrSlug` e `PaginationQueryDto` de `server/src/common/` ([04](04-species-api.md)).

## Verificação

Da pasta `server/`:

```bash
npm run test:e2e
npm run start:dev   # e navegar pelas tags na Scalar
```

## Tarefas

- [ ] e2e comum, um laço sobre os 13 recursos: a lista tem `count` igual ao `count()` do Prisma; o detalhe por id e por slug é `200`; o id 9999 dá `404`. Rodar e ver falhar.
- [ ] Recursos simples compartilhados (RF-05).
- [ ] `skills` com efeitos; e2e dos critérios de Técnicas.
- [ ] `elements` com efetividade e imunidades; e2e de `fire` contra `flora`.
- [ ] `traits`, `temperaments`, `stats`, `growth-rates`, `rarities`, `status-conditions`.
- [ ] `starters`; e2e da ordem 1, 4, 7.
- [ ] Documentação (RF-05).
- [ ] Marcar esta spec e a tabela do README como `concluída`; commit `feat: rotas do catálogo`.
