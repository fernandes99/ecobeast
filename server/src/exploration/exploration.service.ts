import { ConflictException, Injectable } from '@nestjs/common';
import { secureRandom } from '../common/secure-random.js';
import { generateMap } from '../domain/exploration/map-generator.js';
import { DEFAULT_SPAWN_CONFIG } from '../domain/exploration/spawn-config.js';
import {
  type EncounterBiome,
  naturalLevel,
  rollSpawns,
  type SpawnSpecies,
} from '../domain/exploration/spawns.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ExplorationResponseDto } from './exploration.dto.js';
import { ExplorationStore } from './exploration.store.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
const SEED_RANGE = 2 ** 32;

/** Gera um mapa por exploração, com os Ecobeasts dele (biome-encounters/03). */
@Injectable()
export class ExplorationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: ExplorationStore,
  ) {}

  async start(userId: string): Promise<ExplorationResponseDto> {
    const team = await this.prisma.creatureInstance.findMany({
      where: { playerId: userId, location: 'party' },
      select: { level: true },
    });
    if (team.length === 0) throw new ConflictException(NO_PLAYER);

    const map = generateMap(Math.floor(secureRandom() * SEED_RANGE));
    const teamAverage =
      team.reduce((sum, { level }) => sum + level, 0) / team.length;
    const spawns = rollSpawns(
      map.tiles,
      await this.loadSpawnSpecies(),
      teamAverage,
      secureRandom,
    );
    this.store.set(userId, {
      spawns: new Map(spawns.map((spawn) => [spawn.id, spawn])),
      position: map.start,
      positionAt: Date.now(),
    });
    return {
      map: {
        ...map,
        creatures: spawns.map(({ id, speciesId, q, r }) => ({
          id,
          species_id: speciesId,
          q,
          r,
        })),
      },
    };
  }

  private async loadSpawnSpecies(): Promise<SpawnSpecies[]> {
    const [rows, evolutions] = await Promise.all([
      this.prisma.speciesBiome.findMany({ include: { biome: true } }),
      this.prisma.evolution.findMany({
        select: { speciesId: true, evolvedSpeciesId: true, minLevel: true },
      }),
    ]);
    const bySpecies = new Map<number, SpawnSpecies>();
    for (const { speciesId, biome, rate } of rows) {
      const species = bySpecies.get(speciesId) ?? {
        speciesId,
        naturalLevel: naturalLevel(speciesId, evolutions, DEFAULT_SPAWN_CONFIG),
        rates: {},
      };
      species.rates[biome.slug as EncounterBiome] = rate;
      bySpecies.set(speciesId, species);
    }
    return [...bySpecies.values()];
  }
}
