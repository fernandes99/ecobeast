-- A linha do Budflit: a borboleta torcedora, de Inseto com o Psíquico a partir da Cheerwing, o primeiro Suporte Inspirador, que evolui nos níveis 14 e 30 (.specs/budflit-line/01-budflit-line.md).

INSERT INTO "ecobeasts"."species" ("id", "slug", "name", "description", "growth_rate_id", "rarity_id", "base_xp_yield", "capture_rate", "gender_ratio", "height_m", "weight_kg", "evolves_from_species_id") VALUES
    (45, 'budflit', 'Budflit', 'Vive escondida entre as pétalas, de asas sempre fechadas como um botão de flor. Só abre um pouquinho quando alguém do time vai bem, e aí solta umas faíscas de brilho.', 2, 1, 52, 75, 0.5, 0.2, 0.3, NULL),
    (46, 'cheerwing', 'Cheerwing', 'Abriu as asas e virou a torcedora mais barulhenta do campo. Comemora qualquer golpe, até os que erram, e o pó das asas deixa os aliados mais confiantes.', 2, 1, 138, 45, 0.5, 0.6, 2.5, 45),
    (47, 'galafly', 'Galafly', 'As quatro asas abertas parecem a cortina de um palco, e o brilho cai como confete. Rege o time como um maestro e faz cada aliado se sentir a estrela da festa.', 2, 1, 220, 25, 0.5, 1.3, 12.0, 46);
INSERT INTO "ecobeasts"."species_elements" ("species_id", "slot", "element_id") VALUES
    (45, 1, 15),
    (46, 1, 15),
    (46, 2, 10),
    (47, 1, 15),
    (47, 2, 10);
INSERT INTO "ecobeasts"."species_stats" ("species_id", "stat_id", "base_value", "training_yield") VALUES
    (45, 1, 50, 0),
    (45, 2, 30, 0),
    (45, 3, 40, 0),
    (45, 4, 45, 0),
    (45, 5, 60, 0),
    (45, 6, 75, 1),
    (46, 1, 70, 0),
    (46, 2, 35, 0),
    (46, 3, 55, 0),
    (46, 4, 60, 0),
    (46, 5, 85, 0),
    (46, 6, 100, 2),
    (47, 1, 95, 0),
    (47, 2, 45, 0),
    (47, 3, 70, 0),
    (47, 4, 75, 0),
    (47, 5, 110, 1),
    (47, 6, 125, 2);
INSERT INTO "ecobeasts"."species_traits" ("species_id", "trait_id", "slot", "is_hidden") VALUES
    (45, 6, 1, false),
    (45, 2, 3, true),
    (46, 6, 1, false),
    (46, 2, 3, true),
    (47, 6, 1, false),
    (47, 2, 3, true);
INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (45, 3, 1, 1),
    (45, 54, 1, 10),
    (46, 3, 1, 1),
    (46, 54, 1, 10),
    (46, 44, 1, 22),
    (47, 3, 1, 1),
    (47, 54, 1, 10),
    (47, 44, 1, 22);
INSERT INTO "ecobeasts"."evolutions" ("id", "species_id", "evolved_species_id", "evolution_trigger_id", "min_level") VALUES
    (69, 45, 46, 1, 14),
    (70, 46, 47, 1, 30);
INSERT INTO "ecobeasts"."species_biomes" ("species_id", "biome_id", "rate") VALUES
    (45, 1, 35),
    (45, 4, 10),
    (46, 1, 10),
    (46, 4, 3),
    (47, 1, 3),
    (47, 4, 1);
INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent") VALUES
    (45, 13, 200),
    (45, 12, 150),
    (46, 13, 200),
    (46, 12, 150),
    (47, 13, 200),
    (47, 12, 150);
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id") VALUES
    (45, 1),
    (45, 2),
    (46, 1),
    (46, 2),
    (47, 1),
    (47, 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."species"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."species"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."evolutions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."evolutions"));
