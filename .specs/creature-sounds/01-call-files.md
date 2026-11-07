# 01. O arquivo do som e o visualizador

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [content-viewer/04](../content-viewer/04-balance-and-general.md) (a seção Arquivos e o Resumo do visualizador)

## Contexto

Ver o [README](README.md). O visualizador de conteúdo (F1) lista os arquivos de cada Ecobeast pelo `ContentFiles.creature_files` (`res://tools/content_viewer/content_files.gd`): front, board e as 4 folhas. O som entra como o 7º arquivo, para o dono ver quem ainda não tem.

## Escopo

- O caminho do som, `res://assets/creatures/<slug>/call.wav`, no `ContentFiles`.
- A linha "call" na seção Arquivos do Ecobeast e o cartão "Com call" no Resumo.

## Fora do escopo

- Tocar o som em qualquer tela do jogo.
- Os arquivos de som: o dono manda depois.

## Requisitos

- **RF-01:** `ContentFiles.CREATURE_CALL_PATH` é `res://assets/creatures/%s/call.wav`, e `creature_files` devolve o som por último, com o rótulo "call" e o tipo `Kind.SOUND`.
- **RF-02:** Na seção Arquivos do Ecobeast, o "call" fica na linha das imagens paradas (front e board): com o arquivo, "▶ Ouvir"; sem ele, o tracejado com o caminho e "call · falta".
- **RF-03:** A lista do Ecobeast e o Resumo contam o som entre os arquivos: "4/7" no lugar de "4/6", e "call" entra no que falta de cada um.
- **RF-04:** O Resumo ganha o cartão "Com call", depois de "Com as folhas da luta", com quantos Ecobeasts têm o `call.wav`.
- **RF-05:** Nenhuma tela do jogo muda.

## Critérios de aceite

- [x] O Ruvo mostra "call · falta" e o caminho `res://assets/creatures/ruvo/call.wav` na seção Arquivos.
- [x] O Resumo mostra "Com call" com "0 de 14", e o Ruvo na lista do que falta com "call".
- [x] Com um `call.wav` de teste na pasta do Ruvo, aparece "▶ Ouvir" no lugar do tracejado (o arquivo de teste não fica no repositório).

## Desenho técnico

**Alterar:**

- `res://tools/content_viewer/content_files.gd`: `CREATURE_CALL_PATH` e a entrada "call" em `creature_files`.
- `res://tools/content_viewer/species_tab.gd`: em `_files`, o som vai para a linha das imagens.
- `res://tools/content_viewer/summary_tab.gd`: o cartão "Com call".
- [content-viewer/architecture.md](../content-viewer/architecture.md): o som na lista dos arquivos do Ecobeast.
- [glossary.md](../glossary.md): o termo "Som do Ecobeast".

**Reutilizar:** `FilePreview.create` com `Kind.SOUND`, que já toca os sons das Técnicas e mostra o tracejado dos que faltam.

O caminho mora no `ContentFiles` porque nenhuma tela do jogo usa o som ainda. Quando a próxima fase tocar o som, a constante passa para a classe do jogo que o toca, e o `ContentFiles` a usa de lá, como faz com o `front.png`.

## Verificação

- `godot --headless --path client --quit-after 30` sem erros nem avisos de script.
- O script sem janela do content-viewer ganha os critérios de aceite, e as conferências de antes passam com "4/7".
- Manual, com F1: o Ruvo e o Resumo.

## Tarefas

- [x] Conferências novas no script sem janela, vendo falhar.
- [x] `ContentFiles`, aba Ecobeasts e Resumo.
- [x] Verificação sem janela, com e sem o `call.wav` de teste.
- [ ] O dono ver com F1.

## Resultado da verificação

Em 2026-11-06, as 6 conferências novas e as 2 que mudaram para "4/7" (Ruvo e Ruvaroth) falharam antes do código e passaram depois; a contagem das pastas sem catálogo também passou a esperar "4/7". O script sem janela, com o catálogo da API, deu 0 falhas em 114 conferências: "Com call" com 0 de 14, o "call" no que falta do Ruvo e do Ruvaroth, e o Ruvo com "call · falta" e o caminho. Com um `call.wav` de teste na pasta do Ruvo (uma cópia do som de dano, apagada depois), deu 0 falhas: "1 de 14", o Ruvo com 5/7 e "▶ Ouvir". O jogo sem janela abriu sem erros nem avisos de script. Falta o dono ver com F1.
