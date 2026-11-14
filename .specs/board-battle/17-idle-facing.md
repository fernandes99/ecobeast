# 17. Parado, olhando para onde andou

- **Status:** concluída (falta o dono ver no editor)
- **Depende de:** [07-battle-sprites](07-battle-sprites.md)

## Contexto

Na [07](07-battle-sprites.md), o idle da luta tem só duas vistas: de frente, para os selvagens, e de costas, para os do jogador. Depois de andar, o Ecobeast volta para uma delas, mesmo tendo andado de lado. Em 2026-11-09, o dono gerou no PixelLab o idle do Ruvo nas 6 direções que faltavam ("terminei com todas os sprites do ruvo, atualize todos que faltam"). O zip novo traz os mesmos arquivos do antigo, iguais byte a byte, mais o idle de 15 quadros em east, south-east, north-east, west, south-west e north-west.

Claude perguntou como o Ecobeast parado deve usar as vistas novas, e o dono escolheu "olhar o último passo": depois de andar, ele fica parado olhando para onde andou.

O zip também tem o walk de frente e de costas, que o tabuleiro não usa, porque todo passo é para o lado ou numa diagonal. O dono pediu as duas vistas na folha mesmo assim ("mesmo não usando eu quero o walk de frente e de costa também").

## Escopo

- O zip novo do Ruvo em `art-source/ruvo/pixellab.zip`.
- O `idle.png` da luta com 5 linhas, quando o zip tem as vistas de lado.
- O `walk.png` da luta com 5 linhas, quando o zip tem o walk de frente e de costas.
- No tabuleiro, o Ecobeast parado olhando para o último passo.
- O visualizador de conteúdo mostrando as vistas novas do idle.

## Fora do escopo

- Virar para o alvo de uma Técnica, ou para o inimigo mais perto.
- Usar o walk de frente e de costas no tabuleiro: ele fica na folha, mas todo passo é para o lado ou numa diagonal.
- As folhas do Ruvak, que continuam com o idle de 2 linhas (na [24](24-ruvak-idle.md), ele ganhou o idle de 5, do PixelLab).

## Requisitos

- **RF-01:** O `idle.png` da luta pode ter 2 ou 5 linhas. As 2 primeiras não mudam: 0, de frente (south); 1, de costas (north). As outras 3 seguem a ordem do walk: 2, diagonal descendo (south-east); 3, de lado (east); 4, diagonal subindo (north-east). Todas olham para a direita, e a esquerda é a mesma arte espelhada.
- **RF-02:** O `walk.png` da luta pode ter 3 ou 5 linhas. As 3 primeiras não mudam: 0, diagonal descendo (south-east); 1, de lado (east); 2, diagonal subindo (north-east). As outras 2 são 3, de frente (south), e 4, de costas (north). O tabuleiro não as usa; o visualizador de conteúdo as mostra.
- **RF-03:** A ferramenta (`battle_sheets.py`) põe as vistas a mais de cada folha quando o zip tem todas elas: o idle de south-east, east e north-east, e o walk de south e north. Sem nenhuma, a folha sai como antes. Com só parte delas, ela para e diz qual falta. O `battle.json` também vale para as vistas novas.
- **RF-04:** As células são quadradas e iguais nas duas folhas. O jogo tira as linhas de cada folha da proporção entre as alturas do idle e do walk: cada combinação (idle de 2 ou 5 linhas, walk de 3 ou 5) dá uma proporção diferente, então só uma serve. Sem nenhuma que sirva, é um erro, e a espécie fica com o `board.png`.
- **RF-05:** Ao entrar no tabuleiro, o Ecobeast fica como na [07](07-battle-sprites.md): os do jogador de costas e os selvagens de frente.
- **RF-06:** Depois de andar, ele toca o idle da vista do último passo, com o mesmo espelho: de lado, a linha de lado; descendo, a diagonal descendo; subindo, a diagonal subindo. Ele continua assim até andar de novo ou sair do tabuleiro. Ajustar a posição com a resposta do servidor (`snap`) não muda para onde ele olha.
- **RF-07:** Quem tem o idle de 2 linhas, ou não tem as folhas da luta, volta para a vista da [07](07-battle-sprites.md) depois de andar, como hoje.
- **RF-08:** No visualizador de conteúdo, as vistas do idle e do walk da luta que a folha da espécie tem aparecem animadas, e as que ela não tem aparecem como faltando.

## Critérios de aceite

- [x] Com o zip novo, a ferramenta gera o `idle.png` e o `walk.png` do Ruvo com 5 linhas, e as linhas que já existiam ficam iguais às de antes, pixel a pixel.
- [x] No visualizador, o idle e o walk da luta do Ruvo não têm direção faltando.
- [x] O Ruvo entra no tabuleiro de costas (do jogador) ou de frente (selvagem).
- [x] Depois de andar para a direita, o Ruvo parado toca o idle de lado; para a esquerda, o mesmo espelhado; numa diagonal, o idle da diagonal.
- [x] O Ruvak, com o idle de 2 linhas, volta para a vista de antes depois de andar.
- [ ] O dono vê no editor o Ruvo parado olhando para onde andou.

## Desenho técnico

**Alterar:**

- `.claude/skills/creature-sprites/scripts/battle_sheets.py`: as vistas a mais de cada folha (`EXTRA`), opcionais em grupo.
- `res://screens/board_battle/battle_sheets.gd`: `IDLE_DOWN`, `IDLE_SIDE`, `IDLE_UP`, `WALK_SOUTH` e `WALK_NORTH`; `rows` por folha e a célula, achados por `_find_rows` na proporção das alturas; `has_row(sheet, row)`.
- `res://screens/board_battle/board_view.gd`: o `Token` guarda a linha do idle do último passo (`facing`). O `_face` a escolhe, e o `_rest` a usa quando a folha tem a linha.
- `res://tools/content_viewer/content_files.gd` e `file_preview.gd`: as vistas de lado do idle e as de frente e de costas do walk, e cada vista confere se a folha da espécie tem a linha.
- A skill `creature-sprites`: a seção das folhas da luta.

## Verificação

- A ferramenta com o zip novo: 5 linhas no idle e no walk, com as 2 primeiras do idle e as 3 primeiras do walk iguais às de antes.
- Um teste sem janela do `BattleSheets`, do `BoardView` e do visualizador (36 itens): o Ruvo com 5 linhas no idle e no walk; o Ruvak com 2 e 3; parado de costas e de frente ao entrar; o idle de lado, de diagonal e espelhado depois de andar; o `snap` mantendo a vista; o Ruvak com 2 linhas voltando para a vista de antes.
- O jogo sem janela abre sem erros nem avisos de script.
