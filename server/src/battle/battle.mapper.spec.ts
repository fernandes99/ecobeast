import { makeCombatant, makeState } from '../domain/battle/testing.js';
import { noStages } from '../domain/battle/stages.js';
import type { NewCreature } from '../domain/rules/creature-factory.js';
import { toPlayerDto } from '../player/player.mapper.js';
import {
  BattleCreatureRow,
  toBattleDto,
  toCombatant,
  toEnemyCombatant,
} from './battle.mapper.js';

const SLUGS = ['hp', 'atk', 'def', 'sp_atk', 'sp_def', 'spd'];

function creature(
  overrides: Partial<BattleCreatureRow> = {},
): BattleCreatureRow {
  return {
    uid: 'c1',
    playerId: 'p1',
    speciesId: 1,
    nickname: null,
    level: 5,
    currentXp: 125,
    currentHp: 12,
    temperamentId: 3,
    traitId: 4,
    gender: 'female',
    isPrismatic: false,
    bond: 70,
    heldItemId: null,
    statusConditionId: 1,
    location: 'party',
    partySlot: 1,
    originalPlayerId: 'p1',
    caughtAt: new Date('2026-10-30T12:01:02.003Z'),
    caughtZoneId: null,
    stats: SLUGS.map((slug, index) => ({
      creatureUid: 'c1',
      statId: index + 1,
      genes: slug === 'hp' ? 31 : 0,
      trainingPoints: 0,
      stat: { slug },
    })),
    skills: [
      { creatureUid: 'c1', slot: 1, skillId: 8, currentPp: 35 },
      { creatureUid: 'c1', slot: 2, skillId: 9, currentPp: 20 },
    ],
    species: {
      growthRate: { xpMultiplier: 1 },
      stats: SLUGS.map((slug) => ({
        baseValue: slug === 'hp' ? 39 : 52,
        stat: { slug },
      })),
      elements: [{ elementId: 1 }, { elementId: 13 }],
    },
    temperament: {
      increasedStat: { slug: 'atk' },
      decreasedStat: { slug: 'def' },
    },
    trait: { slug: 'instinct' },
    statusCondition: { slug: 'burn' },
    ...overrides,
  };
}

describe('toCombatant', () => {
  it('leva a criatura para a batalha com o HP, o PP e o status do banco', () => {
    expect(toCombatant(creature())).toMatchObject({
      creatureUid: 'c1',
      speciesId: 1,
      elementIds: [1, 13],
      level: 5,
      traitSlug: 'instinct',
      currentHp: 12,
      statusSlug: 'burn',
      sleepTurns: 0,
      confusionTurns: 0,
      isFeared: false,
      isTrapped: false,
      isProtected: false,
      stages: noStages(),
      skills: [
        { skillId: 8, currentPp: 35 },
        { skillId: 9, currentPp: 20 },
      ],
    });
  });

  it('usa os mesmos stats que o jogador vê', () => {
    const row = creature();
    const { party } = toPlayerDto({
      id: 'p1',
      name: 'Ana',
      level: 1,
      coins: 0,
      createdAt: new Date(),
      creatures: [row],
      inventory: [],
    });
    expect(toCombatant(row).stats).toEqual(party[0]!.stats);
  });

  it('sem status, fica nulo', () => {
    const row = creature({ statusCondition: null });
    expect(toCombatant(row).statusSlug).toBeNull();
  });
});

describe('toEnemyCombatant', () => {
  const created: NewCreature = {
    speciesId: 7,
    level: 4,
    genes: { hp: 1, atk: 1, def: 1, sp_atk: 1, sp_def: 1, spd: 1 },
    trainingPoints: { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 },
    temperamentId: 1,
    traitId: 2,
    gender: 'male',
    skills: [{ skillId: 3, slot: 1, currentPp: 25 }],
    currentXp: 64,
    stats: { hp: 18, atk: 9, def: 8, sp_atk: 7, sp_def: 6, spd: 5 },
    currentHp: 18,
    bond: 70,
    isPrismatic: false,
  };

  it('não existe no banco e entra sem status', () => {
    expect(toEnemyCombatant(created, [2], 'hard_shell')).toEqual({
      creatureUid: null,
      speciesId: 7,
      elementIds: [2],
      level: 4,
      traitSlug: 'hard_shell',
      stats: created.stats,
      currentHp: 18,
      statusSlug: null,
      sleepTurns: 0,
      confusionTurns: 0,
      isFeared: false,
      isTrapped: false,
      isProtected: false,
      stages: noStages(),
      skills: [{ skillId: 3, currentPp: 25 }],
    });
  });
});

describe('toBattleDto', () => {
  const stats = { hp: 20, atk: 10, def: 9, sp_atk: 11, sp_def: 9, spd: 11 };

  function state() {
    const player = makeCombatant({
      creatureUid: 'c1',
      stats,
      currentHp: 14,
      statusSlug: 'burn',
      skills: [{ skillId: 1, currentPp: 33 }],
    });
    player.stages.atk = 1;
    const enemy = makeCombatant({
      creatureUid: null,
      speciesId: 7,
      level: 4,
      traitSlug: 'hard_shell',
      stats: { ...stats, hp: 18 },
      currentHp: 9,
      confusionTurns: 2,
      skills: [{ skillId: 99, currentPp: 5 }],
    });
    enemy.stages.def = -1;
    return makeState(player, enemy, { turn: 3 });
  }

  it('monta o JSON do que o jogador vê', () => {
    expect(toBattleDto(state())).toEqual({
      phase: 'choose_action',
      result: null,
      turn: 3,
      can_flee: true,
      player: {
        active_index: 0,
        team: [
          {
            uid: 'c1',
            species_id: 1,
            level: 5,
            hp: 14,
            max_hp: 20,
            status: 'burn',
            confused: false,
            stages: { ...noStages(), atk: 1 },
            skills: [{ skill_id: 1, current_pp: 33 }],
          },
        ],
      },
      enemy: {
        active: {
          species_id: 7,
          level: 4,
          hp: 9,
          max_hp: 18,
          status: null,
          confused: true,
          stages: { ...noStages(), def: -1 },
        },
        team_size: 1,
        fainted: 0,
      },
    });
  });

  it('não mostra as Técnicas nem o Traço do inimigo', () => {
    const json = JSON.stringify(toBattleDto(state()).enemy);
    expect(json).not.toContain('skill');
    expect(json).not.toContain('hard_shell');
    expect(json).not.toContain('trait');
  });

  it('não mostra as criaturas do inimigo fora de campo', () => {
    const bench = makeCombatant({ creatureUid: null, speciesId: 55 });
    const fallen = makeCombatant({ creatureUid: null, currentHp: 0 });
    const active = makeCombatant({ creatureUid: null, speciesId: 7 });
    const dto = toBattleDto({
      ...state(),
      enemy: { team: [fallen, active, bench], activeIndex: 1 },
    });
    expect(dto.enemy.active.species_id).toBe(7);
    expect(dto.enemy.team_size).toBe(3);
    expect(dto.enemy.fainted).toBe(1);
    expect(JSON.stringify(dto)).not.toContain('55');
  });
});
