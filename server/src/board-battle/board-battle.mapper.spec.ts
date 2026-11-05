import {
  at,
  fighter,
  FIRE_GROUND,
  makeBoardState,
  wild,
} from '../domain/board/testing.js';
import type { BoardVezBodyDto } from './board-battle.dto.js';
import { toBoardBattleDto, toBoardInput } from './board-battle.mapper.js';

describe('toBoardBattleDto', () => {
  const state = () =>
    makeBoardState(
      [fighter(30), fighter(10)],
      [wild(5, { traitSlug: 'hard_shell' })],
      {
        queue: [
          { side: 'player', position: 0 },
          { side: 'enemy', position: 0 },
        ],
      },
      {
        round: 2,
        marks: [{ cell: at(2, 3), groundEffectId: FIRE_GROUND, remaining: 4 }],
        entryCells: [at(0, 5)],
      },
    );

  it('traz a rodada, o tabuleiro, as marcas e a fila', () => {
    const dto = toBoardBattleDto(state());
    expect(dto.round).toBe(2);
    expect(dto.board.cells).toHaveLength(42);
    expect(dto.board.zones.player[0]).toEqual(at(0, 5));
    expect(dto.marks).toEqual([
      { ...at(2, 3), ground_effect_id: FIRE_GROUND, remaining: 4 },
    ]);
    expect(dto.queue).toEqual([
      { side: 'player', position: 0 },
      { side: 'enemy', position: 0 },
    ]);
  });

  it('traz onde cada um está e onde quem entra pode ficar', () => {
    const dto = toBoardBattleDto(state());
    expect(dto.player.cells).toEqual([at(2, 5)]);
    expect(dto.enemy.cells).toEqual([at(2, 1)]);
    expect(dto.player.entry_cells).toEqual([at(0, 5)]);
  });

  it('continua escondendo as Técnicas e o Traço do selvagem', () => {
    const json = JSON.stringify(toBoardBattleDto(state()).enemy);
    expect(json).not.toContain('skill');
    expect(json).not.toContain('hard_shell');
  });
});

describe('toBoardInput', () => {
  it('leva a vez com o passo e a Técnica, só com os campos dela', () => {
    const body = {
      position: 0,
      move: { q: 1, r: 3 },
      action: { type: 'skill', slot: 2, item_id: 9, target: { q: 1, r: 2 } },
    } as BoardVezBodyDto;
    expect(toBoardInput(body)).toEqual({
      position: 0,
      move: { q: 1, r: 3 },
      action: { type: 'skill', slot: 2, target: { q: 1, r: 2 } },
    });
  });

  it('sem passo, a vez não tem move', () => {
    const body = { position: 1, action: { type: 'wait' } } as BoardVezBodyDto;
    expect(toBoardInput(body)).toEqual({
      position: 1,
      action: { type: 'wait' },
    });
  });

  it('no choose_next, leva quem entra e onde', () => {
    const body = {
      entries: [{ position: 0, team_index: 2, cell: { q: 0, r: 6 } }],
    } as BoardVezBodyDto;
    expect(toBoardInput(body)).toEqual({
      entries: [{ position: 0, team_index: 2, cell: { q: 0, r: 6 } }],
    });
  });
});
