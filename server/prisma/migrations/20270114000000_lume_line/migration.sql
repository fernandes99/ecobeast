-- A linha do Lume: a coruja da noite, a primeira de Sombra pura (.specs/lume-line/01-lume-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (20, 'lume', 'Lume', 'Passa o dia dormindo no oco de uma árvore. À noite, os olhos enormes refletem a lua, e ele enxerga até o que se esconde no escuro.', 2, 2, 60, 45, 0.5, 0.3, 1.1, NULL),
    (21, 'owlume', 'Owlume', 'Voa sem fazer nenhum som. As pintas claras das asas imitam as estrelas, e quem olha para o céu não o vê chegar.', 2, 2, 140, 45, 0.5, 0.9, 6.0, 20),
    (22, 'noclume', 'Noclume', 'Dizem que guarda a noite enquanto o mundo dorme. O rosto brilha como a lua cheia, e quem cruza o seu olhar esquece o caminho de volta.', 2, 2, 230, 45, 0.5, 1.5, 18.0, 21);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (20, 1, 11),
    (21, 1, 11),
    (22, 1, 11),
    (22, 2, 10);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (20, 1, 45, 0),
    (20, 2, 35, 0),
    (20, 3, 35, 0),
    (20, 4, 60, 1),
    (20, 5, 55, 0),
    (20, 6, 80, 0),
    (21, 1, 60, 0),
    (21, 2, 45, 0),
    (21, 3, 45, 0),
    (21, 4, 85, 2),
    (21, 5, 70, 0),
    (21, 6, 115, 0),
    (22, 1, 80, 0),
    (22, 2, 55, 0),
    (22, 3, 55, 0),
    (22, 4, 115, 3),
    (22, 5, 95, 0),
    (22, 6, 125, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (20, 6, 1, false),
    (20, 2, 3, true),
    (21, 6, 1, false),
    (21, 2, 3, true),
    (22, 6, 1, false),
    (22, 2, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (20, 3, 1, 1),
    (20, 28, 1, 1),
    (20, 53, 1, 5),
    (20, 54, 1, 10),
    (20, 11, 1, 14),
    (20, 44, 1, 18),
    (20, 55, 1, 24),
    (20, 35, 1, 30),
    (20, 46, 1, 36),
    (21, 60, 2, 0),
    (21, 3, 1, 1),
    (21, 28, 1, 1),
    (21, 53, 1, 5),
    (21, 54, 1, 10),
    (21, 11, 1, 14),
    (21, 44, 1, 18),
    (21, 55, 1, 24),
    (21, 35, 1, 30),
    (21, 46, 1, 36),
    (21, 12, 1, 44),
    (22, 12, 2, 0),
    (22, 3, 1, 1),
    (22, 28, 1, 1),
    (22, 60, 1, 1),
    (22, 53, 1, 5),
    (22, 54, 1, 10),
    (22, 11, 1, 14),
    (22, 44, 1, 18),
    (22, 55, 1, 24),
    (22, 35, 1, 30),
    (22, 46, 1, 36);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (54, 20, 21, 1, 20),
    (55, 21, 22, 1, 38);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (20, 1, 20),
    (20, 2, 35),
    (21, 1, 6),
    (21, 2, 12),
    (22, 2, 3);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (20, 4),
    (21, 4),
    (22, 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
