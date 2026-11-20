# board-size

O tabuleiro da luta deixa de ter sempre 3 colunas por 6 linhas: a cada luta, o servidor sorteia a largura e a altura numa faixa que cresce com o formato (1×1, 2×2 ou 3×3). Os dois lados começam perto do meio, à mesma distância de hoje, e o campo a mais em volta vira espaço para recuar, fugir de uma marca e cercar. A luta abre com a câmera passando pelos dois times, no tamanho de hexágono de hoje, e para em quem age primeiro; a pinça afasta até o campo inteiro e aproxima até 2,5 vezes o hexágono de hoje.

## Contexto

Em 2026-11-20, o dono pediu: "vamos agora melhorar as zonas de batalha, hoje ela é fixa em um único tamanho. Eu quero que ela tenha tamanhos aleatórios." Ele sugeriu de 4×4 a 10×10 no 1×1, de 6×6 a 12×12 no 2×2 e de 8×8 a 16×16 no 3×3, às vezes quadrado e às vezes retangular, e pediu a pinça e o arrasto no campo.

O motivo, nas palavras dele: "Eu quero ter mais surpresas com o terreno, o tamanho dele vai ser um dos pontos, mas futuramente vamos colocar talvez objetos que vão ocupar um hexagono ou outro, que podem beneficiar ou não um dos times [...]. A ideia aqui é melhorar a experiencia das lutas, ser algo mais divertido e dinamico."

Hoje:

- **Servidor:** `server/src/domain/board/board.ts` monta sempre 3 × 6 hexágonos (`BOARD_COLUMNS` e `BOARD_ROWS`). O jogador começa na linha 4 e o inimigo na 1, com as zonas de entrada nas duas linhas de cada ponta. O tabuleiro já é guardado como uma lista de hexágonos (`Board.cells`), e a vista manda essa lista ao jogo.
- **Jogo:** o `BoardView` desenha qualquer lista de hexágonos, e o `board_battle_screen.gd` já tem a pinça, a roda do mouse e o arrasto ([camera-zoom/02](../camera-zoom/02-battle-zoom.md)), com o zoom de 1 (o campo inteiro) a 2,5 vezes isso.
- **Ritmo:** cada Ecobeast anda 1 hexágono por vez, e a maioria das Técnicas tem alcance 1.

Claude propôs três caminhos para o começo da luta num campo grande:

- **A:** os dois lados começam perto do meio, à distância de hoje, andando 1 por vez.
- **B:** cada lado começa na sua ponta, andando mais por vez.
- **C:** cada lado começa na sua ponta, andando 1 por vez, o que daria até 14 vezes só andando.

O dono escolheu o **A**.

## Objetivos

1. Cada luta tem um tabuleiro de tamanho sorteado pelo servidor, dentro da faixa do formato, quadrado ou retangular.
2. Os dois lados começam perto do centro, à distância de hoje, e a luta mantém o ritmo.
3. A abertura da luta mostra o time do jogador, depois o inimigo e por fim quem age primeiro, e a pinça e o arrasto servem num campo de qualquer tamanho.
4. O tabuleiro continua sendo uma lista de hexágonos, pronta para os objetos que ocupam hexágonos de uma iniciativa futura.

## Anti-objetivos

- A luta ficar mais lenta: ninguém passa várias vezes só andando antes do primeiro golpe.
- Mudar o equilíbrio das Técnicas, o andar de 1 hexágono por vez ou a IA além do que o campo novo exige.

## Decisões

Do dono, em 2026-11-20:

| Decisão | Motivo |
| --- | --- |
| O caminho A: os lados começam perto do meio, à distância de hoje, andando 1 por vez | Manter o ritmo de hoje e usar o campo maior como espaço de manobra, onde os objetos de depois vão entrar |
| As faixas: de 4 a 10 no 1×1, de 6 a 12 no 2×2 e de 8 a 16 no 3×3, quadrado ou retangular | A sugestão dele, _a revisar_ depois de jogar |
| As bordas irregulares, com mordidas que tiram alguns hexágonos da borda, sem tocar no começo dos times, sem partir o campo e deixando pelo menos 80% dele | O pedido dele ("é possivel deixar as bordas um pouco irregulares, para não ser um campo totamente retangulo ou quadrado?") e a proposta de Claude, aprovada ("Sim, pode seguir") |
| A câmera abre mostrando o time do jogador, com zoom, espera 2 s, passa ao time inimigo no mesmo zoom, espera 2 s e depois foca quem faz a primeira vez | O pedido dele: "Eu quero que a camera começe mostrando meu time com um zoom espere uns 2s, e depois faça uma transição até o time inimigo no mesmo zoom e espere 2s, e depois foca quem for fazer a primeira rodada." |

Escolhas de Claude (corrigíveis; ao mudar uma, atualize aqui e na fase):

| Decisão | Motivo |
| --- | --- |
| A largura e a altura são sorteadas cada uma, uniformes e independentes, dentro da faixa | Sai quadrado às vezes e retangular às vezes, como o dono pediu, sem uma regra a mais |
| O formato da faixa é o número de vagas pedido para a luta (o `slots` do inimigo) | Um Domador 3×3 contra um jogador com 2 Ecobeasts de pé continua num campo de 3×3 |
| As faixas e a distância ficam como constantes em `board.ts`, e não no catálogo | São regras do motor, como o `MOVE_RANGE`; viram tabela se o dono quiser mexer pelo painel |
| As linhas da frente dos dois lados ficam a 3 linhas uma da outra, centralizadas na altura; as colunas de começo ficam centralizadas na largura | É a distância de hoje (linhas 1 e 4) |
| A zona de entrada de cada lado é a linha da frente dele e a de trás, de ponta a ponta | É a regra de hoje (duas linhas de largura inteira), levada para o meio |
| O zoom da abertura é o do hexágono de hoje (o de um 3 × 6 inteiro na mesma área), ou o campo inteiro, se ele já couber assim; as passagens duram 0,8 s; um toque na tela pula a abertura | O hexágono que o dono já aprovou na [board-battle/06](../board-battle/06-board-look.md); pular, para não esperar 4 s em toda luta |
| A pinça afasta até o campo inteiro e aproxima até 2,5 vezes o hexágono de hoje, e não mais 2,5 vezes o campo | Num 16 × 16, 2,5 vezes o campo inteiro ainda deixaria os Ecobeasts pequenos |
| Quem faz a primeira vez é o dono do primeiro `vez_started` da primeira resposta | É quem a luta mostra agindo primeiro, inimigo ou não |
| O tamanho é sorteado no serviço (`rollBoardSize`) e entra no motor pelas opções; sem ele, o motor usa os 3 × 6 de hoje | Os testes do motor continuam com o tabuleiro e o sorteio de hoje |

## Fora do escopo

- Objetos, obstáculos ou buracos no meio do tabuleiro: só a borda ganha mordidas ([03](03-board-bites.md)).
- A câmera seguir o Ecobeast da vez depois da abertura.
- Andar mais de 1 hexágono por vez.

## Fases

| # | Fase | Entrega | Status |
| --- | --- | --- | --- |
| 1 | [01-board-size-rules](01-board-size-rules.md) | No servidor: o sorteio do tamanho, o tabuleiro e as zonas no tamanho sorteado e os lados começando perto do meio | concluída |
| 2 | [02-board-size-screen](02-board-size-screen.md) | No jogo: a abertura da câmera pelos dois times e o zoom pelo tamanho do hexágono, com o campo de qualquer tamanho | concluída (falta o dono conferir no celular) |
| 3 | [03-board-bites](03-board-bites.md) | No servidor: as mordidas na borda, para o campo não ser um retângulo cheio | concluída (falta o dono conferir no jogo) |
