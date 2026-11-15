-- A Praia e o Vau, quem nasce na Praia e as decorações dela como peças (.specs/coast-rivers/01-sea-and-beach.md).

INSERT INTO "ecobeasts"."biomes" ("id", "slug", "name", "description") VALUES
    (10, 'beach', 'Praia', 'Areia clara na beira do mar, com conchas e o vento salgado.'),
    (11, 'wford', 'Vau', 'Água rasa sobre o cascalho, onde dá pé para atravessar.');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."biomes"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biomes"));

INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate")
SELECT v."species_id", v."biome_id", v."rate"
FROM (VALUES
    (4, 10, 50), (12, 10, 20), (5, 10, 15), (7, 10, 10), (6, 10, 5)
) AS v ("species_id", "biome_id", "rate")
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."species" s WHERE s."id" = v."species_id");

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (91, 'shells', 'Conchas', 4),
    (92, 'starfish', 'Estrela-do-mar', 4),
    (93, 'driftwood', 'Tronco à deriva', 4),
    (94, 'beach_rock', 'Pedra de praia', 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));
