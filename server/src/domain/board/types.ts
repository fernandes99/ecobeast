import type {
  BattleState,
  SideSlug,
  Spot,
  TurnContext,
} from '../battle/types.js';
import type { HexCoord } from '../exploration/hex.js';

/** Os hexágonos do tabuleiro e a área de largada de cada lado (.specs/board-battle/architecture.md). */
export interface Board {
  cells: HexCoord[];
  /** Em ordem de entrada: a linha da frente primeiro, e as colunas em ordem. */
  zones: Record<SideSlug, HexCoord[]>;
}

export interface GroundMark {
  cell: HexCoord;
  groundEffectId: number;
  /** Quantas vezes da fila ainda faltam. */
  remaining: number;
}

/** Um lugar na fila, com quem ocupava a vaga quando a rodada começou. */
export interface QueueEntry extends Spot {
  teamIndex: number;
}

export interface BoardState extends BattleState {
  board: Board;
  /** Por lado e por vaga: onde está quem ocupa a vaga, ou nulo fora do tabuleiro. */
  cells: Record<SideSlug, (HexCoord | null)[]>;
  marks: GroundMark[];
  round: number;
  /** O que falta da rodada, na ordem. O primeiro é quem joga agora. */
  queue: QueueEntry[];
  /** No `choose_next`: onde quem entra pode ficar. */
  entryCells: HexCoord[];
}

export interface BoardContext extends TurnContext {
  state: BoardState;
}

/** O que o Ecobeast faz na vez, depois de andar. */
export type BoardAction =
  | { type: 'skill'; slot: number; target?: HexCoord }
  | { type: 'emergency'; target?: HexCoord }
  | { type: 'item'; item_id: number; team_index: number }
  | { type: 'switch'; team_index: number }
  | { type: 'capture'; item_id: number; target: HexCoord }
  | { type: 'flee' }
  | { type: 'wait' };

/** A vez de um Ecobeast: andar (opcional) e depois agir. */
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

/** No `choose_action`, uma vez; no `choose_next`, quem entra em cada vaga. */
export type BoardInput = BoardVez | { entries: BoardEntry[] };
