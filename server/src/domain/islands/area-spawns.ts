import type { Random } from '../battle/types.js';
import { type HexCoord, hexKey } from '../exploration/hex.js';
import { type MapSpawn, pickWeighted } from '../exploration/spawns.js';
import {
  blockedKeys,
  type DraftAreaSpecies,
  type IslandDraft,
} from './island-draft.js';

export interface SpawnArea {
  tiles: HexCoord[];
  spawnCount: number;
  species: DraftAreaSpecies[];
}

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
