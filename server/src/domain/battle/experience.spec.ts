import { startBattle } from './engine.js';
import {
  always,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeSkill,
  makeState,
  play,
} from './testing.js';
import type { BattleAction, Combatant } from './types.js';

const SCRATCH = makeSkill({ id: 1 });
const IDLE = makeSkill({
  id: 4,
  power: 0,
  accuracy: 0,
  category: 'support',
  targetSlug: 'self',
});
const NILU = 4;
/** Um selvagem de nível 5 com xp base 62 dá 44 de XP. */
const catalog = makeCatalog({}, [SCRATCH, IDLE], {}, {}, { [NILU]: 62 });
const ATTACK: BattleAction = { type: 'skill', slot: 1 };

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    skills: [{ skillId: SCRATCH.id, currentPp: 10 }],
    ...overrides,
  });
}

/** O inimigo de nível 5 que cai no primeiro golpe e nunca age antes. */
function weakWild(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({
    creatureUid: null,
    speciesId: NILU,
    currentHp: 1,
    stats: { hp: 19, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 1 },
    skills: [{ skillId: IDLE.id, currentPp: 10 }],
    ...overrides,
  });
}

describe('quem esteve em campo', () => {
  it('o inimigo começa com quem está em campo do outro lado', () => {
    const { state } = startBattle(
      [fighter(), fighter()],
      [weakWild()],
      true,
      catalog,
      always(0.5),
    );
    expect(state.enemy.team[0]!.foughtBy).toEqual([0]);
  });

  it('quem entra numa troca passa a contar, sem repetir', () => {
    let { state } = play(
      makeState([fighter(), fighter()], weakWild({ currentHp: 19 })),
      { type: 'switch', team_index: 1 },
      catalog,
    );
    ({ state } = play(state, { type: 'switch', team_index: 0 }, catalog));
    expect(state.enemy.team[0]!.foughtBy).toEqual([0, 1]);
  });

  it('o próximo inimigo começa com quem está em campo', () => {
    const { state } = play(
      makeState(fighter(), [weakWild(), weakWild()]),
      ATTACK,
      catalog,
    );
    expect(state.enemy.activeIndices[0]).toBe(1);
    expect(state.enemy.team[1]!.foughtBy).toEqual([0]);
  });
});

describe('XP ao derrubar o inimigo', () => {
  it('quem venceu sozinho recebe tudo, logo depois do desmaio', () => {
    const { state, events } = play(
      makeState(fighter(), weakWild()),
      ATTACK,
      catalog,
    );
    expect(state.result).toBe('victory');
    const types = events.map((event) => event.type);
    expect(types.slice(types.indexOf('fainted'))).toEqual([
      'fainted',
      'xp_gained',
      'coins_gained',
      'battle_ended',
    ]);
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 0, amount: 44 },
    ]);
    expect(state.player.team[0]!.xpEarned).toBe(44);
  });

  it('dois que entraram em campo dividem', () => {
    const { state, events } = play(
      makeState([fighter(), fighter()], weakWild({ foughtBy: [0, 1] }), {
        player: { team: [fighter(), fighter()], activeIndices: [1] },
      }),
      ATTACK,
      catalog,
    );
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 0, amount: 22 },
      { type: 'xp_gained', team_index: 1, amount: 22 },
    ]);
    expect(state.player.team.map((creature) => creature.xpEarned)).toEqual([
      22, 22,
    ]);
  });

  it('quem desmaiou fica de fora, e quem sobrou recebe tudo', () => {
    const { events } = play(
      makeState([fighter(), fighter()], weakWild({ foughtBy: [0, 1] }), {
        player: {
          team: [fighter({ currentHp: 0 }), fighter()],
          activeIndices: [1],
        },
      }),
      ATTACK,
      catalog,
    );
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 1, amount: 44 },
    ]);
  });

  it('quem nunca entrou em campo não recebe', () => {
    const { state, events } = play(
      makeState([fighter(), fighter()], weakWild()),
      ATTACK,
      catalog,
    );
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 0, amount: 44 },
    ]);
    expect(state.player.team[1]!.xpEarned).toBe(0);
  });

  it('quem está no nível 100 não recebe nem conta na divisão', () => {
    const { events } = play(
      makeState(
        [fighter({ level: 100 }), fighter()],
        weakWild({ foughtBy: [0, 1] }),
        {
          player: {
            team: [fighter({ level: 100 }), fighter()],
            activeIndices: [1],
          },
        },
      ),
      ATTACK,
      catalog,
    );
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 1, amount: 44 },
    ]);
  });

  it('sem ninguém para receber, não há evento', () => {
    const { state, events } = play(
      makeState(fighter({ level: 100 }), weakWild()),
      ATTACK,
      catalog,
    );
    expect(state.result).toBe('victory');
    expect(eventsOf(events, 'xp_gained')).toEqual([]);
  });

  it('o XP soma a cada inimigo derrubado', () => {
    let { state } = play(
      makeState(fighter(), [weakWild(), weakWild()]),
      ATTACK,
      catalog,
    );
    ({ state } = play(state, ATTACK, catalog));
    expect(state.result).toBe('victory');
    expect(state.player.team[0]!.xpEarned).toBe(88);
  });

  it('fugir não dá XP', () => {
    const { state, events } = play(
      makeState(fighter(), weakWild({ currentHp: 19 })),
      { type: 'flee' },
      catalog,
      always(0.5),
    );
    expect(state.result).toBe('fled');
    expect(eventsOf(events, 'xp_gained')).toEqual([]);
    expect(state.player.team[0]!.xpEarned).toBe(0);
  });
});
