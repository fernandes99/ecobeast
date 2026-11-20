# 03. As bordas irregulares

- **Status:** concluída (falta o dono conferir no jogo)
- **Depende de:** [01](01-board-size-rules.md)

## Contexto

Depois da [01](01-board-size-rules.md), todo tabuleiro é um retângulo cheio de `columns × rows`. Em 2026-11-20, o dono pediu: "é possivel deixar as bordas um pouco irregulares, para não ser um campo totamente retangulo ou quadrado?". Claude propôs tirar algumas "mordidas" da borda, e o dono aprovou ("Sim, pode seguir").

O jogo já desenha qualquer lista de hexágonos: onde falta um, o `BoardView.cover` pinta o chão de fora, como em volta do tabuleiro.

## Escopo

- O sorteio das mordidas na borda do tabuleiro de cada luta nova.

## Fora do escopo

- Buracos no meio do tabuleiro, obstáculos e objetos.
- Mudar o jogo: ele já desenha o tabuleiro com buracos.

## Requisitos

- **RF-01:** `rollBoard(slots: number, random: Random): Board` sorteia o tamanho (`rollBoardSize`), monta o retângulo (`makeBoard`) e tira as mordidas (`biteBoard`). O `BoardBattleService.begin` passa a usar o `rollBoard` e entrega o tabuleiro pronto ao `startBoardBattle`, pela opção `board?: Board` no lugar da `size`; sem ela, o motor usa o `makeBoard()` padrão.
- **RF-02:** O número de mordidas: o máximo é `clamp(round(casas / 20), 1, 5)` e o mínimo é `min(2, máximo)`; o número é sorteado uniforme entre os dois (_a revisar_). Um 4 × 4 leva 1 mordida, um 10 × 10 de 2 a 5, e um 16 × 16 de 2 a 5.
- **RF-03:** Cada mordida começa numa casa da borda (com menos de 6 vizinhos no tabuleiro) sorteada entre as que podem sair, e tira de 1 a 3 casas (sorteado): depois da primeira, cada casa a mais é sorteada entre os vizinhos das casas já tiradas nessa mordida que ficam a até 1 hexágono da primeira e podem sair. Uma mordida que não acha casa para começar ou para crescer para ali.
- **RF-04:** Uma casa só pode sair se:
  - não é uma casa protegida: as casas de começo dos dois lados, com 1, 2 e 3 vagas, e os vizinhos delas;
  - o tabuleiro continua de uma peça só sem ela (todas as casas ligadas por vizinhos);
  - sobram pelo menos 80% das casas do retângulo.
- **RF-05:** As zonas de entrada perdem as casas que saíram, na mesma ordem. O `Board.size` continua sendo o retângulo sorteado, e a vista manda o `columns` e o `rows` dele.

## Critérios de aceite

- [x] Um teste com 300 sementes em cada formato mostra que o tabuleiro mordido fica de uma peça só, com pelo menos 80% das casas, com as casas protegidas, com as zonas dentro do tabuleiro e com as casas de começo de 1, 2 e 3 vagas livres.
- [x] O mesmo teste mostra que um 4 × 4 perde no máximo 3 casas e que, nos tabuleiros de 6 × 6 para cima, quase todo sorteio (mais de 90%) perde alguma casa.
- [x] O e2e da luta de teste confere que as casas são no máximo `columns × rows` e no mínimo 80% disso.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Desenho técnico

- `server/src/domain/board/board.ts`: `rollBoard`, `biteBoard` e as constantes `MIN_KEPT = 0.8`, `CELLS_PER_BITE = 20`, `MAX_BITES = 5` e `MAX_BITE = 3`.
- `server/src/domain/board/board-engine.ts`: `BoardOptions.board` no lugar de `size`.
- `server/src/board-battle/board-battle.service.ts`: o `rollBoard`.
- `server/test/board-battle.e2e-spec.ts`: as casas entre 80% e 100% do retângulo.
- Documentos: [board-battle/architecture.md](../board-battle/architecture.md) e o README.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

## Resultado da verificação

Em 2026-11-20: os testes novos do `board.spec.ts` falharam antes do código (o `rollBoard` não existia) e passaram depois. Com 300 sementes em cada formato, o tabuleiro mordido ficou de uma peça só, com pelo menos 80% das casas, as casas protegidas e as zonas dentro dele, o 4 × 4 perdeu no máximo 3 casas, e mais de 90% dos tabuleiros de 6 × 6 para cima perderam alguma. A primeira versão conferia se o tabuleiro continuava inteiro em toda casa candidata e estourou o tempo no 3×3; a de agora confere só a casa sorteada. O servidor fica com 1046 testes de unidade passando, lint e typecheck sem erro, e o e2e da luta passa com as casas entre 80% e 100% do retângulo. O jogo não mudou: o `BoardView.cover` já pinta o chão de fora onde falta casa. Não foi visto com janela.
