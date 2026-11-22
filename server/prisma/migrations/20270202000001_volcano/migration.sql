-- O Vulcão, a Lava rasa e a Lava funda, com a zona Comum de cada um e a linha do Ruvo no Vulcão (.specs/volcano/03-volcano-records.md).
-- Ninguém nasce na lava: ela bloqueia o andar, como a água.

INSERT INTO "ecobeasts"."biomes" ("id", "slug", "name", "description") VALUES
    (13, 'volcano', 'Vulcão', 'Rocha escura e quente, que ainda guarda o fogo de baixo da terra.'),
    (14, 'lshallow', 'Lava rasa', 'Rocha derretida que escorre devagar e brilha no escuro.'),
    (15, 'ldeep', 'Lava funda', 'O coração do vulcão, quente demais para chegar perto.');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."biomes"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biomes"));

INSERT INTO "ecobeasts"."biome_zones" ("id", "slug", "biome_id", "name", "share", "sort_order") VALUES
    (38, 'volcano', 13, 'Comum', 100, 1),
    (39, 'lshallow', 14, 'Comum', 100, 1),
    (40, 'ldeep', 15, 'Comum', 100, 1);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."biome_zones"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biome_zones"));

-- A linha do Ruvo, o Ruvaroth um pouco mais comum que na Montanha. Só as espécies que existem.
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate")
SELECT v."species_id", v."biome_id", v."rate"
FROM (VALUES (1, 13, 20), (2, 13, 30), (3, 13, 15)) AS v ("species_id", "biome_id", "rate")
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."species" s WHERE s."id" = v."species_id");
