-- A dureza de cada chão e os 4 tipos novos (.specs/free-trails/01-ground-types.md).

ALTER TABLE "ecobeasts"."ground_types" ADD COLUMN "hardness" SMALLINT;
UPDATE "ecobeasts"."ground_types" SET "hardness" = CASE "slug"
  WHEN 'stone_trail' THEN 3
  WHEN 'cobble_floor' THEN 3
  ELSE 1
END;
ALTER TABLE "ecobeasts"."ground_types" ALTER COLUMN "hardness" SET NOT NULL;
ALTER TABLE "ecobeasts"."ground_types" ADD CONSTRAINT "ground_types_hardness_check" CHECK ("hardness" BETWEEN 1 AND 3);

INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind", "hardness") VALUES
  (5, 'gravel_trail', 'Cascalho', 'trail', 2),
  (6, 'stepping_stones', 'Pisantes', 'trail', 3),
  (7, 'sand_trail', 'Areia batida', 'trail', 1),
  (8, 'worn_trail', 'Trilha gasta', 'trail', 1);
SELECT setval('"ecobeasts"."ground_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."ground_types"));
