-- map-realism/02: o bioma Vau (id 11) sai do jogo; os rios do mapa sorteado só se atravessam por ponte.
DELETE FROM "ecobeasts"."species_biome_zones"
WHERE "biome_zone_id" IN (SELECT "id" FROM "ecobeasts"."biome_zones" WHERE "biome_id" = 11);
DELETE FROM "ecobeasts"."species_biomes" WHERE "biome_id" = 11;
UPDATE "ecobeasts"."island_tiles" SET "biome_id" = 6, "biome_zone_id" = NULL WHERE "biome_id" = 11;
DELETE FROM "ecobeasts"."biome_zones" WHERE "biome_id" = 11;
DELETE FROM "ecobeasts"."biomes" WHERE "id" = 11;
