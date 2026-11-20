# 01. O tamanho sorteado do tabuleiro

- **Status:** concluída
- **Depende de:** [board-battle/02](../board-battle/02-board-engine.md) (o motor do tabuleiro)

## Contexto

`server/src/domain/board/board.ts` monta o tabuleiro de 3 × 6 (`makeBoard`) e põe cada Ecobeast na linha de começo do lado dele (`startCell`), com as colunas de `START_COLUMNS`. O `startBoardBattle` (`board-engine.ts`) chama os dois, e o `BoardBattleService.begin` chama o `startBoardBattle`. Esta fase faz o tamanho variar por luta ([README](README.md)).

## Escopo

- O sorteio da largura e da altura por formato.
- O tabuleiro, as zonas e as casas de começo num tamanho qualquer.
- O serviço sorteando o tamanho de cada luta nova.

## Fora do escopo

- O jogo ([02](02-board-size-screen.md)): ele já desenha qualquer lista de hexágonos.
- Lutas em andamento: elas guardam o próprio tabuleiro e não mudam.

## Requisitos

- **RF-01:** `BoardSize` é `{ columns: number; rows: number }`. As faixas por formato, com as duas pontas incluídas e cada eixo sorteado sozinho:

  | Formato (`slots`) | Mínimo | Máximo |
  | --- | --- | --- |
  | 1 | 4 | 10 |
  | 2 | 6 | 12 |
  | 3 | 8 | 16 |

  Um formato fora da tabela usa a faixa do 1.
- **RF-02:** `rollBoardSize(slots: number, random: Random): BoardSize` sorteia as colunas e depois as linhas, cada uma uniforme na faixa.
- **RF-03:** `makeBoard(size: BoardSize = DEFAULT_BOARD_SIZE)` monta `columns × rows` hexágonos com o `cellAt` de hoje. `DEFAULT_BOARD_SIZE` é `{ columns: 3, rows: 6 }`, o tabuleiro de hoje.
- **RF-04:** As linhas de começo. Com `rows` linhas, a linha da frente do inimigo é `floor((rows - 4) / 2)`, e a do jogador fica 3 linhas abaixo dela. Com 6 linhas, saem as linhas 1 e 4, como hoje.
- **RF-05:** As zonas de entrada. A do inimigo é a linha da frente dele e a de cima dela, se houver. A do jogador é a linha da frente dele e a de baixo dela, se houver. As duas vão de ponta a ponta da largura. Com 3 × 6, ficam as linhas 0 e 1 e as 4 e 5, como hoje.
- **RF-06:** As colunas de começo. Com `columns` colunas, o centro `c` é `floor((columns - 1) / 2)`, e as colunas de começo ficam em volta dele: `[c]` com 1 vaga, `[c - 1, c + 1]` com 2 e `[c - 2, c, c + 2]` com 3. Quando as de 3 vagas não cabem na largura, elas ficam juntas, `[c - 1, c, c + 1]`. No 3 × 6 padrão, isso dá as colunas de hoje: `[1]`, `[0, 2]` e `[0, 1, 2]`.
- **RF-07:** `startCell(side, position, slots, board)` usa as linhas e as colunas do tabuleiro da luta. O `Board` guarda o tamanho (`size: BoardSize`) para isso. A vista da luta (`battle.board`) passa a trazer `columns` e `rows`, ao lado de `cells` e `zones`, documentados no Swagger.
- **RF-08:** `BoardOptions` ganha `size?: BoardSize`. O `startBoardBattle` monta o tabuleiro com ele, ou com o `DEFAULT_BOARD_SIZE` sem ele. (Na [03](03-board-bites.md), a opção virou `board?: Board`, o tabuleiro já mordido.)
- **RF-09:** O `BoardBattleService.begin` sorteia `rollBoardSize(slots, secureRandom)` com o `slots` pedido para a luta (o do inimigo) e o passa ao `startBoardBattle`. Vale para a luta contra um selvagem, contra um Domador do mapa e no Desafiar.
- **RF-10:** A IA e as regras de alcance, de andar e de entrada não mudam: elas já leem o tabuleiro da luta.

## Critérios de aceite

- [x] Um teste mostra que, com um `Random` de teste, o `rollBoardSize` dá as duas pontas de cada faixa e nunca sai delas, nos três formatos.
- [x] Um teste mostra que o `makeBoard` de 7 × 5 tem 35 hexágonos e as zonas nas linhas 0 e 3 e nas 3 e 4 conforme o RF-05, e que o padrão continua igual ao de hoje.
- [x] Um teste mostra que, num tabuleiro de 10 × 10, os dois lados começam a 3 hexágonos um do outro, nas colunas centrais, com 1, 2 e 3 vagas, e que no 3 × 6 as casas de começo são as de hoje.
- [x] Um teste do serviço (ou e2e) mostra que uma luta nova tem o tamanho dentro da faixa do formato e que a vista traz `columns` e `rows`.
- [x] Lint, typecheck, testes de unidade e e2e do servidor passam.

## Desenho técnico

- `server/src/domain/board/types.ts`: `BoardSize` e `Board.size`.
- `server/src/domain/board/board.ts`: `BOARD_SIZE_RANGES`, `DEFAULT_BOARD_SIZE`, `rollBoardSize`, `makeBoard(size)`, as linhas e colunas de começo e as zonas por tamanho; `BOARD_COLUMNS` e `BOARD_ROWS` saem.
- `server/src/domain/board/board-engine.ts`: `BoardOptions.size`.
- `server/src/board-battle/board-battle.service.ts`: o sorteio no `begin`.
- `server/src/board-battle/board-battle.dto.ts`: `columns` e `rows` no `BoardDto`.
- `server/test/board-battle.e2e-spec.ts`: as duas checagens de 18 hexágonos viram a faixa do formato.
- Documentos: [board-battle/architecture.md](../board-battle/architecture.md) (o tabuleiro) e o `GDD.md`, se ele fixa 3 × 6.

## Verificação

```bash
cd server && npm run lint && npm run typecheck && npm test && npm run test:e2e
```

## Resultado da verificação

Em 2026-11-20: os testes novos do `board.spec.ts` falharam antes do código e passaram depois, e o servidor fica com 1043 testes de unidade passando, lint e typecheck sem erro. No e2e, a luta de teste 1×1 tem as colunas e as linhas entre 4 e 10, `columns × rows` hexágonos e os dois lados a 3 hexágonos. Três e2e da luta usavam as casas fixas do 3 × 6 (a casa do inimigo na captura e o passo de andar) e passaram a ler as casas da resposta de início. Na suíte e2e inteira, só falham os 2 testes da carga inicial (`species_day_phases` e `species_skills`), de antes desta iniciativa.
