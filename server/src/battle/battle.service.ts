import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { secureRandom } from '../common/secure-random.js';
import { Env } from '../config/env.js';
import { rollEncounter } from '../domain/battle/encounter.js';
import { applyAction, startBattle } from '../domain/battle/engine.js';
import type {
  BattleAction,
  BattleEvent,
  BattleState,
  Combatant,
} from '../domain/battle/types.js';
import { createCreature } from '../domain/rules/creature-factory.js';
import { MAX_LEVEL } from '../domain/rules/xp-curve.js';
import { loadCreatureBlueprint } from '../player/creature-params.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { loadBattleCatalog } from './battle-catalog.js';
import { BattleResponseDto, INVALID_ENEMY } from './battle.dto.js';
import {
  BATTLE_PLAYER_INCLUDE,
  toBattleDto,
  toCombatant,
  toEnemyCombatant,
} from './battle.mapper.js';
import { BattleStore } from './battle.store.js';

const NO_PLAYER = 'Crie seu Domador primeiro.';
const NO_HEALTHY_CREATURE = 'Cure sua equipe no Refúgio.';
export const NO_BATTLE = 'Nenhuma batalha em andamento.';
const CAN_FLEE_WILD = true;

function toResponse(state: BattleState, events: BattleEvent[]) {
  return { battle: toBattleDto(state), events };
}

/** A batalha do jogador, na memória; o banco só muda no fim dela. */
@Injectable()
export class BattleService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly store: BattleStore,
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

  /** O inimigo é sorteado aqui, perto do nível de quem entra em campo. */
  async startWild(userId: string): Promise<BattleResponseDto> {
    const team = await this.loadTeam(userId);
    const species = await this.prisma.species.findMany({
      select: { id: true },
      orderBy: { id: 'asc' },
    });
    const { speciesId, level } = rollEncounter(
      species.map(({ id }) => id),
      team.find((creature) => creature.currentHp > 0)!.level,
      secureRandom,
    );
    return this.begin(userId, team, await this.createEnemy(speciesId, level));
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

    if (outcome.state.phase === 'ended') {
      this.store.delete(userId);
      await this.saveTeam(userId, outcome.state);
    } else {
      this.store.set(userId, { ...battle, state: outcome.state });
    }
    return toResponse(outcome.state, outcome.events);
  }

  private async begin(
    userId: string,
    team: Combatant[],
    enemy: Combatant,
  ): Promise<BattleResponseDto> {
    const catalog = await loadBattleCatalog(this.prisma);
    const { state, events } = startBattle(
      team,
      [enemy],
      CAN_FLEE_WILD,
      catalog,
      secureRandom,
    );
    // Substitui a batalha anterior, se houver, sem gravar nada dela.
    this.store.set(userId, { state, catalog });
    return toResponse(state, events);
  }

  private async loadTeam(userId: string): Promise<Combatant[]> {
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
    return player.creatures.map(toCombatant);
  }

  private async createEnemy(
    speciesId: number,
    level: number,
  ): Promise<Combatant> {
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
    return toEnemyCombatant(
      creature,
      blueprint.elementIds,
      blueprint.traitSlugs.get(creature.traitId)!,
    );
  }

  /**
   * Grava HP, status e PP de uma vez. Com `updateMany`, um Domador apagado no
   * meio da luta não encontra nada, e a batalha termina sem erro.
   */
  private async saveTeam(userId: string, state: BattleState): Promise<void> {
    const conditions = await this.prisma.statusCondition.findMany({
      select: { id: true, slug: true },
    });
    const statusIds = new Map(conditions.map(({ id, slug }) => [slug, id]));

    await this.prisma.$transaction(
      state.player.team.flatMap((creature) => {
        const uid = creature.creatureUid!;
        const statusSlug = creature.statusSlug;
        return [
          this.prisma.creatureInstance.updateMany({
            where: { uid, playerId: userId },
            data: {
              currentHp: creature.currentHp,
              statusConditionId: statusSlug ? statusIds.get(statusSlug)! : null,
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
    );
  }
}
