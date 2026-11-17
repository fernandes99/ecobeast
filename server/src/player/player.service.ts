import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { BattleStore } from '../battle/battle.store.js';
import { CodexService } from '../codex/codex.service.js';
import { secureRandom } from '../common/secure-random.js';
import { Env } from '../config/env.js';
import { createCreature } from '../domain/rules/creature-factory.js';
import { MAX_LEVEL, totalXpForLevel } from '../domain/rules/xp-curve.js';
import { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { checkedAppearance } from './appearance-check.js';
import { loadCreatureBlueprint, newCreatureData } from './creature-params.js';
import {
  AppearanceDto,
  INVALID_NAME,
  NAME_TAKEN,
  PlayerDto,
} from './player.dto.js';
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
/** O rosto 1, no lugar Rosto: a aparência padrão de quem é criado. */
const DEFAULT_FACE = { appearanceSlotId: 1, appearancePartId: 1 };

const HEAL_INCLUDE = {
  creatures: {
    ...PLAYER_INCLUDE.creatures,
    include: {
      ...PLAYER_INCLUDE.creatures.include,
      skills: { include: { skill: { select: { maxPp: true } } } },
    },
  },
} satisfies Prisma.PlayerInclude;

function normalizeName(raw: string): string {
  return raw.trim().replace(/\s+/g, ' ');
}

function checkedName(raw: string): string {
  const name = normalizeName(raw);
  if (!NAME_PATTERN.test(name)) throw new BadRequestException(INVALID_NAME);
  return name;
}

function isUniqueViolation(error: unknown): boolean {
  return (
    error instanceof Prisma.PrismaClientKnownRequestError &&
    error.code === 'P2002'
  );
}

@Injectable()
export class PlayerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly battles: BattleStore,
    private readonly codex: CodexService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async get(userId: string): Promise<PlayerDto | null> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      include: PLAYER_INCLUDE,
    });
    return player ? toPlayerDto(player) : null;
  }

  /** Sem nome, o Domador nasce com `""`, e a introdução o nomeia (liora-intro/01). */
  async create(userId: string, rawName?: string): Promise<PlayerDto> {
    const name = rawName === undefined ? '' : checkedName(rawName);
    try {
      const player = await this.prisma.player.create({
        data: {
          id: userId,
          name,
          coins: START_COINS,
          appearanceParts: { create: DEFAULT_FACE },
        },
        include: PLAYER_INCLUDE,
      });
      return toPlayerDto(player);
    } catch (error) {
      if (isUniqueViolation(error)) throw new ConflictException(PLAYER_EXISTS);
      throw error;
    }
  }

  /** Dá o nome uma vez só: o UPDATE só pega quem ainda não tem nome. */
  async setName(userId: string, rawName: string): Promise<PlayerDto> {
    const name = checkedName(rawName);
    const { count } = await this.prisma.player.updateMany({
      where: { id: userId, name: '' },
      data: { name },
    });
    if (count === 0) {
      const exists = await this.prisma.player.findUnique({
        where: { id: userId },
        select: { id: true },
      });
      throw new ConflictException(exists ? NAME_TAKEN : NO_PLAYER);
    }
    return (await this.get(userId))!;
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
    const others = (
      await this.prisma.starterOption.findMany({
        where: { speciesId: { not: speciesId } },
        select: { speciesId: true },
      })
    ).map((row) => row.speciesId);
    try {
      // Uma transação só; a chave única de player_id + party_slot barra o
      // segundo pedido simultâneo. O Bestiário não briga com ele: as duas
      // escritas dele ignoram a linha que já existe.
      await this.prisma.$transaction([
        this.prisma.creatureInstance.create({
          data: newCreatureData(userId, creature, statIds, {
            location: 'party',
            partySlot: STARTER_SLOT,
          }),
        }),
        this.codex.caughtWrite(userId, [speciesId]),
        this.codex.seenWrite(userId, others),
      ]);
    } catch (error) {
      if (isUniqueViolation(error)) throw new ConflictException(STARTER_TAKEN);
      throw error;
    }
    return (await this.get(userId))!;
  }

  async setAppearance(
    userId: string,
    appearance: AppearanceDto,
  ): Promise<PlayerDto> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!player) throw new ConflictException(NO_PLAYER);

    const worn = await checkedAppearance(this.prisma, appearance);

    await this.prisma.$transaction([
      this.prisma.player.update({
        where: { id: userId },
        data: {
          bodyTypeId: appearance.body_type_id,
          skinPaletteId: appearance.skin_palette_id,
        },
      }),
      this.prisma.playerAppearancePart.deleteMany({
        where: { playerId: userId },
      }),
      this.prisma.playerAppearancePart.createMany({
        data: worn.map(({ slotId, partId, paletteId }) => ({
          playerId: userId,
          appearanceSlotId: slotId,
          appearancePartId: partId,
          paletteId,
        })),
      }),
    ]);
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

  async almostLevelUp(userId: string): Promise<PlayerDto> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      include: PLAYER_INCLUDE,
    });
    if (!player || player.creatures.length === 0) {
      throw new ConflictException(NO_PLAYER);
    }

    await this.prisma.$transaction(
      player.creatures
        .filter((creature) => creature.level < MAX_LEVEL)
        .map((creature) =>
          this.prisma.creatureInstance.update({
            where: { uid: creature.uid },
            data: {
              currentXp:
                totalXpForLevel(
                  creature.species.growthRate.xpMultiplier,
                  creature.level + 1,
                ) - 1,
            },
          }),
        ),
    );
    return (await this.get(userId))!;
  }

  async remove(userId: string): Promise<void> {
    // deleteMany não reclama de Domador inexistente; a cascata leva o resto.
    await this.prisma.player.deleteMany({ where: { id: userId } });
  }
}
