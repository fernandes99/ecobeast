-- A Geleira, o bioma raro de gelo, com a zona Comum, o Lago gelado e quem nasce nela (.specs/glacier/03-glacier-records.md).
-- O id 11 foi do Vau, que saiu (map-realism/02); ids não se reaproveitam.

INSERT INTO "ecobeasts"."biomes" ("id", "slug", "name", "description") VALUES
    (12, 'glacier', 'Geleira', 'Chão de gelo liso e duro, onde até a neve escorrega.');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."biomes"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biomes"));

-- O Lago gelado tem o share 0, como o Lago: o gerador põe a zona pelo lago da Geleira, não por faixa.
INSERT INTO "ecobeasts"."biome_zones" ("id", "slug", "biome_id", "name", "share", "sort_order") VALUES
    (35, 'glacier', 12, 'Comum', 100, 1),
    (36, 'wshallow_ice_lake', 6, 'Lago gelado', 0, 6),
    (37, 'wdeep_ice_lake', 7, 'Lago gelado', 0, 6);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."biome_zones"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biome_zones"));

-- O Hushling e o Echofrost, com 30% das taxas da Neve (100 e 30). Só as espécies que existem.
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate")
SELECT v."species_id", v."biome_id", v."rate"
FROM (VALUES (10, 12, 30), (11, 12, 10)) AS v ("species_id", "biome_id", "rate")
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."species" s WHERE s."id" = v."species_id");
