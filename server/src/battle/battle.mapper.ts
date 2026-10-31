import { noStages } from '../domain/battle/stages.js';
import type {
  BattleAction,
  BattleState,
  Combatant,
} from '../domain/battle/types.js';
import type { NewCreature } from '../domain/rules/creature-factory.js';
import { Prisma } from '../generated/prisma/client.js';
import { creatureStats, PLAYER_INCLUDE } from '../player/player.mapper.js';
import type {
  BattleActionBodyDto,
  BattleDto,
  EnemyCreatureDto,
} from './battle.dto.js';

const { creatures: PARTY } = PLAYER_INCLUDE;

/** O que a batalha lê da equipe, além do que a resposta do jogador já lê. */
export const BATTLE_PLAYER_INCLUDE = {
  creatures: {
    ...PARTY,
    include: {
      ...PARTY.include,
      species: {
        select: {
          ...PARTY.include.species.select,
          elements: { orderBy: { slot: 'asc' }, select: { elementId: true } },
        },
      },
      trait: { select: { slug: true } },
      statusCondition: { select: { slug: true } },
    },
  },
} satisfies Prisma.PlayerInclude;

export type BattleCreatureRow = Prisma.PlayerGetPayload<{
  include: typeof BATTLE_PLAYER_INCLUDE;
}>['creatures'][number];

const FRESH_IN_BATTLE = {
  sleepTurns: 0,
  confusionTurns: 0,
  isFeared: false,
  isTrapped: false,
  isProtected: false,
};

export function toCombatant(row: BattleCreatureRow): Combatant {
  return {
    ...FRESH_IN_BATTLE,
    creatureUid: row.uid,
    speciesId: row.speciesId,
    elementIds: row.species.elements.map((element) => element.elementId),
    level: row.level,
    traitSlug: row.trait.slug,
    stats: creatureStats(row),
    currentHp: row.currentHp,
    statusSlug: row.statusCondition?.slug ?? null,
    stages: noStages(),
    skills: row.skills.map(({ skillId, currentPp }) => ({
      skillId,
      currentPp,
    })),
  };
}

/** O inimigo selvagem só existe nesta batalha. */
export function toEnemyCombatant(
  creature: NewCreature,
  elementIds: number[],
  traitSlug: string,
): Combatant {
  return {
    ...FRESH_IN_BATTLE,
    creatureUid: null,
    speciesId: creature.speciesId,
    elementIds,
    level: creature.level,
    traitSlug,
    stats: creature.stats,
    currentHp: creature.currentHp,
    statusSlug: null,
    stages: noStages(),
    skills: creature.skills.map(({ skillId, currentPp }) => ({
      skillId,
      currentPp,
    })),
  };
}

export function toBattleAction(body: BattleActionBodyDto): BattleAction {
  switch (body.type) {
    case 'skill':
      return { type: 'skill', slot: body.slot! };
    case 'switch':
      return { type: 'switch', team_index: body.team_index! };
    default:
      return { type: body.type };
  }
}

/** O que o jogador vê: do inimigo, só quem está em campo. */
export function toBattleDto(state: BattleState): BattleDto {
  const { player, enemy } = state;
  return {
    phase: state.phase,
    result: state.result,
    turn: state.turn,
    can_flee: state.canFlee,
    player: {
      active_index: player.activeIndex,
      team: player.team.map((creature) => ({
        ...toVisibleCreature(creature),
        uid: creature.creatureUid!,
        skills: creature.skills.map((skill) => ({
          skill_id: skill.skillId,
          current_pp: skill.currentPp,
        })),
      })),
    },
    enemy: {
      active: toVisibleCreature(enemy.team[enemy.activeIndex]!),
      team_size: enemy.team.length,
      fainted: enemy.team.filter((creature) => creature.currentHp === 0).length,
    },
  };
}

function toVisibleCreature(creature: Combatant): EnemyCreatureDto {
  return {
    species_id: creature.speciesId,
    level: creature.level,
    hp: creature.currentHp,
    max_hp: creature.stats.hp,
    status: creature.statusSlug,
    confused: creature.confusionTurns > 0,
    stages: creature.stages,
  };
}
