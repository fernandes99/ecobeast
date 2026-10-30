import { PlayerRow, toPlayerDto } from './player.mapper.js';

type CreatureRow = PlayerRow['creatures'][number];

const CAUGHT_AT = new Date('2026-10-30T12:01:02.003Z');
const SLUGS = ['hp', 'atk', 'def', 'sp_atk', 'sp_def', 'spd'];

function creature(overrides: Partial<CreatureRow> = {}): CreatureRow {
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
    statusConditionId: null,
    location: 'party',
    partySlot: 1,
    originalPlayerId: 'p1',
    caughtAt: CAUGHT_AT,
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
      stats: SLUGS.map((slug) => ({
        baseValue: slug === 'hp' ? 39 : 52,
        stat: { slug },
      })),
    },
    temperament: {
      increasedStat: { slug: 'atk' },
      decreasedStat: { slug: 'def' },
    },
    ...overrides,
  };
}

function player(creatures: CreatureRow[] = []): PlayerRow {
  return {
    id: 'p1',
    name: 'Ana',
    level: 1,
    coins: 1000,
    createdAt: new Date('2026-10-30T12:00:00.000Z'),
    creatures,
  };
}

describe('toPlayerDto', () => {
  it('devolve o Domador com created_at em UTC e a equipe vazia', () => {
    expect(toPlayerDto(player())).toEqual({
      id: 'p1',
      name: 'Ana',
      level: 1,
      coins: 1000,
      created_at: '2026-10-30T12:00:00.000Z',
      party: [],
    });
  });

  it('converte a criatura para o contrato do cliente', () => {
    const [dto] = toPlayerDto(player([creature()])).party;

    expect(dto).toEqual({
      uid: 'c1',
      species_id: 1,
      nickname: '',
      level: 5,
      current_xp: 125,
      current_hp: 12,
      stats: { hp: 20, atk: 11, def: 9, sp_atk: 10, sp_def: 10, spd: 10 },
      genes: { hp: 31, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 },
      training_points: { hp: 0, atk: 0, def: 0, sp_atk: 0, sp_def: 0, spd: 0 },
      temperament_id: 3,
      trait_id: 4,
      gender: 'female',
      is_prismatic: false,
      bond: 70,
      skills: [
        { skill_id: 8, current_pp: 35 },
        { skill_id: 9, current_pp: 20 },
      ],
      status_condition_id: null,
      held_item_id: null,
      original_player_id: 'p1',
      caught_at: '2026-10-30T12:01:02.003Z',
      caught_zone_id: null,
    });
  });

  it('mantém o apelido e a ordem da equipe recebida', () => {
    const { party } = toPlayerDto(
      player([
        creature({ uid: 'a', partySlot: 1, nickname: 'Brasa' }),
        creature({ uid: 'b', partySlot: 2 }),
      ]),
    );
    expect(party.map((item) => item.uid)).toEqual(['a', 'b']);
    expect(party[0]!.nickname).toBe('Brasa');
  });

  it('recalcula os stats com os stats base atuais do catálogo', () => {
    const row = creature();
    row.species.stats = row.species.stats.map((stat) => ({
      ...stat,
      baseValue: stat.stat.slug === 'atk' ? 100 : stat.baseValue,
    }));
    const [dto] = toPlayerDto(player([row])).party;
    // floor(200 · 5 / 100) + 5 = 15; aumentado: 16.
    expect(dto!.stats.atk).toBe(16);
  });

  it('avisa se faltar um stat da criatura', () => {
    const row = creature();
    row.stats = row.stats.slice(1);
    expect(() => toPlayerDto(player([row]))).toThrow(/hp/);
  });
});
