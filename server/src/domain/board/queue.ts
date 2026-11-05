import { combatantAt } from '../battle/field.js';
import { orderTurn } from '../battle/turn-order.js';
import type { Random } from '../battle/types.js';
import { standingOnBoard } from './board.js';
import type { BoardState, QueueEntry } from './types.js';

/**
 * A fila da rodada: todos de pé no tabuleiro, dos dois lados, pela Velocidade
 * efetiva, com o empate sorteado. A prioridade das Técnicas não conta.
 */
export function roundQueue(state: BoardState, random: Random): QueueEntry[] {
  const spots = [
    ...standingOnBoard(state, 'player'),
    ...standingOnBoard(state, 'enemy'),
  ];
  const entries = spots.map((spot) => ({
    spot,
    priority: 0,
    combatant: combatantAt(state, spot),
  }));
  return orderTurn(entries, random).map(({ spot }) => ({
    ...spot,
    teamIndex: state[spot.side].activeIndices[spot.position]!,
  }));
}
