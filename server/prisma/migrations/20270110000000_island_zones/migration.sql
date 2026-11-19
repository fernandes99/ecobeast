-- A zona de cada hexágono das ilhas; nulo é a Comum (.specs/biome-zones/03-island-zones.md).

ALTER TABLE "ecobeasts"."island_tiles" ADD COLUMN "biome_zone_id" INTEGER;

CREATE INDEX "island_tiles_biome_zone_id_idx" ON "ecobeasts"."island_tiles"("biome_zone_id");

ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_biome_zone_id_fkey" FOREIGN KEY ("biome_zone_id") REFERENCES "ecobeasts"."biome_zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
