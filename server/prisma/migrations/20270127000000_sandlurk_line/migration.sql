-- A linha do Sandlurk: o escorpião enterrado, Inseto/Toxina, que evolui no nível 30 (.specs/sandlurk-line/01-sandlurk-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (29, 'sandlurk', 'Sandlurk', 'Passa dias enterrado na duna, só com os olhos de fora, sempre com cara de tédio. Não se dá ao trabalho de fugir: espera quem pisa perto demais e belisca sem nem levantar.', 2, 2, 60, 45, 0.5, 0.4, 6.0, NULL),
    (30, 'dunestrike', 'Dunestrike', 'Fica imóvel sob a areia quente por horas, até a presa entrar no alcance do ferrão. O bote é um só, lento de esperar e rápido demais para ver, e o veneno amarelo deixa a vítima dura no lugar.', 2, 2, 175, 25, 0.5, 1.1, 85.0, 29);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (29, 1, 15),
    (29, 2, 9),
    (30, 1, 15),
    (30, 2, 9);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (29, 1, 50, 0),
    (29, 2, 60, 0),
    (29, 3, 75, 1),
    (29, 4, 25, 0),
    (29, 5, 50, 0),
    (29, 6, 40, 0),
    (30, 1, 85, 0),
    (30, 2, 105, 0),
    (30, 3, 125, 2),
    (30, 4, 35, 0),
    (30, 5, 80, 0),
    (30, 6, 55, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (29, 4, 1, false),
    (30, 4, 1, false);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (29, 14, 1, 1),
    (29, 28, 1, 1),
    (29, 47, 1, 5),
    (29, 74, 1, 13),
    (29, 96, 1, 21),
    (30, 14, 1, 1),
    (30, 28, 1, 1),
    (30, 47, 1, 5),
    (30, 74, 1, 13),
    (30, 96, 1, 21),
    (30, 72, 1, 34),
    (30, 75, 1, 42);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (60, 29, 30, 1, 30);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (29, 8, 30),
    (29, 10, 12),
    (30, 8, 8),
    (30, 10, 3);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (29, 21, 200),
    (29, 22, 50),
    (30, 21, 200),
    (30, 22, 50);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (29, 1),
    (29, 2),
    (30, 1),
    (30, 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
