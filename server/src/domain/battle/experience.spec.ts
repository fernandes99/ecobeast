import { awardXp, recordEntry } from './experience.js';
import { faintIfDown } from './status.js';
import {
  contextOf,
  ENEMY,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeState,
  PLAYER,
} from './testing.js';
import type { BattleState, Combatant } from './types.js';

const NILU = 4;
/** Um selvagem de nível 5 com xp base 62 dá 44 de XP. */
const catalog = makeCatalog({}, [], {}, {}, { [NILU]: 62 });

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant(overrides);
}

function wild(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({ creatureUid: null, speciesId: NILU, ...overrides });
}

/** O inimigo em campo cai, como depois de um golpe. */
function defeat(state: BattleState) {
  const turn = contextOf(state, catalog);
  turn.state.enemy.team[0]!.currentHp = 0;
  faintIfDown(turn, ENEMY);
  return turn;
}

/** Dois do jogador, com o segundo em campo, contra um inimigo que os dois enfrentaram. */
function afterSwitch(first: Combatant, second: Combatant = fighter()) {
  return makeState([first, second], wild({ foughtBy: [0, 1] }), {
    player: { team: [first, second], activeIndices: [1] },
  });
}

describe('quem esteve em campo', () => {
  it('o inimigo que entra começa com quem está em campo do outro lado', () => {
    const turn = contextOf(makeState([fighter(), fighter()], wild()), catalog);
    turn.state.enemy.team[0]!.foughtBy = [];
    recordEntry(turn, ENEMY);
    expect(turn.state.enemy.team[0]!.foughtBy).toEqual([0]);
  });

  it('quem entra numa troca passa a contar, sem repetir', () => {
    const turn = contextOf(makeState([fighter(), fighter()], wild()), catalog);
    turn.state.player.activeIndices[0] = 1;
    recordEntry(turn, PLAYER);
    turn.state.player.activeIndices[0] = 0;
    recordEntry(turn, PLAYER);
    expect(turn.state.enemy.team[0]!.foughtBy).toEqual([0, 1]);
  });
});

describe('XP ao derrubar o inimigo', () => {
  it('quem venceu sozinho recebe tudo, logo depois do desmaio', () => {
    const { state, events } = defeat(makeState(fighter(), wild()));
    expect(events).toEqual([
      { type: 'fainted', side: 'enemy', position: 0 },
      { type: 'xp_gained', team_index: 0, amount: 44 },
    ]);
    expect(state.player.team[0]!.xpEarned).toBe(44);
  });

  it('dois que entraram em campo dividem', () => {
    const { state, events } = defeat(afterSwitch(fighter()));
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 0, amount: 22 },
      { type: 'xp_gained', team_index: 1, amount: 22 },
    ]);
    expect(state.player.team.map((creature) => creature.xpEarned)).toEqual([
      22, 22,
    ]);
  });

  it('quem desmaiou fica de fora, e quem sobrou recebe tudo', () => {
    const { events } = defeat(afterSwitch(fighter({ currentHp: 0 })));
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 1, amount: 44 },
    ]);
  });

  it('quem nunca entrou em campo não recebe', () => {
    const { state, events } = defeat(makeState([fighter(), fighter()], wild()));
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 0, amount: 44 },
    ]);
    expect(state.player.team[1]!.xpEarned).toBe(0);
  });

  it('quem está no nível 100 não recebe nem conta na divisão', () => {
    const { events } = defeat(afterSwitch(fighter({ level: 100 })));
    expect(eventsOf(events, 'xp_gained')).toEqual([
      { type: 'xp_gained', team_index: 1, amount: 44 },
    ]);
  });

  it('sem ninguém para receber, não há evento', () => {
    const { events } = defeat(makeState(fighter({ level: 100 }), wild()));
    expect(eventsOf(events, 'xp_gained')).toEqual([]);
  });

  it('o XP soma a cada inimigo derrubado', () => {
    const turn = contextOf(makeState(fighter(), [wild(), wild()]), catalog);
    for (const enemy of turn.state.enemy.team) {
      awardXp(turn, { ...enemy, foughtBy: [0] });
    }
    expect(turn.state.player.team[0]!.xpEarned).toBe(88);
  });

  it('o do jogador que cai não dá XP', () => {
    const turn = contextOf(
      makeState(fighter({ currentHp: 0 }), wild()),
      catalog,
    );
    faintIfDown(turn, PLAYER);
    expect(eventsOf(turn.events, 'xp_gained')).toEqual([]);
  });
});
