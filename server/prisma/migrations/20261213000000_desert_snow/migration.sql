-- Os biomas Deserto e Neve e quem nasce neles (.specs/desert-snow/01-biome-records.md).

INSERT INTO "ecobeasts"."biomes" ("id", "slug", "name", "description") VALUES
    (8, 'desert', 'Deserto', 'Areia solta, sol forte e pouca sombra.'),
    (9, 'snow', 'Neve', 'Chão coberto de neve, frio o ano inteiro.');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."biomes"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biomes"));

-- Só as espécies que existem: a carga inicial tem as 9 primeiras, e o banco tem mais.
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate")
SELECT v."species_id", v."biome_id", v."rate"
FROM (VALUES
    (12, 8, 50), (1, 8, 40), (2, 8, 30), (13, 8, 30), (3, 8, 10), (14, 8, 5), (7, 8, 5),
    (10, 9, 100), (11, 9, 30), (4, 9, 10), (5, 9, 5)
) AS v ("species_id", "biome_id", "rate")
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."species" s WHERE s."id" = v."species_id");
