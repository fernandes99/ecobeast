import { always } from '../battle/testing.js';
import { hexDistance } from '../exploration/hex.js';
import { chooseEnemyVez } from './board-ai.js';
import {
  at,
  boardCatalog,
  fighter,
  FIRE_GROUND,
  makeBoardState,
  wild,
} from './testing.js';

const catalog = boardCatalog();
const ENEMY = { side: 'enemy', position: 0 } as const;
const NO_PP = [
  { skillId: 1, currentPp: 0 },
  { skillId: 2, currentPp: 0 },
];

describe('a vez do selvagem', () => {
  it('longe, anda até o Ecobeast do jogador e ataca de onde chegou', () => {
    const scratcher = wild(30, { skills: [{ skillId: 1, currentPp: 35 }] });
    const state = makeBoardState([fighter(10)], [scratcher], {
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.move).toBeDefined();
    expect(hexDistance(vez.move!, at(2, 5))).toBe(1);
    expect(vez.action).toMatchObject({ type: 'skill', target: at(2, 5) });
  });

  it('se já alcança alguém, fica onde está e ataca', () => {
    const state = makeBoardState([fighter(10)], [wild(30)], {
      cells: { enemy: [at(2, 3)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.move).toBeUndefined();
    expect(vez.action.type).toBe('skill');
  });

  it('entre dois hexágonos igualmente bons, prefere o sem marca', () => {
    const onlyScratch = wild(30, { skills: [{ skillId: 1, currentPp: 35 }] });
    const state = makeBoardState(
      [fighter(10)],
      [onlyScratch],
      { queue: [ENEMY] },
      {
        marks: [{ cell: at(2, 4), groundEffectId: FIRE_GROUND, remaining: 6 }],
      },
    );
    for (const roll of [0.1, 0.9]) {
      const vez = chooseEnemyVez(state, catalog, always(roll), ENEMY);
      expect(vez.move).toEqual(at(3, 4));
    }
  });

  it('sem PP, usa a emergência em quem está ao lado', () => {
    const state = makeBoardState([fighter(10)], [wild(30, { skills: NO_PP })], {
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.action).toEqual({ type: 'emergency', target: at(2, 5) });
  });

  it('sem nada que alcance depois de andar, só se aproxima e espera', () => {
    const state = makeBoardState([fighter(10)], [wild(30, { skills: NO_PP })], {
      cells: { player: [at(2, 6)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.move).toBeDefined();
    expect(vez.action).toEqual({ type: 'wait' });
  });
});
