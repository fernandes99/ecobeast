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

  it('as 85 tabelas e o histórico de migrations ficam no schema ecobeasts', async () => {
    const rows = await prisma.$queryRaw<{ n: number }[]>`
      SELECT count(*)::int AS n FROM information_schema.tables WHERE table_schema = 'ecobeasts'`;
    expect(rows[0].n).toBe(85);
  });

  it('recusa uma marca que muda um atributo em 0 estágio (puffcoo-line)', async () => {
    const result = await attempt(prisma, async (tx) => {
      const effect = await tx.groundEffect.findFirstOrThrow();
      const stat = await tx.stat.findFirstOrThrow({ where: { slug: 'atk' } });
      await tx.groundEffectStat.create({
        data: { groundEffectId: effect.id, statId: stat.id, stages: 0 },
      });
    });
    expectRejected(result, 'ground_effect_stats_stages_check');
  });

  it('recusa uma porta fora da sala (interiors)', async () => {
    const result = await attempt(prisma, async (tx) => {
      await tx.$executeRaw`
        INSERT INTO "ecobeasts"."interiors" (name, width, height, door_x, door_y, updated_at)
        VALUES ('Teste', 8, 6, 8, 5, now())`;
    });
    expectRejected(result, 'interiors_door_check');
  });

  it('recusa um contador com recorte desconhecido (player-stats)', async () => {
    const result = await attempt(prisma, async (tx) => {
      await tx.counter.create({
        data: { slug: 'zz_teste', name: 'Teste', subject: 'species' },
      });
    });
    expectRejected(result, 'counters_subject_check');
  });

  it('recusa um contador do Domador negativo (player-stats)', async () => {
    const result = await attempt(prisma, async (tx) => {
      const player = await tx.player.create({ data: { name: 'Teste' } });
      await tx.playerCounter.create({
        data: { playerId: player.id, counterId: 1, value: -1 },
      });
    });
    expectRejected(result, 'player_counters_value_check');
  });

  it('recusa uma parte do dia que começa depois do minuto 1439 (day-night)', async () => {
    const result = await attempt(prisma, async (tx) => {
      await tx.dayPhase.create({
        data: { slug: 'zz_teste', name: 'Teste', startMinute: 1440 },
      });
    });
    expectRejected(result, 'day_phases_start_minute_check');
  });

  it('recusa uma luz de peça com cor fora do formato (day-night)', async () => {
    const result = await attempt(prisma, async (tx) => {
      const type = await tx.propType.findFirstOrThrow();
      await tx.propTypeLight.create({
        data: {
          propTypeId: type.id,
          position: 99,
          x: 0,
          y: -10,
          radius: 8,
          color: '#FFCC00',
        },
      });
    });
    expectRejected(result, 'prop_type_lights_color_check');
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

  it('recusa uma parte do dia de nascer que não existe (day-phase-spawns)', async () => {
    const result = await attempt(prisma, async (tx) => {
      await tx.speciesDayPhase.create({
        data: { speciesId: 1, dayPhaseId: 999_999 },
      });
    });
    expectRejected(result, 'species_day_phases_day_phase_id_fkey');
  });

  it.each([-1, 101])(
    'recusa zona com share %i, fora de 0 a 100 (biome-zones/01)',
    async (share) => {
      const result = await attempt(prisma, async (tx) => {
        await tx.biomeZone.create({
          data: {
            slug: 'zz_teste',
            biomeId: 1,
            name: 'Teste',
            share,
            sortOrder: 9,
          },
        });
      });
      expectRejected(result, 'biome_zones_share_check');
    },
  );

  it.each([-1, 1001])(
    'recusa rate_percent %i, fora de 0 a 1000 (biome-zones/01)',
    async (ratePercent) => {
      const result = await attempt(prisma, async (tx) => {
        await tx.speciesBiomeZone.create({
          data: { speciesId: 1, biomeZoneId: 12, ratePercent },
        });
      });
      expectRejected(result, 'species_biome_zones_rate_percent_check');
    },
  );

  it.each(['', 'x'.repeat(21)])(
    'recusa nome de Domador "%s" fora de 1 a 20 caracteres',
    async (name) => {
      const result = await attempt(prisma, (tx) =>
        tx.npcTamerName.create({ data: { name } }),
      );
      expectRejected(result, 'npc_tamer_names_name_check');
    },
  );

  it.each(['', 'x'.repeat(121)])(
    'recusa fala de Domador fora de 1 a 120 caracteres (%#)',
    async (text) => {
      const result = await attempt(prisma, (tx) =>
        tx.npcTamerGreeting.create({ data: { text } }),
      );
      expectRejected(result, 'npc_tamer_greetings_text_check');
    },
  );

  it('aceita nome de 20 e fala de 120 caracteres', async () => {
    const result = await attempt(prisma, async (tx) => {
      await tx.npcTamerName.create({ data: { name: 'x'.repeat(20) } });
      await tx.npcTamerGreeting.create({ data: { text: 'x'.repeat(120) } });
    });
    expect(result).toBe('accepted');
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

  it('recusa Bestiário capturado antes de visto', async () => {
    const result = await attempt(prisma, async (tx) => {
      const { player, ids } = await createPlayerWithCreature(tx);
      await tx.codexEntry.create({
        data: {
          playerId: player.id,
          speciesId: ids.speciesId,
          seenAt: new Date('2026-11-09T12:00:00Z'),
          caughtAt: new Date('2026-11-09T11:00:00Z'),
        },
      });
    });
    expectRejected(result, 'codex_entries_caught_at_check');
  });

  it('aceita Bestiário só visto, e capturado na mesma hora em que foi visto', async () => {
    const result = await attempt(prisma, async (tx) => {
      const { player, ids } = await createPlayerWithCreature(tx);
      const other = await createSpecies(tx);
      const at = new Date('2026-11-09T12:00:00Z');
      await tx.codexEntry.createMany({
        data: [
          { playerId: player.id, speciesId: ids.speciesId, seenAt: at },
          {
            playerId: player.id,
            speciesId: other.id,
            seenAt: at,
            caughtAt: at,
          },
        ],
      });
    });
    expect(result).toBe('accepted');
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

  describe('ilhas do editor (map-editor/01)', () => {
    async function draftMap(tx: Tx) {
      const island = await tx.island.create({ data: {} });
      return tx.islandMap.create({
        data: {
          islandId: island.id,
          kind: 'draft',
          name: 'Ilha',
          startQ: 0,
          startR: 0,
          contentHash: 'x',
          updatedAt: new Date(),
        },
      });
    }

    it('recusa versão de ilha que não é draft nem published', async () => {
      const result = await attempt(prisma, async (tx) => {
        const map = await draftMap(tx);
        await tx.islandMap.update({
          where: { id: map.id },
          data: { kind: 'old' },
        });
      });
      expectRejected(result, 'island_maps_kind_check');
    });

    it('recusa variante 7 e altura 11, e aceita variante 6 na altura 10', async () => {
      const biome = await prisma.biome.findFirstOrThrow();
      const tile = (height: number, variant: number) =>
        attempt(prisma, async (tx) => {
          const map = await draftMap(tx);
          await tx.islandTile.create({
            data: {
              islandMapId: map.id,
              q: 0,
              r: 0,
              biomeId: biome.id,
              height,
              variant,
            },
          });
        });
      expectRejected(await tile(1, 7), 'island_tiles_variant_check');
      expectRejected(await tile(11, 1), 'island_tiles_height_check');
      expectRejected(await tile(-1, 1), 'island_tiles_height_check');
      expect(await tile(10, 6)).toBe('accepted');
    });

    it('recusa espécie de área com mínimo acima do máximo', async () => {
      const result = await attempt(prisma, async (tx) => {
        const map = await draftMap(tx);
        const species = await createSpecies(tx);
        await tx.islandArea.create({
          data: {
            islandMapId: map.id,
            name: 'Área',
            colorHex: '#123456',
            species: {
              create: {
                speciesId: species.id,
                weight: 1,
                minLevel: 9,
                maxLevel: 3,
              },
            },
          },
        });
      });
      expectRejected(result, 'island_area_species_level_check');
    });

    it('recusa área com a quantidade de Ecobeasts fora de 1 a 200', async () => {
      for (const spawnCount of [0, 201]) {
        const result = await attempt(prisma, async (tx) => {
          const map = await draftMap(tx);
          await tx.islandArea.create({
            data: {
              islandMapId: map.id,
              name: 'Área',
              colorHex: '#123456',
              spawnCount,
            },
          });
        });
        expectRejected(result, 'island_areas_spawn_count_check');
      }
    });

    it('não deixa duas ações no mesmo hexágono', async () => {
      const result = await attempt(prisma, async (tx) => {
        const map = await draftMap(tx);
        const type = await tx.actionType.findFirstOrThrow();
        for (let i = 0; i < 2; i++) {
          await tx.islandAction.create({
            data: {
              islandMapId: map.id,
              actionTypeId: type.id,
              tiles: { create: { islandMapId: map.id, q: 1, r: 1 } },
            },
          });
        }
      });
      expectRejected(result, 'island_action_tiles_island_map_id_q_r_key');
    });

    it('recusa uma linha de bloqueio de tipo com número ímpar de pontos (free-objects)', async () => {
      const result = await attempt(prisma, async (tx) => {
        const type = await tx.propType.findFirstOrThrow();
        await tx.propTypeBlock.create({
          data: {
            propTypeId: type.id,
            position: 99,
            closed: false,
            points: [0, 0, 1],
          },
        });
      });
      expectRejected(result, 'prop_type_blocks_points_check');
    });

    it('recusa uma linha de bloqueio de peça com um ponto só (free-objects)', async () => {
      const result = await attempt(prisma, async (tx) => {
        const map = await draftMap(tx);
        const type = await tx.propType.findFirstOrThrow();
        const prop = await tx.islandProp.create({
          data: {
            islandMapId: map.id,
            propTypeId: type.id,
            q: 0,
            r: 0,
            dx: 0,
            dy: 0,
            variant: 1,
            mirrored: false,
            customBlock: true,
          },
        });
        await tx.islandPropBlock.create({
          data: {
            islandPropId: prop.id,
            position: 0,
            closed: false,
            points: [0, 0],
          },
        });
      });
      expectRejected(result, 'island_prop_blocks_points_check');
    });

    it('recusa variante 0 de peça solta (free-props/01)', async () => {
      const result = await attempt(prisma, async (tx) => {
        const map = await draftMap(tx);
        const type = await tx.propType.findFirstOrThrow();
        await tx.islandProp.create({
          data: {
            islandMapId: map.id,
            propTypeId: type.id,
            q: 0,
            r: 0,
            dx: 0,
            dy: 0,
            variant: 0,
            mirrored: false,
          },
        });
      });
      expectRejected(result, 'island_props_variant_check');
    });

    it('recusa NPC com slug ou sprite fora do formato (island-npcs/01)', async () => {
      for (const [slug, sprite, check] of [
        ['Guarda', 'ruvo', 'npcs_slug_check'],
        ['guarda_teste', 'ruvo-2', 'npcs_sprite_check'],
      ]) {
        const result = await attempt(prisma, (tx) =>
          tx.npc.create({
            data: { slug, name: 'Guarda', description: 'Teste.', sprite },
          }),
        );
        expectRejected(result, check);
      }
    });

    it('recusa diálogo de NPC com mais de 2.000 caracteres (island-npcs/01)', async () => {
      const result = await attempt(prisma, async (tx) => {
        const map = await draftMap(tx);
        const npc = await tx.npc.findFirstOrThrow();
        await tx.islandNpc.create({
          data: {
            islandMapId: map.id,
            npcId: npc.id,
            q: 0,
            r: 0,
            still: true,
            dialogue: 'a'.repeat(2_001),
          },
        });
      });
      expectRejected(result, 'island_npcs_dialogue_check');
    });

    it('recusa fala padrão de NPC com mais de 2.000 caracteres (village-crowd/01)', async () => {
      const result = await attempt(prisma, (tx) =>
        tx.npc.create({
          data: {
            slug: 'zz_test_default_dialogue',
            name: 'Teste',
            description: 'Teste.',
            sprite: 'ruvo',
            defaultDialogue: 'a'.repeat(2_001),
          },
        }),
      );
      expectRejected(result, 'npcs_default_dialogue_check');
    });

    it('recusa traço com largura 7 ou com um ponto só (free-trails/03)', async () => {
      for (const [width, points, check] of [
        [7, [0, 0, 10, 0], 'island_trails_width_check'],
        [22, [0, 0], 'island_trails_points_check'],
        [22, [0, 0, 10], 'island_trails_points_check'],
      ] as const) {
        const result = await attempt(prisma, async (tx) => {
          const map = await draftMap(tx);
          await tx.islandTrail.create({
            data: {
              islandMapId: map.id,
              groundTypeId: 1,
              position: 0,
              width,
              points: [...points],
            },
          });
        });
        expectRejected(result, check);
      }
    });

    it('recusa parede com um ponto só ou com 3 números (free-fences/01)', async () => {
      for (const points of [
        [0, 0],
        [0, 0, 10],
      ]) {
        const result = await attempt(prisma, async (tx) => {
          const map = await draftMap(tx);
          await tx.islandWall.create({
            data: { islandMapId: map.id, wallTypeId: 1, position: 0, points },
          });
        });
        expectRejected(result, 'island_walls_points_check');
      }
    });

    it('recusa tipo de parede com slug fora do formato (free-fences/01)', async () => {
      const result = await attempt(prisma, (tx) =>
        tx.wallType.create({
          data: { slug: 'Muro Alto', name: 'Teste', visible: true },
        }),
      );
      expectRejected(result, 'wall_types_slug_check');
    });

    it('recusa ponte sem exatamente 4 números (bridges/01)', async () => {
      for (const points of [
        [0, 0],
        [0, 0, 10, 0, 20, 0],
      ]) {
        const result = await attempt(prisma, async (tx) => {
          const map = await draftMap(tx);
          await tx.islandBridge.create({
            data: { islandMapId: map.id, bridgeTypeId: 5, position: 0, points },
          });
        });
        expectRejected(result, 'island_bridges_points_check');
      }
    });

    it('recusa ponte com largura fora de 16 a 64 (bridges/01)', async () => {
      for (const width of [15, 65]) {
        const result = await attempt(prisma, async (tx) => {
          const map = await draftMap(tx);
          await tx.islandBridge.create({
            data: {
              islandMapId: map.id,
              bridgeTypeId: 5,
              position: 0,
              points: [0, 0, 64, 0],
              width,
            },
          });
        });
        expectRejected(result, 'island_bridges_width_check');
      }
    });

    it('recusa estilo de ponte com slug fora do formato (bridges/01)', async () => {
      const result = await attempt(prisma, (tx) =>
        tx.bridgeType.create({ data: { slug: 'Ponte Alta', name: 'Teste' } }),
      );
      expectRejected(result, 'bridge_types_slug_check');
    });

    it('recusa tipo de chão e de ação fora da lista', async () => {
      const ground = await attempt(prisma, (tx) =>
        tx.groundType.create({
          data: {
            slug: 'teste_chao',
            name: 'Teste',
            kind: 'wall',
            hardness: 1,
          },
        }),
      );
      expectRejected(ground, 'ground_types_kind_check');
      const action = await attempt(prisma, (tx) =>
        tx.actionType.create({
          data: {
            slug: 'teste_acao',
            name: 'Teste',
            colorHex: '#123456',
            kind: 'teleport',
          },
        }),
      );
      expectRejected(action, 'action_types_kind_check');
    });

    it('recusa dureza de chão fora de 1 a 3 (free-trails/01)', async () => {
      const ground = await attempt(prisma, (tx) =>
        tx.groundType.create({
          data: {
            slug: 'teste_chao',
            name: 'Teste',
            kind: 'trail',
            hardness: 4,
          },
        }),
      );
      expectRejected(ground, 'ground_types_hardness_check');
    });

    it('tem os 28 tipos de chão, cada um com a dureza (free-trails/01 e ground-variety/01 e 02)', async () => {
      const grounds = await prisma.groundType.findMany({
        orderBy: { id: 'asc' },
      });
      expect(grounds.map(({ slug }) => slug)).toEqual([
        'dirt_trail',
        'stone_trail',
        'cobble_floor',
        'dirt_floor',
        'gravel_trail',
        'stepping_stones',
        'sand_trail',
        'worn_trail',
        'wood_planks',
        'brick_floor',
        'flagstone_floor',
        'marble_floor',
        'mossy_trail',
        'basalt_floor',
        'shell_trail',
        'tilled_soil',
        'straw_floor',
        'mud_trail',
        'leaf_trail',
        'snow_trail',
        'blue_cobble_trail',
        'cracked_earth_trail',
        'sandstone_trail',
        'slate_trail',
        'pale_cobble_trail',
        'river_stones',
        'loose_slabs',
        'pebble_scatter',
      ]);
      for (const { hardness } of grounds) {
        expect(hardness).toBeGreaterThanOrEqual(1);
        expect(hardness).toBeLessThanOrEqual(3);
      }
    });
  });

  describe('a aparência do Domador (tamer-appearance/01)', () => {
    it('recusa lugar com tipo de paleta fora da lista e camada menor que 1', async () => {
      const kind = await attempt(prisma, (tx) =>
        tx.appearanceSlot.create({
          data: {
            slug: 'teste_lugar',
            name: 'Teste',
            layer: 90,
            paletteKind: 'eyes',
            required: false,
          },
        }),
      );
      expectRejected(kind, 'appearance_slots_palette_kind_check');
      const layer = await attempt(prisma, (tx) =>
        tx.appearanceSlot.create({
          data: {
            slug: 'teste_lugar',
            name: 'Teste',
            layer: 0,
            required: false,
          },
        }),
      );
      expectRejected(layer, 'appearance_slots_layer_check');
    });

    it('recusa peça com hair_cut fora da lista', async () => {
      const result = await attempt(prisma, (tx) =>
        tx.appearancePart.create({
          data: {
            slug: 'teste_peca',
            name: 'Teste',
            appearanceSlotId: 6,
            hairCut: 'half',
          },
        }),
      );
      expectRejected(result, 'appearance_parts_hair_cut_check');
    });

    it('recusa paleta com tipo fora da lista ou cor fora do formato', async () => {
      const colors = {
        color1Hex: '#ffffff',
        color2Hex: '#cccccc',
        color3Hex: '#999999',
        color4Hex: '#666666',
      };
      const kind = await attempt(prisma, (tx) =>
        tx.palette.create({
          data: {
            slug: 'teste_paleta',
            name: 'Teste',
            kind: 'eyes',
            ...colors,
          },
        }),
      );
      expectRejected(kind, 'palettes_kind_check');
      const color = await attempt(prisma, (tx) =>
        tx.palette.create({
          data: {
            slug: 'teste_paleta',
            name: 'Teste',
            kind: 'cloth',
            ...colors,
            color4Hex: '#FFF',
          },
        }),
      );
      expectRejected(color, 'palettes_colors_check');
    });
  });
});
