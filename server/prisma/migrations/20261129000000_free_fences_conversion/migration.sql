-- free-fences/04: as cercas de grade (tipo 29, town_fence) viram paredes, e o tipo sai.
-- Duas cercas vizinhas na mesma altura estão ligadas, como no HexFences de antes. O centro
-- plano de (q, r), a partir do (0, 0), é (64q + 32r, 42r).
WITH "fences" AS (
    SELECT o."id", o."island_map_id", o."q", o."r", o."variant", t."height"
    FROM "ecobeasts"."island_objects" o
    JOIN "ecobeasts"."island_tiles" t
        ON t."island_map_id" = o."island_map_id" AND t."q" = o."q" AND t."r" = o."r"
    WHERE o."object_type_id" = 29
),
"pairs" AS (
    SELECT a."island_map_id", a."id" AS "a_id", b."id" AS "b_id",
        64 * a."q" + 32 * a."r" AS "ax", 42 * a."r" AS "ay",
        64 * b."q" + 32 * b."r" AS "bx", 42 * b."r" AS "by",
        a."variant" AS "a_variant", b."variant" AS "b_variant"
    FROM "fences" a
    JOIN "fences" b
        ON b."island_map_id" = a."island_map_id" AND b."height" = a."height" AND a."id" < b."id"
        AND (b."q" - a."q", b."r" - a."r") IN ((1, -1), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1))
),
"converted" AS (
    SELECT "island_map_id", "a_id" AS "first", "b_id" AS "second", 0 AS "part", "a_variant" AS "variant",
        ARRAY["ax", "ay", "bx", "by"] AS "points"
    FROM "pairs" WHERE "a_variant" = "b_variant"
    UNION ALL
    SELECT "island_map_id", "a_id", "b_id", 0, "a_variant",
        ARRAY["ax", "ay", ("ax" + "bx") / 2, ("ay" + "by") / 2]
    FROM "pairs" WHERE "a_variant" <> "b_variant"
    UNION ALL
    SELECT "island_map_id", "a_id", "b_id", 1, "b_variant",
        ARRAY["bx", "by", ("ax" + "bx") / 2, ("ay" + "by") / 2]
    FROM "pairs" WHERE "a_variant" <> "b_variant"
    UNION ALL
    SELECT f."island_map_id", f."id", 0, 0, f."variant",
        ARRAY[64 * f."q" + 32 * f."r" - 30, 42 * f."r", 64 * f."q" + 32 * f."r" + 30, 42 * f."r"]
    FROM "fences" f
    WHERE NOT EXISTS (SELECT 1 FROM "pairs" p WHERE p."a_id" = f."id" OR p."b_id" = f."id")
)
INSERT INTO "ecobeasts"."island_walls" ("island_map_id", "wall_type_id", "position", "points")
SELECT c."island_map_id",
    (SELECT w."id" FROM "ecobeasts"."wall_types" w
        WHERE w."slug" = CASE WHEN c."variant" = 2 THEN 'stone_fence' ELSE 'wood_fence' END),
    COALESCE((SELECT MAX(e."position") FROM "ecobeasts"."island_walls" e WHERE e."island_map_id" = c."island_map_id"), -1)
        + ROW_NUMBER() OVER (PARTITION BY c."island_map_id" ORDER BY c."first", c."second", c."part"),
    c."points"
FROM "converted" c;

-- Os hexágonos de cada objeto saem junto pelo CASCADE; os do tipo também.
DELETE FROM "ecobeasts"."island_objects" WHERE "object_type_id" = 29;
DELETE FROM "ecobeasts"."map_object_types" WHERE "id" = 29;
