# 04. Balanceamento, iniciais, curvas de XP, Domador e sons de dano

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [03-world-and-items](03-world-and-items.md)

## Contexto

Com as 3 fases prontas, o dono perguntou o que mais faltava no visualizador, olhando o banco e o resto. A comparação do schema com as abas mostrou que o catálogo já aparece quase todo. Faltavam colunas dos Ecobeasts que pesam no balanceamento (curva de XP, XP ao ser derrotado, captura, gênero e pontos de Treino), a tabela dos iniciais (`starter_options`) e a das curvas de XP (`growth_rates`). O dono pediu esses 3 itens, mais os sons de dano e o Domador, "que hoje é apenas o sprite".

A arte de cada Elemento (`res://assets/ui/elements/<slug>/`, que só Fogo, Água e Flora têm) também foi oferecida, e o dono não pediu. As regras que moram no código do servidor (fuga, dano, Estados, spawn, moedas) ficam para depois, junto com o mapa: a API não as envia.

## Escopo

- No detalhe do Ecobeast, o bloco **Progressão e captura** e a marca de inicial.
- No Resumo, os iniciais e as curvas de XP.
- Uma aba **Geral**, a última, com o Domador e os sons de dano.

## Fora do escopo

- A arte dos Elementos.
- As regras do código do servidor e o mapa.
- Dados do jogador (nome, nível, moedas): moram nas tabelas do jogador, não no catálogo.

## Requisitos

- **RF-01:** O detalhe do Ecobeast ganha, entre Stats base e Traços, o bloco **Progressão e captura**: a curva de XP com o multiplicador ("Médio (×1)"), o XP que ele dá ao ser derrotado, a captura de 0 a 100 ("45 de 100"), o gênero ("50% macho · 50% fêmea", ou "sem gênero" quando `gender_ratio` é −1) e os pontos de Treino que rende ao ser derrotado ("Velocidade +1"; sem nenhum, "—").
- **RF-02:** Um Ecobeast que está em `starter_options` leva, ao lado da raridade, "inicial (Nº de N)", na ordem de `sort_order`.
- **RF-03:** O Resumo ganha, depois dos cartões dos Ecobeasts, o bloco **Iniciais**, com os iniciais em ordem (links), e o bloco **Curvas de XP**, com cada curva, o multiplicador e quantos Ecobeasts a usam.
- **RF-04:** A aba **Geral** fica depois de Estados e tem o bloco **Domador**, com as folhas `res://assets/tamer/idle.png` e `run.png` em todas as direções, andando no ritmo do jogo (`TamerSprite.IDLE_SECONDS` e `RUN_SECONDS`), as do lado esquerdo espelhadas, e o texto de `res://assets/tamer/CREDITOS.md`, que diz de onde vem a arte.
- **RF-05:** A aba Geral tem o bloco **Sons de dano**, com "normal", "super efetivo" e "pouco efetivo" (`res://assets/sounds/hits/normal.wav`, `super.wav` e `weak.wav`), cada um com "▶ Ouvir" ou o tracejado com o caminho.
- **RF-06:** A tela da luta continua tocando os sons de dano, agora com o caminho do `ContentFiles`.

## Critérios de aceite

- [ ] O Ruvo mostra "Médio (×1)", 62 de XP, "45 de 100", "50% macho · 50% fêmea", "Velocidade +1" e "inicial (1º de 3)".
- [ ] O Resumo mostra Ruvo, Nilu e Elu nos iniciais e as 3 curvas (Rápido ×0,8, Médio ×1 e Lento ×1,25) com quantos Ecobeasts usam cada uma.
- [ ] A aba Geral mostra o Domador parado e correndo nas 8 direções, os créditos e os 3 sons de dano tocando.
- [ ] Na luta, o som de dano continua tocando.

## Desenho técnico

**Criar:** `res://tools/content_viewer/general_tab.gd`.

**Alterar:**

- `content_files.gd`: `HIT_SOUND_PATH` (sai da tela da luta), os sons de dano com os nomes, as folhas do Domador e o caminho dos créditos. O `Entry` ganha `cycle`, o tempo de um ciclo da folha, para o Domador usar o ritmo dele.
- `file_preview.gd`: uma folha do explorar usa o `cycle` do `Entry` quando ele vem preenchido.
- `species_tab.gd`, `summary_tab.gd` e `content_viewer.gd` (a aba Geral, `TAB_GENERAL`).
- `res://screens/board_battle/board_battle_screen.gd`: usa `ContentFiles.HIT_SOUND_PATH`.

**Reutilizar:** `GameData.get_rows` para `growth_rates`, `starter_options` e `species_stats`; `TamerSprite.SHEET_PATH`, `IDLE`, `RUN`, `IDLE_SECONDS` e `RUN_SECONDS`; `ContentFiles.EXPLORE_DIRECTIONS`, porque a folha do Domador tem o mesmo formato da do explorar.

## Verificação

- `godot --headless --path client --quit-after 30` sem erros nem avisos de script.
- O script sem janela das fases anteriores ganha: os dados do Ruvo do critério de aceite, os 3 iniciais e as 3 curvas no Resumo, as 2 folhas do Domador com 8 direções e os 3 sons na aba Geral.
- Os testes da luta seguem passando.
- Manual, com F5: os critérios de aceite. Prints do Ruvo, do Resumo e da aba Geral.

## Tarefas

- [x] Progressão e captura e a marca de inicial no Ecobeast.
- [x] Iniciais e curvas de XP no Resumo.
- [x] A aba Geral.
- [x] Verificação sem janela e prints com janela.
- [ ] O dono ver com F5.

## Resultado da verificação

Em 2026-11-06, o projeto importou sem erros, e o jogo sem janela abriu sem erros nem avisos de script. A checagem de carga e os testes do golpe e do som de dano seguiram com 0 falhas, com o caminho do som vindo do `ContentFiles`.

O script sem janela, com o catálogo da API, deu 0 falhas em 110 conferências (as das fases 01 a 03 e as desta): a aba Geral como a 10ª; o Ruvo com "Médio (×1)", 62 de XP, "45 de 100", "50% macho · 50% fêmea", "Velocidade +1" e "inicial (1º de 3)", e o Ruvak sem a marca de inicial; Ruvo, Nilu e Elu nos iniciais e as 3 curvas no Resumo; o Domador nas 8 direções, parado e correndo, com os créditos; e os 3 sons de dano.

O Resumo mostrou que os 14 Ecobeasts usam a curva Média: Rápida e Lenta não têm nenhum.

Prints com janela mostraram o Resumo, o Ruvo e a aba Geral. Falta o dono ver com F5.
