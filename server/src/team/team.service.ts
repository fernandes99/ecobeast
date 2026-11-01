import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { isUUID } from 'class-validator';
import { BattleStore } from '../battle/battle.store.js';
import { firstFreePartySlot, isSameTeam } from '../domain/team/party.js';
import { Prisma } from '../generated/prisma/client.js';
import type { CreatureDto, PlayerDto } from '../player/player.dto.js';
import { CREATURE_INCLUDE, toCreatureDto } from '../player/player.mapper.js';
import { CREATURE_NOT_FOUND, PlayerService } from '../player/player.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { INVALID_ORDER } from './team.dto.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
export const ALREADY_IN_TEAM = 'Esse Ecobeast já está na equipe.';
export const ALREADY_STORED = 'Esse Ecobeast já está no Santuário.';
export const TEAM_FULL = 'A equipe está cheia.';
export const LAST_CREATURE = 'A equipe precisa de ao menos 1 Ecobeast.';
/** Reordenar faz vários acessos ao banco, e cada um cruza a rede. */
const TRANSACTION_TIMEOUT_MS = 20_000;

type Tx = Prisma.TransactionClient;

interface Member {
  uid: string;
  partySlot: number | null;
}

const TO_STORAGE = { location: 'storage', partySlot: null } as const;

function toParty(partySlot: number) {
  return { location: 'party', partySlot } as const;
}

/** A equipe e o Santuário (.specs/team-and-storage/architecture.md). */
@Injectable()
export class TeamService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly players: PlayerService,
    private readonly battles: BattleStore,
  ) {}

  async storage(userId: string): Promise<CreatureDto[]> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      select: {
        creatures: {
          where: { location: 'storage' },
          orderBy: [{ caughtAt: 'desc' }, { uid: 'asc' }],
          include: CREATURE_INCLUDE,
        },
      },
    });
    if (!player) throw new ConflictException(NO_PLAYER);
    return player.creatures.map(toCreatureDto);
  }

  async order(userId: string, uids: string[]): Promise<PlayerDto> {
    return this.changeTeam(userId, async (tx, team) => {
      const current = team.map(({ uid }) => uid);
      if (!isSameTeam(current, uids)) {
        throw new BadRequestException(INVALID_ORDER);
      }
      this.battles.delete(userId);
      // A vaga é única linha a linha: todos saem antes de alguém entrar.
      await tx.creatureInstance.updateMany({
        where: { uid: { in: current } },
        data: TO_STORAGE,
      });
      for (const [index, uid] of uids.entries()) {
        await tx.creatureInstance.update({
          where: { uid },
          data: toParty(index + 1),
        });
      }
    });
  }

  async bring(
    userId: string,
    uid: string,
    replaceUid?: string,
  ): Promise<PlayerDto> {
    return this.changeTeam(userId, async (tx, team) => {
      const creature = await this.findCreature(tx, userId, uid);
      if (creature.location === 'party') {
        throw new BadRequestException(ALREADY_IN_TEAM);
      }
      const leaving = replaceUid
        ? team.find((member) => member.uid === replaceUid)
        : null;
      if (replaceUid && !leaving) {
        throw new NotFoundException(CREATURE_NOT_FOUND);
      }
      const partySlot =
        leaving?.partySlot ??
        firstFreePartySlot(team.map((member) => member.partySlot!));
      if (partySlot === null) throw new ConflictException(TEAM_FULL);

      this.battles.delete(userId);
      if (leaving) {
        await tx.creatureInstance.update({
          where: { uid: leaving.uid },
          data: TO_STORAGE,
        });
      }
      await tx.creatureInstance.update({
        where: { uid },
        data: toParty(partySlot),
      });
    });
  }

  async store(userId: string, uid: string): Promise<PlayerDto> {
    return this.changeTeam(userId, async (tx, team) => {
      const creature = await this.findCreature(tx, userId, uid);
      if (creature.location === 'storage') {
        throw new BadRequestException(ALREADY_STORED);
      }
      if (team.length === 1) throw new BadRequestException(LAST_CREATURE);

      this.battles.delete(userId);
      await tx.creatureInstance.update({ where: { uid }, data: TO_STORAGE });
    });
  }

  /**
   * Toda escrita começa travando a linha do Domador: de dois pedidos ao mesmo
   * tempo, o segundo espera o primeiro e lê a equipe já mudada.
   */
  private async changeTeam(
    userId: string,
    write: (tx: Tx, team: Member[]) => Promise<void>,
  ): Promise<PlayerDto> {
    await this.prisma.$transaction(
      async (tx) => {
        await tx.player.updateMany({
          where: { id: userId },
          data: { coins: { increment: 0 } },
        });
        const team = await tx.creatureInstance.findMany({
          where: { playerId: userId, location: 'party' },
          orderBy: { partySlot: 'asc' },
          select: { uid: true, partySlot: true },
        });
        if (team.length === 0) throw new ConflictException(NO_PLAYER);
        await write(tx, team);
      },
      { timeout: TRANSACTION_TIMEOUT_MS },
    );
    return (await this.players.get(userId))!;
  }

  /** Filtrar pelo dono faz a criatura de outro Domador parecer inexistente. */
  private async findCreature(tx: Tx, userId: string, uid: string) {
    const creature = isUUID(uid)
      ? await tx.creatureInstance.findFirst({
          where: { uid, playerId: userId },
          select: { location: true },
        })
      : null;
    if (!creature) throw new NotFoundException(CREATURE_NOT_FOUND);
    return creature;
  }
}
