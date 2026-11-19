import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  INVALID_ENEMY,
  NO_CHALLENGER,
  NO_EXPLORATION,
} from '../battle/battle.dto.js';
import { secureRandom } from '../common/secure-random.js';
import { generateMap } from '../domain/exploration/map-generator.js';
import { assignZones } from '../domain/exploration/map-zones.js';
import {
  bornIn,
  type MapSpawn,
  rollSpawns,
} from '../domain/exploration/spawns.js';
import {
  areasBornIn,
  rollAreaSpawns,
  spawnAreas,
} from '../domain/islands/area-spawns.js';
import { minuteOfDay } from '../domain/world-clock/world-clock.js';
import type { HexCoord } from '../domain/exploration/hex.js';
import type { TamerSize } from '../domain/tamers/tamer-config.js';
import {
  type MapTamer,
  rollChallenger,
  rollMapTamers,
} from '../domain/tamers/tamers.js';
import type { Env } from '../config/env.js';
import {
  ISLAND_NOT_FOUND,
  IslandsService,
} from '../islands/islands.service.js';
import { PrismaService } from '../prisma/prisma.service.js';
import {
  DebugClearResponseDto,
  DebugSpawnBodyDto,
  DebugSpawnResponseDto,
  DebugTamerBodyDto,
  DebugTamerResponseDto,
  ExplorationResponseDto,
  MapCreatureDto,
  MapTamerDto,
  toBridgeDto,
  toPropDto,
  toNpcDto,
  toTrailDto,
  toWallDto,
} from './exploration.dto.js';
import { DiscoveriesService } from '../islands/discoveries.service.js';
import { ExplorationStore } from './exploration.store.js';
import {
  loadSpawnSpecies,
  loadZones,
  loadTamerTexts,
  partyAverageLevel,
  speciesBornAt,
} from './spawn-data.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
export const NO_TEAM = 'Escolha seu primeiro Ecobeast antes de viajar.';
const SEED_RANGE = 2 ** 32;

function toMapTamerDto({
  id,
  q,
  r,
  nameId,
  greetingId,
}: MapTamer): MapTamerDto {
  return { id, q, r, name_id: nameId, greeting_id: greetingId };
}

function toMapCreatureDto({ id, speciesId, q, r }: MapSpawn): MapCreatureDto {
  return { id, species_id: speciesId, q, r };
}

@Injectable()
export class ExplorationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: ExplorationStore,
    private readonly config: ConfigService<Env, true>,
    private readonly islands: IslandsService,
    private readonly discoveries: DiscoveriesService,
  ) {}

  async start(
    userId: string,
    islandId?: number,
    debugMinute?: number,
  ): Promise<ExplorationResponseDto> {
    const teamAverage = await partyAverageLevel(this.prisma, userId);
    // Sem equipe, só a ilha casa abre: a introdução acontece nela (liora-intro/01).
    if (teamAverage === null) {
      const player = await this.prisma.player.findUnique({
        where: { id: userId },
        select: { id: true },
      });
      if (!player) throw new ConflictException(NO_PLAYER);
      if (
        islandId === undefined ||
        islandId !== (await this.islands.homeId())
      ) {
        throw new ConflictException(NO_TEAM);
      }
    }
    const minute =
      debugMinute !== undefined &&
      this.config.get('ENABLE_TEST_BATTLE', { infer: true })
        ? debugMinute
        : minuteOfDay(Date.now());
    if (islandId !== undefined) {
      return this.startIsland(userId, islandId, minute);
    }
    if (teamAverage === null) throw new ConflictException(NO_TEAM);

    const generated = generateMap(Math.floor(secureRandom() * SEED_RANGE));
    const [species, texts, born, zones] = await Promise.all([
      loadSpawnSpecies(this.prisma),
      loadTamerTexts(this.prisma),
      speciesBornAt(this.prisma, minute),
      loadZones(this.prisma),
    ]);
    const map = {
      ...generated,
      tiles: assignZones(generated.tiles, generated.seed, zones),
    };
    const spawns = rollSpawns(
      map.tiles,
      bornIn(species, born),
      teamAverage,
      secureRandom,
    );
    const tamers = rollMapTamers(
      map.tiles,
      map.start,
      species,
      teamAverage,
      texts,
      secureRandom,
    );
    this.store.set(userId, {
      spawns: new Map(spawns.map((spawn) => [spawn.id, spawn])),
      tamers: new Map(tamers.map((tamer) => [tamer.id, tamer])),
      position: map.start,
      positionAt: Date.now(),
    });
    return {
      map: {
        ...map,
        creatures: spawns.map(toMapCreatureDto),
        tamers: tamers.map(toMapTamerDto),
        island: null,
        actions: [],
        props: [],
        trails: [],
        walls: [],
        npcs: [],
      },
      discovered: [],
    };
  }

  private async startIsland(
    userId: string,
    islandId: number,
    minute: number,
  ): Promise<ExplorationResponseDto> {
    const island = await this.islands.readPublished(islandId);
    if (!island) throw new NotFoundException(ISLAND_NOT_FOUND);
    const { draft } = island;
    const [typeBlocks, born, discovered] = await Promise.all([
      this.islands.readTypeBlocks(),
      speciesBornAt(this.prisma, minute),
      this.discoveries.listDiscovered(userId, island.id, draft.tiles),
    ]);
    const spawns = rollAreaSpawns(
      areasBornIn(spawnAreas(draft, typeBlocks), born),
      secureRandom,
    );
    this.store.set(userId, {
      spawns: new Map(spawns.map((spawn) => [spawn.id, spawn])),
      tamers: new Map(),
      position: draft.start,
      positionAt: Date.now(),
    });
    return {
      map: {
        // A seed escolhe as decorações e os escorridos no desenho; o editor
        // usa o mesmo id, então a ilha fica igual à dele.
        seed: island.id,
        start: draft.start,
        // A área de cada hexágono fica no servidor.
        tiles: draft.tiles.map(
          ({ q, r, biome, height, variant, ground, bare, zone }) => ({
            q,
            r,
            biome,
            height,
            variant,
            ...(ground === undefined ? {} : { ground }),
            ...(bare === true ? { bare } : {}),
            ...(zone === undefined ? {} : { zone }),
          }),
        ),
        creatures: spawns.map(toMapCreatureDto),
        tamers: [],
        island: { id: island.id, name: island.name },
        actions: draft.actions.map(({ actionTypeId, tiles }) => ({
          action_type_id: actionTypeId,
          tiles,
        })),
        props: draft.props.map(toPropDto),
        trails: (draft.trails ?? []).map(toTrailDto),
        walls: (draft.walls ?? []).map(toWallDto),
        bridges: (draft.bridges ?? []).map(toBridgeDto),
        npcs: (draft.npcs ?? []).map((npc, index) => ({
          id: index + 1,
          ...toNpcDto(npc),
        })),
      },
      discovered,
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

  /**
   * Põe um Domador do tamanho pedido num hexágono da exploração guardada, no
   * lugar do que houver ali (npc-tamers/03, RF-10). A equipe usa as taxas de
   * todos os biomas, como a do Desafiar: o servidor não guarda os hexágonos e
   * não sabe o bioma.
   */
  async debugTamer(
    userId: string,
    body: DebugTamerBodyDto,
  ): Promise<DebugTamerResponseDto> {
    this.requireTestRoutes();
    if (!this.store.get(userId)) throw new NotFoundException(NO_EXPLORATION);
    const [species, texts, teamAverage] = await Promise.all([
      loadSpawnSpecies(this.prisma),
      loadTamerTexts(this.prisma),
      partyAverageLevel(this.prisma, userId),
    ]);
    const rolled = rollChallenger(
      species,
      teamAverage ?? 1,
      texts,
      secureRandom,
      { size: body.size as TamerSize },
    );
    if (!rolled) throw new ConflictException(NO_CHALLENGER);

    // Lido de novo depois dos `await`: uma exploração nova pode ter chegado.
    const exploration = this.store.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    for (const tamer of exploration.tamers.values()) {
      if (tamer.q === body.q && tamer.r === body.r) {
        exploration.tamers.delete(tamer.id);
      }
    }
    const tamer: MapTamer = {
      ...rolled,
      id: Math.max(0, ...exploration.tamers.keys()) + 1,
      q: body.q,
      r: body.r,
      debug: true,
    };
    exploration.tamers.set(tamer.id, tamer);
    return { tamer: toMapTamerDto(tamer) };
  }

  /**
   * O teleporte de depuração (minimap/03): a posição vira a conferida agora, e o
   * Procurar vale nela na hora. O mapa não mora aqui; quem confere se dá para
   * pisar é o jogo.
   */
  setPosition(userId: string, position: HexCoord): HexCoord {
    const exploration = this.store.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    this.store.set(userId, {
      ...exploration,
      position: { q: position.q, r: position.r },
      positionAt: Date.now(),
    });
    return { q: position.q, r: position.r };
  }

  debugClear(userId: string): DebugClearResponseDto {
    this.requireTestRoutes();
    const exploration = this.store.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);
    const removed = [...exploration.spawns.values()]
      .filter((spawn) => spawn.debug)
      .map((spawn) => spawn.id);
    for (const id of removed) exploration.spawns.delete(id);
    const removedTamers = [...exploration.tamers.values()]
      .filter((tamer) => tamer.debug)
      .map((tamer) => tamer.id);
    for (const id of removedTamers) exploration.tamers.delete(id);
    return { removed_ids: removed, removed_tamer_ids: removedTamers };
  }

  private requireTestRoutes(): void {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
  }

  private async teamAverageLevel(userId: string): Promise<number> {
    const average = await partyAverageLevel(this.prisma, userId);
    if (average === null) return 1;
    return Math.min(100, Math.max(1, Math.round(average)));
  }
}
