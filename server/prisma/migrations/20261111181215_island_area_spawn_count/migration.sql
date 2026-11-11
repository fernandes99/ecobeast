-- AlterTable: as áreas que já existem ficam com 10 (islands/01)
ALTER TABLE "ecobeasts"."island_areas" ADD COLUMN     "spawn_count" INTEGER NOT NULL DEFAULT 10;

-- CHECK escrito à mão (islands/01)
ALTER TABLE "ecobeasts"."island_areas" ADD CONSTRAINT "island_areas_spawn_count_check" CHECK ("spawn_count" BETWEEN 1 AND 200);
