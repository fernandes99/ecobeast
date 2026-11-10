import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { secureRandom } from '../common/secure-random.js';
import { Env } from '../config/env.js';
import { applyAction, startBattle } from '../domain/battle/engine.js';
import type {
  BattleAction,
  BattleEvent,
  BattleState,
} from '../domain/battle/types.js';
import type { HexCoord } from '../domain/exploration/hex.js';
import { PARTY_SIZE } from '../domain/team/party.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { loadBattleCatalog } from './battle-catalog.js';
import {
  BattleRecordsService,
  type BattleFinish,
  type Enemy,
  type EnemyChoice,
  type Team,
} from './battle-records.service.js';
import { BattleResponseDto } from './battle.dto.js';
import { toBattleDto } from './battle.mapper.js';
import { BattleStore } from './battle.store.js';

export { MIN_STEP_MS } from './battle-records.service.js';
export const NO_BATTLE = 'Nenhuma batalha em andamento.';
const CAN_FLEE_WILD = true;
const NOT_FINISHED: BattleFinish = {
  capturedTo: null,
  progression: [],
  registeredSpeciesIds: [],
};

function toResponse(
  state: BattleState,
  events: BattleEvent[],
  { capturedTo, progression }: BattleFinish = NOT_FINISHED,
) {
  return {
    battle: toBattleDto(state),
    events,
    captured_to: capturedTo,
    spawn_id: null,
    progression,
  };
}

/**
 * A luta de hoje, com todos escolhendo juntos (legado: a luta de Explorar zona
 * passa a ser a do tabuleiro na board-battle/05). Na memória; o banco só muda
 * no fim dela.
 */
@Injectable()
export class BattleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: BattleStore,
    private readonly records: BattleRecordsService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  /** A batalha de teste: a equipe inimiga e as vagas vêm do corpo. */
  async start(
    userId: string,
    choices: EnemyChoice[],
    slots = 1,
  ): Promise<BattleResponseDto> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    const team = await this.records.loadTeam(userId);
    const enemies = await this.records.createEnemies(choices);
    return this.begin(userId, team, enemies, false, slots);
  }

  /** O inimigo sai do hexágono do Domador; a equipe é conferida antes de gastá-lo. */
  async startWild(
    userId: string,
    position: HexCoord,
    god = false,
  ): Promise<BattleResponseDto> {
    const team = await this.records.loadTeam(userId);
    const spawn = this.records.takeSpawn(userId, position);
    const enemy = await this.records.createEnemy(spawn.speciesId, spawn.level);
    // O modo God é só de depuração: fora das rotas de teste, ele não existe.
    const godMode =
      god && this.config.get('ENABLE_TEST_BATTLE', { infer: true });
    return {
      ...(await this.begin(userId, team, [enemy], godMode)),
      spawn_id: spawn.id,
    };
  }

  /**
   * Da leitura à escrita no `store` não há `await`: dois pedidos ao mesmo
   * tempo não jogam o mesmo turno, nem gravam o fim duas vezes.
   */
  async act(
    userId: string,
    actions: BattleAction[],
  ): Promise<BattleResponseDto> {
    const battle = this.store.get(userId);
    if (!battle || battle.kind !== 'classic') {
      throw new NotFoundException(NO_BATTLE);
    }

    const outcome = applyAction(
      battle.state,
      actions,
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
  ): Promise<BattleResponseDto> {
    const catalog = await loadBattleCatalog(this.prisma);
    const { state, events } = startBattle(
      team.creatures,
      enemies.map(({ combatant }) => combatant),
      CAN_FLEE_WILD,
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
    // Substitui a batalha anterior, de qualquer tipo, sem gravar nada dela.
    this.store.set(userId, { kind: 'classic', state, catalog, wilds });
    return toResponse(state, events);
  }
}
