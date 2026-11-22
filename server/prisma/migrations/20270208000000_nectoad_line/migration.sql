-- A linha do Nectoad: o sapo do néctar, de Toxina com a Flora na forma final, o primeiro Guardião Muralha física, que evolui no nível 22 (.specs/nectoad-line/01-nectoad-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (43, 'nectoad', 'Nectoad', 'Senta no meio das flores e jura que é uma delas. A pele solta um néctar doce que atrai os insetos e os deixa tontos de veneno. Fica ofendido se ninguém elogia a cor dele.', 2, 1, 56, 75, 0.5, 0.35, 2.0, NULL),
    (44, 'toxbloom', 'Toxbloom', 'Um dia nasceu uma flor de verdade nas costas, e ele nunca mais abaixou o queixo. Aguenta qualquer golpe sem desfazer a pose, e o néctar que pinga das pétalas envenena o chão em volta.', 2, 1, 170, 35, 0.5, 1.0, 70.0, 43);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (43, 1, 9),
    (44, 1, 9),
    (44, 2, 3);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (43, 1, 60, 0),
    (43, 2, 45, 0),
    (43, 3, 65, 1),
    (43, 4, 40, 0),
    (43, 5, 50, 0),
    (43, 6, 30, 0),
    (44, 1, 100, 0),
    (44, 2, 75, 0),
    (44, 3, 110, 2),
    (44, 4, 65, 0),
    (44, 5, 85, 0),
    (44, 6, 45, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (43, 4, 1, false),
    (43, 5, 3, true),
    (44, 4, 1, false),
    (44, 5, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (43, 74, 1, 1),
    (43, 15, 1, 8),
    (43, 75, 1, 26),
    (44, 74, 1, 1),
    (44, 15, 1, 8),
    (44, 75, 1, 26),
    (44, 68, 1, 30);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (68, 43, 44, 1, 22);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (43, 1, 30),
    (43, 2, 10),
    (44, 1, 8),
    (44, 2, 3);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (43, 13, 200),
    (43, 15, 50),
    (44, 13, 200),
    (44, 15, 50);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (43, 1),
    (43, 3),
    (43, 4),
    (44, 1),
    (44, 3),
    (44, 4);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
