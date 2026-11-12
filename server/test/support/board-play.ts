import { hexDistance, hexNeighbors } from '../../src/domain/exploration/hex.js';

const ARRANHAO_SLOT = 1;
/** Bem mais vezes do que uma luta precisa; só evita um teste sem fim. */
const MAX_VEZES = 80;

export interface Cell {
  q: number;
  r: number;
}

export interface PlayableBattle {
  phase: string;
  board: { cells: Cell[] };
  queue: { side: string; position: number }[];
  player: { cells: (Cell | null)[] };
  enemy: { cells: (Cell | null)[] };
}

const sameCell = (a: Cell, b: Cell) => a.q === b.q && a.r === b.r;

/**
 * A vez de quem joga agora: ao lado de um inimigo, usa Arranhão nele; senão,
 * anda 1 hexágono na direção do mais perto e, se ficar ao lado, usa Arranhão.
 */
export function attackVez(battle: PlayableBattle): object {
  const position = battle.queue[0]!.position;
  const me = battle.player.cells[position]!;
  const foes = battle.enemy.cells.filter((cell) => cell !== null);
  const nextTo = (from: Cell) =>
    foes.find((foe) => hexDistance(from, foe) === 1);
  const gap = (from: Cell) =>
    Math.min(...foes.map((foe) => hexDistance(from, foe)));
  const scratch = (target: Cell) => ({
    type: 'skill',
    slot: ARRANHAO_SLOT,
    target,
  });
  const beside = nextTo(me);
  if (beside) return { position, action: scratch(beside) };
  const taken = [...battle.player.cells, ...battle.enemy.cells].filter(
    (cell) => cell !== null,
  );
  const steps = hexNeighbors(me)
    .filter(
      (cell) =>
        battle.board.cells.some((boardCell) => sameCell(boardCell, cell)) &&
        !taken.some((other) => sameCell(other, cell)),
    )
    .sort((a, b) => gap(a) - gap(b));
  const move = steps[0];
  if (!move) return { position, action: { type: 'wait' } };
  const target = nextTo(move);
  return {
    position,
    move,
    action: target ? scratch(target) : { type: 'wait' },
  };
}

export const waitVez = (battle: PlayableBattle) => ({
  position: battle.queue[0]!.position,
  action: { type: 'wait' },
});

export const fleeVez = (battle: PlayableBattle) => ({
  position: battle.queue[0]!.position,
  action: { type: 'flee' },
});

export async function playOut<T extends { battle: PlayableBattle }>(
  act: (body: object) => Promise<T>,
  first: T,
  vez: (battle: T['battle']) => object = attackVez,
): Promise<T> {
  let body = first;
  for (let turn = 0; turn < MAX_VEZES; turn++) {
    if (body.battle.phase !== 'choose_action') break;
    body = await act(vez(body.battle));
  }
  return body;
}
