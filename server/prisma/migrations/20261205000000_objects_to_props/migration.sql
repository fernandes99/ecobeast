-- free-objects/04: os objetos de grade viram peças soltas, e as tabelas deles saem.
-- O centro plano de (q, r) é (64q + 32r + 32, 42r + 29); o pé de um objeto é a média
-- dos x dos centros dos hexágonos dele e o maior y mais 29, como no MapObjectSprite.

-- 1. Os tipos: os mesmos slug, nome e variantes, com ids novos.
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants")
SELECT CASE "id" WHEN 21 THEN 22 WHEN 22 THEN 23 WHEN 24 THEN 24 WHEN 25 THEN 25 WHEN 26 THEN 26 WHEN 41 THEN 27 END,
    "slug", "name", "variants"
FROM "ecobeasts"."map_object_types"
WHERE "id" IN (21, 22, 24, 25, 26, 41);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

-- 2. O bloqueio dos tipos: o contorno dos hexágonos do formato, 4 px para dentro, a partir do pé.
INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "position", "closed", "points") VALUES
    (22, 0, true, ARRAY[0, -20, -32, -4, -60, -18, -60, -40, -28, -56, -28, -82, 0, -96, 28, -82, 28, -56, 60, -40, 60, -18, 32, -4]),
    (23, 0, true, ARRAY[0, -20, -32, -4, -60, -18, -60, -40, -28, -56, -28, -82, 0, -96, 28, -82, 28, -56, 60, -40, 60, -18, 32, -4]),
    (24, 0, true, ARRAY[0, -54, 28, -40, 28, -18, 0, -4, -28, -18, -28, -40]),
    (25, 0, true, ARRAY[-32, -54, 0, -38, 32, -54, 60, -40, 60, -18, 32, -4, 0, -20, -32, -4, -60, -18, -60, -40]),
    (26, 0, true, ARRAY[0, -20, -32, -4, -60, -18, -60, -40, -28, -56, -28, -82, 0, -96, 28, -82, 28, -56, 60, -40, 60, -18, 32, -4]),
    (27, 0, true, ARRAY[0, -20, -32, -4, -60, -18, -60, -40, -28, -56, -28, -82, 0, -96, 28, -82, 28, -56, 60, -40, 60, -18, 32, -4]);

-- 3. As peças: o pé de cada objeto, o hexágono dele pela conta do grid_coord e a ação
-- que ficava embaixo dele (a com mais hexágonos ali).
CREATE TEMP TABLE "converted" AS
WITH "feet" AS (
    SELECT o."id", o."island_map_id", o."object_type_id", o."variant", o."mirrored",
        ROUND(AVG(64 * t."q" + 32 * t."r" + 32))::int AS "fx",
        MAX(42 * t."r" + 29) + 29 AS "fy"
    FROM "ecobeasts"."island_objects" o
    JOIN "ecobeasts"."island_object_tiles" t ON t."object_id" = o."id"
    GROUP BY o."id"
),
"cells" AS (
    SELECT f.*, FLOOR(f."fy" / 42.0)::int AS "r0",
        f."fy" - FLOOR(f."fy" / 42.0)::int * 42 AS "ir",
        f."fx" - 32 * FLOOR(f."fy" / 42.0)::int AS "x"
    FROM "feet" f
),
"columns" AS (
    SELECT c.*, FLOOR(c."x" / 64.0)::int AS "q0", c."x" - FLOOR(c."x" / 64.0)::int * 64 AS "ic"
    FROM "cells" c
),
"hexes" AS (
    SELECT c.*,
        CASE WHEN c."ic" < 32 AND c."ir" < 16 - c."ic" / 2.0 THEN c."q0"
             WHEN c."ic" >= 32 AND c."ir" < (c."ic" - 32) / 2.0 THEN c."q0" + 1
             ELSE c."q0" END AS "q",
        CASE WHEN c."ic" < 32 AND c."ir" < 16 - c."ic" / 2.0 THEN c."r0" - 1
             WHEN c."ic" >= 32 AND c."ir" < (c."ic" - 32) / 2.0 THEN c."r0" - 1
             ELSE c."r0" END AS "r"
    FROM "columns" c
)
SELECT h."id" AS "object_id", h."island_map_id",
    CASE h."object_type_id" WHEN 21 THEN 22 WHEN 22 THEN 23 WHEN 24 THEN 24 WHEN 25 THEN 25 WHEN 26 THEN 26 WHEN 41 THEN 27 END AS "prop_type_id",
    h."q", h."r",
    h."fx" - (64 * h."q" + 32 * h."r" + 32) AS "dx",
    h."fy" - (42 * h."r" + 29) AS "dy",
    h."variant", h."mirrored",
    (SELECT a."action_type_id"
     FROM "ecobeasts"."island_action_tiles" at
     JOIN "ecobeasts"."island_actions" a ON a."id" = at."action_id"
     JOIN "ecobeasts"."island_object_tiles" ot
        ON ot."object_id" = h."id" AND ot."q" = at."q" AND ot."r" = at."r"
     WHERE at."island_map_id" = h."island_map_id"
     GROUP BY a."id", a."action_type_id"
     ORDER BY COUNT(*) DESC, a."id"
     LIMIT 1) AS "action_type_id"
FROM "hexes" h;

INSERT INTO "ecobeasts"."island_props"
    ("island_map_id", "prop_type_id", "q", "r", "dx", "dy", "variant", "mirrored", "custom_block", "action_type_id")
SELECT "island_map_id", "prop_type_id", "q", "r", "dx", "dy", "variant", "mirrored", false, "action_type_id"
FROM "converted";

-- 4. As ações embaixo dos objetos saem desses hexágonos; a que fica sem nenhum sai.
DELETE FROM "ecobeasts"."island_action_tiles" at
USING "ecobeasts"."island_object_tiles" ot
WHERE ot."island_map_id" = at."island_map_id" AND ot."q" = at."q" AND ot."r" = at."r";
DELETE FROM "ecobeasts"."island_actions" a
WHERE NOT EXISTS (SELECT 1 FROM "ecobeasts"."island_action_tiles" at WHERE at."action_id" = a."id");

-- 5. Os hexágonos dos objetos não tinham decorações sorteadas, e continuam sem.
UPDATE "ecobeasts"."island_tiles" t SET "bare" = true
FROM "ecobeasts"."island_object_tiles" ot
WHERE ot."island_map_id" = t."island_map_id" AND ot."q" = t."q" AND ot."r" = t."r";

-- 6. As tabelas dos objetos saem.
DROP TABLE "ecobeasts"."island_object_tiles";
DROP TABLE "ecobeasts"."island_objects";
DROP TABLE "ecobeasts"."map_object_type_tiles";
DROP TABLE "ecobeasts"."map_object_types";
