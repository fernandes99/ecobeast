import { TAMER_CREATURE } from '../battle/capture.js';
import { always, eventsOf } from '../battle/testing.js';
import type { BattleState } from '../battle/types.js';
import { applyBoardVez, startBoardBattle } from './board-engine.js';
import {
  at,
  boardCatalog,
  fighter,
  makeBoardState,
  playVez,
  wild,
} from './testing.js';

const SCRATCH_SLOT = 1;
const SPHERE = 50;
const TAMER: Partial<BattleState> = { opponent: 'tamer', canFlee: false };

function rewardingCatalog() {
  const catalog = boardCatalog();
  catalog.xpYields.set(7, 50);
  catalog.captureRates.set(7, 100);
  catalog.items.set(SPHERE, {
    healAmount: null,
    curesStatus: false,
    captureBonus: 1,
  });
  return catalog;
}

function finishingBlow(overrides: Partial<BattleState>) {
  return playVez(
    makeBoardState(
      [fighter(30)],
      [wild(5, { currentHp: 1 })],
      { cells: { enemy: [at(2, 4)] } },
      { coins: 100, ...overrides },
    ),
    {
      position: 0,
      action: { type: 'skill', slot: SCRATCH_SLOT, target: at(2, 4) },
    },
    rewardingCatalog(),
  );
}

function knockedOut(overrides: Partial<BattleState>) {
  return playVez(
    makeBoardState(
      [fighter(30, { currentHp: 1 })],
      [wild(5)],
      {
        cells: { enemy: [at(1, 3)] },
        queue: [
          { side: 'player', position: 0 },
          { side: 'enemy', position: 0 },
        ],
      },
      { coins: 100, ...overrides },
    ),
    { position: 0, action: { type: 'wait' } },
    rewardingCatalog(),
  );
}

describe('começo da luta contra Domador', () => {
  it('desliga a fuga e aceita vagas diferentes por lado', () => {
    const { state } = startBoardBattle(
      [fighter(30)],
      [wild(5), wild(5), wild(5)],
      boardCatalog(),
      always(0.5),
      [],
      { opponent: 'tamer', slots: { player: 1, enemy: 3 } },
    );
    expect(state.opponent).toBe('tamer');
    expect(state.canFlee).toBe(false);
    expect(state.cells.enemy.filter((cell) => cell !== null)).toHaveLength(3);
    expect(state.cells.player).toHaveLength(1);
  });

  it('sem opponent, a luta é contra selvagem, como hoje', () => {
    const { state } = startBoardBattle(
      [fighter(30)],
      [wild(5)],
      boardCatalog(),
      always(0.5),
    );
    expect(state.opponent).toBe('wild');
    expect(state.canFlee).toBe(true);
  });
});

describe('ações recusadas contra Domador', () => {
  it('a Esfera é recusada antes de conferir o item, sem gastar a vez', () => {
    const state = makeBoardState([fighter(30)], [wild(5)], {}, TAMER);
    const outcome = applyBoardVez(
      state,
      {
        position: 0,
        action: { type: 'capture', item_id: SPHERE, target: at(1, 1) },
      },
      rewardingCatalog(),
      always(0),
    );
    expect(outcome).toEqual({ error: TAMER_CREATURE });
    expect(TAMER_CREATURE).toBe(
      'Não dá para capturar o Ecobeast de outro Domador.',
    );
  });

  it('a fuga é recusada', () => {
    const outcome = applyBoardVez(
      makeBoardState([fighter(30)], [wild(5)], {}, TAMER),
      { position: 0, action: { type: 'flee' } },
      boardCatalog(),
      always(0.9),
    );
    expect(outcome).toEqual({ error: 'Não dá para fugir agora.' });
  });
});

describe('recompensa contra Domador', () => {
  // xpYield(50, nível 5) = floor(250 ÷ 7) = 35.
  it('o XP é 1,5× o do selvagem, arredondado para baixo', () => {
    const fromWild = finishingBlow({});
    const fromTamer = finishingBlow(TAMER);
    expect(eventsOf(fromWild.events, 'xp_gained')[0]!.amount).toBe(35);
    expect(eventsOf(fromTamer.events, 'xp_gained')[0]!.amount).toBe(52);
  });

  it('a vitória paga com base 60, e o selvagem com base 20', () => {
    // Níveis iguais e o sorteio do meio: a própria base.
    expect(eventsOf(finishingBlow({}).events, 'coins_gained')[0]!.amount).toBe(
      20,
    );
    const { state, events } = finishingBlow(TAMER);
    expect(state.result).toBe('victory');
    expect(eventsOf(events, 'coins_gained')[0]!.amount).toBe(60);
    expect(state.coinsChange).toBe(60);
  });

  it('a derrota tira com base 15, e o selvagem com base 5', () => {
    expect(eventsOf(knockedOut({}).events, 'coins_lost')[0]!.amount).toBe(5);
    const { state, events } = knockedOut(TAMER);
    expect(state.result).toBe('defeat');
    expect(eventsOf(events, 'coins_lost')[0]!.amount).toBe(15);
    expect(state.coinsChange).toBe(-15);
  });

  it('a derrota não tira mais do que o Domador tinha', () => {
    const { state } = knockedOut({ ...TAMER, coins: 4 });
    expect(state.coinsChange).toBe(-4);
  });
});
