import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { INVALID_ENEMY, NO_EXPLORATION } from '../battle/battle.dto.js';
import { secureRandom } from '../common/secure-random.js';
import { generateMap } from '../domain/exploration/map-generator.js';
import { DEFAULT_SPAWN_CONFIG } from '../domain/exploration/spawn-config.js';
import {
  type EncounterBiome,
  naturalLevel,
  rollSpawns,
  type SpawnSpecies,
} from '../domain/exploration/spawns.js';
import type { Env } from '../config/env.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  DebugClearResponseDto,
  DebugSpawnBodyDto,
  DebugSpawnResponseDto,
  ExplorationResponseDto,
} from './exploration.dto.js';
import { ExplorationStore } from './exploration.store.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
const SEED_RANGE = 2 ** 32;

/** Gera um mapa por exploração, com os Ecobeasts dele (biome-encounters/03). */
@Injectable()
export class ExplorationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: ExplorationStore,
    private readonly config: ConfigService<Env, true>,
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

  /**
   * Põe um Ecobeast à escolha na exploração guardada, para Procurar enfrentá-lo
   * (biome-encounters/05). Não confere o hexágono: o servidor não guarda os
   * hexágonos, e Procurar já confere a posição do Domador.
   */
  async debugSpawn(
    userId: string,
    body: DebugSpawnBodyDto,
  ): Promise<DebugSpawnResponseDto> {
    this.requireTestRoutes();
    if (!this.store.get(userId)) throw new NotFoundException(NO_EXPLORATION);
    const species = await this.prisma.species.findUnique({
      where: { id: body.species_id },
      select: { id: true },
    });
    if (!species) throw new BadRequestException(INVALID_ENEMY);
    const level = body.level ?? (await this.teamAverageLevel(userId));

    // Lido de novo depois dos `await`: uma exploração nova pode ter chegado.
    const exploration = this.store.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    const id = Math.max(0, ...exploration.spawns.keys()) + 1;
    exploration.spawns.set(id, {
      id,
      speciesId: species.id,
      level,
      q: body.q,
      r: body.r,
      debug: true,
    });
    return {
      creature: { id, species_id: species.id, q: body.q, r: body.r },
    };
  }

  /** Tira da exploração todos os Ecobeasts do spawn de depuração, e só eles. */
  debugClear(userId: string): DebugClearResponseDto {
    this.requireTestRoutes();
    const exploration = this.store.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    const removed = [...exploration.spawns.values()]
      .filter((spawn) => spawn.debug)
      .map((spawn) => spawn.id);
    for (const id of removed) exploration.spawns.delete(id);
    return { removed_ids: removed };
  }

  private requireTestRoutes(): void {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
  }

  /** A média de nível da equipe principal, arredondada, de 1 a 100. */
  private async teamAverageLevel(userId: string): Promise<number> {
    const team = await this.prisma.creatureInstance.findMany({
      where: { playerId: userId, location: 'party' },
      select: { level: true },
    });
    if (team.length === 0) return 1;
    const average =
      team.reduce((sum, { level }) => sum + level, 0) / team.length;
    return Math.min(100, Math.max(1, Math.round(average)));
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
