import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { randomInt } from 'node:crypto';
import {
  createCreature,
  CreateCreatureParams,
} from '../domain/rules/creature-factory.js';
import { STAT_SLUGS, StatSlug } from '../domain/rules/types.js';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { INVALID_NAME, PlayerDto } from './player.dto.js';
import { PLAYER_INCLUDE, toPlayerDto, toStatBlock } from './player.mapper.js';

const NAME_PATTERN = /^[\p{L}\p{N} ]{2,16}$/u;
const START_COINS = 1000;
const STARTER_LEVEL = 5;
const STARTER_SLOT = 1;
const PLAYER_EXISTS = 'Você já tem um Domador.';
const NO_PLAYER = 'Crie seu Domador primeiro.';
const STARTER_TAKEN = 'Você já escolheu seu Ecobeast.';
const NOT_A_STARTER = 'Esse Ecobeast não pode ser escolhido.';
export const CREATURE_NOT_FOUND = 'Ecobeast não encontrado.';

/** O maior intervalo aceito pelo `crypto.randomInt`. */
const RANDOM_RANGE = 2 ** 48 - 1;

/** Número em [0, 1) de uma fonte segura, para os sorteios das regras. */
function secureRandom(): number {
  return randomInt(RANDOM_RANGE) / RANDOM_RANGE;
}

/** Pontas sem espaço e sequências de espaço viram uma. */
function normalizeName(raw: string): string {
  return raw.trim().replace(/\s+/g, ' ');
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}

/** O jogador no banco (.specs/auth-google/03-player-api.md). */
@Injectable()
export class PlayerService {
  constructor(private readonly prisma: PrismaService) {}

  async get(userId: string): Promise<PlayerDto | null> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      include: PLAYER_INCLUDE,
    });
    return player ? toPlayerDto(player) : null;
  }

  async create(userId: string, rawName: string): Promise<PlayerDto> {
    const name = normalizeName(rawName);
    if (!NAME_PATTERN.test(name)) throw new BadRequestException(INVALID_NAME);
    try {
      const player = await this.prisma.player.create({
        data: { id: userId, name, coins: START_COINS },
        include: PLAYER_INCLUDE,
      });
      return toPlayerDto(player);
    } catch (error) {
      if (isUniqueViolation(error)) throw new ConflictException(PLAYER_EXISTS);
      throw error;
    }
  }

  async chooseStarter(userId: string, speciesId: number): Promise<PlayerDto> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: { _count: { select: { creatures: true } } },
    });
    if (!player) throw new ConflictException(NO_PLAYER);
    if (player._count.creatures > 0) {
      throw new ConflictException(STARTER_TAKEN);
    }
    const option = await this.prisma.starterOption.findUnique({
      where: { speciesId },
    });
    if (!option) throw new BadRequestException(NOT_A_STARTER);

    const { params, statIds } = await this.creatureParams(speciesId);
    const creature = createCreature(params, secureRandom);
    try {
      // A escrita aninhada é uma transação só; a chave única de
      // player_id + party_slot barra o segundo pedido simultâneo.
      await this.prisma.creatureInstance.create({
        data: {
          playerId: userId,
          speciesId: creature.speciesId,
          level: creature.level,
          currentXp: creature.currentXp,
          currentHp: creature.currentHp,
          temperamentId: creature.temperamentId,
          traitId: creature.traitId,
          gender: creature.gender,
          isPrismatic: creature.isPrismatic,
          bond: creature.bond,
          location: 'party',
          partySlot: STARTER_SLOT,
          originalPlayerId: userId,
          caughtAt: new Date(),
          stats: {
            create: STAT_SLUGS.map((slug) => ({
              statId: statIds[slug],
              genes: creature.genes[slug],
              trainingPoints: creature.trainingPoints[slug],
            })),
          },
          skills: { create: creature.skills },
        },
      });
    } catch (error) {
      if (isUniqueViolation(error)) throw new ConflictException(STARTER_TAKEN);
      throw error;
    }
    return (await this.get(userId))!;
  }

  async setNickname(
    userId: string,
    uid: string,
    rawNickname: string,
  ): Promise<PlayerDto> {
    const nickname = normalizeName(rawNickname);
    if (nickname && !NAME_PATTERN.test(nickname)) {
      throw new BadRequestException(INVALID_NAME);
    }
    // Filtrar pelo dono faz a criatura de outro Domador parecer inexistente.
    const { count } = await this.prisma.creatureInstance.updateMany({
      where: { uid, playerId: userId },
      data: { nickname: nickname || null },
    });
    if (count === 0) throw new NotFoundException(CREATURE_NOT_FOUND);
    return (await this.get(userId))!;
  }

  async remove(userId: string): Promise<void> {
    // deleteMany não reclama de Domador inexistente; a cascata leva o resto.
    await this.prisma.player.deleteMany({ where: { id: userId } });
  }

  /** O que as regras precisam do catálogo para criar uma criatura. */
  private async creatureParams(speciesId: number): Promise<{
    params: CreateCreatureParams;
    statIds: Record<StatSlug, number>;
  }> {
    const [species, temperaments] = await Promise.all([
      this.prisma.species.findUniqueOrThrow({
        where: { id: speciesId },
        include: {
          growthRate: true,
          stats: { include: { stat: true } },
          traits: { where: { isHidden: false }, orderBy: { slot: 'asc' } },
          skills: {
            // Mesma ordem do catálogo que o cliente lê.
            orderBy: [{ level: 'asc' }, { skillId: 'asc' }],
            include: { skill: true, skillLearnMethod: true },
          },
        },
      }),
      this.prisma.temperament.findMany({
        orderBy: { id: 'asc' },
        include: { increasedStat: true, decreasedStat: true },
      }),
    ]);
    return {
      statIds: toStatBlock(species.stats, (row) => row.statId),
      params: {
        species: {
          id: species.id,
          genderRatio: species.genderRatio,
          baseStats: toStatBlock(species.stats, (row) => row.baseValue),
        },
        level: STARTER_LEVEL,
        learnset: species.skills.map((row) => ({
          skillId: row.skillId,
          method: row.skillLearnMethod.slug,
          level: row.level,
        })),
        maxPpBySkill: new Map(
          species.skills.map((row) => [row.skillId, row.skill.maxPp]),
        ),
        traitIds: species.traits.map((row) => row.traitId),
        temperaments: temperaments.map((row) => ({
          id: row.id,
          increasedStat: row.increasedStat.slug as StatSlug,
          decreasedStat: row.decreasedStat.slug as StatSlug,
        })),
        xpMultiplier: species.growthRate.xpMultiplier,
      },
    };
  }
}
