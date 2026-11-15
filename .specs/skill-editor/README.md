# skill-editor

Na aba Técnicas do visualizador de conteúdo (F1), o dono edita qualquer dado de uma Técnica e cria Técnicas novas, sem abrir o painel do Supabase. Quem salva é o servidor, por rotas do editor, e a mudança vale a partir da próxima luta.

## Contexto

Em 2026-11-15, o dono pediu: "No painel do F1, quero poder editar todos os dados das técnicas." Para quê: "ajustar números enquanto testo as lutas, e criar novas também."

O que existe hoje:

- **O F1 só mostra.** O [content-viewer](../content-viewer/README.md) foi decidido como só leitura ("editar continua no painel do Supabase"). Esta iniciativa muda isso só para a aba Técnicas. As outras abas continuam só leitura.
- **O jogo fala só com o NestJS.** Para salvar, o servidor ganha rotas novas. O editor de ilhas (F2) já tem rotas assim, em `/v1/editor`, protegidas pelo `EditorGuard`: só as contas em `MAP_EDITOR_USER_IDS` passam ([map-editor/architecture.md](../map-editor/architecture.md), "Quem edita").
- **A luta copia as Técnicas quando começa.** O `begin` de `server/src/board-battle/board-battle.service.ts` chama `loadBattleCatalog`, e a luta guarda essa cópia até acabar. Uma mudança salva vale na próxima luta.
- **O catálogo baixado** (`GET /v1/catalog`) fica guardado no servidor por até 60 s (`BundleService`) e no aparelho, pela versão. Depois de salvar, o servidor joga fora a cópia dele, e o F1 baixa o catálogo de novo.
- **Os dados de uma Técnica** ficam em três tabelas: `skills` (os campos), `skill_effects` (os efeitos, em ordem) e `species_skills` (quem aprende, como e em que nível).

## Objetivos

1. Mudar qualquer campo, efeito ou aprendiz de uma Técnica no F1 e ver a mudança na próxima luta.
2. Criar uma Técnica nova no F1, com efeitos e aprendizes, pronta para aparecer na luta.
3. O servidor confere tudo antes de gravar, com as mesmas regras do banco, e diz em português o que está errado.

## Anti-objetivos

- O jogador nunca vê nada disso: o F1 só existe com o jogo rodando pelo editor, e as rotas só aceitam quem está em `MAP_EDITOR_USER_IDS`.
- Uma luta em andamento não muda.

## Decisões

Do dono, em 2026-11-15:

| Decisão | Motivo |
| --- | --- |
| Editar e criar Técnicas no F1 | "ajustar números enquanto testo as lutas, e criar novas também" |
| A mudança vale a partir da próxima luta (opção A) | Escolha do dono entre valer na próxima luta e valer também na luta aberta |
| Um botão **Editar** troca a ficha por um formulário com **Salvar** e **Cancelar** (opção 1) | Escolha do dono entre o botão Editar e a ficha sempre editável |

Escolhas de Claude, apresentadas ao dono (corrigíveis; ao mudar uma, atualize aqui e no [architecture.md](architecture.md)):

| Decisão | Motivo |
| --- | --- |
| O formulário edita os campos da Técnica, os efeitos e quem aprende | Uma Técnica que nenhum Ecobeast aprende nunca aparece na luta |
| O `slug` é escolhido ao criar e não muda depois | Ele é o nome dos arquivos de ícone, efeito e som |
| Apagar uma Técnica fica de fora | Os Ecobeasts que já a conhecem dependem dela no banco |
| As rotas ficam em `/v1/editor/skills`, com o mesmo `AuthGuard` e `EditorGuard` do editor de ilhas | A proteção já existe e já está configurada no `.env` do dono |
| Salvar manda a Técnica inteira (campos, efeitos e aprendizes) de uma vez, e o servidor troca tudo numa transação | Não sobra Técnica pela metade se uma parte falhar |
| Não muda o banco: nenhuma migration | Todas as colunas já existem |
| O servidor confere com as regras do `CatalogValidator` do jogo, além dos CHECKs do banco | Uma Técnica que o jogo recusa deixa todos os jogadores, e o próprio F1, sem catálogo |
| O formulário não oferece o efeito `set_weather` | O clima ainda não existe, e o banco e o jogo pedem coisas opostas para ele |
| Os e2e criam e apagam só Técnicas `zz_teste_`, sem tocar nas do jogo | Os testes rodam no banco do Supabase, que é o mesmo do jogo |

## Fora do escopo

- Editar nas outras abas do F1 (Ecobeasts, Elementos, Itens…).
- Apagar ou renomear o `slug` de uma Técnica.
- Mudar uma luta que já começou.
- Pôr ou trocar os arquivos (ícone, efeito, som). Uma Técnica nova aparece com os arquivos faltando, tracejados, como hoje.
- Atualizar o `server/prisma/seed-data/skills.json`, que já está para trás do banco ([content-viewer](../content-viewer/README.md)).
- Desfazer uma mudança salva, ou guardar o histórico dela.

## Pré-requisitos

- [content-viewer](../content-viewer/README.md) e [map-editor](../map-editor/README.md) concluídas: a aba Técnicas e o `EditorGuard`.
- [skill-cooldown](../skill-cooldown/README.md) concluída: o campo `cooldown`.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-skill-routes](01-skill-routes.md) | Servidor: criar e salvar uma Técnica inteira, com as conferências e o catálogo novo | concluída |
| 2 | [02-skill-form](02-skill-form.md) | Jogo: o botão Editar, o formulário, Nova Técnica e o F1 com os dados novos | concluída (falta o dono usar) |
| 3 | [03-team-target](03-team-target.md) | Servidor e jogo: o alvo "Meu time", com o alcance, e o Banho de Sol nele | concluída (falta o dono jogar) |

O desenho compartilhado está no [architecture.md](architecture.md).
