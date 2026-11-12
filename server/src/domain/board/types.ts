import type {
  BattleState,
  SideSlug,
  Spot,
  TurnContext,
} from '../battle/types.js';
import type { HexCoord } from '../exploration/hex.js';

export interface Board {
  cells: HexCoord[];
  /** Em ordem de entrada: a linha da frente primeiro, e as colunas em ordem. */
  zones: Record<SideSlug, HexCoord[]>;
}

export interface GroundMark {
  cell: HexCoord;
  groundEffectId: number;
  remaining: number;
}

export interface QueueEntry extends Spot {
  teamIndex: number;
}

export interface BoardState extends BattleState {
  board: Board;
  cells: Record<SideSlug, (HexCoord | null)[]>;
  marks: GroundMark[];
  round: number;
  queue: QueueEntry[];
  entryCells: HexCoord[];
}

export interface BoardContext extends TurnContext {
  state: BoardState;
}

export type BoardAction =
  | { type: 'skill'; slot: number; target?: HexCoord }
  | { type: 'emergency'; target?: HexCoord }
  | { type: 'item'; item_id: number; team_index: number }
  | { type: 'switch'; team_index: number }
  | { type: 'capture'; item_id: number; target: HexCoord }
  | { type: 'flee' }
  | { type: 'wait' };

export interface BoardVez {
  position: number;
  move?: HexCoord;
  action: BoardAction;
}

export interface BoardEntry {
  position: number;
  team_index: number;
  cell: HexCoord;
}

export type BoardInput = BoardVez | { entries: BoardEntry[] };
