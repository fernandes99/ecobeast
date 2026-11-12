-- Vegetação, casas e santuários novos, sem a casa na árvore
-- (.specs/island-villages/04-plants-and-animations.md). Depois dela, rode
-- prisma/recompute-island-hashes.ts.

-- A Vegetação põe as plantas do terreno num hexágono, sem bloquear.
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (20, 'plants', 'Vegetação', 10);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (20, 0, 0, false);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));

-- A casa na árvore sai das ilhas.
DELETE FROM "ecobeasts"."island_objects" WHERE "object_type_id" = 14;
DELETE FROM "ecobeasts"."map_object_types" WHERE "id" = 14;

-- Mais variantes.
UPDATE "ecobeasts"."map_object_types" SET "variants" = 4 WHERE "id" = 17;
UPDATE "ecobeasts"."map_object_types" SET "variants" = 11 WHERE "id" = 18;
UPDATE "ecobeasts"."map_object_types" SET "variants" = 10 WHERE "id" = 19;
