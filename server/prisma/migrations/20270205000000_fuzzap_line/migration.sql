-- A linha do Fuzzap: o lêmingue de estática, de Volt com o Gelo na forma final, o primeiro de controle, que evolui no nível 24 (.specs/fuzzap-line/01-fuzzap-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (41, 'fuzzap', 'Fuzzap', 'Rola na neve até o pelo ficar cheio de estática. Assusta-se com qualquer barulho e solta um choque sem querer, e aí fica mais assustado ainda com o próprio choque.', 1, 1, 52, 75, 0.5, 0.25, 1.5, NULL),
    (42, 'blizzvolt', 'Blizzvolt', 'O medo virou vigília: não tira os olhos de quem chega perto. A cauda de cristal guarda a tempestade, e o pelo solta raios quando alguém dá um passo a mais.', 1, 1, 165, 35, 0.5, 0.9, 45.0, 41);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (41, 1, 4),
    (42, 1, 4),
    (42, 2, 7);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (41, 1, 50, 0),
    (41, 2, 50, 0),
    (41, 3, 45, 0),
    (41, 4, 45, 0),
    (41, 5, 50, 0),
    (41, 6, 60, 1),
    (42, 1, 85, 0),
    (42, 2, 80, 0),
    (42, 3, 75, 0),
    (42, 4, 70, 0),
    (42, 5, 85, 0),
    (42, 6, 85, 2);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (41, 6, 1, false),
    (41, 2, 3, true),
    (42, 6, 1, false),
    (42, 2, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (41, 39, 1, 1),
    (41, 40, 1, 6),
    (41, 91, 1, 14),
    (42, 39, 1, 1),
    (42, 40, 1, 6),
    (42, 91, 1, 14),
    (42, 64, 1, 30);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (67, 41, 42, 1, 24);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (41, 5, 10),
    (41, 9, 40),
    (41, 12, 20),
    (42, 5, 3),
    (42, 9, 10),
    (42, 12, 6);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (41, 23, 200),
    (41, 24, 50),
    (42, 23, 200),
    (42, 24, 50);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (41, 1),
    (41, 3),
    (41, 4),
    (42, 1),
    (42, 3),
    (42, 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
