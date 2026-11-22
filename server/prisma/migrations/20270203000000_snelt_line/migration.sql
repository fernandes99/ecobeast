-- A linha do Snelt: o caracol-fornalha, de Metal com o Fogo na forma final, o primeiro canhão especial lento, que evolui nos níveis 16 e 32 (.specs/snelt-line/01-snelt-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (38, 'snelt', 'Snelt', 'Lustra a concha de ferro até ver o próprio reflexo nela. Se alguém a arranha, esquenta de raiva e solta fumaça pelo topo.', 2, 1, 55, 70, 0.5, 0.3, 6.0, NULL),
    (39, 'smeltrudge', 'Smeltrudge', 'Leva horas para atravessar uma trilha, porque para em cada pedra com minério para avaliar. Só derrete na fornalha o que acha digno dela.', 2, 1, 140, 40, 0.5, 0.9, 120.0, 38),
    (40, 'magmollusk', 'Magmollusk', 'Dizem que nenhuma peça saiu torta da fornalha dele. Despeja metal derretido sem pressa nenhuma e olha de cima quem não aguenta o calor.', 2, 1, 225, 25, 0.5, 1.6, 450.0, 39);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (38, 1, 8),
    (39, 1, 8),
    (40, 1, 8),
    (40, 2, 1);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (38, 1, 55, 0),
    (38, 2, 35, 0),
    (38, 3, 60, 0),
    (38, 4, 65, 1),
    (38, 5, 50, 0),
    (38, 6, 25, 0),
    (39, 1, 75, 0),
    (39, 2, 45, 0),
    (39, 3, 80, 0),
    (39, 4, 95, 2),
    (39, 5, 70, 0),
    (39, 6, 35, 0),
    (40, 1, 100, 0),
    (40, 2, 55, 0),
    (40, 3, 100, 0),
    (40, 4, 130, 3),
    (40, 5, 90, 0),
    (40, 6, 40, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (38, 4, 1, false),
    (38, 1, 3, true),
    (39, 4, 1, false),
    (39, 1, 3, true),
    (40, 4, 1, false),
    (40, 1, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (38, 5, 1, 1),
    (38, 15, 1, 8),
    (38, 89, 1, 24),
    (39, 5, 1, 1),
    (39, 15, 1, 8),
    (39, 89, 1, 24),
    (39, 9, 1, 38),
    (40, 5, 1, 1),
    (40, 15, 1, 8),
    (40, 89, 1, 24),
    (40, 9, 1, 38);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (65, 38, 39, 1, 16),
    (66, 39, 40, 1, 32);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (38, 3, 30),
    (38, 5, 40),
    (38, 13, 30),
    (39, 3, 8),
    (39, 5, 12),
    (39, 13, 10),
    (40, 3, 2),
    (40, 5, 3),
    (40, 13, 4);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (38, 20, 200),
    (39, 20, 200),
    (40, 20, 200);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (38, 1),
    (38, 2),
    (38, 3),
    (38, 4),
    (39, 1),
    (39, 2),
    (39, 3),
    (39, 4),
    (40, 1),
    (40, 2),
    (40, 3),
    (40, 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
