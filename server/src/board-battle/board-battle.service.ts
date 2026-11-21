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
import { rollBoard } from '../domain/board/board.js';
import { borrowedTeam } from '../domain/board/skill-test.js';
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
import {
  INVALID_SKILL_TEST,
  type BoardBattleResponseDto,
} from './board-battle.dto.js';
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
  slots?: number;
  opponent?: Opponent;
  tamer?: BattleTamer | null;
  sandbox?: boolean;
  idleEnemies?: boolean;
}

export interface SkillTest {
  skillId: number;
  speciesId: number;
  enemySpeciesId: number;
  level: number;
  enemyIdle: boolean;
  slots: number;
}

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

  async start(
    userId: string,
    choices: EnemyChoice[],
    slots = 1,
  ): Promise<BoardBattleResponseDto> {
    this.requireTestBattle();
    const team = await this.records.loadTeam(userId);
    const enemies = await this.records.createEnemies(choices);
    return this.begin(userId, team, enemies, { slots });
  }

  /**
   * A luta de teste da Técnica (skill-test/01): um Ecobeast emprestado, fora da
   * equipe, contra o oponente pedido. Nada dela é gravado.
   */
  async startSkillTest(
    userId: string,
    test: SkillTest,
  ): Promise<BoardBattleResponseDto> {
    this.requireTestBattle();
    const skill = await this.prisma.skill.findUnique({
      where: { id: test.skillId },
      select: { id: true, maxPp: true },
    });
    if (!skill) throw new BadRequestException(INVALID_SKILL_TEST);
    const create = (speciesId: number) =>
      Array.from({ length: test.slots }, () =>
        this.records.createEnemy(speciesId, test.level),
      );
    const [users, enemies] = await Promise.all([
      Promise.all(create(test.speciesId)),
      Promise.all(create(test.enemySpeciesId)),
    ]).catch((error: unknown) => {
      if (error instanceof BadRequestException) {
        throw new BadRequestException(INVALID_SKILL_TEST);
      }
      throw error;
    });
    const team: Team = {
      creatures: borrowedTeam(
        users.map(({ combatant }) => combatant),
        skill,
      ),
      bag: [],
      coins: 0,
    };
    return this.begin(userId, team, enemies, {
      slots: test.slots,
      sandbox: true,
      idleEnemies: test.enemyIdle,
    });
  }

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
      if (!battle.sandbox) await this.recordSeen(userId, outcome.events);
      return toResponse(outcome.state, outcome.events, tamer);
    }
    this.store.delete(userId);
    if (battle.sandbox) return toResponse(outcome.state, outcome.events, tamer);
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

  private requireTestBattle(): void {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
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
      sandbox = false,
      idleEnemies = false,
    }: BeginOptions = {},
  ): Promise<BoardBattleResponseDto> {
    const catalog = await loadBattleCatalog(this.prisma);
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
        partyFree: sandbox ? 0 : PARTY_SIZE - team.creatures.length,
        opponent,
        board: rollBoard(slots, secureRandom),
        freeSkills: sandbox,
        idleEnemies,
        noRewards: sandbox,
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
      if (sandbox) return toResponse(state, events, tamer);
      await this.recordSeen(userId, events);
      const finish = await this.finish(userId, state, wilds, tamer);
      return toResponse(state, events, tamer, finish);
    }
    this.store.set(userId, { state, catalog, wilds, tamer, sandbox });
    if (!sandbox) await this.recordSeen(userId, events);
    return toResponse(state, events, tamer);
  }
}
