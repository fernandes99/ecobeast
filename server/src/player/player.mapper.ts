import { calculateStats } from '../domain/rules/stat-calculator.js';
import { STAT_SLUGS, StatBlock, StatSlug } from '../domain/rules/types.js';
import { MAX_LEVEL, totalXpForLevel } from '../domain/rules/xp-curve.js';
import { Prisma } from '../generated/prisma/client.js';
import { CreatureDto, PlayerDto } from './player.dto.js';

/** O que uma resposta do jogador precisa ler do banco. */
export const PLAYER_INCLUDE = {
  creatures: {
    where: { location: 'party' },
    orderBy: { partySlot: 'asc' },
    include: {
      stats: { include: { stat: { select: { slug: true } } } },
      skills: { orderBy: { slot: 'asc' } },
      species: {
        select: {
          growthRate: { select: { xpMultiplier: true } },
          stats: {
            select: { baseValue: true, stat: { select: { slug: true } } },
          },
        },
      },
      temperament: {
        select: {
          increasedStat: { select: { slug: true } },
          decreasedStat: { select: { slug: true } },
        },
      },
    },
  },
} satisfies Prisma.PlayerInclude;

export type PlayerRow = Prisma.PlayerGetPayload<{
  include: typeof PLAYER_INCLUDE;
}>;

type CreatureRow = PlayerRow['creatures'][number];

/** Monta os 6 stats a partir de linhas com o slug do stat. */
export function toStatBlock<Row extends { stat: { slug: string } }>(
  rows: Row[],
  value: (row: Row) => number,
): StatBlock {
  const block = {} as StatBlock;
  for (const slug of STAT_SLUGS) {
    const row = rows.find((item) => item.stat.slug === slug);
    if (!row) throw new Error(`Falta o stat ${slug}.`);
    block[slug] = value(row);
  }
  return block;
}

/** O JSON do jogador (.specs/auth-google/03-player-api.md, RF-07). */
export function toPlayerDto(row: PlayerRow): PlayerDto {
  return {
    id: row.id,
    name: row.name,
    level: row.level,
    coins: row.coins,
    created_at: row.createdAt.toISOString(),
    party: row.creatures.map(toCreatureDto),
  };
}

function toCreatureDto(row: CreatureRow): CreatureDto {
  const genes = toStatBlock(row.stats, (stat) => stat.genes);
  const trainingPoints = toStatBlock(row.stats, (stat) => stat.trainingPoints);
  const { xpMultiplier } = row.species.growthRate;
  return {
    uid: row.uid,
    species_id: row.speciesId,
    nickname: row.nickname ?? '',
    level: row.level,
    current_xp: row.currentXp,
    level_xp: totalXpForLevel(xpMultiplier, row.level),
    next_level_xp:
      row.level < MAX_LEVEL
        ? totalXpForLevel(xpMultiplier, row.level + 1)
        : null,
    current_hp: row.currentHp,
    // Recalculado a cada resposta: um ajuste de balanceamento vale para todos.
    stats: calculateStats(
      toStatBlock(row.species.stats, (stat) => stat.baseValue),
      genes,
      trainingPoints,
      row.level,
      {
        increasedStat: row.temperament.increasedStat.slug as StatSlug,
        decreasedStat: row.temperament.decreasedStat.slug as StatSlug,
      },
    ),
    genes,
    training_points: trainingPoints,
    temperament_id: row.temperamentId,
    trait_id: row.traitId,
    gender: row.gender,
    is_prismatic: row.isPrismatic,
    bond: row.bond,
    skills: row.skills.map((skill) => ({
      skill_id: skill.skillId,
      current_pp: skill.currentPp,
    })),
    status_condition_id: row.statusConditionId,
    held_item_id: row.heldItemId,
    original_player_id: row.originalPlayerId,
    caught_at: row.caughtAt.toISOString(),
    caught_zone_id: row.caughtZoneId,
  };
}
