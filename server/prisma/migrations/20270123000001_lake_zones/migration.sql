-- A água doce (os lagos e os rios do mapa sorteado) ganha a zona Lago, sem algas (.specs/sea-life/07-lakes-and-trash.md).
-- O share é 0: o gerador põe a zona pela água doce, não por faixa.

INSERT INTO "ecobeasts"."biome_zones" ("id", "slug", "biome_id", "name", "share", "sort_order") VALUES
    (33, 'wshallow_lake', 6, 'Lago', 0, 5),
    (34, 'wdeep_lake', 7, 'Lago', 0, 5);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."biome_zones"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biome_zones"));
