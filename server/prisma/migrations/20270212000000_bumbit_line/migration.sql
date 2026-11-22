-- A linha do Bumbit: a abelha operária, de Inseto com a Flora no Bloomarch, o primeiro Controlador Arquiteto, que evolui nos níveis 15 e 32 (.specs/bumbit-line/01-bumbit-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (48, 'bumbit', 'Bumbit', 'Vive preocupado com a ordem das flores e fica nervoso quando uma pétala cai fora do lugar. As asinhas mal o levantam, então ele vai de flor em flor a pé, zumbindo baixinho.', 2, 1, 54, 75, 0.5, 0.3, 0.6, NULL),
    (49, 'buzzwork', 'Buzzwork', 'Conta cada flor do campo e anota tudo de cabeça. Manda nos outros sem parar e espalha um mel grudento no caminho de quem atrapalha o trabalho.', 2, 1, 140, 45, 0.5, 0.8, 7.0, 48),
    (50, 'bloomarch', 'Bloomarch', 'O manto de pétalas cresce do próprio pelo. Já não se apressa: com um zumbido grave, decide onde cada um pisa, e o mel que pinga das mandíbulas segura quem tenta passar.', 2, 1, 222, 25, 0.5, 1.5, 28.0, 49);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (48, 1, 15),
    (49, 1, 15),
    (50, 1, 15),
    (50, 2, 3);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (48, 1, 50, 0),
    (48, 2, 35, 0),
    (48, 3, 50, 0),
    (48, 4, 45, 0),
    (48, 5, 55, 1),
    (48, 6, 65, 0),
    (49, 1, 70, 0),
    (49, 2, 50, 0),
    (49, 3, 70, 0),
    (49, 4, 65, 0),
    (49, 5, 75, 2),
    (49, 6, 75, 0),
    (50, 1, 90, 0),
    (50, 2, 70, 0),
    (50, 3, 90, 0),
    (50, 4, 85, 1),
    (50, 5, 95, 2),
    (50, 6, 90, 0);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (48, 6, 1, false),
    (48, 4, 3, true),
    (49, 6, 1, false),
    (49, 4, 3, true),
    (50, 6, 1, false),
    (50, 4, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (48, 3, 1, 1),
    (49, 3, 1, 1),
    (49, 30, 1, 26),
    (50, 3, 1, 1),
    (50, 30, 1, 26);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (71, 48, 49, 1, 15),
    (72, 49, 50, 1, 32);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (48, 1, 30),
    (48, 4, 10),
    (49, 1, 10),
    (49, 4, 3),
    (50, 1, 3),
    (50, 4, 1);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (48, 13, 200),
    (48, 19, 50),
    (49, 13, 200),
    (49, 19, 50),
    (50, 13, 200),
    (50, 19, 50);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (48, 1),
    (48, 3),
    (49, 1),
    (49, 3),
    (50, 1),
    (50, 3);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
