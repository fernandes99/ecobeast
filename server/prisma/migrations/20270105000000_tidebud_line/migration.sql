-- A linha do Tidebud: o cavalo-marinho de folhas e raios, a primeira de Volt (.specs/tidebud-line/01-tidebud-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (17, 'tidebud', 'Tidebud', 'Se esconde entre as algas com a cauda enrolada num talo. Quando se assusta, a crista solta uma faísca azul.', 2, 3, 62, 45, 0.5, 0.4, 1.8, NULL),
    (18, 'kelpcoil', 'Kelpcoil', 'As veias douradas guardam a eletricidade da água. Nas noites de tempestade, os cristais das costas acendem um a um.', 2, 3, 142, 45, 0.5, 1.1, 12.0, 17),
    (19, 'tempestide', 'Tempestide', 'Onde ele sobe à superfície, o mar fica revolto e os raios correm pelas folhas. Os marinheiros contam que ele chama a chuva.', 2, 3, 236, 45, 0.5, 2.0, 48.0, 18);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (17, 1, 2),
    (18, 1, 2),
    (18, 2, 4),
    (19, 1, 2),
    (19, 2, 4);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (17, 1, 44, 0),
    (17, 2, 36, 0),
    (17, 3, 40, 0),
    (17, 4, 65, 1),
    (17, 5, 55, 0),
    (17, 6, 75, 0),
    (18, 1, 58, 0),
    (18, 2, 48, 0),
    (18, 3, 52, 0),
    (18, 4, 88, 2),
    (18, 5, 72, 0),
    (18, 6, 102, 0),
    (19, 1, 76, 0),
    (19, 2, 60, 0),
    (19, 3, 66, 0),
    (19, 4, 115, 3),
    (19, 5, 90, 0),
    (19, 6, 123, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (17, 3, 1, false),
    (17, 2, 3, true),
    (18, 3, 1, false),
    (18, 2, 3, true),
    (19, 3, 1, false),
    (19, 2, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (17, 3, 1, 1),
    (17, 28, 1, 1),
    (17, 16, 1, 5),
    (17, 17, 1, 9),
    (17, 32, 1, 13),
    (17, 31, 1, 17),
    (17, 21, 1, 22),
    (17, 22, 1, 28),
    (17, 34, 1, 34),
    (18, 3, 1, 1),
    (18, 28, 1, 1),
    (18, 16, 1, 5),
    (18, 17, 1, 9),
    (18, 32, 1, 13),
    (18, 31, 1, 17),
    (18, 21, 1, 22),
    (18, 22, 1, 28),
    (18, 34, 1, 34),
    (18, 26, 1, 50),
    (19, 3, 1, 1),
    (19, 28, 1, 1),
    (19, 16, 1, 5),
    (19, 17, 1, 9),
    (19, 32, 1, 13),
    (19, 31, 1, 17),
    (19, 21, 1, 22),
    (19, 22, 1, 28),
    (19, 34, 1, 34),
    (19, 26, 1, 44);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (52, 17, 18, 1, 18),
    (53, 18, 19, 1, 38);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (17, 6, 15),
    (17, 11, 20),
    (17, 10, 10),
    (18, 6, 6),
    (18, 7, 4),
    (18, 11, 8),
    (18, 10, 3),
    (19, 6, 1),
    (19, 7, 3);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (17, 3),
    (17, 4),
    (18, 3),
    (18, 4),
    (19, 1),
    (19, 2),
    (19, 3),
    (19, 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
