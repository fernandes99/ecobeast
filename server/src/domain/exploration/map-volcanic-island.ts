import type { Random } from '../battle/types.js';
import type { HexCoord } from './hex.js';
import type { MapConfig } from './map-config.js';
import {
  buildCone,
  carveVolcanoStairs,
  straightDistance,
  angleOf,
  type Volcano,
  type VolcanoCell,
} from './map-volcano.js';

/** Um hexágono do gerador, no que a ilha vulcânica lê e muda (volcano/05). */
export interface IslandCell extends VolcanoCell {
  moisture: number;
  sea: boolean;
  neighbors: readonly IslandCell[];
}

/** A terra ocupa de 45% a 60% do mapa, e o cone, de 40% a 60% da terra. A revisar. */
const LAND_SHARE = [0.45, 0.6] as const;
const CONE_SHARE = [0.4, 0.6] as const;
/** O quanto a costa entorta, numa parte do raio, e em quantos pontos. A revisar. */
const COAST_WOBBLE = 0.1;
const COAST_POINTS = 10;
/** A água entre a ilha e a beira do mapa, além da rasa. */
const EDGE_SEA = 2;
/** O cinto de floresta tem pelo menos isto entre a praia e o pé do cone. */
const MIN_BELT = 3;
/** O Boreal fica com a parte mais úmida do cinto (o clima Úmido). A revisar. */
const BOREAL_FROM = 0.45;
const ISLAND_CONE = { stairsMin: 3, stairsMax: 4, craterShare: 0.35 };
const HEX_AREA = Math.sqrt(3) / 2;
const BELT_HEIGHT = 1;

export interface VolcanicIsland<C extends IslandCell> {
  start: C;
  volcano: Volcano<C>;
}

/**
 * A ilha vulcânica (volcano/05): o mapa inteiro vira o oceano em volta de uma ilha
 * só, mais ou menos redonda, no meio dele, com a Praia na costa, o cinto de Planície
 * e Boreal e o cone no centro. Sem lagos, rios, pontes nem outras montanhas.
 */
export function shapeVolcanicIsland<C extends IslandCell>(
  cells: readonly C[],
  random: Random,
  config: MapConfig,
): VolcanicIsland<C> {
  // O centro é o ponto mais longe da beira do mapa, e a costa nunca chega até ela:
  // os braços do contorno do mapa ficam no mar, e a ilha fica cercada de água.
  const fromEdge = layers(cells, (cell) => cell.neighbors.length < 6);
  const center = cells.reduce((best, cell) =>
    fromEdge.get(cell)! > fromEdge.get(best)! ? cell : best,
  );
  const landShare = LAND_SHARE[0] + random() * (LAND_SHARE[1] - LAND_SHARE[0]);
  const coneShare = CONE_SHARE[0] + random() * (CONE_SHARE[1] - CONE_SHARE[0]);
  const target = landShare * cells.length;
  const waves = Array.from(
    { length: COAST_POINTS },
    () => (random() * 2 - 1) * COAST_WOBBLE,
  );
  const coastOf = (cell: HexCoord) => {
    const at =
      ((angleOf(center, cell) / (Math.PI * 2)) * COAST_POINTS + COAST_POINTS) %
      COAST_POINTS;
    const low = Math.floor(at);
    const t = (1 - Math.cos((at - low) * Math.PI)) / 2;
    const wave = waves[low]! * (1 - t) + waves[(low + 1) % COAST_POINTS]! * t;
    return 1 + wave;
  };
  // O raio da costa que dá a parte de terra sorteada, até o limite da beira.
  const landWith = (radius: number) =>
    cells.filter(
      (cell) => straightDistance(center, cell) <= radius * coastOf(cell),
    );
  const limit =
    (fromEdge.get(center)! - config.shallowWidth - EDGE_SEA) /
    (1 + COAST_WOBBLE);
  let low = 1;
  let high = Math.max(low, limit);
  if (landWith(high).length > target) {
    for (let step = 0; step < 24; step += 1) {
      const middle = (low + high) / 2;
      if (landWith(middle).length < target) low = middle;
      else high = middle;
    }
  }
  const island = connected(center, new Set(landWith(high)));
  for (const cell of cells) {
    cell.shape = 'flat';
    cell.sea = !island.has(cell);
  }
  const landRadius = Math.sqrt((island.size * HEX_AREA) / Math.PI);
  const fromSea = layers(cells, (cell) => cell.sea);
  const fromLand = layers(cells, (cell) => !cell.sea);
  const beachWidth =
    config.beachMinWidth +
    Math.floor(random() * (config.beachMaxWidth - config.beachMinWidth + 1));
  for (const cell of cells) {
    if (cell.sea) {
      cell.biome =
        fromLand.get(cell)! <= config.shallowWidth ? 'wshallow' : 'wdeep';
      cell.height = 0;
    } else if (fromSea.get(cell)! <= beachWidth) {
      cell.biome = 'beach';
      cell.height = BELT_HEIGHT;
    } else {
      cell.biome = cell.moisture > BOREAL_FROM ? 'boreal' : 'temperate';
      cell.height = BELT_HEIGHT;
    }
  }

  const shortestCoast = Math.min(
    ...cells
      .filter((cell) => cell.sea)
      .map((cell) => straightDistance(center, cell)),
  );
  const radius = Math.max(
    6,
    Math.floor(
      Math.min(
        landRadius * Math.sqrt(coneShare),
        shortestCoast - beachWidth - MIN_BELT - 2,
      ),
    ),
  );
  const volcano = buildCone(cells, center, radius, random, ISLAND_CONE);
  carveVolcanoStairs(cells, volcano, random);

  // A chegada fica no meio do cinto de floresta, num ângulo sorteado.
  const startAngle = random() * Math.PI * 2 - Math.PI;
  const middle = (radius + 1 + shortestCoast - beachWidth) / 2;
  const away = (cell: C) => {
    const turn = Math.abs(angleOf(center, cell) - startAngle);
    const angle = Math.min(turn, Math.PI * 2 - turn);
    return angle * middle + Math.abs(straightDistance(center, cell) - middle);
  };
  const belt = cells.filter(
    (cell) => cell.biome === 'temperate' || cell.biome === 'boreal',
  );
  const choices = belt.length > 0 ? belt : cells.filter((cell) => !cell.sea);
  const start = choices.reduce((best, cell) =>
    away(cell) < away(best) ? cell : best,
  );
  return { start, volcano };
}

function connected<C extends IslandCell>(
  begin: C,
  allowed: ReadonlySet<C>,
): Set<C> {
  const seen = new Set([begin]);
  const pending = [begin];
  while (pending.length > 0) {
    for (const next of pending.pop()!.neighbors as readonly C[]) {
      if (seen.has(next) || !allowed.has(next)) continue;
      seen.add(next);
      pending.push(next);
    }
  }
  return seen;
}

/** A distância de cada hexágono até o mais perto de `from`, pelos vizinhos (0 nos próprios). */
function layers<C extends IslandCell>(
  cells: readonly C[],
  from: (cell: C) => boolean,
): Map<C, number> {
  const distance = new Map<C, number>();
  let layer = cells.filter(from);
  for (const cell of layer) distance.set(cell, 0);
  for (let step = 1; layer.length > 0; step += 1) {
    const next: C[] = [];
    for (const cell of layer) {
      for (const other of cell.neighbors as readonly C[]) {
        if (distance.has(other)) continue;
        distance.set(other, step);
        next.push(other);
      }
    }
    layer = next;
  }
  return distance;
}
