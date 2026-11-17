import {
  BadRequestException,
  ConflictException,
  Injectable,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  invalidMarkMessage,
  MARK_PATTERN,
  MARKS_PER_CALL_MESSAGE,
  MAX_MARKS,
  MAX_MARKS_MESSAGE,
  MAX_MARKS_PER_CALL,
} from './story.dto.js';

const NO_PLAYER = 'Crie seu Domador primeiro.';

/** Os Marcos da história de cada Domador (story/01), guardados sem significado. */
@Injectable()
export class StoryService {
  constructor(private readonly prisma: PrismaService) {}

  async addMarks(userId: string, value: unknown): Promise<string[]> {
    const marks = checkMarks(value);
    return this.prisma.$transaction(async (tx) => {
      // Trava o Domador para dois pedidos juntos não passarem do limite.
      const locked = await tx.$queryRaw<{ id: string }[]>`
        SELECT "id" FROM "ecobeasts"."players" WHERE "id" = ${userId}::uuid FOR UPDATE`;
      if (locked.length === 0) throw new ConflictException(NO_PLAYER);
      const existing = await tx.playerStoryMark.findMany({
        where: { playerId: userId },
        select: { mark: true },
      });
      const have = new Set(existing.map(({ mark }) => mark));
      const fresh = marks.filter((mark) => !have.has(mark));
      if (have.size + fresh.length > MAX_MARKS) {
        throw new BadRequestException(MAX_MARKS_MESSAGE);
      }
      if (fresh.length > 0) {
        await tx.playerStoryMark.createMany({
          data: fresh.map((mark) => ({ playerId: userId, mark })),
          skipDuplicates: true,
        });
      }
      return [...have, ...fresh].sort();
    });
  }
}

/** Os Marcos do pedido, sem repetidos; recusa com a mensagem do primeiro erro. */
export function checkMarks(value: unknown): string[] {
  if (
    !Array.isArray(value) ||
    value.length < 1 ||
    value.length > MAX_MARKS_PER_CALL
  ) {
    throw new BadRequestException(MARKS_PER_CALL_MESSAGE);
  }
  for (const item of value as unknown[]) {
    if (typeof item !== 'string' || !MARK_PATTERN.test(item)) {
      throw new BadRequestException(invalidMarkMessage(item));
    }
  }
  return [...new Set(value as string[])];
}
