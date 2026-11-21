-- As zonas da Água rasa e da Água profunda, com quem nasce mais ou menos nelas (.specs/sea-life/02-sea-zones.md).

UPDATE "ecobeasts"."biome_zones" SET "share" = 50, "sort_order" = 2 WHERE "id" IN (6, 7);

INSERT INTO "ecobeasts"."biome_zones" ("id", "slug", "biome_id", "name", "share", "sort_order") VALUES
    (25, 'wshallow_rocks', 6, 'Pedras rasas', 21, 1),
    (26, 'wshallow_seagrass', 6, 'Algal', 21, 3),
    (27, 'wshallow_trash', 6, 'Lixo', 8, 4),
    (28, 'wdeep_rocks', 7, 'Rochedo', 21, 1),
    (29, 'wdeep_kelp', 7, 'Floresta de algas', 21, 3),
    (30, 'wdeep_trash', 7, 'Lixo', 8, 4);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."biome_zones"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biome_zones"));

INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent")
SELECT "v"."species_id", "v"."biome_zone_id", "v"."rate_percent"
FROM (VALUES
    (4, 26, 150), (5, 26, 150), (17, 26, 150), (18, 26, 150),
    (4, 29, 150), (5, 29, 150), (17, 29, 150), (18, 29, 150),
    (6, 28, 150),
    (4, 27, 50), (5, 27, 50), (6, 27, 50), (17, 27, 50), (18, 27, 50), (19, 27, 50),
    (4, 30, 50), (5, 30, 50), (6, 30, 50), (17, 30, 50), (18, 30, 50), (19, 30, 50)
) AS "v" ("species_id", "biome_zone_id", "rate_percent")
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."species" "s" WHERE "s"."id" = "v"."species_id");
