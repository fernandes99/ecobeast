import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { loadBattleCatalog } from '../battle/battle-catalog.js';
import {
  BattleRecordsService,
  type BattleFinish,
  type Enemy,
  type EnemyChoice,
  type Team,
} from '../battle/battle-records.service.js';
import { NO_CHALLENGER } from '../battle/battle.dto.js';
import { NO_BATTLE } from '../battle/battle.dto.js';
import {
  BattleStore,
  type BattleTamer,
  type WildCreature,
} from '../battle/battle.store.js';
import { CodexService } from '../codex/codex.service.js';
import { secureRandom } from '../common/secure-random.js';
import { Env } from '../config/env.js';
import type { BattleEvent, Opponent } from '../domain/battle/types.js';
import { enemySpeciesEntered } from '../domain/codex/codex.js';
import {
  applyBoardVez,
  startBoardBattle,
} from '../domain/board/board-engine.js';
import type { BoardInput, BoardState } from '../domain/board/types.js';
import type { HexCoord } from '../domain/exploration/hex.js';
import { rollChallenger, type TamerCreature } from '../domain/tamers/tamers.js';
import { PARTY_SIZE } from '../domain/team/party.js';
import {
  loadSpawnSpecies,
  loadTamerTexts,
  partyAverageLevel,
} from '../exploration/spawn-data.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { BoardBattleResponseDto } from './board-battle.dto.js';
import { toBoardBattleDto } from './board-battle.mapper.js';

const NOT_FINISHED: BattleFinish = {
  capturedTo: null,
  progression: [],
  registeredSpeciesIds: [],
};

function toResponse(
  state: BoardState,
  events: BattleEvent[],
  tamer: BattleTamer | null,
  {
    capturedTo,
    progression,
    registeredSpeciesIds,
  }: BattleFinish = NOT_FINISHED,
): BoardBattleResponseDto {
  return {
    battle: toBoardBattleDto(state, tamer),
    events,
    captured_to: capturedTo,
    spawn_id: null,
    tamer_id: null,
    progression,
    registered_species_ids: registeredSpeciesIds,
  };
}

interface BeginOptions {
  godMode?: boolean;
  /** Vagas do inimigo; as do jogador são estas, ou menos se faltar quem lute. */
  slots?: number;
  opponent?: Opponent;
  tamer?: BattleTamer | null;
}

/**
 * A luta no tabuleiro do jogador (.specs/board-battle/03-board-api.md), contra
 * selvagem ou contra Domador NPC (.specs/npc-tamers/03-tamer-api.md). Fica
 * na memória, no mesmo `BattleStore` da luta de hoje: começar uma descarta a
 * outra. O banco só muda no fim, como na luta de hoje.
 */
@Injectable()
export class BoardBattleService {
  private readonly logger = new Logger(BoardBattleService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly store: BattleStore,
    private readonly records: BattleRecordsService,
    private readonly codex: CodexService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /** A luta de teste: a equipe inimiga e as vagas vêm do corpo. */
  async start(
    userId: string,
    choices: EnemyChoice[],
    slots = 1,
  ): Promise<BoardBattleResponseDto> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    const team = await this.records.loadTeam(userId);
    const enemies = await this.records.createEnemies(choices);
    return this.begin(userId, team, enemies, { slots });
  }

  /** O encontro de Explorar zona, como o da luta de hoje, com 1 vaga. */
  async startWild(
    userId: string,
    position: HexCoord,
    god = false,
  ): Promise<BoardBattleResponseDto> {
    const team = await this.records.loadTeam(userId);
    const spawn = this.records.takeSpawn(userId, position);
    const enemy = await this.records.createEnemy(spawn.speciesId, spawn.level);
    return {
      ...(await this.begin(userId, team, [enemy], {
        godMode: this.godMode(god),
      })),
      spawn_id: spawn.id,
    };
  }

  /** A luta contra o Domador NPC do hexágono do jogador; ele sai do mapa. */
  async startTamer(
    userId: string,
    position: HexCoord,
    god = false,
  ): Promise<BoardBattleResponseDto> {
    const team = await this.records.loadTeam(userId);
    const tamer = this.records.takeTamer(userId, position);
    const enemies = await this.tamerTeam(tamer.team);
    return {
      ...(await this.begin(userId, team, enemies, {
        godMode: this.godMode(god),
        slots: tamer.size,
        opponent: 'tamer',
        tamer: { nameId: tamer.nameId, source: 'map' },
      })),
      tamer_id: tamer.id,
    };
  }

  /** O Desafiar do Hub: um Domador sorteado na hora, sem mexer na exploração. */
  async startChallenge(userId: string): Promise<BoardBattleResponseDto> {
    const team = await this.records.loadTeam(userId);
    const [species, texts, teamAverage] = await Promise.all([
      loadSpawnSpecies(this.prisma),
      loadTamerTexts(this.prisma),
      partyAverageLevel(this.prisma, userId),
    ]);
    const tamer = rollChallenger(
      species,
      teamAverage ?? 1,
      texts,
      secureRandom,
    );
    if (!tamer) throw new ConflictException(NO_CHALLENGER);
    const enemies = await this.tamerTeam(tamer.team);
    return this.begin(userId, team, enemies, {
      slots: tamer.size,
      opponent: 'tamer',
      tamer: { nameId: tamer.nameId, source: 'challenge' },
    });
  }

  /**
   * Da leitura à escrita no `store` não há `await`: dois pedidos ao mesmo
   * tempo não jogam a mesma vez, nem gravam o fim duas vezes.
   */
  async act(
    userId: string,
    input: BoardInput,
  ): Promise<BoardBattleResponseDto> {
    const battle = this.store.get(userId);
    if (!battle) {
      throw new NotFoundException(NO_BATTLE);
    }
    const tamer = battle.tamer ?? null;
    const outcome = applyBoardVez(
      battle.state as BoardState,
      input,
      battle.catalog,
      secureRandom,
    );
    if ('error' in outcome) throw new BadRequestException(outcome.error);

    if (outcome.state.phase !== 'ended') {
      this.store.set(userId, { ...battle, state: outcome.state });
      await this.recordSeen(userId, outcome.events);
      return toResponse(outcome.state, outcome.events, tamer);
    }
    this.store.delete(userId);
    await this.recordSeen(userId, outcome.events);
    const finish = await this.finish(
      userId,
      outcome.state,
      battle.wilds,
      tamer,
    );
    return toResponse(outcome.state, outcome.events, tamer, finish);
  }

  /**
   * O Bestiário (.specs/codex/01-codex-records.md, RF-04): quem do lado inimigo
   * entrou em campo nesta resposta fica visto. Vem depois de a luta ser
   * guardada, e uma falha aqui não atrapalha a luta.
   */
  private async recordSeen(
    userId: string,
    events: BattleEvent[],
  ): Promise<void> {
    try {
      await this.codex.recordSeen(userId, enemySpeciesEntered(events));
    } catch (error) {
      this.logger.error('Não deu para gravar o visto no Bestiário.', error);
    }
  }

  private godMode(requested: boolean): boolean {
    return requested && this.config.get('ENABLE_TEST_BATTLE', { infer: true });
  }

  private tamerTeam(team: TamerCreature[]): Promise<Enemy[]> {
    return this.records.createEnemies(
      team.map(({ speciesId, level }) => ({ speciesId, level })),
    );
  }

  /** Grava o fim. A derrota para um Domador do mapa encerra a exploração. */
  private async finish(
    userId: string,
    state: BoardState,
    wilds: WildCreature[],
    tamer: BattleTamer | null,
  ): Promise<BattleFinish> {
    const finish = await this.records.finish(userId, state, wilds);
    if (state.result === 'defeat' && tamer?.source === 'map') {
      this.records.endExploration(userId);
    }
    return finish;
  }

  private async begin(
    userId: string,
    team: Team,
    enemies: Enemy[],
    {
      godMode = false,
      slots = 1,
      opponent = 'wild',
      tamer = null,
    }: BeginOptions = {},
  ): Promise<BoardBattleResponseDto> {
    const catalog = await loadBattleCatalog(this.prisma);
    // Quem tem menos Ecobeasts de pé do que as vagas luta com os que tem.
    const standing = team.creatures.filter(
      (creature) => creature.currentHp > 0,
    ).length;
    const { state, events } = startBoardBattle(
      team.creatures,
      enemies.map(({ combatant }) => combatant),
      catalog,
      secureRandom,
      team.bag,
      {
        godMode,
        coins: team.coins,
        slots: { player: Math.min(slots, standing), enemy: slots },
        partyFree: PARTY_SIZE - team.creatures.length,
        opponent,
      },
    );
    const wilds = enemies.map(({ creature, statIds }) => ({
      creature,
      statIds,
    }));
    // Os inimigos podem jogar antes e acabar com a luta já na abertura: o fim
    // é gravado aqui, e não fica luta nenhuma, nem a anterior.
    if (state.phase === 'ended') {
      this.store.delete(userId);
      await this.recordSeen(userId, events);
      const finish = await this.finish(userId, state, wilds, tamer);
      return toResponse(state, events, tamer, finish);
    }
    // Substitui a luta anterior, de qualquer tipo, sem gravar nada dela.
    this.store.set(userId, { state, catalog, wilds, tamer });
    await this.recordSeen(userId, events);
    return toResponse(state, events, tamer);
  }
}
