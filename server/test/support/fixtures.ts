import { testSlug, Tx } from './db.js';

/** Linhas mínimas e válidas, criadas dentro de uma transação de teste. */

export function createElement(tx: Tx) {
  return tx.element.create({
    data: {
      slug: testSlug('el'),
      name: 'Teste',
      colorHex: '#123456',
      isRare: false,
    },
  });
}

export function createStat(tx: Tx) {
  return tx.stat.create({
    data: {
      slug: testSlug('st'),
      name: 'Teste',
      shortName: 'TST',
      isBattleOnly: false,
    },
  });
}

export async function createSpecies(tx: Tx) {
  const growthRate = await tx.growthRate.create({
    data: { slug: testSlug('gr'), name: 'Teste', xpMultiplier: 1 },
  });
  const rarity = await tx.rarity.create({
    data: {
      slug: testSlug('ra'),
      name: 'Teste',
      sortOrder: 1000 + Math.floor(Math.random() * 1e6),
    },
  });
  return tx.species.create({
    data: {
      slug: testSlug('sp'),
      name: 'Teste',
      description: 'Espécie de teste.',
      growthRateId: growthRate.id,
      rarityId: rarity.id,
      baseXpYield: 50,
      captureRate: 45,
      genderRatio: 0.5,
      heightM: 1,
      weightKg: 10,
      evolvesFromSpeciesId: null,
    },
  });
}

export async function createSkillParents(tx: Tx) {
  const element = await createElement(tx);
  const category = await tx.skillCategory.create({
    data: { slug: testSlug('sc'), name: 'Teste' },
  });
  const target = await tx.skillTarget.create({
    data: { slug: testSlug('tg'), name: 'Teste' },
  });
  return {
    elementId: element.id,
    skillCategoryId: category.id,
    skillTargetId: target.id,
  };
}

export function skillData(
  parents: Awaited<ReturnType<typeof createSkillParents>>,
  accuracy: number,
) {
  return {
    slug: testSlug('sk'),
    name: 'Teste',
    description: 'Técnica de teste.',
    ...parents,
    power: 40,
    accuracy,
    maxPp: 35,
    priority: 0,
    critStage: 0,
    makesContact: true,
    minHits: 1,
    maxHits: 1,
  };
}

/** Domador com uma criatura na equipe (slot 1). */
export async function createPlayerWithCreature(tx: Tx) {
  const species = await createSpecies(tx);
  const up = await createStat(tx);
  const down = await createStat(tx);
  const temperament = await tx.temperament.create({
    data: {
      slug: testSlug('tp'),
      name: 'Teste',
      increasedStatId: up.id,
      decreasedStatId: down.id,
    },
  });
  const trait = await tx.trait.create({
    data: {
      slug: testSlug('tr'),
      name: 'Teste',
      description: 'Traço de teste.',
    },
  });
  const player = await tx.player.create({ data: { name: 'Teste' } });
  const creature = await tx.creatureInstance.create({
    data: creatureData(player.id, species.id, temperament.id, trait.id, {
      location: 'party',
      partySlot: 1,
    }),
  });
  return {
    player,
    creature,
    statId: up.id,
    ids: {
      speciesId: species.id,
      temperamentId: temperament.id,
      traitId: trait.id,
    },
  };
}

export function creatureData(
  playerId: string,
  speciesId: number,
  temperamentId: number,
  traitId: number,
  place: { location: 'party' | 'storage'; partySlot: number | null },
) {
  return {
    playerId,
    speciesId,
    level: 5,
    currentXp: 125,
    currentHp: 20,
    temperamentId,
    traitId,
    gender: 'male' as const,
    isPrismatic: false,
    bond: 70,
    ...place,
    originalPlayerId: playerId,
    caughtAt: new Date(),
  };
}
