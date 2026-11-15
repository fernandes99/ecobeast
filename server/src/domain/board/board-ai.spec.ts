import { always, makeEffect, makeSkill } from '../battle/testing.js';
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
  it('a 2 hexágonos, anda 1 até o Ecobeast do jogador e ataca de onde chegou', () => {
    const scratcher = wild(30, { skills: [{ skillId: 1, currentPp: 35 }] });
    const state = makeBoardState([fighter(10)], [scratcher], {
      cells: { enemy: [at(1, 2)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.move).toBeDefined();
    expect(hexDistance(vez.move!, at(1, 4))).toBe(1);
    expect(vez.action).toMatchObject({ type: 'skill', target: at(1, 4) });
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
      { cells: { enemy: [at(1, 2)] }, queue: [ENEMY] },
      {
        marks: [{ cell: at(1, 3), groundEffectId: FIRE_GROUND, remaining: 6 }],
      },
    );
    for (const roll of [0.1, 0.9]) {
      const vez = chooseEnemyVez(state, catalog, always(roll), ENEMY);
      expect(vez.move).toEqual(at(0, 3));
    }
  });

  it('sem PP, usa a emergência em quem está ao lado', () => {
    const state = makeBoardState([fighter(10)], [wild(30, { skills: NO_PP })], {
      cells: { enemy: [at(1, 2)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.action).toEqual({ type: 'emergency', target: at(1, 4) });
  });

  it('sem nada que alcance depois de andar, só se aproxima e espera', () => {
    const state = makeBoardState([fighter(10)], [wild(30, { skills: NO_PP })], {
      cells: { player: [at(1, 5)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.move).toBeDefined();
    expect(vez.action).toEqual({ type: 'wait' });
  });
});

describe('o selvagem e o countdown (skill-cooldown/01)', () => {
  it('não usa a Técnica bloqueada nem a emergência: só espera', () => {
    const blocked = wild(30, {
      skills: [{ skillId: 1, currentPp: 35, readyRound: 3 }],
    });
    const state = makeBoardState([fighter(10)], [blocked], {
      cells: { enemy: [at(1, 3)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.action).toEqual({ type: 'wait' });
  });

  it('com a Técnica de volta, ataca', () => {
    const ready = wild(30, {
      skills: [{ skillId: 1, currentPp: 35, readyRound: 1 }],
    });
    const state = makeBoardState([fighter(10)], [ready], {
      cells: { enemy: [at(1, 3)] },
      queue: [ENEMY],
    });
    const vez = chooseEnemyVez(state, catalog, always(0.5), ENEMY);
    expect(vez.action).toMatchObject({ type: 'skill', slot: 1 });
  });
});

describe('o selvagem e o alvo do time (skill-editor/03)', () => {
  const SUNBATH = makeSkill({
    id: 40,
    category: 'support',
    power: 0,
    targetSlug: 'ally',
    effects: [makeEffect({ effectSlug: 'heal', percent: 50 })],
  });
  const withSun = boardCatalog([SUNBATH]);

  function pack(allyHp: number) {
    const healer = wild(30, {
      skills: [{ skillId: SUNBATH.id, currentPp: 10 }],
    });
    return makeBoardState(
      [fighter(10)],
      [healer, wild(5, { currentHp: allyHp })],
      {
        slots: { player: 1, enemy: 2 },
        cells: { player: [at(1, 5)], enemy: [at(0, 1), at(1, 1)] },
        queue: [ENEMY],
      },
    );
  }

  it('cura o aliado ao lado com menos da metade do HP, sem andar', () => {
    const vez = chooseEnemyVez(pack(80), withSun, always(0.5), ENEMY);
    expect(vez.move).toBeUndefined();
    expect(vez.action).toEqual({ type: 'skill', slot: 1, target: at(1, 1) });
  });

  it('com todos acima da metade, não usa', () => {
    const vez = chooseEnemyVez(pack(150), withSun, always(0.5), ENEMY);
    expect(vez.action).toEqual({ type: 'wait' });
  });
});
