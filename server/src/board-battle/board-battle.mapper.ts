import { toBattleDto } from '../battle/battle.mapper.js';
import type { BattleTamer } from '../battle/battle.store.js';
import type {
  BoardAction,
  BoardInput,
  BoardState,
} from '../domain/board/types.js';
import type {
  BoardActionDto,
  BoardBattleDto,
  BoardVezBodyDto,
} from './board-battle.dto.js';

export function toBoardBattleDto(
  state: BoardState,
  tamer: BattleTamer | null = null,
): BoardBattleDto {
  const dto = toBattleDto(state);
  return {
    ...dto,
    round: state.round,
    board: state.board,
    marks: state.marks.map(({ cell, groundEffectId, remaining }) => ({
      ...cell,
      ground_effect_id: groundEffectId,
      remaining,
    })),
    queue: state.queue.map(({ side, position }) => ({ side, position })),
    player: {
      ...dto.player,
      cells: state.cells.player,
      entry_cells: state.entryCells,
    },
    enemy: { ...dto.enemy, cells: state.cells.enemy },
    tamer: tamer && { name_id: tamer.nameId, source: tamer.source },
  };
}

export function toBoardInput(body: BoardVezBodyDto): BoardInput {
  if (body.entries) {
    return {
      entries: body.entries.map(({ position, team_index, cell }) => ({
        position,
        team_index,
        cell: { q: cell.q, r: cell.r },
      })),
    };
  }
  return {
    position: body.position!,
    ...(body.move && { move: { q: body.move.q, r: body.move.r } }),
    action: toBoardAction(body.action!),
  };
}

function toBoardAction(action: BoardActionDto): BoardAction {
  const target = action.target && { q: action.target.q, r: action.target.r };
  switch (action.type) {
    case 'skill':
      return { type: 'skill', slot: action.slot!, ...(target && { target }) };
    case 'emergency':
      return { type: 'emergency', ...(target && { target }) };
    case 'item':
      return {
        type: 'item',
        item_id: action.item_id!,
        team_index: action.team_index!,
      };
    case 'switch':
      return { type: 'switch', team_index: action.team_index! };
    case 'capture':
      return { type: 'capture', item_id: action.item_id!, target: target! };
    case 'flee':
      return { type: 'flee' };
    case 'wait':
      return { type: 'wait' };
  }
}
