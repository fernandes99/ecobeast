import type {
  BattleCatalog,
  BattleSkill,
  BattleSkillEffect,
  StageSlug,
} from '../domain/battle/types.js';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';

const SLUG = { select: { slug: true } } as const;

const SKILL_INCLUDE = {
  element: SLUG,
  skillCategory: SLUG,
  skillTarget: SLUG,
  effects: {
    orderBy: { sortOrder: 'asc' },
    include: {
      effectType: SLUG,
      skillTarget: SLUG,
      statusCondition: SLUG,
      stat: SLUG,
    },
  },
} satisfies Prisma.SkillInclude;

type SkillRow = Prisma.SkillGetPayload<{ include: typeof SKILL_INCLUDE }>;
type EffectRow = SkillRow['effects'][number];

export interface CatalogRows {
  skills: SkillRow[];
  efficacy: {
    attackerElementId: number;
    defenderElementId: number;
    multiplier: number;
  }[];
  immunities: { elementId: number; statusCondition: { slug: string } }[];
  items: {
    id: number;
    healAmount: number | null;
    curesStatus: boolean;
    captureBonus: number | null;
  }[];
  species: { id: number; captureRate: number; baseXpYield: number }[];
}

/** O catálogo que as regras da batalha recebem, lido do banco. */
export async function loadBattleCatalog(
  prisma: PrismaService,
): Promise<BattleCatalog> {
  const [skills, efficacy, immunities, items, species] = await Promise.all([
    prisma.skill.findMany({ include: SKILL_INCLUDE }),
    prisma.elementEfficacy.findMany(),
    prisma.statusConditionImmunity.findMany({
      select: { elementId: true, statusCondition: SLUG },
    }),
    prisma.item.findMany({
      select: {
        id: true,
        healAmount: true,
        curesStatus: true,
        captureBonus: true,
      },
    }),
    prisma.species.findMany({
      select: { id: true, captureRate: true, baseXpYield: true },
    }),
  ]);
  return toBattleCatalog({ skills, efficacy, immunities, items, species });
}

export function toBattleCatalog(rows: CatalogRows): BattleCatalog {
  const statusImmunities = new Map<string, number[]>();
  for (const { elementId, statusCondition } of rows.immunities) {
    const elementIds = statusImmunities.get(statusCondition.slug) ?? [];
    statusImmunities.set(statusCondition.slug, [...elementIds, elementId]);
  }
  return {
    skills: new Map(rows.skills.map((row) => [row.id, toBattleSkill(row)])),
    efficacy: new Map(
      rows.efficacy.map((row) => [
        `${row.attackerElementId}:${row.defenderElementId}`,
        row.multiplier,
      ]),
    ),
    statusImmunities,
    items: new Map(rows.items.map(({ id, ...item }) => [id, item])),
    captureRates: new Map(
      rows.species.map(({ id, captureRate }) => [id, captureRate]),
    ),
    xpYields: new Map(
      rows.species.map(({ id, baseXpYield }) => [id, baseXpYield]),
    ),
  };
}

function toBattleSkill(row: SkillRow): BattleSkill {
  return {
    id: row.id,
    elementId: row.elementId,
    elementSlug: row.element.slug,
    category: row.skillCategory.slug as BattleSkill['category'],
    power: row.power,
    accuracy: row.accuracy,
    maxPp: row.maxPp,
    priority: row.priority,
    critStage: row.critStage,
    targetSlug: row.skillTarget.slug,
    effects: row.effects.map(toBattleEffect),
  };
}

function toBattleEffect(row: EffectRow): BattleSkillEffect {
  return {
    effectSlug: row.effectType.slug,
    chance: row.chance,
    targetSlug: row.skillTarget?.slug ?? null,
    statusSlug: row.statusCondition?.slug ?? null,
    statSlug: (row.stat?.slug as StageSlug | undefined) ?? null,
    stages: row.stages,
    percent: row.percent,
  };
}
