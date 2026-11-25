import type {
  AppearanceCatalog,
  AppearanceInput,
} from '../appearance/appearance.js';

// Criar, editar e apagar NPCs pelo F2 (island-npcs/04).

export const MAX_NPC_NAME = 30;
export const MAX_NPC_DESCRIPTION = 200;
export const MAX_NPC_DIALOGUE = 2000;

/** O slug do nome: sem acento, minúsculo, `_` no resto e um número se já existir. */
export function npcSlug(name: string, taken: ReadonlySet<string>): string {
  const base =
    name
      .normalize('NFD')
      .replace(/[̀-ͯ]/g, '')
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '_')
      .replace(/^_+|_+$/g, '') || 'npc';
  if (!taken.has(base)) return base;
  for (let n = 2; ; n += 1) {
    const slug = `${base}_${n}`;
    if (!taken.has(slug)) return slug;
  }
}

const byId = <T extends { id: number }>(a: T, b: T) => a.id - b.id;

/**
 * A roupa com que um NPC pessoa nasce: a primeira pele, a peça de menor id que
 * serve no corpo em cada lugar obrigatório e a primeira cor que o lugar aceita.
 * `null` se o corpo não existe ou falta peça ou cor para um lugar obrigatório.
 */
export function defaultAppearance(
  bodyTypeId: number,
  catalog: AppearanceCatalog,
): AppearanceInput | null {
  const body = catalog.bodies.find(({ id }) => id === bodyTypeId);
  if (!body) return null;
  const firstPalette = (kind: string) =>
    catalog.palettes.filter((palette) => palette.kind === kind).sort(byId)[0];
  const skin = firstPalette('skin');
  if (!skin) return null;
  const parts: AppearanceInput['parts'] = [];
  for (const slot of catalog.slots
    .filter(({ required }) => required)
    .sort(byId)) {
    const part = catalog.parts
      .filter(
        ({ slotId, bodyTypeId: partBody }) =>
          slotId === slot.id &&
          (partBody === null ||
            partBody === body.id ||
            partBody === body.adultBodyTypeId),
      )
      .sort(byId)[0];
    if (!part) return null;
    let paletteId: number | null = null;
    if (slot.paletteKind !== null) {
      const palette = firstPalette(slot.paletteKind);
      if (!palette) return null;
      paletteId = palette.id;
    }
    parts.push({ partId: part.id, paletteId });
  }
  return { bodyTypeId, skinPaletteId: skin.id, parts };
}

export interface NpcUsage {
  /** Os mapas onde ele está posto, com a ilha de cada um. */
  islandMaps: { islandId: number; name: string; kind: string }[];
  interiors: string[];
  givenQuests: number;
  targetQuests: number;
  tamer: boolean;
}

/** A frase de onde o NPC está em uso, ou `null` se ele pode ser apagado. */
export function npcUsageText(usage: NpcUsage): string | null {
  const places: string[] = [];
  const islands = new Map<number, { name: string; kinds: Set<string> }>();
  for (const { islandId, name, kind } of usage.islandMaps) {
    const island = islands.get(islandId) ?? { name, kinds: new Set<string>() };
    island.kinds.add(kind);
    islands.set(islandId, island);
  }
  for (const { name, kinds } of islands.values()) {
    const labels = ['draft', 'published']
      .filter((kind) => kinds.has(kind))
      .map((kind) => (kind === 'draft' ? 'rascunho' : 'publicada'));
    places.push(`posto em ${name} (${labels.join(' e ')})`);
  }
  for (const name of new Set(usage.interiors)) {
    places.push(`na sala ${name}`);
  }
  if (usage.givenQuests > 0) {
    places.push(
      `dá ${usage.givenQuests} ${usage.givenQuests === 1 ? 'missão' : 'missões'}`,
    );
  }
  if (usage.targetQuests > 0) {
    places.push(
      `é o alvo de ${usage.targetQuests} ${usage.targetQuests === 1 ? 'missão' : 'missões'}`,
    );
  }
  if (usage.tamer) places.push('é Domador de uma ilha');
  if (places.length === 0) return null;
  return `Esse NPC está em uso: ${places.join('; ')}. Tire-o de lá antes de excluir.`;
}
