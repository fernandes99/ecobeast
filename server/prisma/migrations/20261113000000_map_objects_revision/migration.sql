-- Revisão dos objetos das ilhas (.specs/island-villages/03-map-objects.md, "Revisão: casas,
-- árvores, pedras e hortas"). Depois dela, rode prisma/recompute-island-hashes.ts.

-- Casas de 2 e 3 hexágonos.
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (18, 'house_medium', 'Casa média', 6);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (19, 'house_large', 'Casa grande', 5);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (18, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (18, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (19, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (19, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (19, 1, -1, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));

-- A casa com horta vira casa média, que tem o mesmo formato.
UPDATE "ecobeasts"."island_objects" SET "object_type_id" = 18, "variant" = LEAST("variant", 6) WHERE "object_type_id" = 2;

-- O castelo, a ponte e o ninho saem das ilhas.
DELETE FROM "ecobeasts"."island_objects" WHERE "object_type_id" IN (4, 12, 15);
DELETE FROM "ecobeasts"."map_object_types" WHERE "id" IN (2, 4, 12, 15);

-- A árvore e a pedra passam a ocupar 1 hexágono: fica só o de apoio.
DELETE FROM "ecobeasts"."island_object_tiles" AS tile
USING "ecobeasts"."island_objects" AS object
WHERE tile."object_id" = object."id"
  AND object."object_type_id" IN (5, 6)
  AND (tile."q", tile."r") <> (object."q", object."r");
DELETE FROM "ecobeasts"."map_object_type_tiles" WHERE "object_type_id" IN (5, 6) AND ("dq", "dr") <> (0, 0);
UPDATE "ecobeasts"."map_object_types" SET "slug" = 'tree', "name" = 'Árvore', "variants" = 8 WHERE "id" = 5;
UPDATE "ecobeasts"."map_object_types" SET "slug" = 'rock', "name" = 'Pedra', "variants" = 6 WHERE "id" = 6;

-- Mais variantes.
UPDATE "ecobeasts"."map_object_types" SET "variants" = 9 WHERE "id" = 1;
UPDATE "ecobeasts"."map_object_types" SET "variants" = 6 WHERE "id" = 7;
