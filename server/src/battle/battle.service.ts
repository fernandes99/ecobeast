import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { secureRandom } from '../common/secure-random.js';
import { Env } from '../config/env.js';
import { applyAction, startBattle } from '../domain/battle/engine.js';
import type {
  BattleAction,
  BattleBagItem,
  BattleEvent,
  BattleState,
  Combatant,
} from '../domain/battle/types.js';
import { type HexCoord, hexDistance } from '../domain/exploration/hex.js';
import type { MapSpawn } from '../domain/exploration/spawns.js';
import {
  type CreatureProgress,
  progressCreature,
} from '../domain/progression/levels.js';
import {
  createCreature,
  type NewCreature,
} from '../domain/rules/creature-factory.js';
import { MAX_LEVEL } from '../domain/rules/xp-curve.js';
import { firstFreePartySlot } from '../domain/team/party.js';
import { ExplorationStore } from '../exploration/exploration.store.js';
import {
  type CreaturePlace,
  loadCreatureBlueprint,
  newCreatureData,
} from '../player/creature-params.js';
import { CREATURE_INCLUDE, creatureStats } from '../player/player.mapper.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { loadBattleCatalog } from './battle-catalog.js';
import {
  BattleResponseDto,
  type CapturedTo,
  type CreatureProgressDto,
  INVALID_ENEMY,
  NO_EXPLORATION,
  NOTHING_HERE,
  UNREACHABLE,
} from './battle.dto.js';
import {
  BATTLE_PLAYER_INCLUDE,
  toBattleDto,
  toCombatant,
  toEnemyCombatant,
} from './battle.mapper.js';
import { BattleStore, type WildCreature } from './battle.store.js';

const NO_PLAYER = 'Crie seu Domador primeiro.';
const NO_HEALTHY_CREATURE = 'Cure sua equipe no Refúgio.';
export const NO_BATTLE = 'Nenhuma batalha em andamento.';
const CAN_FLEE_WILD = true;
/** Um passo no cliente leva 360 ms; a diferença é a folga para o relógio. */
export const MIN_STEP_MS = 300;

interface Team {
  creatures: Combatant[];
  bag: BattleBagItem[];
}

interface Enemy extends WildCreature {
  combatant: Combatant;
}

/** Quem ganhou XP na luta, já com o nível, o XP e o HP que vão para o banco. */
interface ProgressedCreature {
  uid: string;
  teamIndex: number;
  xpGained: number;
  progress: CreatureProgress;
}

function toResponse(
  state: BattleState,
  events: BattleEvent[],
  capturedTo: CapturedTo | null = null,
  progressed: ProgressedCreature[] = [],
) {
  return {
    battle: toBattleDto(state),
    events,
    captured_to: capturedTo,
    spawn_id: null,
    progression: progressed.map(toProgressDto),
  };
}

function toProgressDto({
  uid,
  teamIndex,
  xpGained,
  progress,
}: ProgressedCreature): CreatureProgressDto {
  return {
    uid,
    team_index: teamIndex,
    xp_gained: xpGained,
    level_before: progress.levelBefore,
    level_after: progress.levelAfter,
    current_xp: progress.currentXp,
    level_xp: progress.levelXp,
    next_level_xp: progress.nextLevelXp,
    stats_before: progress.statsBefore,
    stats_after: progress.statsAfter,
    evolution: null,
    learned_skill_ids: [],
    pending_skill_ids: [],
  };
}

/** O inimigo como o fim da luta o deixou. */
function capturedCreature(wild: WildCreature, enemy: Combatant): NewCreature {
  const { creature } = wild;
  return {
    ...creature,
    currentHp: enemy.currentHp,
    skills: creature.skills.map((skill, index) => ({
      ...skill,
      currentPp: enemy.skills[index]!.currentPp,
    })),
  };
}

/** A batalha do jogador, na memória; o banco só muda no fim dela. */
@Injectable()
export class BattleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: BattleStore,
    private readonly explorations: ExplorationStore,
    private readonly config: ConfigService<Env, true>,
  ) {}

  async start(
    userId: string,
    speciesId: number,
    level: number,
  ): Promise<BattleResponseDto> {
    if (!this.config.get('ENABLE_TEST_BATTLE', { infer: true })) {
      throw new NotFoundException('Rota não encontrada.');
    }
    const team = await this.loadTeam(userId);
    return this.begin(userId, team, await this.createEnemy(speciesId, level));
  }

  /** O inimigo sai do hexágono do Domador; a equipe é conferida antes de gastá-lo. */
  async startWild(
    userId: string,
    position: HexCoord,
  ): Promise<BattleResponseDto> {
    const team = await this.loadTeam(userId);
    const spawn = this.takeSpawn(userId, position);
    const enemy = await this.createEnemy(spawn.speciesId, spawn.level);
    return { ...(await this.begin(userId, team, enemy)), spawn_id: spawn.id };
  }

  /**
   * Da leitura à remoção não há `await`: dois pedidos ao mesmo tempo não
   * enfrentam o mesmo Ecobeast. Quem mente a posição não chega antes de quem anda.
   */
  private takeSpawn(userId: string, position: HexCoord): MapSpawn {
    const exploration = this.explorations.get(userId);
    if (!exploration) throw new NotFoundException(NO_EXPLORATION);

    const now = Date.now();
    const walked = hexDistance(exploration.position, position);
    if (walked * MIN_STEP_MS > now - exploration.positionAt) {
      throw new ConflictException(UNREACHABLE);
    }
    this.explorations.set(userId, {
      ...exploration,
      position,
      positionAt: now,
    });

    const here = [...exploration.spawns.values()].filter(
      ({ q, r }) => q === position.q && r === position.r,
    );
    if (here.length === 0) throw new ConflictException(NOTHING_HERE);
    const spawn = here[Math.floor(secureRandom() * here.length)]!;
    exploration.spawns.delete(spawn.id);
    return spawn;
  }

  /**
   * Da leitura à escrita no `store` não há `await`: dois pedidos ao mesmo
   * tempo não jogam o mesmo turno, nem gravam o fim duas vezes.
   */
  async act(userId: string, action: BattleAction): Promise<BattleResponseDto> {
    const battle = this.store.get(userId);
    if (!battle) throw new NotFoundException(NO_BATTLE);

    const outcome = applyAction(
      battle.state,
      action,
      battle.catalog,
      secureRandom,
    );
    if ('error' in outcome) throw new BadRequestException(outcome.error);

    if (outcome.state.phase !== 'ended') {
      this.store.set(userId, { ...battle, state: outcome.state });
      return toResponse(outcome.state, outcome.events);
    }
    this.store.delete(userId);
    const progressed = await this.progressTeam(userId, outcome.state);
    const capturedTo = await this.saveTeam(
      userId,
      outcome.state,
      battle.wild,
      progressed,
    );
    return toResponse(outcome.state, outcome.events, capturedTo, progressed);
  }

  /**
   * O nível, o XP, os stats e o HP de quem ganhou XP, a partir do que está no
   * banco. Só a vitória dá XP; nos outros fins, a lista é vazia.
   */
  private async progressTeam(
    userId: string,
    state: BattleState,
  ): Promise<ProgressedCreature[]> {
    if (state.result !== 'victory') return [];
    const earners = state.player.team
      .map((creature, teamIndex) => ({ creature, teamIndex }))
      .filter(({ creature }) => creature.xpEarned > 0);
    if (earners.length === 0) return [];

    const rows = await this.prisma.creatureInstance.findMany({
      where: {
        playerId: userId,
        uid: { in: earners.map(({ creature }) => creature.creatureUid!) },
      },
      include: CREATURE_INCLUDE,
    });
    const byUid = new Map(rows.map((row) => [row.uid, row]));
    // Um Ecobeast apagado no meio da luta fica de fora, como no `saveTeam`.
    return earners.flatMap(({ creature, teamIndex }) => {
      const row = byUid.get(creature.creatureUid!);
      if (!row) return [];
      const progress = progressCreature(
        {
          level: row.level,
          currentXp: row.currentXp,
          currentHp: creature.currentHp,
        },
        creature.xpEarned,
        row.species.growthRate.xpMultiplier,
        (level) => creatureStats({ ...row, level }),
      );
      return [
        { uid: row.uid, teamIndex, xpGained: creature.xpEarned, progress },
      ];
    });
  }

  private async begin(
    userId: string,
    team: Team,
    { combatant, ...wild }: Enemy,
  ): Promise<BattleResponseDto> {
    const catalog = await loadBattleCatalog(this.prisma);
    const { state, events } = startBattle(
      team.creatures,
      [combatant],
      CAN_FLEE_WILD,
      catalog,
      secureRandom,
      team.bag,
    );
    // Substitui a batalha anterior, se houver, sem gravar nada dela.
    this.store.set(userId, { state, catalog, wild });
    return toResponse(state, events);
  }

  private async loadTeam(userId: string): Promise<Team> {
    const player = await this.prisma.player.findUnique({
      where: { id: userId },
      include: BATTLE_PLAYER_INCLUDE,
    });
    if (!player || player.creatures.length === 0) {
      throw new ConflictException(NO_PLAYER);
    }
    if (player.creatures.every((creature) => creature.currentHp === 0)) {
      throw new ConflictException(NO_HEALTHY_CREATURE);
    }
    return {
      creatures: player.creatures.map(toCombatant),
      bag: player.inventory.map(({ itemId, quantity }) => ({
        itemId,
        quantity,
        used: 0,
      })),
    };
  }

  private async createEnemy(speciesId: number, level: number): Promise<Enemy> {
    if (level < 1 || level > MAX_LEVEL) {
      throw new BadRequestException(INVALID_ENEMY);
    }
    const blueprint = await loadCreatureBlueprint(
      this.prisma,
      speciesId,
      level,
    );
    if (!blueprint) throw new BadRequestException(INVALID_ENEMY);

    const creature = createCreature(blueprint.params, secureRandom);
    return {
      creature,
      statIds: blueprint.statIds,
      combatant: toEnemyCombatant(
        creature,
        blueprint.elementIds,
        blueprint.traitSlugs.get(creature.traitId)!,
      ),
    };
  }

  /**
   * Grava HP, status, PP, XP, nível, itens gastos e o capturado de uma vez. Com `updateMany`,
   * um Domador apagado no meio da luta não encontra nada, e a batalha termina
   * sem erro. Devolve para onde foi o capturado.
   */
  private async saveTeam(
    userId: string,
    state: BattleState,
    wild: WildCreature,
    progressed: ProgressedCreature[],
  ): Promise<CapturedTo | null> {
    const progressByUid = new Map(
      progressed.map(({ uid, progress }) => [uid, progress]),
    );
    const conditions = await this.prisma.statusCondition.findMany({
      select: { id: true, slug: true },
    });
    const statusIds = new Map(conditions.map(({ id, slug }) => [slug, id]));
    const place =
      state.result === 'captured' ? await this.capturePlace(userId) : null;
    const enemy = state.enemy.team[state.enemy.activeIndex]!;

    await this.prisma.$transaction([
      ...state.player.team.flatMap((creature) => {
        const uid = creature.creatureUid!;
        const statusSlug = creature.statusSlug;
        const progress = progressByUid.get(uid);
        return [
          this.prisma.creatureInstance.updateMany({
            where: { uid, playerId: userId },
            data: {
              currentHp: progress?.currentHp ?? creature.currentHp,
              statusConditionId: statusSlug ? statusIds.get(statusSlug)! : null,
              ...(progress && {
                level: progress.levelAfter,
                currentXp: progress.currentXp,
              }),
            },
          }),
          ...creature.skills.map(({ skillId, currentPp }) =>
            this.prisma.creatureInstanceSkill.updateMany({
              where: { creatureUid: uid, skillId },
              data: { currentPp },
            }),
          ),
        ];
      }),
      ...state.bag
        .filter(({ used }) => used > 0)
        .flatMap(({ itemId, used }) => {
          const row = { playerId: userId, itemId };
          // O CHECK de quantidade não aceita 0: a linha sai antes do desconto.
          return [
            this.prisma.inventoryItem.deleteMany({
              where: { ...row, quantity: { lte: used } },
            }),
            this.prisma.inventoryItem.updateMany({
              where: row,
              data: { quantity: { decrement: used } },
            }),
          ];
        }),
      ...(place
        ? [
            this.prisma.creatureInstance.create({
              data: {
                ...newCreatureData(
                  userId,
                  capturedCreature(wild, enemy),
                  wild.statIds,
                  place,
                ),
                statusConditionId: enemy.statusSlug
                  ? statusIds.get(enemy.statusSlug)!
                  : null,
              },
            }),
          ]
        : []),
    ]);
    return place?.location ?? null;
  }

  /** A vaga do capturado. Todo Domador tem equipe: sem ela, ele foi apagado. */
  private async capturePlace(userId: string): Promise<CreaturePlace | null> {
    const party = await this.prisma.creatureInstance.findMany({
      where: { playerId: userId, location: 'party' },
      select: { partySlot: true },
    });
    if (party.length === 0) return null;

    const partySlot = firstFreePartySlot(party.map((row) => row.partySlot!));
    return partySlot === null
      ? { location: 'storage', partySlot }
      : { location: 'party', partySlot };
  }
}
