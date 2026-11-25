# 04. Criar, editar e apagar NPCs no F2

- **Status:** concluída (falta o dono conferir no F2)
- **Depende de:** [02-npc-tool](02-npc-tool.md), [liora-intro/02](../liora-intro/) (os NPCs pessoas e o botão Aparência) e [dialogue-voices/03](../dialogue-voices/) (a voz do NPC no F2)

## Contexto

Em 2026-11-24, o dono pediu: "Na aba de NPC eu queria ter a possibilidade de criar novos NPCs ou excluir novos NPC". Hoje o catálogo `npcs` só muda pelo painel do Supabase; o F2 põe no mapa os que já existem e troca a aparência e a voz deles.

Nas perguntas da fase, o dono escolheu:

- apagar um NPC em uso é **recusado**, e o F2 diz onde ele está ("Recusar e dizer onde");
- o mesmo formulário **cria e edita** o nome, a descrição, a fala padrão e o Ecobeast de um NPC ("Sim, criar e editar").

## Escopo

- Servidor: 3 rotas novas em `/v1/editor/npcs`, com os testes.
- Jogo: a ferramenta NPC do F2 (`NpcPanel`) ganha o "+ Novo NPC", o "Editar" e o "Excluir do catálogo".

## Requisitos

### Servidor

- **RF-01:** `POST /v1/editor/npcs` cria um NPC com `name` (1 a 30 letras, sem os espaços das pontas), `description` (até 200), `default_dialogue` (até 2.000), `voice_id` (opcional; sem ele, a voz padrão da tabela, a Média) e um só de:
  - `sprite`: o `slug` de uma espécie (`species`), para um NPC Ecobeast;
  - `body_type_id`: um corpo (`body_types`, os de criança também), para um NPC pessoa. Ele nasce com a primeira cor de pele, uma peça em cada lugar obrigatório (a de menor id que serve no corpo) e a primeira cor que o lugar aceita; o dono o veste depois pelo botão Aparência.
- **RF-02:** O `slug` sai do nome, sem acento, em minúsculas, com `_` no lugar do resto (`"Dona Zélia"` vira `dona_zelia`), e ganha `_2`, `_3`… se já existir. Um nome sem nenhuma letra ou número vira `npc`.
- **RF-03:** `PUT /v1/editor/npcs/:id` troca o `name`, a `description` e a `default_dialogue`, e o `sprite` só de um NPC Ecobeast. Um NPC não troca de Ecobeast para pessoa nem de pessoa para Ecobeast: `sprite` num NPC pessoa responde 400. O `slug` não muda.
- **RF-04:** `DELETE /v1/editor/npcs/:id` apaga o NPC e as peças da aparência dele, só se ele não está em uso. Em uso, responde 409 com a lista de onde ele está, numa frase: posto numa ilha (o nome dela, e "rascunho" ou "publicada"), numa sala (o nome dela), dando ou sendo o alvo de uma missão (quantas), ou sendo um Domador de ilha.
- **RF-05:** As 3 rotas liberam o catálogo novo (`BundleService.invalidate`) e respondem o NPC no formato da linha do catálogo (`id`, `slug`, `name`, `description`, `sprite`, `body_type_id`, `skin_palette_id`, `voice_id`, `default_dialogue`). Elas exigem o editor (`MAP_EDITOR_USER_IDS`), como as outras rotas de `/v1/editor`.

### F2

- **RF-06:** Acima da busca da ferramenta NPC, o botão "+ Novo NPC" abre o formulário: Nome, Descrição, Tipo (Ecobeast ou Pessoa), a espécie (Ecobeast) ou o corpo (Pessoa), e a fala padrão. Criar salva na hora, baixa o catálogo de novo e deixa o NPC novo escolhido na lista, pronto para pôr no mapa.
- **RF-07:** Com um NPC escolhido na lista, aparecem o "Editar", que abre o mesmo formulário com os dados dele (o Tipo travado), e o "Excluir do catálogo".
- **RF-08:** O "Excluir do catálogo" pede o segundo clique ("Confirmar: excluir"). Antes de chamar o servidor, o F2 confere as cenas da história (`Story.library`): um NPC usado numa cena não é apagado, e a barra de baixo diz quais cenas. A recusa do servidor também vai para a barra de baixo.
- **RF-09:** O "Apagar NPC (Delete)" de hoje continua tirando só o NPC posto no mapa, e passa a se chamar "Tirar do mapa (Delete)", para não confundir com o "Excluir do catálogo".

## Fora do escopo

- Apagar junto as missões, os NPCs postos e as cenas de um NPC em uso.
- Trocar o tipo do NPC (Ecobeast e pessoa) depois de criado.
- Mudar o `slug` ou o id de um NPC.
- Conferir no servidor as cenas da história, que moram no jogo.

## Onde ficou

- As regras puras em `server/src/domain/npcs/npc-catalog.ts`: `npcSlug`, `defaultAppearance` (a roupa com que a pessoa nasce, conferida pelo `appearanceError`) e `npcUsageText` (a frase do 409), com os testes em `npc-catalog.spec.ts`.
- As rotas em `NpcsEditorController` e `NpcsEditorService` (`create`, `update`, `remove`), com os DTOs `NpcCreateBodyDto`, `NpcUpdateBodyDto`, `NpcRowDto` e `NpcDeleteResponseDto`; o e2e `npc-catalog-editor.e2e-spec.ts` está no grupo `e2e-catalog-writers` e apaga no fim os NPCs que cria.
- O F2: o `NpcCatalogForm` (`client/tools/map_editor/npc_catalog_form.gd`), no topo da ferramenta NPC, com a conferência das cenas (`scenes_using`) e do rascunho aberto (`placed_in_draft`), e o `EditorApi.create_npc`, `update_npc` e `delete_npc`. Depois de salvar ou excluir, o catálogo vem de novo (`GameData.load_catalog`), como no botão Aparência.
- A lista "NPC alvo" da ferramenta Missões passou a ser refeita a cada missão aberta, para mostrar um NPC criado depois de abrir o F2.

## Critérios de aceite

- [ ] Criar um NPC Ecobeast e um pessoa pelo F2 e pô-los no mapa (falta o dono conferir).
- [ ] Editar o nome de um NPC muda o nome na lista e na caixa de fala (falta o dono conferir).
- [x] Apagar um NPC em uso diz onde ele está e não apaga; sem uso, ele some (no e2e; a lista do F2 falta o dono conferir).
- [x] Os e2e de `npc-catalog-editor.e2e-spec.ts` e os testes de `npc-catalog.spec.ts` passam.
