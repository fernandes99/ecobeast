-- A linha do Snekit: a serpente, a primeira com Toxina, que evolui por Vínculo mais o nível 32 (.specs/snekit-line/01-snekit-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (23, 'snekit', 'Snekit', 'Fica enrolada nas pedras quentes, olhando de lado para quem passa. Mostra a língua como quem zomba, e morde antes de qualquer aviso.', 2, 1, 58, 80, 0.5, 0.4, 2.4, NULL),
    (24, 'venomaw', 'Venomaw', 'Ergue a cabeça e abre a bocarra ao menor ruído. O veneno verde que escorre das presas queima o chão onde cai, e nenhuma criatura chega perto do ninho dela.', 2, 1, 170, 30, 0.5, 1.2, 38.0, 23);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (23, 1, 13),
    (24, 1, 13),
    (24, 2, 9);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (23, 1, 45, 0),
    (23, 2, 62, 1),
    (23, 3, 40, 0),
    (23, 4, 35, 0),
    (23, 5, 45, 0),
    (23, 6, 68, 0),
    (24, 1, 75, 0),
    (24, 2, 105, 2),
    (24, 3, 70, 0),
    (24, 4, 55, 0),
    (24, 5, 70, 0),
    (24, 6, 95, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (23, 2, 1, false),
    (24, 2, 1, false);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (23, 3, 1, 1),
    (23, 28, 1, 1),
    (23, 14, 1, 6),
    (23, 2, 1, 12),
    (24, 74, 2, 0),
    (24, 3, 1, 1),
    (24, 28, 1, 1),
    (24, 74, 1, 1),
    (24, 14, 1, 6),
    (24, 2, 1, 12),
    (24, 75, 1, 36);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level", "min_bond") VALUES
    (56, 23, 24, 3, 32, 220);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (23, 1, 35),
    (23, 4, 30),
    (23, 8, 40),
    (24, 4, 6),
    (24, 8, 10);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (23, 2),
    (23, 3),
    (24, 2),
    (24, 3);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
