# 01. As rotas para criar e salvar uma Técnica

- **Status:** concluída
- **Depende de:** [map-editor](../map-editor/README.md) (o `EditorGuard`), [skill-cooldown](../skill-cooldown/README.md)

## Contexto

O F1 vai editar Técnicas ([README](README.md)), mas o jogo só fala com o NestJS. Esta fase dá ao servidor as duas rotas do [architecture.md](architecture.md): criar e salvar uma Técnica inteira, com os efeitos e quem aprende. O formulário no jogo fica para a [02](02-skill-form.md).

## Escopo

- `POST /v1/editor/skills` e `PUT /v1/editor/skills/:id`, protegidas como as do editor de ilhas.
- As conferências do [architecture.md](architecture.md), com as mensagens em pt-BR.
- A gravação numa transação, trocando os efeitos e os aprendizes.
- O catálogo novo logo depois de salvar (`BundleService.invalidate()`).
- A documentação das rotas no OpenAPI (`/docs`).

## Fora do escopo

- O formulário no jogo ([02](02-skill-form.md)).
- Apagar uma Técnica ou mudar o `slug`.
- Rotas de leitura: o F1 lê do catálogo que já baixa.

## Requisitos

- **RF-01:** `POST /v1/editor/skills` cria a Técnica, os efeitos e os aprendizes, e responde `201` com `{ "id" }`.
- **RF-02:** `PUT /v1/editor/skills/:id` troca os campos da Técnica e os aprendizes, e grava os efeitos que vieram reaproveitando as linhas na mesma posição, e responde `200` com `{ "id" }`. O `slug` do corpo é ignorado.
- **RF-03:** Um `id` que não existe responde `404` "Técnica não encontrada.".
- **RF-04:** Cada regra do [architecture.md](architecture.md), "As conferências", que falha responde `400` com uma mensagem em pt-BR que diz o campo e o limite, como "O poder vai de 0 a 250." ou "O efeito 2 (Aplicar status) precisa de um Estado.". Nada é gravado. As regras incluem as do `CatalogValidator` do jogo: o que o servidor grava, o jogo sempre aceita.
- **RF-05:** Ao criar, um `slug` que já existe responde `409` "Já existe uma Técnica com esse slug.".
- **RF-06:** A gravação é uma transação: se uma parte falha, a Técnica fica como estava.
- **RF-07:** Os efeitos ganham `sort_order` de 1 em diante, na ordem da lista, e `weather_id` nulo.
- **RF-08:** Depois de gravar, o próximo `GET /v1/catalog` já traz os dados novos, com outra `version`.
- **RF-09:** Sem `MAP_EDITOR_USER_IDS`, as rotas respondem `404` "Rota não encontrada.". Com um usuário fora da lista, `403`.

## Critérios de aceite

- [x] Num e2e, criar uma Técnica `zz_teste_` com 2 efeitos e 1 aprendiz devolve o id novo, e o catálogo traz as 3 linhas.
- [x] Num e2e, salvar o poder 90 nessa Técnica e ler o catálogo devolve o poder 90 e outra versão.
- [x] Num e2e, salvar com `max_hits` menor que `min_hits` responde `400`, e o banco não muda.
- [x] Num e2e, um efeito `apply_status` sem Estado responde `400`, e os efeitos de antes continuam.
- [x] Num e2e, um efeito `heal` com `stat_id` preenchido responde `400`.
- [x] Num e2e, um efeito `set_weather` responde `400`.
- [x] Num teste de unidade de `skill-draft.ts`, tirar de uma espécie a única Técnica `level_up` no nível 1 é recusado, e um aprendiz `evolution` só passa com o nível 0.
- [x] Num e2e, criar com um `slug` repetido responde `409`.
- [x] Num e2e, um usuário fora de `MAP_EDITOR_USER_IDS` recebe `403`.
- [x] Depois dos e2e, não sobra nenhuma Técnica `zz_teste_` no banco.
- [x] A `/docs` mostra as duas rotas no grupo do editor, com o corpo e as respostas.

## Desenho técnico

**Criar:**
- `server/src/editor/skills-editor.dto.ts`: o corpo (`SkillDraftDto`, `SkillEffectDraftDto`, `SkillLearnerDraftDto`) com `class-validator` para os tipos e os limites de cada campo, e a resposta `SkillSavedResponseDto`.
- `server/src/domain/skills/skill-draft.ts` (`skillDraftError`): as conferências que olham o catálogo ou mais de um campo:
  - os ids que existem;
  - `min_hits` ≤ `max_hits` e o par da marca no chão;
  - as colunas de cada tipo de efeito (a tabela do [architecture.md](architecture.md), espelho do `EFFECT_PARAMS`);
  - o nível por método e o par espécie e método repetido;
  - a Técnica `level_up` no nível 1 de cada espécie, com os aprendizes das outras Técnicas somados aos novos desta.

  É uma função pura: recebe o corpo e as tabelas e devolve a primeira mensagem, ou nada.
- `server/src/domain/skills/skill-draft.spec.ts`: os testes de unidade de cada regra.
- `server/src/editor/skills-editor.service.ts`: lê as tabelas de apoio, roda as conferências, grava na transação e chama `BundleService.invalidate()`.
- `server/src/editor/skills-editor.controller.ts`: as duas rotas, com `@UseGuards(AuthGuard, EditorGuard)` e o OpenAPI, como `islands-editor.controller.ts`.
- `server/test/skills-editor.e2e-spec.ts`: os critérios de aceite, com as Técnicas `zz_teste_` e a limpeza do [architecture.md](architecture.md), "Os testes e o banco".

**Alterar:**
- `server/src/editor/editor.module.ts`: o controlador e o serviço novos, e o `BundleModule` importado.
- `server/src/catalog/bundle/bundle.service.ts`: `invalidate()`, que apaga `cached`.
- `server/src/catalog/bundle/bundle.module.ts`: exportar o `BundleService`.

**Reutilizar:** o `EditorGuard`, o `AuthGuard`, o padrão de DTO e de OpenAPI do editor de ilhas e os nomes de colunas de `camelToSnakeKeys` / `snakeToCamelKeys` (`server/src/common/case.ts`).

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test
cd server && npm run test:e2e
```

À mão: com o servidor no ar, abrir `/docs` e ver as duas rotas.

## Tarefas

- [x] DTOs e conferências, com os testes de unidade.
- [x] Serviço, transação e `invalidate()`.
- [x] Controlador, módulo e OpenAPI.
- [x] e2e.
- [x] Lint, typecheck e a suíte inteira.

## Resultado da verificação

Em 2026-11-15:

- **Testes:** os 16 de unidade de `skill-draft.spec.ts` e os 12 e2e de `skills-editor.e2e-spec.ts` passam. A suíte inteira também passa (66 arquivos de unidade e 19 de e2e), com o lint e o typecheck.
- **Pelo jogo:** com o servidor novo numa porta à parte, o formulário da [02](02-skill-form.md) criou uma Técnica, salvou o poder 90 e mostrou a recusa de `min_hits` > `max_hits`. O catálogo baixado depois passou no `CatalogValidator`. A Técnica de teste foi apagada.
- **Divergências do desenho:**
  - As conferências ficaram em `server/src/domain/skills/skill-draft.ts`, e não em `src/editor/skill-rules.ts`. Elas são regras puras, como as da ilha em `src/domain/islands/island-draft.ts`.
  - **O contador de id.** O primeiro e2e falhou com `500`: o contador de `skill_effects` estava atrás das linhas postas pelo painel com o id escrito à mão, e o `INSERT` batia num id que já existia. Antes de inserir, o serviço agora põe o contador de `skills` e de `skill_effects` depois do maior id (`catchUpIds`). Um e2e atrasa o contador e confere que criar funciona.
  - **A ordem dos e2e.** O e2e do editor grava no catálogo, e o `bundle.e2e-spec.ts` contava as Técnicas ao mesmo tempo. O `vitest.config.e2e.ts` agora tem dois grupos (`projects` com `sequence.groupOrder`), e o editor de Técnicas roda depois de todos os outros.
  - **Os ids dos efeitos.** Salvar apagava e criava de novo os efeitos, e cada vez eles ganhavam ids novos. O dono salvou duas Técnicas pelo F1, e os efeitos 1 e 2 viraram 89 e 90, o que quebrou o `seed.e2e-spec.ts`. Agora o efeito na posição N reaproveita a linha da posição N, e um e2e confere que os ids continuam. Os dois efeitos voltaram aos ids 1 e 2 (o conteúdo era o mesmo do seed).
  - Um erro de tipo ou de limite no corpo (o `ValidationPipe`) junta todas as mensagens com "; ". As conferências do `skill-draft.ts` devolvem só a primeira.

