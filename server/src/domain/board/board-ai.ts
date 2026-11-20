import {
  dealsDamage,
  pickSlot,
  skillWeight,
  type SkillOption,
} from '../battle/ai.js';
import { hasPp } from '../battle/emergency.js';
import { combatantAt } from '../battle/field.js';
import type {
  BattleCatalog,
  BattleSkill,
  Random,
  Spot,
} from '../battle/types.js';
import { type HexCoord, hexDistance } from '../exploration/hex.js';
import { ALLY_TARGET, areaOf } from './areas.js';
import { cellOf, MOVE_RANGE, reachable, standingOnBoard } from './board.js';
import { isReady } from './cooldown.js';
import { markAt } from './marks.js';
import type { BoardAction, BoardState, BoardVez } from './types.js';

/** A IA só cura quem está com esta fração do HP ou menos (a revisar). */
export const HEAL_BELOW = 0.5;

interface Attack {
  target: HexCoord;
  foe: Spot;
}

function pick<Item>(items: Item[], random: Random): Item {
  return items.length > 1
    ? items[Math.floor(random() * items.length)]!
    : items[0]!;
}

export function chooseEnemyVez(
  state: BoardState,
  catalog: BattleCatalog,
  random: Random,
  spot: Spot,
): BoardVez {
  const { position } = spot;
  const from = cellOf(state, spot)!;
  const targets = standingOnBoard(state, 'player');
  if (targets.length === 0) return { position, action: { type: 'wait' } };

  const nearest = Math.min(
    ...targets.map((target) => hexDistance(from, cellOf(state, target)!)),
  );
  const target = pick(
    targets.filter(
      (candidate) => hexDistance(from, cellOf(state, candidate)!) === nearest,
    ),
    random,
  );
  const me = combatantAt(state, spot);
  const usable = me.skills.flatMap((learned, index) => {
    const skill = catalog.skills.get(learned.skillId);
    return skill && learned.currentPp > 0 && isReady(learned, state.round)
      ? [{ slot: index + 1, skill }]
      : [];
  });
  const damaging = usable.filter(
    ({ skill }) => dealsDamage(skill) && skill.targetSlug !== 'self',
  );

  const reachesNow =
    damaging.some(({ skill }) =>
      attackFrom(state, spot, from, skill, target),
    ) ||
    usable.some(
      ({ skill }) =>
        skill.targetSlug === ALLY_TARGET && hurtAlly(state, spot, from, skill),
    );
  const stuck = me.isDazed || (me.trappedTurns ?? 0) > 0;
  const garden =
    !stuck && me.currentHp < me.stats.hp * HEAL_BELOW
      ? gardenNear(state, catalog, from)
      : null;
  const destination = stuck
    ? from
    : (garden ??
      (reachesNow
        ? from
        : approach(state, from, cellOf(state, target)!, random)));
  const move = destination === from ? {} : { move: destination };
  const action = chooseAction(
    state,
    catalog,
    random,
    spot,
    destination,
    target,
    usable,
  );
  return { position, ...move, action };
}

/** Um hexágono com marca que cura ao alcance de um passo, de onde está ou vizinho. */
function gardenNear(
  state: BoardState,
  catalog: BattleCatalog,
  from: HexCoord,
): HexCoord | null {
  const heals = (cell: HexCoord) => {
    const mark = markAt(state, cell);
    return (
      mark !== undefined &&
      (catalog.groundEffects.get(mark.groundEffectId)?.healPercent ?? null) !==
        null
    );
  };
  if (heals(from)) return from;
  for (const path of reachable(state, from, MOVE_RANGE).values()) {
    if (heals(path.at(-1)!)) return path.at(-1)!;
  }
  return null;
}

function approach(
  state: BoardState,
  from: HexCoord,
  goal: HexCoord,
  random: Random,
): HexCoord {
  const cells = [
    from,
    ...[...reachable(state, from, MOVE_RANGE).values()].map((path) =>
      path.at(-1)!,
    ),
  ];
  const best = Math.min(...cells.map((cell) => hexDistance(cell, goal)));
  if (hexDistance(from, goal) === best) return from;
  const closest = cells.filter((cell) => hexDistance(cell, goal) === best);
  const unmarked = closest.filter((cell) => !markAt(state, cell));
  return pick(unmarked.length > 0 ? unmarked : closest, random);
}

function attackFrom(
  state: BoardState,
  spot: Spot,
  cell: HexCoord,
  skill: BattleSkill,
  preferred: Spot,
): Attack | null {
  const candidates = [
    preferred,
    ...standingOnBoard(state, 'player').filter(
      (other) => other.position !== preferred.position,
    ),
  ];
  for (const candidate of candidates) {
    const targetCell = cellOf(state, candidate)!;
    const area = areaOf(state, spot, cell, skill, targetCell);
    if ('error' in area || area.foes.length === 0) continue;
    return { target: targetCell, foe: area.foes[0]! };
  }
  return null;
}

/** O aliado ao alcance mais ferido, pela fração do HP; no empate, o próprio autor. */
function hurtAlly(
  state: BoardState,
  spot: Spot,
  cell: HexCoord,
  skill: BattleSkill,
): HexCoord | null {
  const hurt = standingOnBoard(state, spot.side)
    .map((ally) => {
      const self = ally.position === spot.position;
      const creature = combatantAt(state, ally);
      return {
        self,
        target: self ? cell : cellOf(state, ally)!,
        fraction: creature.currentHp / creature.stats.hp,
      };
    })
    .filter(
      ({ target, fraction }) =>
        fraction <= HEAL_BELOW &&
        !('error' in areaOf(state, spot, cell, skill, target)),
    )
    .sort((a, b) => a.fraction - b.fraction || Number(b.self) - Number(a.self));
  return hurt[0]?.target ?? null;
}

function chooseAction(
  state: BoardState,
  catalog: BattleCatalog,
  random: Random,
  spot: Spot,
  cell: HexCoord,
  target: Spot,
  usable: { slot: number; skill: BattleSkill }[],
): BoardAction {
  const me = combatantAt(state, spot);
  if (usable.length === 0) {
    if (hasPp(me)) return { type: 'wait' };
    const adjacent = standingOnBoard(state, 'player')
      .sort(
        (a, b) =>
          Number(b.position === target.position) -
          Number(a.position === target.position),
      )
      .find((other) => hexDistance(cell, cellOf(state, other)!) === 1);
    return adjacent
      ? { type: 'emergency', target: cellOf(state, adjacent)! }
      : { type: 'wait' };
  }
  const options: (SkillOption & { target?: HexCoord })[] = [];
  for (const { slot, skill } of usable) {
    if (skill.targetSlug === ALLY_TARGET) {
      const ally = hurtAlly(state, spot, cell, skill);
      if (ally) {
        const weight = skillWeight(me, me, skill, catalog);
        options.push({ slot, weight, target: ally });
      }
      continue;
    }
    if (skill.targetSlug === 'self') {
      const weight = skillWeight(
        me,
        combatantAt(state, target),
        skill,
        catalog,
      );
      options.push({ slot, weight });
      continue;
    }
    const attack = attackFrom(state, spot, cell, skill, target);
    if (!attack) continue;
    const weight = skillWeight(
      me,
      combatantAt(state, attack.foe),
      skill,
      catalog,
    );
    options.push({ slot, weight, target: attack.target });
  }
  if (options.length === 0) return { type: 'wait' };
  const slot = pickSlot(options, random);
  const chosen = options.find((option) => option.slot === slot)!;
  return chosen.target
    ? { type: 'skill', slot, target: chosen.target }
    : { type: 'skill', slot };
}
