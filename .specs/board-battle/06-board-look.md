# 06. Tabuleiro menor e a tela no estilo do print

- **Status:** concluída (falta o dono jogar no editor: ver Verificação)
- **Depende de:** [05](05-board-actions.md)

## Contexto

O dono jogou a luta no tabuleiro em 2026-11-05 e mandou um print de referência. O tabuleiro de 6 × 7 deixa os hexágonos pequenos na tela, e a tela da [04](04-board-screen.md) é uma coluna de controles simples. Esta fase diminui o tabuleiro, aumenta os hexágonos e refaz a tela no estilo do print: cartões dos dois lados, botões grandes e coloridos e a equipe embaixo. Também corrige o Ecobeast que anda sozinho dentro do hexágono. Do print vale o formato. Os nomes e a arte são os do jogo.

## Escopo

- Servidor: o tabuleiro de 3 colunas × 6 linhas.
- Jogo: o fundo de floresta, os hexágonos translúcidos e o destaque de quem joga.
- Jogo: a tela nova, com o cartão do selvagem, a rodada, o cartão de quem joga, os botões e a equipe.
- Jogo: o Ecobeast só anda quando muda de hexágono.

## Fora do escopo

- Tabuleiros sorteados ou por bioma, e um fundo por bioma.
- Animações de Técnica.
- A fila de vezes na tela. Ela sai por enquanto, a pedido do dono, e o `TurnQueueBar` fica sem uso.
- O painel de dica do print. Os avisos continuam numa linha de texto, decisão do dono.

## Requisitos

**Tabuleiro**

- **RF-01:** O tabuleiro tem 3 colunas × 6 linhas, 18 hexágonos. A área do inimigo são as linhas 0 e 1, a do meio as 2 e 3, e a do jogador as 4 e 5. Cada lado começa na linha da frente da sua área, a 1 o inimigo e a 4 o jogador, a 3 hexágonos. As colunas de largada (_a revisar_): 1 vaga na coluna 1, 2 vagas nas colunas 0 e 2, 3 vagas nas 3. Decisão do dono: "3 de largura e 6 de altura".
- **RF-02:** Os hexágonos ficam do tamanho que tinham no tabuleiro de 6 colunas, e o tabuleiro menor fica centrado. O dono testou hexágonos do maior tamanho que cabe e achou grande demais. Cada Ecobeast aparece com o `board.png`, uma pixel art de 30 a 46 pixels de altura (pela altura do catálogo), com contorno escuro, gerada do `front.png` por `res://tools/board_sprites.gd` e mostrada 2× maior, sem filtro, com uma sombra embaixo. As folhas `idle` e `walk` do mapa, de 7 a 24 pixels, ficavam em blocos quando ampliadas: o dono pediu uma pixel art mais refinada, como no print. Sobre o Ecobeast fica só a barra de HP: o nome e o nível vão para os cartões.
- **RF-03:** Atrás de tudo está o fundo de floresta do dono (`res://assets/backgrounds/board/temperate.jpg`, a segunda imagem que ele mandou), cobrindo a tela sem deformar. Os hexágonos são translúcidos e iguais em todo o tabuleiro, sem cor por área. Na [08](08-board-ground.md), a pedido do dono, o chão do mapa de Explorar passou a cobrir a tela, e o fundo de floresta saiu.
- **RF-04:** O hexágono de quem joga agora fica em azul escuro, se ele for do jogador, ou em vermelho escuro, se for selvagem, com uma borda branca. Na primeira versão, o sprite dele também ganhava um contorno branco; o dono pediu para tirar, na [07](07-battle-sprites.md).

**Tela**

- **RF-05:** Em cima: o cartão do selvagem, com o retrato, o nome, o nível, os Elementos e o HP em barra e em números; à direita, "Rodada N" e o botão de informação, que abre o histórico. O nome do Domador não aparece, porque a luta é contra selvagens. O cartão mostra o selvagem que joga agora, ou o último que jogou ou foi atingido. Na [08](08-board-ground.md), o dono tirou a rodada, e o "?" ficou sozinho no canto.
- **RF-06:** Embaixo do tabuleiro: o cartão do Ecobeast do jogador, igual ao do selvagem, com quem joga agora ou o último do jogador que jogou.
- **RF-07:** Os botões, grandes e coloridos, com ícone: Atacar (vermelho), Passar a vez (azul), Mochila (verde) e Fugir (roxo). Atacar troca os botões pelas 4 Técnicas e por "Voltar", ou pela Técnica de emergência, sem PP em todas. O resto da vez (andar, alvo e envio) é o da [04](04-board-screen.md) e da [05](05-board-actions.md). Na [08](08-board-ground.md), o dono achou o visual feio e pediu para tirá-lo por completo: os botões, os painéis e os cartões voltaram ao tema do jogo, e o `board_skin.gd` saiu, até ele trazer outro pacote de GUI.
- **RF-08:** No pé da tela, a equipe: o retrato e a barra de HP de cada um, com destaque para quem joga e os caídos apagados. A barra só mostra. Na ponta dela fica o botão Trocar. Decisão do dono. Na [08](08-board-ground.md), o dono tirou a equipe e o Trocar do pé da tela.
- **RF-09:** A fila de vezes sai da tela. Os avisos (recusa do servidor, a Esfera, a fuga) aparecem numa linha de texto, com contorno, sobre o fundo.

**Sprite**

- **RF-10:** No tabuleiro, o Ecobeast fica parado, só respirando (o corpo estica e encolhe de leve), e dá um pulinho por hexágono quando anda. No mapa, o `CreatureSprite` também só passeia depois do `wander_in`. Hoje ele passeia dentro do hexágono: o `CreatureSprite` é o do mapa, e o Godot religa o `_process` dele ao entrar na árvore, mesmo depois do `set_process(false)`.

## Critérios de aceite

- [ ] O tabuleiro tem 3 × 6 hexágonos, maiores que antes, e um 1 × 1 começa com os dois na coluna 1, a 3 hexágonos.
- [ ] Os hexágonos são translúcidos sobre a floresta, sem verde nem vermelho por área.
- [ ] Quem joga tem o hexágono destacado, com borda branca.
- [ ] O topo mostra o cartão do selvagem e a rodada, sem o nome do Domador e sem a fila.
- [ ] Atacar mostra as Técnicas; Voltar volta aos botões.
- [ ] A equipe aparece embaixo, e Trocar abre a troca.
- [ ] Parado, o Ecobeast não sai do lugar nem toca a folha `walk`.
- [ ] Os testes do servidor passam, e o projeto abre sem erros nem avisos de script.

## Desenho técnico

**Servidor:** `server/src/domain/board/board.ts` (as constantes), e os testes que dependem do tamanho e da largada.

**Jogo:**

- `res://ui/components/creature_sprite.gd`: o passeio só anda com `wander_in`.
- `res://screens/board_battle/board_view.gd`: sem o nome sobre o Ecobeast, com a cor do hexágono ativo por lado e o contorno no sprite.
- `res://screens/board_battle/board_creature_card.gd` e `.tscn`: o cartão de cada lado.
- `res://screens/board_battle/board_team_bar.gd`: a equipe no pé da tela.
- `res://screens/board_battle/board_battle_screen.gd` e `.tscn`: a tela nova.
- `res://screens/board_battle/board_skin.gd`: os painéis e os botões com as peças de `res://assets/ui/board/`, recortadas da folha de assets que o dono mandou em 2026-11-05: o painel azul chanfrado, os fundos dos 4 botões (sem o ícone e o nome que vinham na imagem), os ícones de espadas, mochila e corrida, os ícones de 12 Elementos (Fera e Arcano não têm) e o "?" do histórico.
- `res://tools/board_sprites.gd` e os `board.png` de cada Ecobeast.

## Verificação

```bash
cd server && npm run typecheck && npm run lint && npm test && npm run test:e2e
godot --headless --path client --quit-after 60
```

F5, Explorar zona, um encontro e o "Teste 3×3". Quem implementa diz o que conferiu e o que ficou para o dono.

## Tarefas

- [x] Tabuleiro de 3 × 6 no servidor (RF-01).
- [x] O sprite parado (RF-10).
- [x] Fundo, hexágonos, destaque e contorno (RF-02 a RF-04).
- [x] A tela nova (RF-05 a RF-09).
- [x] Atualizar o README e o `architecture.md`, rodar a verificação e fazer o commit `feat: tabuleiro menor e a tela no estilo do print`.

## Divergências

O que a implementação fez diferente desta spec, e por quê:

- **O cartão e a equipe montam os nós no código**, sem `.tscn`: são poucos nós, e o estilo vem todo do `BattleStyles`.
- **"Passar a vez" virou "Passar"** no botão, para caber com o ícone nos 4 botões da largura. O ícone é uma ampulheta nova, `res://ui/icons/wait.svg`.
- **`BattleHud`, `IconCircle` e `BattleStyles` não foram usados**, nem os ícones `swords.svg` e `run.svg`: a primeira versão desta fase usou `BattleStyles` e os SVG, e o dono achou o resultado feio; a segunda usa as peças da folha dele. O cartão do print tem o retrato do Ecobeast, e não o ícone do Elemento num círculo, como o `BattleHud`. Eles continuam fora do repositório, à espera da decisão do dono.
- **Os testes do motor que dependiam do tamanho foram reescritos** para o 3 × 6, e nenhum usa mais hexágono fora do tabuleiro. "Com o selvagem mais rápido, ele anda e ataca" virou "ele ataca": a 3 hexágonos, a Chama Espiral já alcança sem andar. "Passar por cima da marca" já tinha virado "sair de cima da marca" na [05](05-board-actions.md).

## Resultado da verificação

**Conferido por quem implementou**, sem janela:

- Os testes do motor do tabuleiro (51) e os e2e da luta no tabuleiro (22) passam com o 3 × 6; a suíte inteira roda antes do commit.
- Um teste do `CreatureSprite` fora do mapa mostrou o bug (o sprite saiu de (100, 100) e tocou a `walk`) e depois a correção (parado, só no `idle`).
- O projeto abre sem erros nem avisos; a cena nova instancia; o cartão mostra um Ecobeast real do catálogo, e a barra da equipe tem um retrato por Ecobeast e apaga quem cai.

- Com uma janela, um script abriu a tela de verdade com uma luta 3 × 3 montada nele (sem o servidor e sem a sessão do dono) e salvou prints: os Ecobeasts, os hexágonos, o destaque de quem joga, os cartões, os botões, a equipe e o "?" aparecem como no print de referência.

**Fica para o dono, no editor (F5):** jogar a tela. O painel das Técnicas (depois de Atacar) ainda usa os botões da luta antiga. O tamanho dos cartões, as cores dos botões e o encaixe de tudo em 720 × 1280 não foram vistos.

