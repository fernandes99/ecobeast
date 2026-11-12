import { settleCoins } from './experience.js';
import {
  contextOf,
  eventsOf,
  makeCatalog,
  makeCombatant,
  makeState,
} from './testing.js';
import type { BattleResult, BattleState, Combatant } from './types.js';

const catalog = makeCatalog();

function fighter(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant(overrides);
}

function wild(overrides: Partial<Combatant> = {}): Combatant {
  return makeCombatant({ creatureUid: null, speciesId: 4, ...overrides });
}

function settle(state: BattleState, result: BattleResult) {
  const turn = contextOf(state, catalog);
  settleCoins(turn, result);
  return turn;
}

const won = (player: Combatant, coins = 0) =>
  settle(makeState(player, wild({ currentHp: 0 }), { coins }), 'victory');
const lost = (coins: number) =>
  settle(makeState(fighter({ currentHp: 0 }), wild(), { coins }), 'defeat');

describe('moedas contra o selvagem', () => {
  it('a vitória sorteia as moedas de cada inimigo desmaiado', () => {
    const { state, events } = won(fighter(), 100);
    // Níveis iguais: de 10 a 30, e o sorteio do meio dá 20.
    expect(events).toEqual([
      { type: 'coins_gained', amount: 20, species_id: 4 },
    ]);
    expect(state.coinsChange).toBe(20);
  });

  it('usa o nível de quem está em campo no fim', () => {
    const { events } = won(fighter({ level: 10 }));
    // Selvagem 5 contra 10: de 5 a 15, e o sorteio do meio dá 10.
    expect(eventsOf(events, 'coins_gained')[0]!.amount).toBe(10);
  });

  it('o capturado não dá moedas', () => {
    const { events } = settle(
      makeState(fighter(), wild({ captured: true })),
      'victory',
    );
    expect(events).toEqual([]);
  });

  it('a derrota tira moedas', () => {
    const { state, events } = lost(100);
    // Níveis iguais: de 2 a 7, e o sorteio do meio dá 5.
    expect(events).toEqual([
      { type: 'coins_lost', amount: 5, species_ids: [4] },
    ]);
    expect(state.coinsChange).toBe(-5);
  });

  it('a derrota não tira mais do que o Domador tem', () => {
    expect(lost(3).state.coinsChange).toBe(-3);
    const broke = lost(0);
    expect(broke.state.coinsChange).toBe(0);
    expect(broke.events).toEqual([]);
  });

  it.each(['fled', 'captured'] as const)('%s não mexe nas moedas', (result) => {
    const { state, events } = settle(
      makeState(fighter(), wild(), { coins: 100 }),
      result,
    );
    expect(state.coinsChange).toBe(0);
    expect(events).toEqual([]);
  });
});
