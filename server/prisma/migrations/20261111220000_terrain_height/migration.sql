-- A forma vira bioma e altura (.specs/terrain-height/01, RF-05 e RF-06).
ALTER TABLE "ecobeasts"."island_tiles" ADD COLUMN "height" INTEGER;

UPDATE "ecobeasts"."island_tiles" AS t
SET "height" = CASE
    WHEN t."shape" = 'mont' THEN 4
    WHEN b."slug" = 'stone' THEN 3
    WHEN t."shape" = 'hill' THEN 2
    WHEN b."slug" IN ('wshallow', 'wdeep') THEN 0
    ELSE 1
  END
FROM "ecobeasts"."biomes" AS b
WHERE b."id" = t."biome_id";

UPDATE "ecobeasts"."island_tiles"
SET "biome_id" = (SELECT "id" FROM "ecobeasts"."biomes" WHERE "slug" = 'mountain')
WHERE "shape" = 'mont';

UPDATE "ecobeasts"."island_tiles"
SET "biome_id" = (SELECT "id" FROM "ecobeasts"."biomes" WHERE "slug" = 'hill')
WHERE "shape" = 'hill';

ALTER TABLE "ecobeasts"."island_tiles" ALTER COLUMN "height" SET NOT NULL;

ALTER TABLE "ecobeasts"."island_tiles" DROP CONSTRAINT "island_tiles_variant_check";
ALTER TABLE "ecobeasts"."island_tiles" DROP CONSTRAINT "island_tiles_shape_check";
ALTER TABLE "ecobeasts"."island_tiles" DROP COLUMN "shape";

-- Restrições escritas à mão: o Prisma não as acompanha (terrain-height/01).
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_height_check" CHECK ("height" BETWEEN 0 AND 4);
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_variant_check" CHECK ("variant" BETWEEN 1 AND 6);
