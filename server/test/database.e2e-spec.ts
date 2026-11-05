import { PrismaClient } from '../src/generated/prisma/client.js';
import { attempt, createTestPrisma, testSlug, type Tx } from './support/db.js';
import {
  createElement,
  createItem,
  createPlayerWithCreature,
  createSkillParents,
  createSpecies,
  creatureData,
  skillData,
} from './support/fixtures.js';

// Cada caso roda numa transação desfeita no fim: o banco fica como estava.
// (.specs/backend-api/02-database-schema.md, RF-07)

describe('restrições do banco (e2e)', () => {
  let prisma: PrismaClient;

  beforeAll(() => {
    prisma = createTestPrisma();
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  function expectRejected(
    result: 'accepted' | Error,
    constraint: string,
  ): void {
    expect(result).not.toBe('accepted');
    expect(String((result as Error).message)).toContain(constraint);
  }

  it('nada do jogo fica no schema public (a API automática do Supabase o publica)', async () => {
    const rows = await prisma.$queryRaw<{ table_name: string }[]>`
      SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'`;
    expect(rows.map((row) => row.table_name)).toEqual([]);
  });

  it('as 35 tabelas e o histórico de migrations ficam no schema ecobeasts', async () => {
    const rows = await prisma.$queryRaw<{ n: number }[]>`
      SELECT count(*)::int AS n FROM information_schema.tables WHERE table_schema = 'ecobeasts'`;
    expect(rows[0].n).toBe(36);
  });

  it('recusa Técnica com precisão 150', async () => {
    const result = await attempt(prisma, async (tx) => {
      const parents = await createSkillParents(tx);
      await tx.skill.create({ data: skillData(parents, 150) });
    });
    expectRejected(result, 'skills_accuracy_check');
  });

  it('aceita Técnica com precisão 100', async () => {
    const result = await attempt(prisma, async (tx) => {
      const parents = await createSkillParents(tx);
      await tx.skill.create({ data: skillData(parents, 100) });
    });
    expect(result).toBe('accepted');
  });

  it('recusa cor de Elemento fora do formato #RRGGBB', async () => {
    const result = await attempt(prisma, async (tx) => {
      const element = await createElement(tx);
      await tx.element.update({
        where: { id: element.id },
        data: { colorHex: 'red' },
      });
    });
    expectRejected(result, 'elements_color_hex_check');
  });

  it('recusa slug com letra maiúscula', async () => {
    const result = await attempt(prisma, async (tx) => {
      const element = await createElement(tx);
      await tx.element.update({
        where: { id: element.id },
        data: { slug: 'Fogo' },
      });
    });
    expectRejected(result, 'elements_slug_check');
  });

  it('recusa multiplicador de efetividade 1.5', async () => {
    const result = await attempt(prisma, async (tx) => {
      const a = await createElement(tx);
      const b = await createElement(tx);
      await tx.elementEfficacy.create({
        data: {
          attackerElementId: a.id,
          defenderElementId: b.id,
          multiplier: 1.5,
        },
      });
    });
    expectRejected(result, 'element_efficacy_multiplier_check');
  });

  it('recusa taxa de captura 101', async () => {
    const result = await attempt(prisma, async (tx) => {
      const species = await createSpecies(tx);
      await tx.species.update({
        where: { id: species.id },
        data: { captureRate: 101 },
      });
    });
    expectRejected(result, 'species_capture_rate_check');
  });

  it('aceita taxa de captura de 0 a 100', async () => {
    const result = await attempt(prisma, async (tx) => {
      const species = await createSpecies(tx);
      for (const captureRate of [0, 100]) {
        await tx.species.update({
          where: { id: species.id },
          data: { captureRate },
        });
      }
    });
    expect(result).toBe('accepted');
  });

  async function createSpeciesBiome(tx: Tx, rate: number) {
    const species = await createSpecies(tx);
    const biome = await tx.biome.create({
      data: { slug: testSlug('biome'), name: 'Teste', description: 'Teste' },
    });
    return tx.speciesBiome.create({
      data: { speciesId: species.id, biomeId: biome.id, rate },
    });
  }

  it.each([-1, 101])('recusa taxa de bioma %i', async (rate) => {
    const result = await attempt(prisma, (tx) => createSpeciesBiome(tx, rate));
    expectRejected(result, 'species_biomes_rate_check');
  });

  it.each([0, 100])('aceita taxa de bioma %i', async (rate) => {
    const result = await attempt(prisma, (tx) => createSpeciesBiome(tx, rate));
    expect(result).toBe('accepted');
  });

  it('recusa slug de bioma com letra maiúscula', async () => {
    const result = await attempt(prisma, (tx) =>
      tx.biome.create({
        data: { slug: 'Boreal', name: 'Teste', description: 'Teste' },
      }),
    );
    expectRejected(result, 'biomes_slug_check');
  });

  it('recusa taxa de uma espécie que não existe', async () => {
    const result = await attempt(prisma, async (tx) => {
      const biome = await tx.biome.create({
        data: { slug: testSlug('biome'), name: 'Teste', description: 'Teste' },
      });
      await tx.speciesBiome.create({
        data: { speciesId: 999_999, biomeId: biome.id, rate: 50 },
      });
    });
    expectRejected(result, 'species_biomes_species_id_fkey');
  });

  it('recusa item com preço 0', async () => {
    const result = await attempt(prisma, (tx) => createItem(tx, { price: 0 }));
    expectRejected(result, 'items_price_check');
  });

  it('recusa item com cura 0', async () => {
    const result = await attempt(prisma, (tx) =>
      createItem(tx, { healAmount: 0 }),
    );
    expectRejected(result, 'items_heal_amount_check');
  });

  it('recusa item com bônus de captura 0', async () => {
    const result = await attempt(prisma, (tx) =>
      createItem(tx, { captureBonus: 0 }),
    );
    expectRejected(result, 'items_capture_bonus_check');
  });

  it('aceita item com preço, cura e bônus válidos', async () => {
    const result = await attempt(prisma, (tx) =>
      createItem(tx, { price: 1, healAmount: 1, captureBonus: 0.5 }),
    );
    expect(result).toBe('accepted');
  });

  it('recusa Mochila com item que não existe', async () => {
    const result = await attempt(prisma, async (tx) => {
      const { player } = await createPlayerWithCreature(tx);
      await tx.inventoryItem.create({
        data: { playerId: player.id, itemId: 2_000_000_000, quantity: 1 },
      });
    });
    expectRejected(result, 'inventory_items_item_id_fkey');
  });

  it('recusa apagar um item que está na Mochila de alguém', async () => {
    const result = await attempt(prisma, async (tx) => {
      const { player } = await createPlayerWithCreature(tx);
      const item = await createItem(tx);
      await tx.inventoryItem.create({
        data: { playerId: player.id, itemId: item.id, quantity: 1 },
      });
      await tx.item.delete({ where: { id: item.id } });
    });
    expectRejected(result, 'inventory_items_item_id_fkey');
  });

  it('recusa Elemento de espécie no slot 3', async () => {
    const result = await attempt(prisma, async (tx) => {
      const species = await createSpecies(tx);
      const element = await createElement(tx);
      await tx.speciesElement.create({
        data: { speciesId: species.id, slot: 3, elementId: element.id },
      });
    });
    expectRejected(result, 'species_elements_slot_check');
  });

  it('recusa Evolução com horário "dusk"', async () => {
    const result = await attempt(prisma, async (tx) => {
      const from = await createSpecies(tx);
      const to = await createSpecies(tx);
      const trigger = await tx.evolutionTrigger.create({
        data: { slug: 'zz_test_trigger', name: 'Teste' },
      });
      await tx.evolution.create({
        data: {
          speciesId: from.id,
          evolvedSpeciesId: to.id,
          evolutionTriggerId: trigger.id,
          minLevel: null,
          itemId: null,
          minBond: null,
          timeOfDay: 'dusk',
          zoneId: null,
        },
      });
    });
    expectRejected(result, 'evolutions_time_of_day_check');
  });

  it('recusa Genes 32', async () => {
    const result = await attempt(prisma, async (tx) => {
      const { creature, statId } = await createPlayerWithCreature(tx);
      await tx.creatureInstanceStat.create({
        data: {
          creatureUid: creature.uid,
          statId,
          genes: 32,
          trainingPoints: 0,
        },
      });
    });
    expectRejected(result, 'creature_instance_stats_genes_check');
  });

  it('recusa criatura na equipe sem slot', async () => {
    const result = await attempt(prisma, async (tx) => {
      const { player, ids } = await createPlayerWithCreature(tx);
      await tx.creatureInstance.create({
        data: creatureData(
          player.id,
          ids.speciesId,
          ids.temperamentId,
          ids.traitId,
          {
            location: 'party',
            partySlot: null,
          },
        ),
      });
    });
    expectRejected(result, 'creature_instances_location_check');
  });

  it('não deixa apagar uma espécie usada em species_elements (Restrict)', async () => {
    const result = await attempt(prisma, async (tx) => {
      const species = await createSpecies(tx);
      const element = await createElement(tx);
      await tx.speciesElement.create({
        data: { speciesId: species.id, slot: 1, elementId: element.id },
      });
      await tx.species.delete({ where: { id: species.id } });
    });
    expect(result).not.toBe('accepted');
  });

  it('apagar um Domador apaga as criaturas dele (Cascade)', async () => {
    let remaining = -1;
    const result = await attempt(prisma, async (tx) => {
      const { player, creature } = await createPlayerWithCreature(tx);
      await tx.player.delete({ where: { id: player.id } });
      remaining = await tx.creatureInstance.count({
        where: { uid: creature.uid },
      });
    });
    expect(result).toBe('accepted');
    expect(remaining).toBe(0);
  });
});
