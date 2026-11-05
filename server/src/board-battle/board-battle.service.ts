import {
  BadRequestException,
  Injectable,
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
import { NO_BATTLE } from '../battle/battle.service.js';
import { BattleStore } from '../battle/battle.store.js';
import { secureRandom } from '../common/secure-random.js';
import { Env } from '../config/env.js';
import type { BattleEvent } from '../domain/battle/types.js';
import {
  applyBoardVez,
  startBoardBattle,
} from '../domain/board/board-engine.js';
import type { BoardInput, BoardState } from '../domain/board/types.js';
import type { HexCoord } from '../domain/exploration/hex.js';
import { PARTY_SIZE } from '../domain/team/party.js';
import { PrismaService } from '../prisma/prisma.service.js';
import type { BoardBattleResponseDto } from './board-battle.dto.js';
import { toBoardBattleDto } from './board-battle.mapper.js';

const NOT_FINISHED: BattleFinish = { capturedTo: null, progression: [] };

function toResponse(
  state: BoardState,
  events: BattleEvent[],
  { capturedTo, progression }: BattleFinish = NOT_FINISHED,
): BoardBattleResponseDto {
  return {
    battle: toBoardBattleDto(state),
    events,
    captured_to: capturedTo,
    spawn_id: null,
    progression,
  };
}

/**
 * A luta no tabuleiro do jogador (.specs/board-battle/03-board-api.md). Fica
 * na memória, no mesmo `BattleStore` da luta de hoje: começar uma descarta a
 * outra. O banco só muda no fim, como na luta de hoje.
 */
@Injectable()
export class BoardBattleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: BattleStore,
    private readonly records: BattleRecordsService,
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
    return this.begin(userId, team, enemies, false, slots);
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
    const godMode =
      god && this.config.get('ENABLE_TEST_BATTLE', { infer: true });
    return {
      ...(await this.begin(userId, team, [enemy], godMode)),
      spawn_id: spawn.id,
    };
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
    if (!battle || battle.kind !== 'board') {
      throw new NotFoundException(NO_BATTLE);
    }
    const outcome = applyBoardVez(
      battle.state as BoardState,
      input,
      battle.catalog,
      secureRandom,
    );
    if ('error' in outcome) throw new BadRequestException(outcome.error);

    if (outcome.state.phase !== 'ended') {
      this.store.set(userId, { ...battle, state: outcome.state });
      return toResponse(outcome.state, outcome.events);
    }
    this.store.delete(userId);
    const finish = await this.records.finish(
      userId,
      outcome.state,
      battle.wilds,
    );
    return toResponse(outcome.state, outcome.events, finish);
  }

  private async begin(
    userId: string,
    team: Team,
    enemies: Enemy[],
    godMode = false,
    slots = 1,
  ): Promise<BoardBattleResponseDto> {
    const catalog = await loadBattleCatalog(this.prisma);
    const { state, events } = startBoardBattle(
      team.creatures,
      enemies.map(({ combatant }) => combatant),
      catalog,
      secureRandom,
      team.bag,
      {
        godMode,
        coins: team.coins,
        slots: { player: slots, enemy: slots },
        partyFree: PARTY_SIZE - team.creatures.length,
      },
    );
    const wilds = enemies.map(({ creature, statIds }) => ({
      creature,
      statIds,
    }));
    // Os selvagens podem jogar antes e acabar com a luta já na abertura: o fim
    // é gravado aqui, e não fica luta nenhuma, nem a anterior.
    if (state.phase === 'ended') {
      this.store.delete(userId);
      const finish = await this.records.finish(userId, state, wilds);
      return toResponse(state, events, finish);
    }
    // Substitui a luta anterior, de qualquer tipo, sem gravar nada dela.
    this.store.set(userId, { kind: 'board', state, catalog, wilds });
    return toResponse(state, events);
  }
}
