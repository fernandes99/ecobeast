import { QUEST_TYPES } from '../domain/quests/quests.js';
import type { Prisma } from '../generated/prisma/client.js';

/**
 * Soma um item ganho nas missões "Encontre X item" aceitas e não entregues
 * (auralis/09): vale todo jeito de ganhar, no chão, na Loja, na entrega de
 * missão e no nível do Domador.
 */
export function itemQuestWrite(
  client: Pick<Prisma.TransactionClient, '$executeRaw'>,
  userId: string,
  itemId: number,
  quantity: number,
): Prisma.PrismaPromise<number> {
  return client.$executeRaw`
    UPDATE "ecobeasts"."player_quests" pq
    SET "progress" = LEAST(pq."progress" + ${quantity}, COALESCE(q."amount", 1))
    FROM "ecobeasts"."quests" q
    WHERE pq."quest_id" = q."id"
      AND pq."player_id" = ${userId}::uuid
      AND pq."claimed_at" IS NULL
      AND q."quest_type_id" = ${QUEST_TYPES.find_item}
      AND q."target_item_id" = ${itemId}`;
}
