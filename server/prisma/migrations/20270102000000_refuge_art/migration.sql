-- O prédio do Refúgio refeito da imagem do dono, em 8 cores, com o bloqueio no pé e as luzes novas (.specs/refuge-art/01-refuge-art.md).

UPDATE "ecobeasts"."prop_types" SET "variants" = 8 WHERE "id" = 22;

UPDATE "ecobeasts"."prop_type_blocks"
SET "points" = ARRAY[-88, -50, -58, -50, -58, -13, -34, -13, -34, -3, 34, -3, 34, -44, 88, -44, 88, -86, -88, -86]
WHERE "id" = 1;

UPDATE "ecobeasts"."prop_type_lights" SET "x" = -71, "y" = -63, "radius" = 9, "color" = 'ffcf70' WHERE "id" = 3;
UPDATE "ecobeasts"."prop_type_lights" SET "x" = -47, "y" = -63, "radius" = 9, "color" = 'ffcf70' WHERE "id" = 4;
UPDATE "ecobeasts"."prop_type_lights" SET "x" = 47, "y" = -63, "radius" = 9, "color" = 'ffcf70' WHERE "id" = 5;
UPDATE "ecobeasts"."prop_type_lights" SET "x" = 69, "y" = -63, "radius" = 9, "color" = 'ffcf70' WHERE "id" = 6;
UPDATE "ecobeasts"."prop_type_lights" SET "x" = -15, "y" = -27, "radius" = 18, "color" = 'ffd890' WHERE "id" = 7;
INSERT INTO "ecobeasts"."prop_type_lights" ("id", "prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (149, 22, 0, 5, 14, -27, 18, 'ffd890');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
