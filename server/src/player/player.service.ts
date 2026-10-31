import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BattleStore } from '../battle/battle.store.js';
import { secureRandom } from '../common/secure-random.js';
import { createCreature } from '../domain/rules/creature-factory.js';
import { STAT_SLUGS } from '../domain/rules/types.js';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { loadCreatureBlueprint } from './creature-params.js';
import { INVALID_NAME, PlayerDto } from './player.dto.js';
import { creatureStats, PLAYER_INCLUDE, toPlayerDto } from './player.mapper.js';

const NAME_PATTERN = /^[\p{L}\p{N} ]{2,16}$/u;
const START_COINS = 1000;
const STARTER_LEVEL = 5;
const STARTER_SLOT = 1;
const PLAYER_EXISTS = 'Você já tem um Domador.';
const NO_PLAYER = 'Crie seu Domador primeiro.';
const STARTER_TAKEN = 'Você já escolheu seu Ecobeast.';
const NOT_A_STARTER = 'Esse Ecobeast não pode ser escolhido.';
export const CREATURE_NOT_FOUND = 'Ecobeast não encontrado.';

/** A equipe, com o que a cura precisa para achar os máximos. */
const HEAL_INCLUDE = {
  creatures: {
    ...PLAYER_INCLUDE.creatures,
    include: {
      ...PLAYER_INCLUDE.creatures.include,
      skills: { include: { skill: { select: { maxPp: true } } } },
    },
  },
} satisfies Prisma.PlayerInclude;

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
  constructor(
    private readonly prisma: PrismaService,
    private readonly battles: BattleStore,
  ) {}

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

    // starter_options tem FK para species: a espécie existe.
    const { params, statIds } = (await loadCreatureBlueprint(
      this.prisma,
      speciesId,
      STARTER_LEVEL,
    ))!;
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

  /**
   * Devolve HP e PP ao máximo e tira os status da equipe. A batalha aberta sai
   * antes da escrita: se terminasse depois, gravaria o HP antigo por cima.
   */
  async heal(userId: string): Promise<PlayerDto> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      include: HEAL_INCLUDE,
    });
    if (!player || player.creatures.length === 0) {
      throw new ConflictException(NO_PLAYER);
    }

    this.battles.delete(userId);
    await this.prisma.$transaction(
      player.creatures.flatMap((creature) => [
        this.prisma.creatureInstance.updateMany({
          where: { uid: creature.uid },
          data: {
            currentHp: creatureStats(creature).hp,
            statusConditionId: null,
          },
        }),
        ...creature.skills.map(({ slot, skill }) =>
          this.prisma.creatureInstanceSkill.updateMany({
            where: { creatureUid: creature.uid, slot },
            data: { currentPp: skill.maxPp },
          }),
        ),
      ]),
    );
    return (await this.get(userId))!;
  }

  async remove(userId: string): Promise<void> {
    // deleteMany não reclama de Domador inexistente; a cascata leva o resto.
    await this.prisma.player.deleteMany({ where: { id: userId } });
  }
}
