-- Só ficam a ponte de corda e a de madeira, e cada ponte ganha a largura do piso
-- (.specs/bridges/01-bridge-records.md). Os ids que ficam não mudam.

DELETE FROM "ecobeasts"."island_bridges" WHERE "bridge_type_id" IN (1, 2, 3, 6, 7, 8);
DELETE FROM "ecobeasts"."bridge_types" WHERE "id" IN (1, 2, 3, 6, 7, 8);

ALTER TABLE "ecobeasts"."island_bridges" ADD COLUMN "width" INTEGER NOT NULL DEFAULT 28;
ALTER TABLE "ecobeasts"."island_bridges" ADD CONSTRAINT "island_bridges_width_check" CHECK ("width" BETWEEN 16 AND 64);
