import type { Random } from '../battle/types.js';
import type { HexCoord } from './hex.js';
import type { MapConfig } from './map-config.js';

/** O que o mar, os lagos e os rios precisam de cada hexágono (coast-rivers/02). */
export interface WaterCell<C> extends HexCoord {
  elevation: number;
  sea: boolean;
  wet: boolean;
  neighbors: C[];
}

export interface Lake<C> {
  cells: C[];
}

export type RiverSource = 'spring' | 'lake' | 'edge';

export interface River<C> {
  /** A linha do meio, da nascente à foz. */
  path: C[];
  /** Todos os hexágonos do rio, com a largura. */
  cells: C[];
  source: RiverSource;
}

const SEA_REACH = 20;
/** Um ruído miúdo na altura de escoar faz o rio serpentear em vez de cortar o plano em reta. */
const MEANDER = 0.08;
const LAKE_GAP = 6;
const LAKE_SAMPLES = 12;
export const DEEP_LAKE_FROM = 12;
const BORDER_GAP = 2;
const SPRING_GAP = 4;
const SPRING_HIGH = 0.8;
const SPRING_TRIES = 12;
/** A borda do lago só cresce para fora, até este tanto, para ele nunca ficar mais estreito que o pedido. */
const LAKE_WOBBLE = 0.8;
const ROW_HEIGHT = Math.sqrt(3) / 2;
/** Quantos passos de hexágono cabem num raio em linha reta (o pior caso é na diagonal). */
const STEPS_PER_RADIUS = 2 / Math.sqrt(3);
const MIN_RIVER = 3;
const LAKE_TRIES = 6;
const EDGE_GAP = 2;
const MAX_FIXES = 200;
/** O vau ou a ponte mais longa: quantos hexágonos de rio a linha atravessa. */
const MAX_SPAN = 6;
const MIN_PIECE = 3;
const AXES = [
  { q: 1, r: 0 },
  { q: 0, r: 1 },
  { q: 1, r: -1 },
] as const;

/** A distância de cada hexágono que `through` aceita até o mais perto de `from`. */
export function distances<C extends WaterCell<C>>(
  from: C[],
  through: (cell: C) => boolean,
): Map<C, number> {
  const result = new Map<C, number>(from.map((cell) => [cell, 0]));
  let ring = from;
  for (let step = 1; ring.length > 0; step += 1) {
    const next: C[] = [];
    for (const cell of ring) {
      for (const neighbor of cell.neighbors) {
        if (!result.has(neighbor) && through(neighbor)) {
          result.set(neighbor, step);
          next.push(neighbor);
        }
      }
    }
    ring = next;
  }
  return result;
}

/** Quantos pedaços de terra soltos o mapa tem. */
export function landPieces<C extends WaterCell<C>>(cells: C[]): number {
  const seen = new Set<C>();
  let pieces = 0;
  for (const first of cells) {
    if (first.wet || seen.has(first)) continue;
    pieces += 1;
    seen.add(first);
    const pending = [first];
    while (pending.length > 0) {
      for (const neighbor of pending.pop()!.neighbors) {
        if (!neighbor.wet && !seen.has(neighbor)) {
          seen.add(neighbor);
          pending.push(neighbor);
        }
      }
    }
  }
  return pieces;
}

/** A contagem de `landPieces` da última água que deu certo, para não contar duas vezes. */
const knownPieces = new WeakMap<object, number>();

/** Molha `body`, menos se ele partir a terra: aí desfaz e diz que não deu. */
function wetUnlessSplit<C extends WaterCell<C>>(
  cells: C[],
  body: C[],
): boolean {
  const before = knownPieces.get(cells) ?? landPieces(cells);
  for (const cell of body) cell.wet = true;
  const after = landPieces(cells);
  if (after <= before) {
    knownPieces.set(cells, after);
    return true;
  }
  knownPieces.set(cells, before);
  for (const cell of body) cell.wet = false;
  return false;
}

/** Metade altitude, metade distância até o mar: a terra cai em direção a ele. */
export function drainOf<C extends WaterCell<C>>(
  cells: C[],
  jitter: (cell: C) => number,
): Map<C, number> {
  const sea = cells.filter((cell) => cell.sea);
  const fromSea = distances(sea, () => true);
  return new Map(
    cells.map((cell) => [
      cell,
      (sea.length === 0
        ? cell.elevation
        : 0.5 * cell.elevation +
          0.5 * Math.min((fromSea.get(cell) ?? SEA_REACH) / SEA_REACH, 1)) +
        MEANDER * (jitter(cell) - 0.5),
    ]),
  );
}

export class MinHeap<T> {
  private readonly items: { item: T; key: number; order: number }[] = [];
  private count = 0;

  get size(): number {
    return this.items.length;
  }

  push(item: T, key: number): void {
    this.items.push({ item, key, order: this.count++ });
    let index = this.items.length - 1;
    while (index > 0) {
      const parent = (index - 1) >> 1;
      if (!this.before(index, parent)) break;
      this.swap(index, parent);
      index = parent;
    }
  }

  pop(): { item: T; key: number } {
    const top = this.items[0]!;
    const last = this.items.pop()!;
    if (this.items.length > 0) {
      this.items[0] = last;
      let index = 0;
      for (;;) {
        const left = index * 2 + 1;
        const right = left + 1;
        let best = index;
        if (left < this.items.length && this.before(left, best)) best = left;
        if (right < this.items.length && this.before(right, best)) best = right;
        if (best === index) break;
        this.swap(index, best);
        index = best;
      }
    }
    return top;
  }

  private before(a: number, b: number): boolean {
    const x = this.items[a]!;
    const y = this.items[b]!;
    return x.key < y.key || (x.key === y.key && x.order < y.order);
  }

  private swap(a: number, b: number): void {
    [this.items[a], this.items[b]] = [this.items[b]!, this.items[a]!];
  }
}

/**
 * O Priority-Flood (Barnes, 2014): a partir das saídas, sempre entra o hexágono de menor
 * nível, e um buraco é enchido até o nível de quem o alcançou. Cada hexágono aponta
 * para quem o alcançou, o vizinho por onde ele desce até uma saída, sem subir. Nos
 * empates, entra primeiro quem chegou antes, então a água atravessa o plano pelo caminho
 * mais curto.
 */
export function flowDown<C extends WaterCell<C>>(
  drain: Map<C, number>,
  outlets: C[],
): { down: Map<C, C>; level: Map<C, number> } {
  const down = new Map<C, C>();
  const level = new Map<C, number>();
  const heap = new MinHeap<C>();
  for (const outlet of outlets) {
    level.set(outlet, drain.get(outlet)!);
    heap.push(outlet, drain.get(outlet)!);
  }
  while (heap.size > 0) {
    const { item, key } = heap.pop();
    for (const neighbor of item.neighbors) {
      if (level.has(neighbor) || neighbor.wet) continue;
      const spill = Math.max(drain.get(neighbor)!, key);
      level.set(neighbor, spill);
      down.set(neighbor, item);
      heap.push(neighbor, spill);
    }
  }
  return { down, level };
}

function between(random: Random, low: number, high: number): number {
  const [from, to] = low <= high ? [low, high] : [high, low];
  return from + Math.floor(random() * (to - from + 1));
}

function pick<T>(random: Random, items: T[]): T {
  return items[Math.floor(random() * items.length)]!;
}

/** A distância em linha reta entre os centros de dois hexágonos, em larguras de hexágono. */
function spread(a: HexCoord, b: HexCoord): number {
  return Math.hypot(a.q + a.r / 2 - (b.q + b.r / 2), (a.r - b.r) * ROW_HEIGHT);
}

/**
 * Um lago redondo de `width` hexágonos de largura: os hexágonos a até metade da largura do
 * centro, com a borda recortada por `wobble` (de 0 a 1) só para fora.
 */
function disc<C extends WaterCell<C>>(
  center: C,
  width: number,
  wobble: (cell: C) => number,
): C[] {
  const radius = width / 2;
  const body = [center];
  const seen = new Set([center]);
  for (let index = 0; index < body.length; index += 1) {
    for (const neighbor of body[index]!.neighbors) {
      if (seen.has(neighbor)) continue;
      seen.add(neighbor);
      if (spread(center, neighbor) <= radius + LAKE_WOBBLE * wobble(neighbor)) {
        body.push(neighbor);
      }
    }
  }
  return body;
}

/** Os passos de hexágono que um lago de `width` alcança a partir do centro. */
function lakeReach(width: number): number {
  return Math.ceil((width / 2 + LAKE_WOBBLE) * STEPS_PER_RADIUS);
}

/**
 * Os lagos, redondos e com pelo menos `lakeMinWidth` de largura: cada um tem o centro no
 * mais baixo de alguns hexágonos sorteados onde o disco inteiro cabe, longe do mar, de
 * outro lago e da borda. Um lago que partiria a terra (num estreito do recorte do mapa) é
 * sorteado de novo.
 */
export function placeLakes<C extends WaterCell<C>>(
  cells: C[],
  drain: Map<C, number>,
  wobble: (cell: C) => number,
  random: Random,
  config: MapConfig,
): Lake<C>[] {
  const lakes: Lake<C>[] = [];
  const fromBorder = distances(
    cells.filter((cell) => cell.neighbors.length < 6),
    () => true,
  );
  for (let index = 0; index < config.lakeCount; index += 1) {
    const fromWater = distances(
      cells.filter((cell) => cell.wet),
      () => true,
    );
    for (let tries = 0; tries < LAKE_TRIES; tries += 1) {
      const width = between(random, config.lakeMinWidth, config.lakeMaxWidth);
      const reach = lakeReach(width);
      const eligible = cells.filter(
        (cell) =>
          !cell.wet &&
          (fromWater.get(cell) ?? Infinity) >= reach + LAKE_GAP &&
          fromBorder.get(cell)! >= reach + BORDER_GAP,
      );
      if (eligible.length === 0) continue;
      const samples = Array.from({ length: LAKE_SAMPLES }, () =>
        pick(random, eligible),
      );
      const center = samples.reduce((best, cell) =>
        drain.get(cell)! < drain.get(best)! ? cell : best,
      );
      const body = disc(center, width, wobble);
      if (wetUnlessSplit(cells, body)) {
        lakes.push({ cells: body });
        break;
      }
    }
  }
  return lakes;
}

/**
 * Os rios. Com a chance `throughRiverChance`, o rio vem de fora do mapa: nasce num
 * hexágono de `edges` (a borda do lado oposto ao mar) e corta a terra (coast-rivers/03).
 * Os outros nascem dentro da terra: a nascente fica entre os 20% mais altos, longe de
 * outra água, às vezes num lago pequeno. Todos descem pelo caminho do `flowDown` até
 * encostar no mar, num lago ou em outro rio. O Domador contorna a nascente, mas um rio
 * de dentro que passa por um estreito do recorte do mapa partiria a terra: esse é
 * sorteado de novo.
 */
export function placeRivers<C extends WaterCell<C>>(
  cells: C[],
  drain: Map<C, number>,
  down: Map<C, C>,
  edges: C[],
  wobble: (cell: C) => number,
  random: Random,
  config: MapConfig,
): { rivers: River<C>[]; ponds: Lake<C>[] } {
  const rivers: River<C>[] = [];
  const ponds: Lake<C>[] = [];
  const fromBorder = distances(
    cells.filter((cell) => cell.neighbors.length < 6),
    () => true,
  );
  const pondReach = lakeReach(config.lakeMinWidth);
  const land = cells.filter((cell) => !cell.wet);
  const heights = land.map((cell) => drain.get(cell)!).sort((a, b) => a - b);
  const high = heights[Math.floor(heights.length * SPRING_HIGH)] ?? Infinity;
  const middle = heights[Math.floor(heights.length / 2)] ?? Infinity;
  for (let index = 0; index < config.riverCount; index += 1) {
    const fromWater = distances(
      cells.filter((cell) => cell.wet),
      () => true,
    );
    const springs = land.filter(
      (cell) =>
        !cell.wet &&
        down.has(cell) &&
        drain.get(cell)! >= high &&
        (fromWater.get(cell) ?? Infinity) >= SPRING_GAP,
    );
    if (random() < config.throughRiverChance) {
      const sources = edges.filter(
        (cell) =>
          !cell.wet &&
          down.has(cell) &&
          (fromWater.get(cell) ?? Infinity) >= EDGE_GAP,
      );
      for (
        let tries = 0;
        tries < SPRING_TRIES && sources.length > 0;
        tries += 1
      ) {
        const path = descend(pick(random, sources), down, new Set());
        if (path.length < MIN_RIVER) continue;
        const middle = Math.round(
          (config.riverMinWidth + config.riverMaxWidth) / 2,
        );
        const body = widen(
          path,
          middle,
          config.riverMaxWidth,
          drain,
          new Set(),
        );
        for (const cell of body) cell.wet = true;
        knownPieces.delete(cells);
        rivers.push({ path, cells: body, source: 'edge' });
        break;
      }
      continue;
    }
    // O lago da nascente também é redondo, com a largura mínima dos lagos: ele nasce
    // na metade mais alta da terra, onde o disco inteiro cabe.
    const pondSprings = land.filter(
      (cell) =>
        !cell.wet &&
        down.has(cell) &&
        drain.get(cell)! >= middle &&
        (fromWater.get(cell) ?? Infinity) >= pondReach + 2 &&
        fromBorder.get(cell)! >= pondReach + BORDER_GAP,
    );
    const withPond =
      random() < config.springLakeChance && pondSprings.length > 0;
    const sources = withPond ? pondSprings : springs;
    if (sources.length === 0) continue;
    for (let tries = 0; tries < SPRING_TRIES; tries += 1) {
      const spring = pick(random, sources);
      const pond = withPond ? disc(spring, config.lakeMinWidth, wobble) : [];
      const own = new Set(pond);
      let start: C | undefined = spring;
      while (start && own.has(start)) start = down.get(start);
      const path = descend(start, down, own);
      if (path.length < MIN_RIVER) continue;
      const body = widen(
        path,
        config.riverMinWidth,
        config.riverMaxWidth,
        drain,
        own,
      );
      if (!wetUnlessSplit(cells, [...pond, ...body])) continue;
      if (pond.length > 0) ponds.push({ cells: pond });
      rivers.push({
        path,
        cells: body,
        source: pond.length > 0 ? 'lake' : 'spring',
      });
      break;
    }
  }
  return { rivers, ponds };
}

/**
 * A largura do rio: ela vai de `from` na nascente a `to` na foz. Em volta de cada hexágono
 * da linha do meio entram os vizinhos até metade da largura, e numa largura par entra mais
 * o vizinho mais baixo. A água que já existe (mar, lago, `own`) não entra.
 */
function widen<C extends WaterCell<C>>(
  path: C[],
  from: number,
  to: number,
  drain: Map<C, number>,
  own: Set<C>,
): C[] {
  const body = new Set<C>(path);
  const free = (cell: C) => !cell.wet && !own.has(cell) && !body.has(cell);
  path.forEach((cell, index) => {
    const part = path.length > 1 ? index / (path.length - 1) : 1;
    const width = Math.max(1, Math.round(from + (to - from) * part));
    let ring = [cell];
    for (let step = 0; step < Math.floor((width - 1) / 2); step += 1) {
      const next: C[] = [];
      for (const inner of ring) {
        for (const neighbor of inner.neighbors) {
          if (free(neighbor)) {
            body.add(neighbor);
            next.push(neighbor);
          }
        }
      }
      ring = next;
    }
    if (width % 2 === 0) {
      const side = ring
        .flatMap((inner) => inner.neighbors)
        .filter(free)
        .sort((a, b) => drain.get(a)! - drain.get(b)!)[0];
      if (side) body.add(side);
    }
  });
  return [...body];
}

/** O caminho de `from` pelo `down`, até um hexágono que encosta em água de fora de `own`. */
export function descend<C extends WaterCell<C>>(
  from: C | undefined,
  down: Map<C, C>,
  own: Set<C>,
): C[] {
  const path: C[] = [];
  const inPath = new Set<C>(own);
  let cell = from;
  while (cell && !cell.wet && !inPath.has(cell)) {
    path.push(cell);
    inPath.add(cell);
    if (cell.neighbors.some((neighbor) => neighbor.wet && !own.has(neighbor))) {
      return path;
    }
    cell = down.get(cell);
  }
  if (cell?.wet && !own.has(cell)) return path;
  // Sem mar nem lago, a saída é a borda: o rio sai do mapa.
  return !cell && (path.at(-1)?.neighbors.length ?? 6) < 6 ? path : [];
}

export interface Crossing<C> {
  /** Os hexágonos de rio da linha, de margem a margem. */
  cells: C[];
  /** As duas margens da ponte; sem elas, a linha vira vau. */
  bridge?: [C, C];
}

interface Span<C> {
  cells: C[];
  banks: [C, C];
}

function stepFrom<C extends WaterCell<C>>(
  cell: C,
  q: number,
  r: number,
): C | undefined {
  return cell.neighbors.find(
    (neighbor) => neighbor.q === cell.q + q && neighbor.r === cell.r + r,
  );
}

/**
 * As linhas retas de margem a margem que passam por `cell`, uma por eixo do hexágono, só
 * por hexágonos de `river` que ainda não têm travessia, da mais curta à mais longa.
 */
function spansAt<C extends WaterCell<C>>(
  cell: C,
  river: Set<C>,
  crossed: Set<C>,
): Span<C>[] {
  const spans: Span<C>[] = [];
  for (const axis of AXES) {
    const line = [cell];
    const ends: C[] = [];
    for (const sign of [1, -1]) {
      let at: C | undefined = cell;
      for (;;) {
        at = stepFrom(at, axis.q * sign, axis.r * sign);
        if (!at || !at.wet || !river.has(at) || crossed.has(at)) break;
        line.push(at);
      }
      if (at && !at.wet) ends.push(at);
    }
    if (ends.length === 2 && line.length <= MAX_SPAN) {
      spans.push({ cells: line, banks: [ends[0]!, ends[1]!] });
    }
  }
  return spans.sort((a, b) => a.cells.length - b.cells.length);
}

/**
 * As travessias (coast-rivers/03): a cada `crossingSpacing` hexágonos da linha do meio de
 * um rio que atravessa, a linha reta mais curta de margem a margem vira ponte (se
 * `canBridge` aceita as margens e o sorteio não deu vau) ou uma fileira de vaus. Depois,
 * enquanto uma linha dessas liga a terra da chegada a uma terra que não chega até ela,
 * ela ganha mais uma travessia. A terra que só o mar ou um lago separa fica como está.
 */
export function placeCrossings<C extends WaterCell<C>>(
  rivers: River<C>[],
  lakes: Lake<C>[],
  start: C,
  canBridge: (a: C, b: C) => boolean,
  random: Random,
  config: MapConfig,
): { crossings: Crossing<C>[]; absorbed: C[] } {
  const crossings: Crossing<C>[] = [];
  const crossed = new Set<C>();
  const river = new Set(rivers.flatMap(({ cells }) => cells));
  // Para fechar um canto entre um rio e um lago, a travessia também passa pela beira do lago.
  const inland = new Set([...river, ...lakes.flatMap(({ cells }) => cells)]);
  const add = ({ cells, banks }: Span<C>) => {
    const bridge = canBridge(...banks) && random() >= config.fordShare;
    crossings.push(bridge ? { cells, bridge: banks } : { cells });
    for (const cell of cells) crossed.add(cell);
  };
  for (const { path } of rivers.filter(({ source }) => source === 'edge')) {
    const half = Math.floor(config.crossingSpacing / 2);
    for (let at = half; at < path.length; at += config.crossingSpacing) {
      for (let shift = 0; shift <= half; shift += 1) {
        const span = [path[at + shift], path[at - shift]]
          .flatMap((cell) => (cell ? spansAt(cell, river, crossed) : []))
          .sort((a, b) => a.cells.length - b.cells.length)[0];
        if (span) {
          add(span);
          break;
        }
      }
    }
  }
  for (let fix = 0; fix < MAX_FIXES; fix += 1) {
    const reached = walkable(start, crossings);
    let gap: Span<C> | undefined;
    for (const cell of inland) {
      if (crossed.has(cell)) continue;
      gap = spansAt(cell, inland, crossed).find(
        ({ banks: [a, b] }) => reached.has(a) !== reached.has(b),
      );
      if (gap) break;
    }
    if (!gap) break;
    add(gap);
  }
  return { crossings, absorbed: absorbSlivers(start, crossings, rivers) };
}

/**
 * Um pedaço de terra de menos de `MIN_PIECE` hexágonos que ficou sem caminho, entre um
 * rio e a borda do mapa, vira parte do rio: ali não cabe uma travessia reta.
 */
function absorbSlivers<C extends WaterCell<C>>(
  start: C,
  crossings: Crossing<C>[],
  rivers: River<C>[],
): C[] {
  const reached = walkable(start, crossings);
  const absorbed: C[] = [];
  const seen = new Set<C>();
  for (const river of rivers) {
    for (const cell of river.cells) {
      for (const first of cell.neighbors) {
        if (first.wet || reached.has(first) || seen.has(first)) continue;
        const piece = [first];
        seen.add(first);
        for (let index = 0; index < piece.length; index += 1) {
          for (const next of piece[index]!.neighbors) {
            if (!next.wet && !seen.has(next)) {
              seen.add(next);
              piece.push(next);
            }
          }
        }
        if (piece.length >= MIN_PIECE) continue;
        for (const sliver of piece) {
          sliver.wet = true;
          river.cells.push(sliver);
          absorbed.push(sliver);
        }
      }
    }
  }
  return absorbed;
}

/** A terra que se alcança de `start` andando, pelos vaus e pelas pontes. */
function walkable<C extends WaterCell<C>>(
  start: C,
  crossings: Crossing<C>[],
): Set<C> {
  const fords = new Set(
    crossings.filter((c) => !c.bridge).flatMap((c) => c.cells),
  );
  const links = new Map<C, C[]>();
  for (const { bridge } of crossings) {
    if (!bridge) continue;
    const [a, b] = bridge;
    links.set(a, [...(links.get(a) ?? []), b]);
    links.set(b, [...(links.get(b) ?? []), a]);
  }
  const seen = new Set<C>([start]);
  const pending = [start];
  while (pending.length > 0) {
    const cell = pending.pop()!;
    for (const next of [...cell.neighbors, ...(links.get(cell) ?? [])]) {
      if (seen.has(next) || (next.wet && !fords.has(next))) continue;
      seen.add(next);
      pending.push(next);
    }
  }
  return seen;
}
