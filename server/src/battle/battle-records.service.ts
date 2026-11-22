import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { CodexService } from '../codex/codex.service.js';
import { CountersService } from '../counters/counters.service.js';
import { tamerXpFromBattle } from '../domain/progression/tamer-level.js';
import type { TamerProgressDto } from '../tamer-level/tamer-level.dto.js';
import { TamerLevelService } from '../tamer-level/tamer-level.service.js';
import {
  IslandTamersService,
  type UnlockedIsland,
  type WonArena,
} from '../islands/island-tamers.service.js';
import {
  battleCounters,
  foughtCreatureIndices,
} from '../domain/counters/battle-counters.js';
import { dayPhaseAt, minuteOfDay } from '../domain/world-clock/world-clock.js';
import { secureRandom } from '../common/secure-random.js';
import type {
  BattleBagItem,
  BattleState,
  Combatant,
} from '../domain/battle/types.js';
import type { HexCoord } from '../domain/exploration/hex.js';
import type { MapSpawn } from '../domain/exploration/spawns.js';
import type { MapTamer } from '../domain/tamers/tamers.js';
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
import {
  ExplorationStore,
  type StoredExploration,
} from '../exploration/exploration.store.js';
import {
  type CreaturePlace,
  loadCreatureBlueprint,
  newCreatureData,
} from '../player/creature-params.js';
import { CREATURE_INCLUDE, creatureStats } from '../player/player.mapper.js';
import type { Prisma } from '../generated/prisma/client.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { QuestsService } from '../quests/quests.service.js';
import {
  type LeveledCreature,
  ProgressionService,
  type VictoryPlan,
} from '../progression/progression.service.js';
import {
  type CapturedTo,
  type CreatureProgressDto,
  INVALID_ENEMY,
  NO_EXPLORATION,
  NO_TAMER_HERE,
  NOTHING_HERE,
  TAMER_WAITING,
  UNREACHABLE,
} from './battle.dto.js';
import {
  BATTLE_PLAYER_INCLUDE,
  toCombatant,
  toEnemyCombatant,
} from './battle.mapper.js';
import type { BattleTamer, WildCreature } from './battle.store.js';

const NO_PLAYER = 'Crie seu Domador primeiro.';
const NO_HEALTHY_CREATURE = 'Cure sua equipe no Refúgio.';

export interface Team {
  creatures: Combatant[];
  bag: BattleBagItem[];
  coins: number;
}

export interface EnemyChoice {
  speciesId: number;
  level: number;
}

export interface Enemy extends WildCreature {
  combatant: Combatant;
}

export interface BattleFinish {
  capturedTo: CapturedTo | null;
  progression: CreatureProgressDto[];
  registeredSpeciesIds: number[];
  tamerProgress: TamerProgressDto | null;
  /** A ilha que a vitória contra o Domador da ilha abriu (auralis/04). */
  islandUnlocked: UnlockedIsland | null;
  /** A Arena cujo Mestre a vitória venceu pela primeira vez (auralis/05). */
  arenaWon: WonArena | null;
}

type IslandTamerRef = NonNullable<BattleTamer['islandTamer']>;

interface ProgressedCreature {
  uid: string;
  teamIndex: number;
  xpGained: number;
  progress: CreatureProgress;
  plan: VictoryPlan | null;
}

function toProgressDto({
  uid,
  teamIndex,
  xpGained,
  progress,
  plan,
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
    evolution:
      plan?.evolutionSpeciesId == null
        ? null
        : { species_id: plan.evolutionSpeciesId },
    learned_skill_ids: plan?.learned.map((skill) => skill.skillId) ?? [],
    pending_skill_ids: plan?.pending ?? [],
  };
}

function isAt({ q, r }: HexCoord, position: HexCoord): boolean {
  return q === position.q && r === position.r;
}

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

@Injectable()
export class BattleRecordsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly explorations: ExplorationStore,
    private readonly progression: ProgressionService,
    private readonly codex: CodexService,
    private readonly counters: CountersService,
    private readonly tamerLevel: TamerLevelService,
    private readonly islandTamers: IslandTamersService,
    private readonly quests: QuestsService,
  ) {}

  async loadTeam(userId: string): Promise<Team> {
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
      coins: player.coins,
    };
  }

  async createEnemy(speciesId: number, level: number): Promise<Enemy> {
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

  async createEnemies(choices: EnemyChoice[]): Promise<Enemy[]> {
    const enemies: Enemy[] = [];
    for (const { speciesId, level } of choices) {
      enemies.push(await this.createEnemy(speciesId, level));
    }
    return enemies;
  }

  /**
   * Da leitura à remoção não há `await`: dois pedidos ao mesmo tempo não
   * enfrentam o mesmo Ecobeast. Quem mente a posição não chega antes de quem anda.
   * Com um Domador no hexágono, a luta contra ele vem primeiro (npc-tamers/03).
   */
  takeSpawn(userId: string, position: HexCoord): MapSpawn {
    const exploration = this.confirmPosition(userId, position);
    if (
      [...exploration.tamers.values()].some((tamer) => isAt(tamer, position))
    ) {
      throw new ConflictException(TAMER_WAITING);
    }
    const here = [...exploration.spawns.values()].filter((spawn) =>
      isAt(spawn, position),
    );
    if (here.length === 0) throw new ConflictException(NOTHING_HERE);
    const spawn = here[Math.floor(secureRandom() * here.length)]!;
    exploration.spawns.delete(spawn.id);
    return spawn;
  }

  takeTamer(userId: string, position: HexCoord): MapTamer {
    const exploration = this.confirmPosition(userId, position);
    const tamer = [...exploration.tamers.values()].find((candidate) =>
      isAt(candidate, position),
    );
    if (!tamer) throw new ConflictException(NO_TAMER_HERE);
    exploration.tamers.delete(tamer.id);
    return tamer;
  }

  endExploration(userId: string): void {
    this.explorations.delete(userId);
  }

  private confirmPosition(
    userId: string,
    position: HexCoord,
  ): StoredExploration {
    const exploration = this.explorations.confirmPosition(userId, position);
    if (exploration === 'none') throw new NotFoundException(NO_EXPLORATION);
    if (exploration === 'unreachable') {
      throw new ConflictException(UNREACHABLE);
    }
    return exploration;
  }

  async finish(
    userId: string,
    state: BattleState,
    wilds: WildCreature[],
    islandTamer: IslandTamerRef | null = null,
  ): Promise<BattleFinish> {
    const { progressed, leveled } = await this.progressTeam(userId, state);
    const {
      capturedTo,
      registeredSpeciesIds,
      tamerProgress,
      islandUnlocked,
      arenaWon,
    } = await this.saveTeam(userId, state, wilds, progressed, islandTamer);
    if (state.result === 'victory') {
      const plans = new Map(
        progressed.flatMap(({ uid, plan }) => (plan ? [[uid, plan]] : [])),
      );
      this.progression.remember(userId, leveled, plans);
    }
    return {
      capturedTo,
      progression: progressed.map(toProgressDto),
      registeredSpeciesIds,
      tamerProgress,
      islandUnlocked,
      arenaWon,
    };
  }

  /** A ilha da exploração guardada; nula no mapa sorteado ou sem exploração. */
  currentIslandId(userId: string): number | null {
    return this.explorations.get(userId)?.islandId ?? null;
  }

  private async progressTeam(
    userId: string,
    state: BattleState,
  ): Promise<{ progressed: ProgressedCreature[]; leveled: LeveledCreature[] }> {
    const none = { progressed: [], leveled: [] };
    if (state.result !== 'victory') return none;
    const earners = state.player.team
      .map((creature, teamIndex) => ({ creature, teamIndex }))
      .filter(({ creature }) => creature.xpEarned > 0);
    if (earners.length === 0) return none;

    const rows = await this.prisma.creatureInstance.findMany({
      where: {
        playerId: userId,
        uid: { in: earners.map(({ creature }) => creature.creatureUid!) },
      },
      include: CREATURE_INCLUDE,
    });
    const byUid = new Map(rows.map((row) => [row.uid, row]));
    const leveled: LeveledCreature[] = [];
    // Um Ecobeast apagado no meio da luta fica de fora, como no `saveTeam`.
    const progressed = earners.flatMap(({ creature, teamIndex }) => {
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
      if (progress.levelAfter > progress.levelBefore) {
        leveled.push({
          uid: row.uid,
          speciesId: row.speciesId,
          levelBefore: progress.levelBefore,
          levelAfter: progress.levelAfter,
          skills: row.skills,
        });
      }
      return [
        {
          uid: row.uid,
          teamIndex,
          xpGained: creature.xpEarned,
          progress,
          plan: null as VictoryPlan | null,
        },
      ];
    });
    const plans = await this.progression.planVictory(leveled);
    for (const item of progressed) item.plan = plans.get(item.uid) ?? null;
    return { progressed, leveled };
  }

  private async saveTeam(
    userId: string,
    state: BattleState,
    wilds: WildCreature[],
    progressed: ProgressedCreature[],
    islandTamer: IslandTamerRef | null,
  ): Promise<{
    capturedTo: CapturedTo | null;
    registeredSpeciesIds: number[];
    tamerProgress: TamerProgressDto | null;
    islandUnlocked: UnlockedIsland | null;
    arenaWon: WonArena | null;
  }> {
    const progressByUid = new Map(
      progressed.map(({ uid, progress }) => [uid, progress]),
    );
    const learned = progressed.flatMap(({ uid, plan }) =>
      (plan?.learned ?? []).map((skill) => ({ creatureUid: uid, ...skill })),
    );
    const conditions = await this.prisma.statusCondition.findMany({
      select: { id: true, slug: true },
    });
    const statusIds = new Map(conditions.map(({ id, slug }) => [slug, id]));
    // A captura vale em qualquer fim, até numa derrota depois dela.
    const captured = state.enemy.team.flatMap((enemy, index) =>
      enemy.captured ? [{ enemy, wild: wilds[index]! }] : [],
    );
    const places = await this.capturePlaces(userId, captured.length);
    // O Bestiário registra só quem foi gravado: sem equipe, ninguém é.
    const caughtSpecies = places.map(
      (_, index) => captured[index]!.enemy.speciesId,
    );
    const codexWrite =
      caughtSpecies.length > 0
        ? this.codex.caughtWrite(userId, caughtSpecies)
        : null;

    const counterWrites = await this.counterWrites(userId, state);
    const questWrites = await this.questWrites(
      userId,
      state,
      caughtSpecies,
      islandTamer,
    );
    const island =
      islandTamer &&
      state.result === 'victory' &&
      !state.godMode &&
      !state.noRewards
        ? await this.islandTamers.victory(userId, islandTamer)
        : null;
    const tamer = await this.tamerAward(userId, state, caughtSpecies, island);

    const results = await this.prisma.$transaction([
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
      ...(learned.length > 0
        ? [this.prisma.creatureInstanceSkill.createMany({ data: learned })]
        : []),
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
      ...(state.coinsChange !== 0
        ? [
            this.prisma.player.updateMany({
              where: {
                id: userId,
                coins: { gte: Math.max(0, -state.coinsChange) },
              },
              data: { coins: { increment: state.coinsChange } },
            }),
          ]
        : []),
      ...places.map((place, index) => {
        const { enemy, wild } = captured[index]!;
        return this.prisma.creatureInstance.create({
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
        });
      }),
      ...counterWrites,
      ...questWrites,
      ...tamer.writes,
      ...(island?.writes ?? []),
      // O Bestiário fica por último: o resultado dele é o `results.at(-1)`.
      ...(codexWrite ? [codexWrite] : []),
    ]);
    return {
      capturedTo: places.at(-1)?.location ?? null,
      registeredSpeciesIds: codexWrite
        ? this.codex.newlyCaught(
            caughtSpecies,
            results.at(-1) as { species_id: number }[],
          )
        : [],
      tamerProgress: tamer.progress,
      islandUnlocked: island?.unlocked ?? null,
      arenaWon: island?.arena ?? null,
    };
  }

  /** O XP do Domador (tamer-level/01); o modo deus e a luta de teste não contam. */
  private async tamerAward(
    userId: string,
    state: BattleState,
    caughtSpecies: number[],
    island: { kind: 'first' | 'rematch' | 'arena'; unlocked: unknown } | null,
  ) {
    if (state.godMode || state.noRewards) return { writes: [], progress: null };
    const known = await this.prisma.codexEntry.findMany({
      where: {
        playerId: userId,
        speciesId: { in: caughtSpecies },
        caughtAt: { not: null },
      },
      select: { speciesId: true },
    });
    const caughtBefore = new Set(known.map(({ speciesId }) => speciesId));
    const fresh = new Set(caughtSpecies.filter((id) => !caughtBefore.has(id)));
    const { levels, sources } = await this.tamerLevel.catalog();
    const gained = tamerXpFromBattle(
      {
        rawEnemyXp: state.rawEnemyXp,
        victory: state.result === 'victory',
        opponentIsTamer: state.opponent === 'tamer',
        newSpeciesCount: fresh.size,
        islandTamer: island?.kind,
        islandUnlocked: island?.unlocked != null,
      },
      sources,
    );
    return this.tamerLevel.award(userId, gained, levels);
  }

  /** O progresso das missões (auralis/06); o modo deus e a luta de teste não contam. */
  private async questWrites(
    userId: string,
    state: BattleState,
    caughtSpecies: number[],
    islandTamer: IslandTamerRef | null,
  ): Promise<Prisma.PrismaPromise<unknown>[]> {
    if (state.godMode || state.noRewards) return [];
    const enemies = state.enemy.team;
    return this.quests.battleWrites(userId, {
      capturedSpeciesIds: caughtSpecies,
      defeatedSpeciesIds: enemies
        .filter((enemy) => enemy.currentHp === 0 && !enemy.captured)
        .map(({ speciesId }) => speciesId),
      enemySpeciesIds: [...new Set(enemies.map(({ speciesId }) => speciesId))],
      beatenTamerId:
        islandTamer && state.result === 'victory' ? islandTamer.id : null,
    });
  }

  /** Os contadores do Perfil (player-stats/01); o modo deus não conta. */
  private async counterWrites(
    userId: string,
    state: BattleState,
  ): Promise<Prisma.PrismaPromise<unknown>[]> {
    if (state.godMode || state.noRewards) return [];
    const [phases, spheres] = await Promise.all([
      this.prisma.dayPhase.findMany({
        select: { id: true, slug: true, startMinute: true },
      }),
      this.prisma.item.findMany({
        where: { captureBonus: { not: null } },
        select: { id: true },
      }),
    ]);
    const increments = battleCounters(state, {
      dayPhaseId: dayPhaseAt(minuteOfDay(Date.now()), phases).id,
      sphereItemIds: new Set(spheres.map(({ id }) => id)),
    });
    const fought = foughtCreatureIndices(state).flatMap(
      (index) => state.player.team[index]?.creatureUid ?? [],
    );
    return [
      ...this.counters.increments(userId, increments),
      ...(fought.length > 0
        ? [
            this.prisma.creatureInstance.updateMany({
              where: { playerId: userId, uid: { in: fought } },
              data: { battles: { increment: 1 } },
            }),
          ]
        : []),
    ];
  }

  private async capturePlaces(
    userId: string,
    count: number,
  ): Promise<CreaturePlace[]> {
    if (count === 0) return [];
    const party = await this.prisma.creatureInstance.findMany({
      where: { playerId: userId, location: 'party' },
      select: { partySlot: true },
    });
    if (party.length === 0) return [];

    const occupied = party.map((row) => row.partySlot!);
    return Array.from({ length: count }, (): CreaturePlace => {
      const partySlot = firstFreePartySlot(occupied);
      if (partySlot === null) return { location: 'storage', partySlot };
      occupied.push(partySlot);
      return { location: 'party', partySlot };
    });
  }
}
