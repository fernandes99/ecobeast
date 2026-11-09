# 05. O projétil da Técnica no visualizador

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [02-skills-and-elements](02-skills-and-elements.md) (a aba Técnicas com os arquivos) e [board-battle/15](../board-battle/15-projectile-effects.md) (o projétil das Técnicas)

## Contexto

Na [board-battle/15](../board-battle/15-projectile-effects.md), uma Técnica ganhou uma folha que voa de quem ataca até o alvo, `res://assets/effects/skills/<slug>_projectile.png`, que só existe quando a Técnica cruza o campo. A fase deixou o projétil fora do visualizador, para não marcar "falta" em quase todas as Técnicas. Em 2026-11-07, depois de ver a Faísca Rápida, o dono pediu: "coloque o pojectile também na tela de visualizer (f1), será um campo opcional então tudo bem os outros não terem".

## Escopo

- O projétil no detalhe da Técnica, na linha das Técnicas do Ecobeast e no Resumo, como arquivo opcional.

## Fora do escopo

- Outros arquivos opcionais.
- Mostrar o projétil voando: o preview o toca parado no lugar, como o efeito.

## Requisitos

- **RF-01:** `ContentFiles.skill_optional_files(slug)` devolve os arquivos opcionais da Técnica: hoje, só o "projétil" (`SKILL_PROJECTILE_PATH`, `Kind.EFFECT`). Um `Entry` opcional tem `optional` ligado. `skill_files` continua com os 3 que toda Técnica precisa.
- **RF-02:** Na seção Arquivos da Técnica, o projétil vem depois do som. Com o arquivo, ele toca como o efeito, com o nome "projétil". Sem ele, o quadro fica tracejado em cinza, sem o vermelho do que falta, com "projétil · opcional" e o caminho, em cinza.
- **RF-03:** O projétil não conta no que falta: a lista das Técnicas continua com "3/3", e a Técnica sem projétil não entra em "Técnicas que faltam arquivos".
- **RF-04:** Na lista de Técnicas do Ecobeast, "projétil ✓" aparece no fim só para quem tem o arquivo ("ícone ✓ · efeito ✓ · som ✓ · projétil ✓"). Quem não tem fica como antes.
- **RF-05:** O Resumo ganha o cartão "Com projétil (opcional)", depois de "Com som", com quantas Técnicas têm o arquivo ("1 de 52"), na cor do texto, e não na cor de quanto está pronto.

## Critérios de aceite

- [ ] Com F1, a Faísca Rápida mostra o projétil tocando, e a Arranhão, "projétil · opcional" em cinza.
- [ ] O Resumo mostra "Com projétil (opcional)" com "1 de 52", e as Técnicas continuam "3/3".

## Desenho técnico

**Alterar:**

- `res://tools/content_viewer/content_files.gd`: `Entry.optional` e `skill_optional_files`.
- `res://tools/content_viewer/file_preview.gd`: o opcional que falta, tracejado e escrito em cinza (`UiPalette.TEXT_SECONDARY`).
- `res://tools/content_viewer/skills_tab.gd`: os opcionais depois dos 3 arquivos, no detalhe.
- `res://tools/content_viewer/species_tab.gd`: os opcionais que existem no fim da linha da Técnica.
- `res://tools/content_viewer/summary_tab.gd`: o cartão "Com projétil (opcional)".
- [architecture.md](architecture.md): o projétil na tabela dos arquivos.

## Verificação

- O script sem janela do visualizador, com o catálogo da API, ganha os critérios de aceite: a Arranhão com "projétil · opcional", o caminho e sem "projétil · falta"; a Faísca Rápida com "projétil" e sem o caminho, ainda "3/3"; o Ruvo com "projétil ✓" só na Faísca Rápida; o cartão com "1 de 52". As conferências de antes seguem passando.
- O jogo sem janela abre sem erros nem avisos de script.
- Manual, com F1: o dono vê a Faísca Rápida, a Arranhão e o Resumo.

## Tarefas

- [x] Conferências novas no script sem janela, vendo falhar.
- [x] `ContentFiles`, preview, aba Técnicas, Ecobeast e Resumo.
- [x] Verificação sem janela.
- [ ] O dono ver com F1.

## Resultado da verificação

Em 2026-11-07, as 5 conferências novas falharam antes do código (sem o projétil no detalhe, na linha do Ruvo e no Resumo) e passaram depois. O script sem janela do visualizador, com o catálogo da API, deu 0 falhas: a Arranhão com "projétil · opcional" e o caminho `res://assets/effects/skills/arranhao_projectile.png`, sem "projétil · falta"; a Faísca Rápida com "projétil", sem o caminho, e ainda "3/3" na lista; no Ruvo, "ícone ✓ · efeito ✓ · som ✓ · projétil ✓" só na Faísca Rápida, e as outras 3 Técnicas com os 3 arquivos como antes; o Resumo com "Com projétil (opcional)" em "1 de 52". As conferências de antes seguiram passando. O jogo sem janela abriu sem erros nem avisos de script.

O tracejado cinza e o projétil tocando não foram vistos com janela: falta o dono ver com F1.
