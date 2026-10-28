import { PrismaClient } from '../src/generated/prisma/client.js';
import { attempt, createTestPrisma } from './support/db.js';
import {
  createElement,
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

  it('as 29 tabelas e o histórico de migrations ficam no schema ecobeasts', async () => {
    const rows = await prisma.$queryRaw<{ n: number }[]>`
      SELECT count(*)::int AS n FROM information_schema.tables WHERE table_schema = 'ecobeasts'`;
    expect(rows[0].n).toBe(30);
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

  it('recusa Ascensão com horário "dusk"', async () => {
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
