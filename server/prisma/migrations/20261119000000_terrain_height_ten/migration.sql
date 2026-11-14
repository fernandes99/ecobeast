-- A altura do terreno vai de 0 a 10 (terrain-height/02).
ALTER TABLE "ecobeasts"."island_tiles" DROP CONSTRAINT "island_tiles_height_check";
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_height_check" CHECK ("height" BETWEEN 0 AND 10);
