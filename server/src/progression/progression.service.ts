import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  type EvolutionRule,
  evolutionOffer,
  evolvedTraitId,
  type SpeciesTraitRow,
} from '../domain/progression/evolution.js';
import {
  evolutionSkills,
  learnNewSkills,
  skillsBetween,
} from '../domain/progression/learnset.js';
import type { LearnsetEntry } from '../domain/rules/creature-factory.js';
import { Prisma } from '../generated/prisma/client.js';
import {
  CREATURE_INCLUDE,
  creatureStats,
  toCreatureDto,
} from '../player/player.mapper.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  EvolutionResponseDto,
  LearnSkillResponseDto,
} from './progression.dto.js';
import { type PendingChoice, ProgressionStore } from './progression.store.js';

export const NO_CHOICE = 'Essa escolha não está mais disponível.';
export const UNKNOWN_SKILL = 'Esse Ecobeast não conhece essa Técnica.';
export const EVOLVE_FIRST = 'Escolha primeiro se ele vai evoluir.';

const SLOTS = [1, 2, 3, 4];

/** Quem subiu de nível na vitória, como está no banco antes de gravar o fim. */
export interface LeveledCreature {
  uid: string;
  speciesId: number;
  levelBefore: number;
  levelAfter: number;
  skills: { slot: number; skillId: number }[];
}

export interface LearnedSkill {
  skillId: number;
  slot: number;
  currentPp: number;
}

/** O que a vitória faz com as Técnicas e a evolução de um Ecobeast. */
export interface VictoryPlan {
  evolutionSpeciesId: number | null;
  learned: LearnedSkill[];
  pending: number[];
}

interface SpeciesLearning {
  learnset: LearnsetEntry[];
  maxPp: Map<number, number>;
  traits: SpeciesTraitRow[];
}

interface Learning {
  species: Map<number, SpeciesLearning>;
  evolutions: EvolutionRule[];
}

/** As primeiras vagas livres, de 1 a 4, para as Técnicas aprendidas. */
function fillSlots(
  usedSlots: number[],
  skillIds: number[],
  maxPp: Map<number, number>,
): LearnedSkill[] {
  const free = SLOTS.filter((slot) => !usedSlots.includes(slot));
  return skillIds.map((skillId, index) => ({
    skillId,
    slot: free[index]!,
    currentPp: maxPp.get(skillId) ?? 0,
  }));
}

/**
 * Técnicas novas e evolução depois da vitória, e as escolhas do jogador
 * (.specs/progression/architecture.md).
 */
@Injectable()
export class ProgressionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: ProgressionStore,
  ) {}

  /**
   * A oferta de evolução de cada um e, sem oferta, as Técnicas aprendidas e as
   * pendentes. Não grava nada: o `BattleService` grava junto com o fim da luta.
   */
  async planVictory(
    creatures: LeveledCreature[],
  ): Promise<Map<string, VictoryPlan>> {
    const plans = new Map<string, VictoryPlan>();
    if (creatures.length === 0) return plans;

    const learning = await this.loadLearning(
      creatures.map((creature) => creature.speciesId),
    );
    for (const creature of creatures) {
      const evolutionSpeciesId = evolutionOffer(
        creature.speciesId,
        creature.levelBefore,
        creature.levelAfter,
        learning.evolutions,
      );
      if (evolutionSpeciesId !== null) {
        plans.set(creature.uid, {
          evolutionSpeciesId,
          learned: [],
          pending: [],
        });
        continue;
      }
      const species = learning.species.get(creature.speciesId)!;
      plans.set(creature.uid, {
        evolutionSpeciesId: null,
        ...this.newSkills(
          creature.skills,
          skillsBetween(
            species.learnset,
            creature.levelBefore,
            creature.levelAfter,
          ),
          species.maxPp,
        ),
      });
    }
    return plans;
  }

  /** Substitui as escolhas pendentes do jogador pelas desta vitória. */
  remember(
    userId: string,
    creatures: LeveledCreature[],
    plans: Map<string, VictoryPlan>,
  ): void {
    const choices = new Map<string, PendingChoice>();
    for (const creature of creatures) {
      const plan = plans.get(creature.uid);
      if (!plan) continue;
      if (plan.evolutionSpeciesId === null && plan.pending.length === 0)
        continue;
      choices.set(creature.uid, {
        evolutionSpeciesId: plan.evolutionSpeciesId,
        levelBefore: creature.levelBefore,
        levelAfter: creature.levelAfter,
        pendingSkillIds: plan.pending,
      });
    }
    this.store.replace(userId, choices);
  }

  /**
   * A escolha fica reservada antes de qualquer `await`: dois pedidos ao mesmo
   * tempo não evoluem o mesmo Ecobeast duas vezes. Se a gravação falhar, ela volta.
   */
  async evolve(
    userId: string,
    uid: string,
    accept: boolean,
  ): Promise<EvolutionResponseDto> {
    const choice = this.store.get(userId, uid);
    if (!choice || choice.evolutionSpeciesId === null) {
      throw new NotFoundException(NO_CHOICE);
    }
    this.store.update(userId, uid, { ...choice, evolutionSpeciesId: null });
    try {
      return await this.applyEvolution(userId, uid, choice, accept);
    } catch (error) {
      this.store.update(userId, uid, choice);
      throw error;
    }
  }

  async learnSkill(
    userId: string,
    uid: string,
    skillId: number,
    forgetSkillId: number | null,
  ): Promise<LearnSkillResponseDto> {
    this.pendingChoice(userId, uid, skillId);
    const row = await this.loadCreature(userId, uid);
    const slot =
      forgetSkillId === null
        ? null
        : row.skills.find((skill) => skill.skillId === forgetSkillId)?.slot;
    if (slot === undefined) throw new BadRequestException(UNKNOWN_SKILL);
    const maxPp =
      slot === null
        ? 0
        : (
            await this.prisma.skill.findUniqueOrThrow({
              where: { id: skillId },
            })
          ).maxPp;

    // Da conferência à reserva não há `await`: a mesma Técnica não entra duas vezes.
    const choice = this.pendingChoice(userId, uid, skillId);
    const remaining = choice.pendingSkillIds.filter((id) => id !== skillId);
    this.store.update(
      userId,
      uid,
      remaining.length > 0 ? { ...choice, pendingSkillIds: remaining } : null,
    );
    try {
      if (slot !== null) {
        await this.prisma.creatureInstanceSkill.updateMany({
          where: { creatureUid: uid, slot },
          data: { skillId, currentPp: maxPp },
        });
      }
      const creature = await this.loadCreature(userId, uid);
      return {
        creature: toCreatureDto(creature),
        pending_skill_ids: remaining,
      };
    } catch (error) {
      this.store.update(userId, uid, choice);
      throw error;
    }
  }

  private pendingChoice(
    userId: string,
    uid: string,
    skillId: number,
  ): PendingChoice {
    const choice = this.store.get(userId, uid);
    if (!choice) throw new NotFoundException(NO_CHOICE);
    if (choice.evolutionSpeciesId !== null) {
      throw new ConflictException(EVOLVE_FIRST);
    }
    if (!choice.pendingSkillIds.includes(skillId)) {
      throw new NotFoundException(NO_CHOICE);
    }
    return choice;
  }

  private async applyEvolution(
    userId: string,
    uid: string,
    choice: PendingChoice,
    accept: boolean,
  ): Promise<EvolutionResponseDto> {
    const row = await this.loadCreature(userId, uid);
    const targetId = accept ? choice.evolutionSpeciesId! : row.speciesId;
    const learning = await this.loadLearning([row.speciesId, targetId]);
    const target = learning.species.get(targetId)!;
    const { levelBefore, levelAfter } = choice;

    const candidates = accept
      ? [
          ...evolutionSkills(target.learnset),
          ...skillsBetween(target.learnset, levelBefore, levelAfter),
        ]
      : skillsBetween(target.learnset, levelBefore, levelAfter);
    const { learned, pending } = this.newSkills(
      row.skills,
      candidates,
      target.maxPp,
    );

    const evolved = accept
      ? await this.evolvedData(row, targetId, learning)
      : null;
    await this.prisma.$transaction([
      ...(evolved
        ? [
            this.prisma.creatureInstance.update({
              where: { uid },
              data: evolved,
            }),
          ]
        : []),
      this.prisma.creatureInstanceSkill.createMany({
        data: learned.map((skill) => ({ creatureUid: uid, ...skill })),
      }),
    ]);
    this.store.update(
      userId,
      uid,
      pending.length > 0
        ? { ...choice, evolutionSpeciesId: null, pendingSkillIds: pending }
        : null,
    );
    return {
      creature: toCreatureDto(await this.loadCreature(userId, uid)),
      learned_skill_ids: learned.map((skill) => skill.skillId),
      pending_skill_ids: pending,
    };
  }

  /** Espécie e Traço novos, e o HP atual subindo o mesmo tanto que o máximo. */
  private async evolvedData(
    row: CreatureWithSkills,
    targetId: number,
    learning: Learning,
  ): Promise<{ speciesId: number; traitId: number; currentHp: number }> {
    const species = await this.prisma.species.findUniqueOrThrow({
      where: { id: targetId },
      select: CREATURE_INCLUDE.species.select,
    });
    const hpGain =
      creatureStats({ ...row, species }).hp - creatureStats(row).hp;
    return {
      speciesId: targetId,
      traitId: evolvedTraitId(
        row.traitId,
        learning.species.get(row.speciesId)!.traits,
        learning.species.get(targetId)!.traits,
      ),
      currentHp: row.currentHp > 0 ? Math.max(1, row.currentHp + hpGain) : 0,
    };
  }

  private newSkills(
    known: { slot: number; skillId: number }[],
    candidates: number[],
    maxPp: Map<number, number>,
  ): { learned: LearnedSkill[]; pending: number[] } {
    const { learned, pending } = learnNewSkills(
      known.map((skill) => skill.skillId),
      candidates,
    );
    return {
      learned: fillSlots(
        known.map((skill) => skill.slot),
        learned,
        maxPp,
      ),
      pending,
    };
  }

  /** O Ecobeast deste Domador; sem ele, a escolha não existe mais. */
  private async loadCreature(
    userId: string,
    uid: string,
  ): Promise<CreatureWithSkills> {
    const row = await this.prisma.creatureInstance.findFirst({
      where: { uid, playerId: userId },
      include: CREATURE_INCLUDE,
    });
    if (!row) {
      this.store.update(userId, uid, null);
      throw new NotFoundException(NO_CHOICE);
    }
    return row;
  }

  private async loadLearning(speciesIds: number[]): Promise<Learning> {
    const ids = [...new Set(speciesIds)];
    const [species, evolutions] = await Promise.all([
      this.prisma.species.findMany({
        where: { id: { in: ids } },
        select: {
          id: true,
          skills: {
            select: {
              skillId: true,
              level: true,
              skillLearnMethod: { select: { slug: true } },
              skill: { select: { maxPp: true } },
            },
          },
          traits: { select: { traitId: true, slot: true, isHidden: true } },
        },
      }),
      this.prisma.evolution.findMany({
        where: { speciesId: { in: ids } },
        include: { evolutionTrigger: { select: { slug: true } } },
      }),
    ]);
    return {
      species: new Map(
        species.map((row) => [
          row.id,
          {
            learnset: row.skills.map((skill) => ({
              skillId: skill.skillId,
              method: skill.skillLearnMethod.slug,
              level: skill.level,
            })),
            maxPp: new Map(
              row.skills.map((skill) => [skill.skillId, skill.skill.maxPp]),
            ),
            traits: row.traits,
          },
        ]),
      ),
      evolutions: evolutions.map((row) => ({
        id: row.id,
        speciesId: row.speciesId,
        evolvedSpeciesId: row.evolvedSpeciesId,
        trigger: row.evolutionTrigger.slug,
        minLevel: row.minLevel,
      })),
    };
  }
}

type CreatureWithSkills = Prisma.CreatureInstanceGetPayload<{
  include: typeof CREATURE_INCLUDE;
}>;
