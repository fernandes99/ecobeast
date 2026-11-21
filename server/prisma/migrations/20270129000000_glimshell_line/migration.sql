-- A linha do Glimshell: o jabuti de cristal, de Luz, o primeiro tanque especial, que evolui nos níveis 18 e 36 (.specs/glimshell-line/01-glimshell-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (33, 'glimshell', 'Glimshell', 'Dorme quase o dia todo com o casco virado para o sol. A pedrinha das costas guarda a luz da manhã e brilha fraquinha até de noite.', 3, 2, 62, 45, 0.5, 0.35, 8.0, NULL),
    (34, 'lumoshell', 'Lumoshell', 'Anda tão devagar que os outros desistem de esperar. A luz que escapa pelas frestas do casco desvia os golpes que vêm de longe.', 3, 2, 145, 45, 0.5, 0.8, 85.0, 33),
    (35, 'prismback', 'Prismback', 'Dizem que dorme há mais tempo do que qualquer um lembra. O casco-prisma espalha arco-íris e desvia até os golpes de energia mais fortes, sem que ele abra os olhos.', 3, 2, 240, 45, 0.5, 1.3, 300.0, 34);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (33, 1, 12),
    (34, 1, 12),
    (35, 1, 12);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (33, 1, 70, 0),
    (33, 2, 35, 0),
    (33, 3, 45, 0),
    (33, 4, 50, 0),
    (33, 5, 75, 1),
    (33, 6, 30, 0),
    (34, 1, 95, 0),
    (34, 2, 45, 0),
    (34, 3, 55, 0),
    (34, 4, 65, 0),
    (34, 5, 105, 2),
    (34, 6, 35, 0),
    (35, 1, 125, 0),
    (35, 2, 55, 0),
    (35, 3, 70, 0),
    (35, 4, 90, 0),
    (35, 5, 140, 3),
    (35, 6, 45, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (33, 4, 1, false),
    (34, 4, 1, false),
    (35, 4, 1, false);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (33, 14, 1, 1),
    (33, 104, 1, 12),
    (33, 87, 1, 16),
    (34, 14, 1, 1),
    (34, 104, 1, 12),
    (34, 87, 1, 16),
    (35, 14, 1, 1),
    (35, 104, 1, 12),
    (35, 87, 1, 16);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (62, 33, 34, 1, 18),
    (63, 34, 35, 1, 36);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (33, 3, 20),
    (33, 10, 15),
    (34, 3, 6),
    (34, 10, 4),
    (35, 3, 2),
    (35, 10, 1);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (33, 20, 200),
    (33, 31, 50),
    (34, 20, 200),
    (34, 31, 50),
    (35, 20, 200),
    (35, 31, 50);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (33, 1),
    (33, 2),
    (34, 1),
    (34, 2),
    (35, 1),
    (35, 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
