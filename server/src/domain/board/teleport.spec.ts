import { always, makeEffect, makeSkill } from '../battle/testing.js';
import type { BattleEvent, Combatant } from '../battle/types.js';
import type { HexCoord } from '../exploration/hex.js';
import { NOBODY_THERE } from './areas.js';
import { chooseEnemyVez } from './board-ai.js';
import {
  applyBoardVez,
  CHOOSE_DESTINATION,
  DESTINATION_NOT_FREE,
  NO_DESTINATION,
} from './board-engine.js';
import {
  at,
  boardCatalog,
  fighter,
  FIRE_GROUND,
  makeBoardState,
  playVez,
  SCRATCH,
  wild,
} from './testing.js';
import type { BoardState } from './types.js';

const TELEPORT = makeSkill({
  id: 113,
  category: 'support',
  power: 0,
  accuracy: 0,
  cooldown: 3,
  targetSlug: 'any',
  effects: [makeEffect({ effectSlug: 'teleport', targetSlug: 'any' })],
});
const catalog = boardCatalog([TELEPORT]);
const ASLEEP: Partial<Combatant> = { statusSlug: 'sleep', sleepTurns: 99 };

const moth = (overrides: Partial<Combatant> = {}) =>
  fighter(30, {
    skills: [
      { skillId: TELEPORT.id, currentPp: 5 },
      { skillId: SCRATCH.id, currentPp: 35 },
    ],
    ...overrides,
  });

function field(author = moth()): BoardState {
  return makeBoardState([author, fighter(10)], [wild(5, ASLEEP)], {
    slots: { player: 2, enemy: 1 },
    cells: { player: [at(0, 4), at(1, 4)], enemy: [at(1, 0)] },
  });
}

const teleport = (
  target: HexCoord,
  destination?: HexCoord,
  move?: HexCoord,
) => ({
  position: 0,
  ...(move ? { move } : {}),
  action: {
    type: 'skill',
    slot: 1,
    target,
    ...(destination ? { destination } : {}),
  } as const,
});

function types(events: BattleEvent[]): string[] {
  return events.map((event) => event.type);
}

describe('o Teleporte (veilmoth-line/03)', () => {
  it('leva a si mesmo, um aliado e um inimigo para o hexágono livre', () => {
    const self = playVez(field(), teleport(at(0, 4), at(2, 2)), catalog);
    expect(self.state.cells.player[0]).toEqual(at(2, 2));
    expect(self.events).toContainEqual({
      type: 'teleported',
      side: 'player',
      position: 0,
      from: at(0, 4),
      to: at(2, 2),
    });
    expect(self.events).toContainEqual(
      expect.objectContaining({
        type: 'skill_used',
        cells: [at(0, 4), at(2, 2)],
      }),
    );

    const ally = playVez(field(), teleport(at(1, 4), at(0, 1)), catalog);
    expect(ally.state.cells.player[1]).toEqual(at(0, 1));

    const foe = playVez(field(), teleport(at(1, 0), at(2, 5)), catalog);
    expect(foe.state.cells.enemy[0]).toEqual(at(2, 5));
  });

  it('gasta o PP e começa o countdown', () => {
    const { state } = playVez(field(), teleport(at(1, 0), at(2, 5)), catalog);
    const learned = state.player.team[0]!.skills[0]!;
    expect(learned.currentPp).toBe(4);
    expect(learned.readyRound).toBeGreaterThan(state.round);
  });

  it('recusa o destino ocupado, fora do campo, igual ao do alvo ou ausente', () => {
    const refusal = (input: ReturnType<typeof teleport>) =>
      applyBoardVez(field(), input, catalog, always(0.5));
    expect(refusal(teleport(at(1, 0), at(1, 4)))).toEqual({
      error: DESTINATION_NOT_FREE,
    });
    expect(refusal(teleport(at(1, 0), at(9, 9)))).toEqual({
      error: DESTINATION_NOT_FREE,
    });
    expect(refusal(teleport(at(1, 0), at(1, 0)))).toEqual({
      error: DESTINATION_NOT_FREE,
    });
    expect(refusal(teleport(at(1, 0)))).toEqual({ error: CHOOSE_DESTINATION });
    expect(refusal(teleport(at(2, 2), at(2, 3)))).toEqual({
      error: NOBODY_THERE,
    });
  });

  it('recusa o destino numa Técnica que não teleporta', () => {
    expect(
      applyBoardVez(
        makeBoardState([moth()], [wild(5, ASLEEP)], {
          cells: { player: [at(0, 4)], enemy: [at(0, 3)] },
        }),
        {
          position: 0,
          action: {
            type: 'skill',
            slot: 2,
            target: at(0, 3),
            destination: at(2, 2),
          },
        },
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: NO_DESTINATION });
  });

  it('depois de andar, o autor conta onde chegou, e o hexágono de onde saiu fica livre', () => {
    const { state } = playVez(
      field(),
      teleport(at(1, 0), at(0, 4), at(0, 3)),
      catalog,
    );
    expect(state.cells.player[0]).toEqual(at(0, 3));
    expect(state.cells.enemy[0]).toEqual(at(0, 4));

    expect(
      applyBoardVez(
        field(),
        teleport(at(1, 0), at(0, 3), at(0, 3)),
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: DESTINATION_NOT_FREE });
  });

  it('o inimigo Protegido fica onde está, mas o Teleporte conta como usado', () => {
    const state = field();
    state.enemy.team[0]!.isProtected = true;
    const outcome = playVez(state, teleport(at(1, 0), at(2, 5)), catalog);
    expect(outcome.state.cells.enemy[0]).toEqual(at(1, 0));
    expect(types(outcome.events)).toContain('blocked');
    expect(outcome.state.player.team[0]!.skills[0]!.currentPp).toBe(4);
  });

  it('quem está Preso é teleportado e continua Preso', () => {
    const { state } = playVez(
      field(moth({ trappedTurns: 2 })),
      teleport(at(0, 4), at(2, 2)),
      catalog,
    );
    expect(state.cells.player[0]).toEqual(at(2, 2));
    expect(state.player.team[0]!.trappedTurns).toBeGreaterThan(0);
  });

  it('a marca do destino age quando o teleportado termina a vez nela', () => {
    const state = field();
    state.marks = [
      { cell: at(2, 2), groundEffectId: FIRE_GROUND, remaining: 6 },
    ];
    const outcome = playVez(state, teleport(at(0, 4), at(2, 2)), catalog);
    expect(types(outcome.events)).toContain('ground_damage');
    expect(outcome.state.player.team[0]!.currentHp).toBeLessThan(200);
  });
});

describe('a IA e o Teleporte (veilmoth-line/03)', () => {
  function cornered(currentHp: number): BoardState {
    return makeBoardState(
      [fighter(10)],
      [moth({ creatureUid: null, speciesId: 36, currentHp })],
      {
        cells: { player: [at(1, 2)], enemy: [at(1, 1)] },
        queue: [{ side: 'enemy', position: 0 }],
      },
    );
  }

  it('com metade do HP e um inimigo ao lado, foge para o hexágono livre mais longe', () => {
    const vez = chooseEnemyVez(cornered(100), catalog, always(0.5), {
      side: 'enemy',
      position: 0,
    });
    expect(vez).toEqual({
      position: 0,
      action: {
        type: 'skill',
        slot: 1,
        target: at(1, 1),
        destination: at(0, 5),
      },
    });
  });

  it('com o HP cheio, não usa o Teleporte', () => {
    const vez = chooseEnemyVez(cornered(200), catalog, always(0.5), {
      side: 'enemy',
      position: 0,
    });
    expect(vez.action).not.toEqual(expect.objectContaining({ slot: 1 }));
  });
});
