-- A linha do Veilmoth: a mariposa gêmea, a primeira de Arcano, Épica e só da Noite, que evolui no nível 32 (.specs/veilmoth-line/01-veilmoth-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (36, 'veilmoth', 'Veilmoth', 'Só sai à noite e nunca se afasta do bando. Quando fecha as asas, se desfaz em pó violeta e aparece junto de uma irmã, onde quer que ela esteja.', 3, 4, 70, 25, 0.5, 0.5, 0.4, NULL),
    (37, 'gatemoth', 'Gatemoth', 'Os olhos das asas são portais abertos para outros lugares. Diz-se que os antigos guardavam um em cada altar, para que as ilhas nunca ficassem longe umas das outras.', 3, 4, 230, 15, 0.5, 1.4, 6.0, 36);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (36, 1, 14),
    (37, 1, 14),
    (37, 2, 15);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (36, 1, 50, 0),
    (36, 2, 30, 0),
    (36, 3, 40, 0),
    (36, 4, 70, 0),
    (36, 5, 60, 0),
    (36, 6, 80, 1),
    (37, 1, 80, 0),
    (37, 2, 45, 0),
    (37, 3, 60, 0),
    (37, 4, 115, 2),
    (37, 5, 100, 0),
    (37, 6, 120, 1);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (36, 6, 1, false),
    (37, 6, 1, false);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (36, 3, 1, 1),
    (36, 78, 1, 14),
    (37, 3, 1, 1),
    (37, 78, 1, 14);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (64, 36, 37, 1, 32);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (36, 2, 10),
    (36, 4, 5),
    (37, 2, 2),
    (37, 4, 1);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (36, 16, 200),
    (37, 16, 200);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (36, 4),
    (37, 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
