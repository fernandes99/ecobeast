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
  BattleActionItemDto,
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
  inventory: true,
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
  captured: false,
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
    foughtBy: [],
    xpEarned: 0,
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
    foughtBy: [],
    xpEarned: 0,
  };
}

/** A lista de `actions`, ou o corpo antigo como uma ação na posição 0. */
export function toBattleActions(body: BattleActionBodyDto): BattleAction[] {
  return body.actions
    ? body.actions.map(toBattleAction)
    : [toBattleAction({ ...body, type: body.type! })];
}

function toBattleAction(body: BattleActionItemDto): BattleAction {
  const position = body.position ?? 0;
  const target = body.target === undefined ? {} : { target: body.target };
  switch (body.type) {
    case 'skill':
      return { type: 'skill', position, slot: body.slot!, ...target };
    case 'emergency':
      return { type: 'emergency', position, ...target };
    case 'switch':
      return { type: 'switch', position, team_index: body.team_index! };
    case 'item':
      return {
        type: 'item',
        position,
        item_id: body.item_id!,
        team_index: body.team_index!,
      };
    case 'capture':
      return { type: 'capture', position, item_id: body.item_id!, ...target };
    case 'flee':
      return { type: 'flee', position };
  }
}

/**
 * O que o jogador vê: do inimigo, só quem está em campo. `active_index` e
 * `enemy.active` são o contrato de antes das vagas, até o jogo trocar
 * (battle-slots/02).
 */
export function toBattleDto(state: BattleState): BattleDto {
  const { player, enemy, bag } = state;
  const actives = enemy.activeIndices.map((index) =>
    index === null ? null : toVisibleCreature(enemy.team[index]!),
  );
  return {
    phase: state.phase,
    result: state.result,
    turn: state.turn,
    can_flee: state.canFlee,
    player: {
      active_indices: player.activeIndices,
      pending_positions: state.pendingPositions,
      active_index: player.activeIndices.find((index) => index !== null) ?? 0,
      team: player.team.map((creature) => ({
        ...toVisibleCreature(creature),
        uid: creature.creatureUid!,
        skills: creature.skills.map((skill) => ({
          skill_id: skill.skillId,
          current_pp: skill.currentPp,
        })),
      })),
      items: bag
        .filter(({ quantity }) => quantity > 0)
        .map(({ itemId, quantity }) => ({ item_id: itemId, quantity })),
    },
    enemy: {
      actives,
      active: actives.find((creature) => creature !== null) ?? null,
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
