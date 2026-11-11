import type { Random } from '../battle/types.js';
import { type HexCoord, hexKey } from '../exploration/hex.js';
import { type MapSpawn, pickWeighted } from '../exploration/spawns.js';
import {
  blockedKeys,
  type DraftAreaSpecies,
  type IslandDraft,
} from './island-draft.js';

/**
 * Os Ecobeasts de uma ilha, sorteados pelas áreas que o dono pintou
 * (.specs/islands/02-island-exploration.md, RF-08 a RF-11).
 */

/** Uma área pronta para o sorteio: os hexágonos já vêm sem os de ação e os bloqueados. */
export interface SpawnArea {
  tiles: HexCoord[];
  spawnCount: number;
  species: DraftAreaSpecies[];
}

/** As áreas do rascunho, na ordem da `key`, cada uma sem os hexágonos de ação e os bloqueados. */
export function spawnAreas(
  draft: Pick<IslandDraft, 'tiles' | 'actions' | 'objects' | 'areas'>,
): SpawnArea[] {
  const blocked = blockedKeys(draft);
  const built = new Set([
    ...draft.actions.flatMap(({ tiles }) => tiles.map(hexKey)),
    ...blocked,
  ]);
  return [...draft.areas]
    .sort((a, b) => a.key - b.key)
    .map(({ key, spawnCount, species }) => ({
      tiles: draft.tiles
        .filter((tile) => tile.area === key && !built.has(hexKey(tile)))
        .map(({ q, r }) => ({ q, r })),
      spawnCount,
      species,
    }));
}

/**
 * Em cada área com hexágono e espécie, `spawnCount` Ecobeasts: o hexágono de
 * forma uniforme (podendo repetir), a espécie pelo peso e o nível de forma
 * uniforme entre o mínimo e o máximo dela. Ids de 1 em diante.
 */
export function rollAreaSpawns(areas: SpawnArea[], random: Random): MapSpawn[] {
  const spawns: MapSpawn[] = [];
  for (const { tiles, spawnCount, species } of areas) {
    if (tiles.length === 0 || species.length === 0) continue;
    for (let index = 0; index < spawnCount; index++) {
      const tile = tiles[Math.floor(random() * tiles.length)]!;
      const { speciesId, minLevel, maxLevel } = pickWeighted(species, random);
      const level = minLevel + Math.floor(random() * (maxLevel - minLevel + 1));
      spawns.push({
        id: spawns.length + 1,
        speciesId,
        level,
        q: tile.q,
        r: tile.r,
      });
    }
  }
  return spawns;
}
