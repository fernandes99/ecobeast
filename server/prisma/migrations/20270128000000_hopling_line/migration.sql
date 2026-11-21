-- A linha do Hopling: a canguru médica, de Instinto, o primeiro Ecobeast de suporte, que evolui no nível 28 (.specs/hopling-line/01-hopling-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (31, 'hopling', 'Hopling', 'Anda com um pano na testa e um maço de ervas na mão, sempre de cara amarrada. Reclama de quem se machuca, mas não deixa ninguém sem curativo.', 2, 2, 62, 45, 0.5, 0.6, 9.0, NULL),
    (32, 'pouchmend', 'Pouchmend', 'Tem olheiras de quem nunca dorme e resmunga a cada ferida que trata. O filhote na bolsa, sempre animado, entrega as ervas antes de ela terminar a bronca.', 2, 2, 172, 30, 0.5, 1.6, 52.0, 31);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (31, 1, 13),
    (32, 1, 13);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (31, 1, 65, 1),
    (31, 2, 40, 0),
    (31, 3, 45, 0),
    (31, 4, 45, 0),
    (31, 5, 65, 0),
    (31, 6, 45, 0),
    (32, 1, 100, 2),
    (32, 2, 60, 0),
    (32, 3, 70, 0),
    (32, 4, 70, 0),
    (32, 5, 100, 0),
    (32, 6, 80, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (31, 2, 1, false),
    (32, 2, 1, false);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (31, 27, 1, 1),
    (31, 28, 1, 1),
    (31, 3, 1, 9),
    (31, 2, 1, 13),
    (32, 69, 2, 0),
    (32, 27, 1, 1),
    (32, 28, 1, 1),
    (32, 3, 1, 9),
    (32, 2, 1, 13),
    (32, 69, 1, 34);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (61, 31, 32, 1, 28);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (31, 1, 25),
    (31, 4, 20),
    (32, 1, 6),
    (32, 4, 5);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (31, 13, 150),
    (31, 19, 200),
    (32, 13, 150),
    (32, 19, 200);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (31, 1),
    (31, 3),
    (32, 1),
    (32, 3);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
