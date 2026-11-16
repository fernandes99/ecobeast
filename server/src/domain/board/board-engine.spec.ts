import { always, eventsOf, makeEffect, makeSkill } from '../battle/testing.js';
import type { BattleEvent, Combatant } from '../battle/types.js';
import {
  applyBoardVez,
  CANNOT_REACH,
  DAZED_NO_MOVE,
  ENTRY_NOT_FREE,
  FLEE_NO_MOVE,
  NOT_YOUR_VEZ,
  startBoardBattle,
} from './board-engine.js';
import { ALLY_ONLY, OUT_OF_RANGE } from './areas.js';
import { NOT_READY } from './cooldown.js';
import {
  at,
  boardCatalog,
  fighter,
  FIRE_GROUND,
  makeBoardState,
  playVez,
  wild,
} from './testing.js';
import type { BoardState } from './types.js';

const ASLEEP: Partial<Combatant> = { statusSlug: 'sleep', sleepTurns: 99 };
const SCRATCH_SLOT = 1;
const SPARK_SLOT = 2;
const SPIRAL_SLOT = 3;
const GROWL_SLOT = 4;
const catalog = boardCatalog();

function types(events: BattleEvent[]): string[] {
  return events.map((event) => event.type);
}

describe('começo da luta no tabuleiro', () => {
  it('põe cada um na largada, começa a rodada e dá a vez ao mais rápido', () => {
    const { state, events } = startBoardBattle(
      [fighter(30)],
      [wild(5)],
      catalog,
      always(0.5),
    );
    expect(types(events)).toEqual([
      'battle_started',
      'creature_entered',
      'creature_entered',
      'round_started',
      'vez_started',
    ]);
    expect(eventsOf(events, 'creature_entered').map((e) => e.cell)).toEqual([
      at(1, 4),
      at(1, 1),
    ]);
    expect(state.phase).toBe('choose_action');
    expect(state.queue[0]).toMatchObject({ side: 'player', position: 0 });
  });

  it('com o selvagem mais rápido, ele ataca antes da vez do jogador', () => {
    // A 3 hexágonos, a Chama Espiral dele já alcança: ele nem precisa andar.
    const { state, events } = startBoardBattle(
      [fighter(5)],
      [wild(30)],
      catalog,
      always(0.5),
    );
    expect(eventsOf(events, 'skill_used')[0]).toMatchObject({ side: 'enemy' });
    expect(events.at(-1)).toEqual({
      type: 'vez_started',
      side: 'player',
      position: 0,
    });
    expect(state.queue[0]).toMatchObject({ side: 'player', position: 0 });
  });
});

describe('andar', () => {
  function oneOnOne(): BoardState {
    return makeBoardState([fighter(30)], [wild(5, ASLEEP)]);
  }

  it('andar 1 hexágono livre funciona, com o caminho no evento', () => {
    const { state, events } = playVez(
      oneOnOne(),
      { position: 0, move: at(2, 4), action: { type: 'wait' } },
      catalog,
    );
    const [moved] = eventsOf(events, 'moved');
    expect(moved!.path).toEqual([at(2, 4)]);
    expect(state.cells.player[0]).toEqual(at(2, 4));
  });

  it.each([
    ['a 2 hexágonos', at(0, 0), at(1, 2)],
    ['para o hexágono do selvagem', at(1, 3), at(1, 3)],
    ['para fora do tabuleiro', at(0, 0), { q: 40, r: 40 }],
  ])('recusa andar %s, sem mudar nada', (_, enemyCell, move) => {
    const state = makeBoardState([fighter(30)], [wild(5, ASLEEP)], {
      cells: { enemy: [enemyCell] },
    });
    const before = structuredClone(state);
    expect(
      applyBoardVez(
        state,
        { position: 0, move, action: { type: 'wait' } },
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: CANNOT_REACH });
    expect(state).toEqual(before);
  });

  it('não dá para andar e fugir na mesma vez', () => {
    expect(
      applyBoardVez(
        oneOnOne(),
        { position: 0, move: at(2, 4), action: { type: 'flee' } },
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: FLEE_NO_MOVE });
  });

  it('só joga quem está na vez', () => {
    const state = makeBoardState([fighter(30)], [wild(5)], {
      queue: [{ side: 'enemy', position: 0 }],
    });
    expect(
      applyBoardVez(
        state,
        { position: 0, action: { type: 'wait' } },
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: NOT_YOUR_VEZ });
  });

  it('quem dorme perde a vez inteira, sem andar', () => {
    const state = makeBoardState([fighter(30, ASLEEP)], [wild(5, ASLEEP)]);
    const { state: after, events } = playVez(
      state,
      { position: 0, move: at(1, 3), action: { type: 'wait' } },
      catalog,
    );
    expect(eventsOf(events, 'cannot_act')[0]).toMatchObject({
      side: 'player',
      reason: 'sleep',
    });
    expect(eventsOf(events, 'moved')).toEqual([]);
    expect(after.cells.player[0]).toEqual(at(1, 4));
  });
});

describe('Técnicas na vez', () => {
  it('andar até o selvagem e usar Arranhão atinge ele', () => {
    const { events } = playVez(
      makeBoardState([fighter(30)], [wild(5, ASLEEP)], {
        cells: { enemy: [at(2, 3)] },
      }),
      {
        position: 0,
        move: at(2, 4),
        action: { type: 'skill', slot: SCRATCH_SLOT, target: at(2, 3) },
      },
      catalog,
    );
    expect(eventsOf(events, 'skill_used')[0]).toMatchObject({
      side: 'player',
      cells: [at(2, 3)],
    });
    expect(eventsOf(events, 'damage')[0]).toMatchObject({
      side: 'enemy',
      position: 0,
    });
  });

  it('Arranhão a 2 hexágonos é recusado', () => {
    expect(
      applyBoardVez(
        makeBoardState([fighter(30)], [wild(5)], {
          cells: { enemy: [at(2, 2)] },
        }),
        {
          position: 0,
          move: at(2, 4),
          action: { type: 'skill', slot: SCRATCH_SLOT, target: at(2, 2) },
        },
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: 'Esse hexágono está fora do alcance.' });
  });

  it('Faísca Rápida numa linha com dois selvagens atinge só o primeiro', () => {
    const state = makeBoardState(
      [fighter(30)],
      [wild(5, ASLEEP), wild(5, ASLEEP)],
      {
        slots: { player: 1, enemy: 2 },
        cells: { player: [at(2, 5)], enemy: [at(2, 4), at(1, 3)] },
      },
    );
    const { events } = playVez(
      state,
      {
        position: 0,
        action: { type: 'skill', slot: SPARK_SLOT, target: at(1, 3) },
      },
      catalog,
    );
    const hits = eventsOf(events, 'damage').filter((e) => e.side === 'enemy');
    expect(hits.map((hit) => hit.position)).toEqual([0]);
  });

  it('uma linha que não atinge ninguém gasta o PP e a vez', () => {
    const { state } = playVez(
      makeBoardState([fighter(30)], [wild(5, ASLEEP)], {
        cells: { enemy: [at(0, 0)] },
      }),
      {
        position: 0,
        action: { type: 'skill', slot: SPARK_SLOT, target: at(1, 3) },
      },
      catalog,
    );
    expect(state.player.team[0]!.skills[1]!.currentPp).toBe(19);
  });
});

describe('marca no chão', () => {
  it('Chama Espiral deixa o fogo, que queima quem fica nele a cada vez, por 6 vezes', () => {
    let state = makeBoardState([fighter(30)], [wild(5, ASLEEP)], {
      cells: { enemy: [at(2, 3)] },
    });
    const all: BattleEvent[] = [];
    const first = playVez(
      state,
      {
        position: 0,
        action: { type: 'skill', slot: SPIRAL_SLOT, target: at(2, 3) },
      },
      catalog,
    );
    all.push(...first.events);
    state = first.state;
    expect(eventsOf(first.events, 'mark_placed')).toEqual([
      {
        type: 'mark_placed',
        cell: at(2, 3),
        ground_effect_id: FIRE_GROUND,
        remaining: 6,
      },
    ]);
    for (let vez = 0; vez < 3; vez++) {
      const next = playVez(
        state,
        { position: 0, action: { type: 'wait' } },
        catalog,
      );
      all.push(...next.events);
      state = next.state;
    }
    const burns = eventsOf(all, 'ground_damage');
    expect(burns).toHaveLength(6);
    expect(
      burns.every((burn) => burn.side === 'enemy' && burn.amount === 12),
    ).toBe(true);
    expect(eventsOf(all, 'mark_ended')).toEqual([
      { type: 'mark_ended', cell: at(2, 3) },
    ]);
    expect(state.marks).toEqual([]);
  });

  it('sair de cima da marca andando não queima', () => {
    const state = makeBoardState(
      [fighter(30)],
      [wild(5, ASLEEP)],
      {},
      {
        marks: [{ cell: at(2, 5), groundEffectId: FIRE_GROUND, remaining: 6 }],
      },
    );
    const { events } = playVez(
      state,
      { position: 0, move: at(2, 4), action: { type: 'wait' } },
      catalog,
    );
    expect(
      eventsOf(events, 'ground_damage').filter((e) => e.side === 'player'),
    ).toEqual([]);
  });
});

describe('queda e entrada', () => {
  function burning(): BoardState {
    return makeBoardState(
      [fighter(10, { currentHp: 1 }), fighter(30), fighter(5)],
      [wild(20, ASLEEP)],
      {
        slots: { player: 2, enemy: 1 },
        queue: [
          { side: 'player', position: 1 },
          { side: 'player', position: 0 },
          { side: 'enemy', position: 0 },
        ],
      },
      {
        marks: [{ cell: at(0, 4), groundEffectId: FIRE_GROUND, remaining: 6 }],
      },
    );
  }

  it('um Ecobeast do jogador que cai com reserva leva à escolha de quem entra', () => {
    const { state, events } = playVez(
      burning(),
      { position: 1, action: { type: 'wait' } },
      catalog,
    );
    expect(eventsOf(events, 'fainted')).toEqual([
      { type: 'fainted', side: 'player', position: 0 },
    ]);
    expect(state.phase).toBe('choose_next');
    expect(state.pendingPositions).toEqual([0]);
    expect(state.entryCells).toContainEqual(at(0, 4));
    expect(state.entryCells).not.toContainEqual(at(2, 4));
  });

  it('quem entra fica no hexágono escolhido da área verde e não joga na mesma rodada', () => {
    const fainted = playVez(
      burning(),
      { position: 1, action: { type: 'wait' } },
      catalog,
    );
    const { state, events } = playVez(
      fainted.state,
      { entries: [{ position: 0, team_index: 2, cell: at(1, 5) }] },
      catalog,
    );
    expect(eventsOf(events, 'creature_entered')[0]).toMatchObject({
      side: 'player',
      position: 0,
      team_index: 2,
      cell: at(1, 5),
    });
    const roundStart = events.findIndex((e) => e.type === 'round_started');
    const playsBefore = events
      .slice(0, roundStart === -1 ? events.length : roundStart)
      .filter(
        (e) =>
          e.type === 'vez_started' && e.side === 'player' && e.position === 0,
      );
    expect(playsBefore).toEqual([]);
    expect(state.phase).toBe('choose_action');
  });

  it('recusa entrar num hexágono fora da área livre', () => {
    const fainted = playVez(
      burning(),
      { position: 1, action: { type: 'wait' } },
      catalog,
    );
    expect(
      applyBoardVez(
        fainted.state,
        { entries: [{ position: 0, team_index: 2, cell: at(2, 4) }] },
        catalog,
        always(0.5),
      ),
    ).toEqual({ error: ENTRY_NOT_FREE });
  });

  it('a troca põe quem entra no hexágono de quem saiu', () => {
    const state = makeBoardState(
      [fighter(30), fighter(10)],
      [wild(5, ASLEEP)],
      { cells: { player: [at(1, 3)] } },
    );
    const { state: after, events } = playVez(
      state,
      { position: 0, action: { type: 'switch', team_index: 1 } },
      catalog,
    );
    expect(eventsOf(events, 'creature_entered')[0]).toMatchObject({
      position: 0,
      team_index: 1,
      cell: at(1, 3),
    });
    expect(after.player.activeIndices).toEqual([1]);
    expect(after.cells.player[0]).toEqual(at(1, 3));
  });
});

describe('Esfera, fuga e fim', () => {
  const SPHERE = 50;

  it('capturar um de dois selvagens, longe, mantém a luta com o outro', () => {
    const withSphere = boardCatalog();
    withSphere.items.set(SPHERE, {
      healAmount: null,
      curesStatus: false,
      captureBonus: 1,
    });
    withSphere.captureRates.set(7, 100);
    const state = makeBoardState(
      [fighter(30)],
      [wild(5, ASLEEP), wild(5, ASLEEP)],
      { slots: { player: 1, enemy: 2 } },
      { bag: [{ itemId: SPHERE, quantity: 1, used: 0 }], partyFree: 1 },
    );
    const target = state.cells.enemy[1]!;
    const { state: after, events } = playVez(
      state,
      { position: 0, action: { type: 'capture', item_id: SPHERE, target } },
      withSphere,
      always(0),
    );
    expect(eventsOf(events, 'capture_attempted')[0]).toMatchObject({
      success: true,
      target: 1,
      captured_to: 'party',
    });
    expect(eventsOf(events, 'creature_left')).toEqual([
      { type: 'creature_left', side: 'enemy', position: 1 },
    ]);
    expect(after.cells.enemy[1]).toBeNull();
    expect(after.phase).toBe('choose_action');
  });

  it('fugir com sucesso termina a luta para a equipe toda', () => {
    const { state } = playVez(
      makeBoardState([fighter(30)], [wild(5)]),
      { position: 0, action: { type: 'flee' } },
      catalog,
      always(0.9),
    );
    expect(state.result).toBe('fled');
  });

  it('derrubar o último selvagem vence, com XP e moedas', () => {
    const rewarding = boardCatalog();
    rewarding.xpYields.set(7, 50);
    const { state, events } = playVez(
      makeBoardState([fighter(30)], [wild(5, { currentHp: 1 })], {
        cells: { enemy: [at(2, 4)] },
      }),
      {
        position: 0,
        action: { type: 'skill', slot: SCRATCH_SLOT, target: at(2, 4) },
      },
      rewarding,
    );
    expect(state.result).toBe('victory');
    expect(types(events)).toContain('xp_gained');
    expect(types(events)).toContain('coins_gained');
    expect(events.at(-1)).toEqual({ type: 'battle_ended', result: 'victory' });
  });

  it('uma vez do jogador traz os eventos de todos os selvagens até a próxima vez dele', () => {
    const state = makeBoardState([fighter(30)], [wild(20), wild(10)], {
      slots: { player: 1, enemy: 2 },
      queue: [
        { side: 'player', position: 0 },
        { side: 'enemy', position: 0 },
        { side: 'enemy', position: 1 },
      ],
    });
    const { state: after, events } = playVez(
      state,
      { position: 0, action: { type: 'wait' } },
      catalog,
    );
    const enemyVezes = eventsOf(events, 'vez_started').filter(
      (e) => e.side === 'enemy',
    );
    expect(enemyVezes.map((e) => e.position)).toEqual([0, 1]);
    expect(events.at(-1)).toEqual({
      type: 'vez_started',
      side: 'player',
      position: 0,
    });
    expect(after.queue[0]).toMatchObject({ side: 'player', position: 0 });
  });
});

describe('uma luta inteira', () => {
  function seeded(seed: number): () => number {
    let a = seed;
    return () => {
      a = (a + 0x6d2b79f5) | 0;
      let t = Math.imul(a ^ (a >>> 15), 1 | a);
      t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
  }

  function noSharedCells(state: BoardState): boolean {
    const keys = [...state.cells.player, ...state.cells.enemy]
      .filter((cell) => cell !== null)
      .map((cell) => `${cell!.q},${cell!.r}`);
    return new Set(keys).size === keys.length;
  }

  it.each([1, 2, 3])(
    'um 3×3 com reserva vai até o fim sem travar e sem dois no mesmo hexágono (sorteio %i)',
    (seed) => {
      const random = seeded(seed);
      const team = [10, 20, 30, 15].map((spd) =>
        fighter(spd, { currentHp: 40 }),
      );
      const wilds = [12, 22, 32, 18].map((spd) => wild(spd, { currentHp: 40 }));
      let { state } = startBoardBattle(team, wilds, catalog, random, [], {
        slots: { player: 3, enemy: 3 },
      });
      for (let step = 0; step < 300 && state.phase !== 'ended'; step++) {
        expect(noSharedCells(state)).toBe(true);
        if (state.phase === 'choose_next') {
          const reserves = state.player.team.flatMap((creature, index) =>
            creature.currentHp > 0 &&
            !state.player.activeIndices.includes(index)
              ? [index]
              : [],
          );
          const entries = state.pendingPositions.map((position, i) => ({
            position,
            team_index: reserves[i]!,
            cell: state.entryCells[i]!,
          }));
          ({ state } = playVez(state, { entries }, catalog, random));
          continue;
        }
        const head = state.queue[0]!;
        ({ state } = playVez(
          state,
          { position: head.position, action: { type: 'wait' } },
          catalog,
          random,
        ));
      }
      expect(state.phase).toBe('ended');
      expect(state.result).toBe('defeat');
    },
  );
});

describe('item e marca com status', () => {
  it('o item de cura gasta a vez e cura um Ecobeast da reserva', () => {
    const POTION = 60;
    const withPotion = boardCatalog();
    withPotion.items.set(POTION, {
      healAmount: 20,
      curesStatus: false,
      captureBonus: null,
    });
    const state = makeBoardState(
      [fighter(30), fighter(10, { currentHp: 100 })],
      [wild(5, ASLEEP)],
      {},
      { bag: [{ itemId: POTION, quantity: 1, used: 0 }] },
    );
    const { state: after, events } = playVez(
      state,
      { position: 0, action: { type: 'item', item_id: POTION, team_index: 1 } },
      withPotion,
    );
    expect(eventsOf(events, 'item_used')[0]).toMatchObject({
      team_index: 1,
      healed: 20,
      hp: 120,
    });
    expect(after.bag[0]).toMatchObject({ quantity: 0, used: 1 });
  });

  it('uma marca que congela aplica o status em quem está nela, sem repetir', () => {
    const ICE = 2;
    const icy = boardCatalog();
    icy.groundEffects.set(ICE, {
      damagePercent: null,
      statusSlug: 'freeze',
      stats: [],
    });
    const state = makeBoardState(
      [fighter(30)],
      [wild(5, ASLEEP)],
      {},
      {
        marks: [{ cell: at(1, 4), groundEffectId: ICE, remaining: 6 }],
      },
    );
    const { state: after, events } = playVez(
      state,
      { position: 0, action: { type: 'wait' } },
      icy,
    );
    expect(eventsOf(events, 'status_applied')).toEqual([
      { type: 'status_applied', side: 'player', position: 0, status: 'freeze' },
    ]);
    expect(after.player.team[0]!.statusSlug).toBe('freeze');
    const again = playVez(
      after,
      { position: 0, action: { type: 'wait' } },
      icy,
    );
    const all = [...events, ...again.events];
    expect(eventsOf(all, 'status_applied')).toHaveLength(1);
    expect(eventsOf(all, 'effect_failed')).toEqual([]);
  });
});

describe('countdown das Técnicas (skill-cooldown/01)', () => {
  const SLOW = makeSkill({ id: 30, cooldown: 1 });
  const withSlow = boardCatalog([SLOW]);
  const SLOW_SLOT = 1;
  const strike = (slot: number) => ({
    position: 0,
    action: { type: 'skill', slot, target: at(2, 3) } as const,
  });

  function nextToSleeper(): BoardState {
    return makeBoardState(
      [
        fighter(30, {
          skills: [
            { skillId: SLOW.id, currentPp: 10 },
            { skillId: 1, currentPp: 35 },
          ],
        }),
      ],
      [wild(5, ASLEEP)],
      { cells: { player: [at(2, 4)], enemy: [at(2, 3)] } },
    );
  }

  it('com countdown 1, usada na rodada 1, é recusada na 2 e volta na 3', () => {
    const first = playVez(nextToSleeper(), strike(SLOW_SLOT), withSlow).state;
    expect(first.round).toBe(2);
    expect(first.player.team[0]!.skills[0]!.readyRound).toBe(3);
    expect(
      applyBoardVez(first, strike(SLOW_SLOT), withSlow, always(0.5)),
    ).toEqual({
      error: NOT_READY,
    });

    const second = playVez(
      first,
      { position: 0, action: { type: 'wait' } },
      withSlow,
    ).state;
    expect(second.round).toBe(3);
    const third = playVez(second, strike(SLOW_SLOT), withSlow);
    expect(eventsOf(third.events, 'skill_used')[0]).toMatchObject({
      side: 'player',
    });
  });

  it('com countdown 0, pode ser usada em toda rodada', () => {
    const first = playVez(nextToSleeper(), strike(2), withSlow).state;
    const second = playVez(first, strike(2), withSlow);
    expect(second.state.round).toBe(3);
    expect(eventsOf(second.events, 'skill_used')).toHaveLength(1);
  });

  it('com as Técnicas bloqueadas mas com PP, a emergência é recusada', () => {
    const state = nextToSleeper();
    for (const learned of state.player.team[0]!.skills) learned.readyRound = 5;
    expect(
      applyBoardVez(
        state,
        { position: 0, action: { type: 'emergency', target: at(2, 3) } },
        withSlow,
        always(0.5),
      ),
    ).toEqual({ error: 'Ainda há Técnicas com PP.' });
  });
});

describe('alvo do time (skill-editor/03)', () => {
  const SUNBATH = makeSkill({
    id: 40,
    category: 'support',
    power: 0,
    accuracy: 0,
    targetSlug: 'ally',
    effects: [makeEffect({ effectSlug: 'heal', percent: 50 })],
  });
  const withSun = boardCatalog([SUNBATH]);
  const healer = () =>
    fighter(30, {
      currentHp: 100,
      skills: [{ skillId: SUNBATH.id, currentPp: 10 }],
    });

  function team(allyCell = at(1, 4)): BoardState {
    return makeBoardState(
      [healer(), fighter(10, { currentHp: 80 })],
      [wild(5, ASLEEP)],
      {
        slots: { player: 2, enemy: 1 },
        cells: { player: [at(0, 4), allyCell], enemy: [at(1, 0)] },
      },
    );
  }
  const sun = (
    target: { q: number; r: number },
    move?: { q: number; r: number },
  ) => ({
    position: 0,
    ...(move ? { move } : {}),
    action: { type: 'skill', slot: 1, target } as const,
  });

  it('cura o aliado escolhido, e não o autor', () => {
    const { state } = playVez(team(), sun(at(1, 4)), withSun, always(0.99));
    expect(state.player.team[1]!.currentHp).toBe(180);
    expect(state.player.team[0]!.currentHp).toBe(100);
  });

  it('no próprio hexágono, cura o autor, também depois de andar', () => {
    const still = playVez(team(), sun(at(0, 4)), withSun).state;
    expect(still.player.team[0]!.currentHp).toBe(200);

    const moved = playVez(team(), sun(at(0, 5), at(0, 5)), withSun).state;
    expect(moved.player.team[0]!.currentHp).toBe(200);
    expect(
      applyBoardVez(team(), sun(at(0, 4), at(0, 5)), withSun, always(0.5)),
    ).toEqual({ error: ALLY_ONLY });
  });

  it('recusa um aliado fora do alcance e um inimigo', () => {
    expect(
      applyBoardVez(team(at(2, 4)), sun(at(2, 4)), withSun, always(0.5)),
    ).toEqual({ error: OUT_OF_RANGE });
    const nearEnemy = makeBoardState([healer()], [wild(5, ASLEEP)], {
      cells: { player: [at(0, 4)], enemy: [at(1, 4)] },
    });
    expect(
      applyBoardVez(nearEnemy, sun(at(1, 4)), withSun, always(0.5)),
    ).toEqual({ error: ALLY_ONLY });
  });

  it('não erra e passa pelo Proteger do aliado', () => {
    const state = team();
    state.player.team[1]!.isProtected = true;
    const outcome = playVez(state, sun(at(1, 4)), withSun, always(0.99));
    expect(types(outcome.events)).not.toContain('missed');
    expect(types(outcome.events)).not.toContain('blocked');
    expect(outcome.state.player.team[1]!.currentHp).toBe(180);
  });
});

describe('Atordoado e as marcas que mudam atributos (puffcoo-line/01)', () => {
  const FEATHERS = 2;
  const WHIRL = 3;
  const WIND = 6;
  const field = boardCatalog();
  field.groundEffects.set(FEATHERS, {
    damagePercent: null,
    statusSlug: null,
    stats: [
      { statSlug: 'accuracy', stages: -1 },
      { statSlug: 'evasion', stages: -1 },
    ],
  });
  field.groundEffects.set(WHIRL, {
    damagePercent: null,
    statusSlug: 'dazed',
    stats: [],
  });
  field.statusImmunities.set('dazed', [WIND]);
  const wait = { position: 0, action: { type: 'wait' } } as const;

  function onWhirl(player = fighter(30)): BoardState {
    return makeBoardState(
      [player],
      [wild(5, ASLEEP)],
      {},
      { marks: [{ cell: at(1, 4), groundEffectId: WHIRL, remaining: 6 }] },
    );
  }

  it('atordoado, não anda, e nada muda na luta', () => {
    const state = makeBoardState(
      [fighter(30, { isDazed: true })],
      [wild(5, ASLEEP)],
    );
    const before = structuredClone(state);
    expect(
      applyBoardVez(
        state,
        { position: 0, move: at(2, 4), action: { type: 'wait' } },
        field,
        always(0.5),
      ),
    ).toEqual({ error: DAZED_NO_MOVE });
    expect(state).toEqual(before);
  });

  it('atordoado, ainda usa uma Técnica, e deixa de estar no fim da vez', () => {
    const state = makeBoardState(
      [fighter(30, { isDazed: true })],
      [wild(5, ASLEEP)],
    );
    const { state: after, events } = playVez(
      state,
      {
        position: 0,
        action: { type: 'skill', slot: GROWL_SLOT },
      },
      field,
    );
    expect(eventsOf(events, 'skill_used')).toHaveLength(1);
    expect(eventsOf(events, 'status_ended')).toContainEqual({
      type: 'status_ended',
      side: 'player',
      position: 0,
      status: 'dazed',
    });
    expect(after.player.team[0]!.isDazed).toBe(false);
  });

  it('quem termina a vez no Redemoinho fica atordoado e não sai dele', () => {
    const { state: after, events } = playVez(onWhirl(), wait, field);
    expect(eventsOf(events, 'status_applied')).toEqual([
      { type: 'status_applied', side: 'player', position: 0, status: 'dazed' },
    ]);
    expect(eventsOf(events, 'effect_failed')).toEqual([]);
    expect(after.player.team[0]!.isDazed).toBe(true);
    expect(
      applyBoardVez(
        after,
        { position: 0, move: at(2, 4), action: { type: 'wait' } },
        field,
        always(0.5),
      ),
    ).toEqual({ error: DAZED_NO_MOVE });

    const again = playVez(after, wait, field);
    const order = again.events
      .filter(
        (event) =>
          event.type === 'status_ended' || event.type === 'status_applied',
      )
      .map((event) => event.type);
    expect(order.slice(0, 2)).toEqual(['status_ended', 'status_applied']);
    expect(again.state.player.team[0]!.isDazed).toBe(true);
  });

  it('o queimado também fica atordoado no Redemoinho', () => {
    const { state: after } = playVez(
      onWhirl(fighter(30, { statusSlug: 'burn' })),
      wait,
      field,
    );
    expect(after.player.team[0]!.isDazed).toBe(true);
    expect(after.player.team[0]!.statusSlug).toBe('burn');
  });

  it('o Vento não fica atordoado, sem encher o histórico de falhas', () => {
    const { state: after, events } = playVez(
      onWhirl(fighter(30, { elementIds: [WIND] })),
      wait,
      field,
    );
    expect(eventsOf(events, 'status_applied')).toEqual([]);
    expect(eventsOf(events, 'effect_failed')).toEqual([]);
    expect(after.player.team[0]!.isDazed).toBe(false);
  });

  it('as Penas no ar só baixam quem acabou de jogar, uma vez por vez dele', () => {
    const state = makeBoardState(
      [fighter(30), fighter(20)],
      [wild(5, ASLEEP)],
      {
        slots: { player: 2, enemy: 1 },
        cells: { player: [at(0, 4), at(2, 4)] },
        queue: [
          { side: 'player', position: 0 },
          { side: 'player', position: 1 },
          { side: 'enemy', position: 0 },
        ],
      },
      {
        marks: [
          { cell: at(0, 4), groundEffectId: FEATHERS, remaining: 6 },
          { cell: at(2, 4), groundEffectId: FEATHERS, remaining: 6 },
        ],
      },
    );
    const first = playVez(state, wait, field);
    expect(eventsOf(first.events, 'stat_changed')).toEqual([
      {
        type: 'stat_changed',
        side: 'player',
        position: 0,
        stat: 'accuracy',
        stages: -1,
        value: -1,
      },
      {
        type: 'stat_changed',
        side: 'player',
        position: 0,
        stat: 'evasion',
        stages: -1,
        value: -1,
      },
    ]);
    expect(first.state.player.team[1]!.stages.accuracy).toBe(0);

    const second = playVez(
      first.state,
      { position: 1, action: { type: 'wait' } },
      field,
    );
    const [one, two] = second.state.player.team;
    expect(two!.stages).toMatchObject({ accuracy: -1, evasion: -1 });
    expect(one!.stages).toMatchObject({ accuracy: -1, evasion: -1 });
  });
});
