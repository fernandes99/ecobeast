import 'dotenv/config';
import { PrismaPg } from '@prisma/adapter-pg';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { draftHash } from '../src/domain/islands/island-draft.js';
import { IslandsService } from '../src/islands/islands.service.js';
import type { PrismaService } from '../src/prisma/prisma.service.js';

const prisma = new PrismaClient({
  adapter: new PrismaPg({ connectionString: process.env['DIRECT_URL'] }),
});
const islands = new IslandsService(prisma as unknown as PrismaService);

try {
  const maps = await prisma.islandMap.findMany({
    select: { id: true, contentHash: true },
  });
  let changed = 0;
  for (const map of maps) {
    const hash = draftHash(await islands.readVersion(prisma, map.id));
    if (hash === map.contentHash) continue;
    await prisma.islandMap.update({
      where: { id: map.id },
      data: { contentHash: hash },
    });
    changed += 1;
  }
  console.log(`${maps.length} versões lidas, ${changed} hashes recalculados.`);
} finally {
  await prisma.$disconnect();
}
