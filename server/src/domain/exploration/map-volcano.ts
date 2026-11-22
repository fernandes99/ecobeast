import type { Random } from '../battle/types.js';
import type { MapConfig } from './map-config.js';
import type { HexCoord } from './hex.js';
import { MAX_CLIMB } from './map-slopes.js';

/** Um hexágono do gerador, no que o vulcão lê e muda (volcano/04). */
export interface VolcanoCell extends HexCoord {
  biome: string;
  shape: string;
  height: number;
  neighbors: readonly VolcanoCell[];
}

export interface Volcano<C extends VolcanoCell> {
  center: C;
  radius: number;
  /** Todo hexágono do cone, a lava junto. */
  cone: C[];
  rim: C[];
  /** Os patamares da encosta de fora. */
  slope: C[];
  /** O anel de chão em volta da lava, no fundo da cratera. */
  floor: C[];
  lava: C[];
  /** Os degraus das escadarias, por fora e por dentro, cavados por `carveVolcanoStairs`. */
  stairs: C[];
  /** Os ângulos das escadarias, a partir do centro. */
  stairAngles: number[];
}

export const RIM_HEIGHT = 10;
export const FLOOR_HEIGHT = 6;
/** A lava fica um nível abaixo do piso, como a água (volcano/01). */
export const LAVA_HEIGHT = 5;
/** Um patamar fica 3 níveis acima do de fora: paredão (terrain-plateaus/01). */
const WALL = MAX_CLIMB + 1;
const TOP_TERRACE = RIM_HEIGHT - WALL;
/** A folga em volta do cone, em hexágonos, sem água, ponte nem a chegada. */
export const VOLCANO_MARGIN = 2;
/** O cone cobre colinas e patamares, mas não a Montanha nem o terreno daqui para cima. */
const HIGH_GROUND = 8;
/** O pé do cone fica no 1 ou no 4, e a terra em volta dele desce até esse chão. */
const LOW_FOOT = 1;
const HIGH_FOOT = 4;
/** As partes do cone pela distância ao centro, em hexágonos. A revisar. */
const CRATER_SHARE = 0.5;
const RIM_WIDTH = 2;
const LAVA_RING = 1.5;
const DEEP_SHARE = 0.5;
const DEEP_RING = 1.2;
/** O quanto a borda das faixas entorta, em hexágonos, e em quantos pontos. A revisar. */
const WOBBLE = 1;
const WOBBLE_POINTS = 8;
/** O cone nasce entre os lugares mais longe da borda do mapa, nesta parte deles. */
const CENTER_POOL = 0.25;
const ROW_HEIGHT = Math.sqrt(3) / 2;

export interface ConeOptions {
  stairsMin: number;
  stairsMax: number;
  /** A parte do raio que é cratera: o cone grande da ilha usa menos, senão a lava toma tudo. */
  craterShare: number;
}

const LAND_CONE: ConeOptions = {
  stairsMin: 2,
  stairsMax: 3,
  craterShare: CRATER_SHARE,
};

/**
 * O vulcão em terra (volcano/04): um sorteio próprio decide se sai, o raio e o lugar,
 * o centro de um disco de raio `R + 2` de terra sem água, Montanha, terreno de 8 para
 * cima, ponte nem a chegada (`isBlocked`). Sem lugar no raio sorteado, tenta raios
 * menores. Muda os hexágonos do cone e a terra encostada nele, e devolve o vulcão, ou null.
 */
export function placeVolcano<C extends VolcanoCell>(
  cells: readonly C[],
  climate: string,
  start: C,
  random: Random,
  config: MapConfig,
  isBlocked: (cell: C) => boolean,
): Volcano<C> | null {
  if (climate === 'cold') return null;
  if (random() >= config.volcanoChance) return null;
  const span = config.volcanoMaxRadius - config.volcanoMinRadius + 1;
  const rolled = config.volcanoMinRadius + Math.floor(random() * span);
  const clear = clearance(
    cells,
    (cell) => cell === start || isBlocked(cell) || !openGround(cell),
  );
  const edge = clearance(cells, () => false);
  for (let radius = rolled; radius >= config.volcanoMinRadius; radius -= 1) {
    const fits = cells.filter(
      (cell) => clear.get(cell)! > radius + VOLCANO_MARGIN,
    );
    if (fits.length === 0) continue;
    fits.sort((a, b) => edge.get(b)! - edge.get(a)!);
    const pool = fits.slice(
      0,
      Math.max(1, Math.ceil(fits.length * CENTER_POOL)),
    );
    const center = pool[Math.floor(random() * pool.length)]!;
    return buildCone(cells, center, radius, random, LAND_CONE);
  }
  return null;
}

function openGround(cell: VolcanoCell): boolean {
  return (
    cell.shape !== 'mont' &&
    cell.height < HIGH_GROUND &&
    !['wshallow', 'wdeep', 'lshallow', 'ldeep'].includes(cell.biome)
  );
}

/**
 * A distância de cada hexágono até o mais perto de `blocked` ou até fora do mapa
 * (a beira conta 1).
 */
export function clearance<C extends VolcanoCell>(
  cells: readonly C[],
  blocked: (cell: C) => boolean,
): Map<C, number> {
  const distance = new Map<C, number>();
  let layer: C[] = [];
  for (const cell of cells) {
    if (blocked(cell)) {
      distance.set(cell, 0);
    } else if (cell.neighbors.length < 6) {
      distance.set(cell, 1);
      layer.push(cell);
    }
  }
  for (const cell of cells) {
    if (distance.has(cell)) continue;
    if (cell.neighbors.some((next) => distance.get(next as C) === 0)) {
      distance.set(cell, 1);
      layer.push(cell);
    }
  }
  let step = 1;
  while (layer.length > 0) {
    step += 1;
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

/**
 * O cone em volta de `center`: pela distância ao centro, entortada pela mesma onda
 * em todas as faixas (assim nenhuma faixa some), a lava, o piso, a borda e os
 * patamares, e depois as escadarias. A terra em volta não muda.
 */
export function buildCone<C extends VolcanoCell>(
  cells: readonly C[],
  center: C,
  radius: number,
  random: Random,
  options: ConeOptions,
): Volcano<C> {
  const waves = Array.from(
    { length: WOBBLE_POINTS },
    () => (random() * 2 - 1) * WOBBLE,
  );
  const wobble = (cell: HexCoord) => {
    const angle = angleOf(center, cell);
    const at =
      ((angle / (Math.PI * 2)) * WOBBLE_POINTS + WOBBLE_POINTS) % WOBBLE_POINTS;
    const low = Math.floor(at);
    const t = (1 - Math.cos((at - low) * Math.PI)) / 2;
    return waves[low]! * (1 - t) + waves[(low + 1) % WOBBLE_POINTS]! * t;
  };
  const sized = new Map<C, number>();
  for (const cell of cells) {
    const distance = straightDistance(center, cell);
    if (distance > radius + 1) continue;
    // Perto do centro o ângulo muda muito de um vizinho ao outro: a onda some ali.
    const calm = Math.min(1, distance / (radius * options.craterShare));
    const shaped = distance === 0 ? 0 : distance - wobble(cell) * calm;
    if (shaped <= radius) sized.set(cell, shaped);
  }
  const cone = [...sized.keys()];
  const inside = new Set(cone);
  const around = new Set<C>();
  for (const cell of cone) {
    for (const next of cell.neighbors as readonly C[]) {
      if (!inside.has(next)) around.add(next);
    }
  }
  const low = [...around].filter((cell) => cell.height <= LOW_FOOT + 1);
  const base = low.length * 2 >= around.size ? LOW_FOOT : HIGH_FOOT;
  for (const cell of around) cell.height = Math.min(cell.height, base);
  const terraces: number[] = [];
  for (let height = base + WALL; height <= TOP_TERRACE; height += WALL) {
    terraces.unshift(height);
  }
  const crater = radius * options.craterShare;
  const lavaEdge = crater - LAVA_RING;
  const rimEdge = crater + RIM_WIDTH;
  const band = (radius - rimEdge) / Math.max(1, terraces.length);
  // A funda sempre tem um anel de rasa em volta, mesmo num cone pequeno.
  const deepEdge = Math.min(lavaEdge * DEEP_SHARE, lavaEdge - DEEP_RING);

  const volcano: Volcano<C> = {
    center,
    radius,
    cone,
    rim: [],
    slope: [],
    floor: [],
    lava: [],
    stairs: [],
    stairAngles: [],
  };
  for (const cell of cone) {
    const shaped = sized.get(cell)!;
    cell.shape = 'flat';
    if (shaped <= lavaEdge) {
      cell.biome = shaped <= deepEdge ? 'ldeep' : 'lshallow';
      cell.height = LAVA_HEIGHT;
      volcano.lava.push(cell);
      continue;
    }
    cell.biome = 'volcano';
    if (shaped <= crater) {
      cell.height = FLOOR_HEIGHT;
      volcano.floor.push(cell);
    } else if (shaped <= rimEdge || terraces.length === 0) {
      cell.height = RIM_HEIGHT;
      volcano.rim.push(cell);
    } else {
      const index = Math.min(
        terraces.length - 1,
        Math.floor((shaped - rimEdge) / band),
      );
      cell.height = terraces[index]!;
      volcano.slope.push(cell);
    }
  }
  const count =
    options.stairsMin +
    Math.floor(random() * (options.stairsMax - options.stairsMin + 1));
  const first = random() * Math.PI * 2;
  for (let index = 0; index < count; index += 1) {
    const jitter = (random() - 0.5) * (Math.PI / count) * 0.5;
    volcano.stairAngles.push(first + (index * Math.PI * 2) / count + jitter);
  }
  return volcano;
}

/**
 * As escadarias do cone, depois da garantia de alcance da terra em volta: assim o pé
 * de cada uma já está na altura final do chão de fora.
 */
export function carveVolcanoStairs<C extends VolcanoCell>(
  cells: readonly C[],
  volcano: Volcano<C>,
  random: Random,
): void {
  const inside = new Set(volcano.cone);
  const stairs = new Set<C>();
  for (const angle of volcano.stairAngles) {
    for (const cell of carveStairs(cells, angle, inside, volcano, random)) {
      stairs.add(cell);
    }
  }
  volcano.stairs = [...stairs];
}

function pixelOf({ q, r }: HexCoord): { x: number; y: number } {
  return { x: q + r / 2, y: r * ROW_HEIGHT };
}

/** A distância em linha reta, em hexágonos: o cone sai redondo, e não hexagonal. */
export function straightDistance(center: HexCoord, cell: HexCoord): number {
  const a = pixelOf(center);
  const b = pixelOf(cell);
  return Math.hypot(b.x - a.x, b.y - a.y);
}

export function angleOf(center: HexCoord, cell: HexCoord): number {
  const a = pixelOf(center);
  const b = pixelOf(cell);
  return Math.atan2(b.y - a.y, b.x - a.x);
}

/**
 * Uma escadaria pela reta que sai do centro no ângulo: do primeiro hexágono do piso
 * até o primeiro de fora do cone. Enquanto dois vizinhos da reta passarem de 2 níveis,
 * o do cone muda para 1 ou 2 do outro: o mais alto desce, ou, se o mais alto é o chão
 * de fora, o degrau sobe.
 */
function carveStairs<C extends VolcanoCell>(
  cells: readonly C[],
  angle: number,
  inside: ReadonlySet<C>,
  volcano: Volcano<C>,
  random: Random,
): C[] {
  const { center, radius } = volcano;
  const byKey = new Map(cells.map((cell) => [`${cell.q},${cell.r}`, cell]));
  const from = pixelOf(center);
  const line: C[] = [];
  const steps = (radius + VOLCANO_MARGIN) * 4;
  for (let step = 0; step <= steps; step += 1) {
    const length = ((radius + VOLCANO_MARGIN) * step) / steps;
    const x = from.x + Math.cos(angle) * length;
    const y = from.y + Math.sin(angle) * length;
    const cell = byKey.get(hexKeyOf(x, y));
    if (cell && line.at(-1) !== cell) line.push(cell);
  }
  const floor = new Set(volcano.floor);
  const begin = line.findIndex((cell) => floor.has(cell));
  const out = line.findIndex(
    (cell, index) => index > begin && !inside.has(cell),
  );
  if (begin < 0 || out < 0) return [];
  const path = line.slice(begin, out + 1);
  for (let changed = true; changed;) {
    changed = false;
    for (let index = 1; index < path.length; index += 1) {
      const a = path[index - 1]!;
      const b = path[index]!;
      if (Math.abs(a.height - b.height) <= MAX_CLIMB) continue;
      const [high, low] = a.height > b.height ? [a, b] : [b, a];
      const step = random() < 0.5 ? 1 : 2;
      if (inside.has(high)) high.height = low.height + step;
      else low.height = high.height - step;
      changed = true;
    }
  }
  return path.filter((cell) => inside.has(cell) && !floor.has(cell));
}

/** O hexágono que contém o ponto, em coordenadas de `pixelOf` (arredondamento cúbico). */
function hexKeyOf(x: number, y: number): string {
  const r = y / ROW_HEIGHT;
  const q = x - r / 2;
  const s = -q - r;
  let rq = Math.round(q);
  let rr = Math.round(r);
  const rs = Math.round(s);
  const dq = Math.abs(rq - q);
  const dr = Math.abs(rr - r);
  const ds = Math.abs(rs - s);
  if (dq > dr && dq > ds) rq = -rr - rs;
  else if (dr > ds) rr = -rq - rs;
  return `${rq},${rr}`;
}
