import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BundleService } from '../catalog/bundle/bundle.service.js';
import {
  type SkillDraftTables,
  STARTING_LEVEL,
  skillDraftError,
} from '../domain/skills/skill-draft.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  SkillDraftDto,
  SkillEffectDraftDto,
  SkillSavedResponseDto,
} from './skills-editor.dto.js';

export const SKILL_NOT_FOUND = 'Técnica não encontrada.';
export const SKILL_SLUG_TAKEN = 'Já existe uma Técnica com esse slug.';

const LEVEL_UP = 'level_up';

@Injectable()
export class SkillsEditorService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly bundle: BundleService,
  ) {}

  async create(draft: SkillDraftDto): Promise<SkillSavedResponseDto> {
    this.check(draft, await this.tables(null), true);
    const slug = draft.slug!;
    if (await this.prisma.skill.findUnique({ where: { slug } })) {
      throw new ConflictException(SKILL_SLUG_TAKEN);
    }
    const id = await this.prisma.$transaction(async (tx) => {
      await catchUpIds(tx, 'skills');
      const skill = await tx.skill.create({
        data: { slug, ...skillColumns(draft) },
      });
      await writeChildren(tx, skill.id, draft);
      return skill.id;
    });
    this.bundle.invalidate();
    return { id };
  }

  async save(id: number, draft: SkillDraftDto): Promise<SkillSavedResponseDto> {
    if (!(await this.prisma.skill.findUnique({ where: { id } }))) {
      throw new NotFoundException(SKILL_NOT_FOUND);
    }
    this.check(draft, await this.tables(id), false);
    await this.prisma.$transaction(async (tx) => {
      await tx.skill.update({ where: { id }, data: skillColumns(draft) });
      await tx.speciesSkill.deleteMany({ where: { skillId: id } });
      await writeChildren(tx, id, draft);
    });
    this.bundle.invalidate();
    return { id };
  }

  private check(
    draft: SkillDraftDto,
    tables: SkillDraftTables,
    creating: boolean,
  ): void {
    const error = skillDraftError(draft, tables, creating);
    if (error) throw new BadRequestException(error);
  }

  private async tables(skillId: number | null): Promise<SkillDraftTables> {
    const ids = (rows: { id: number }[]) => new Set(rows.map((row) => row.id));
    const select = { select: { id: true } } as const;
    const [
      elements,
      categories,
      targets,
      areas,
      grounds,
      statuses,
      stats,
      effectTypes,
      species,
      methods,
      levelOne,
    ] = await Promise.all([
      this.prisma.element.findMany(select),
      this.prisma.skillCategory.findMany(select),
      this.prisma.skillTarget.findMany(),
      this.prisma.areaShape.findMany(),
      this.prisma.groundEffect.findMany(select),
      this.prisma.statusCondition.findMany(select),
      this.prisma.stat.findMany(select),
      this.prisma.effectType.findMany(),
      this.prisma.species.findMany({ select: { id: true, name: true } }),
      this.prisma.skillLearnMethod.findMany(),
      this.prisma.speciesSkill.findMany({
        where: {
          level: STARTING_LEVEL,
          skillLearnMethod: { slug: LEVEL_UP },
        },
        select: { speciesId: true, skillId: true },
      }),
    ]);
    return {
      elementIds: ids(elements),
      skillCategoryIds: ids(categories),
      skillTargetIds: ids(targets),
      areaShapeIds: ids(areas),
      targetSlugs: new Map(targets.map((row) => [row.id, row.slug])),
      areaSlugs: new Map(areas.map((row) => [row.id, row.slug])),
      groundEffectIds: ids(grounds),
      statusConditionIds: ids(statuses),
      statIds: ids(stats),
      effectTypes: new Map(
        effectTypes.map((row) => [row.id, { slug: row.slug, name: row.name }]),
      ),
      species: new Map(species.map((row) => [row.id, row.name])),
      learnMethods: new Map(methods.map((row) => [row.id, row.slug])),
      levelOneBefore: new Set(levelOne.map((row) => row.speciesId)),
      levelOneOthers: new Set(
        levelOne
          .filter((row) => row.skillId !== skillId)
          .map((row) => row.speciesId),
      ),
    };
  }
}

function skillColumns(draft: SkillDraftDto) {
  return {
    name: draft.name.trim(),
    description: draft.description,
    elementId: draft.element_id,
    skillCategoryId: draft.skill_category_id,
    power: draft.power,
    accuracy: draft.accuracy,
    maxPp: draft.max_pp,
    priority: draft.priority,
    critStage: draft.crit_stage,
    skillTargetId: draft.skill_target_id,
    makesContact: draft.makes_contact,
    minHits: draft.min_hits,
    maxHits: draft.max_hits,
    areaShapeId: draft.area_shape_id,
    range: draft.range,
    pierces: draft.pierces,
    groundEffectId: draft.ground_effect_id ?? null,
    groundTurns: draft.ground_turns ?? null,
    cooldown: draft.cooldown,
  };
}

// Linhas postas pelo painel com o id escrito à mão deixam o contador para trás.
async function catchUpIds(
  tx: Prisma.TransactionClient,
  table: 'skills' | 'skill_effects',
): Promise<void> {
  await tx.$executeRawUnsafe(
    `SELECT setval(pg_get_serial_sequence('"ecobeasts"."${table}"', 'id'), ` +
      `GREATEST((SELECT COALESCE(max("id"), 1) FROM "ecobeasts"."${table}"), ` +
      `(SELECT last_value FROM "ecobeasts"."${table}_id_seq")))`,
  );
}

function effectColumns(effect: SkillEffectDraftDto, sortOrder: number) {
  return {
    sortOrder,
    effectTypeId: effect.effect_type_id,
    chance: effect.chance,
    skillTargetId: effect.skill_target_id ?? null,
    statusConditionId: effect.status_condition_id ?? null,
    statId: effect.stat_id ?? null,
    stages: effect.stages ?? null,
    percent: effect.percent ?? null,
    value: effect.value ?? null,
    weatherId: null,
    minTurns: effect.min_turns ?? null,
  };
}

/**
 * O efeito na posição N reaproveita a linha que já estava na posição N, para
 * os ids não mudarem a cada vez que a Técnica é salva.
 */
async function writeChildren(
  tx: Prisma.TransactionClient,
  skillId: number,
  draft: SkillDraftDto,
): Promise<void> {
  const existing = await tx.skillEffect.findMany({
    where: { skillId },
    orderBy: { sortOrder: 'asc' },
  });
  const kept = existing.slice(0, draft.effects.length);
  for (const [index, row] of kept.entries()) {
    await tx.skillEffect.update({
      where: { id: row.id },
      data: effectColumns(draft.effects[index]!, index + 1),
    });
  }
  await tx.skillEffect.deleteMany({
    where: { id: { in: existing.slice(kept.length).map((row) => row.id) } },
  });
  await catchUpIds(tx, 'skill_effects');
  await tx.skillEffect.createMany({
    data: draft.effects.slice(kept.length).map((effect, offset) => ({
      skillId,
      ...effectColumns(effect, kept.length + offset + 1),
    })),
  });
  await tx.speciesSkill.createMany({
    data: draft.learners.map((learner) => ({
      speciesId: learner.species_id,
      skillId,
      skillLearnMethodId: learner.skill_learn_method_id,
      level: learner.level ?? null,
    })),
  });
}
