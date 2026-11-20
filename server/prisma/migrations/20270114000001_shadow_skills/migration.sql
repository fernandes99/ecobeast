-- As Técnicas de Sombra especiais da linha do Lume (.specs/lume-line/02-shadow-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (76, 'pena_sombria', 'Pena Sombria', 'Dispara uma pena escura no primeiro da linha, a até 3 hexágonos. Pode deixar o alvo Amedrontado.', 11, 2, 40, 100, 25, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 0),
    (77, 'olhar_da_lua', 'Olhar da Lua', 'Os olhos brilham como a lua e prendem o alvo no lugar, a até 3 hexágonos. Pode deixá-lo Atordoado.', 11, 2, 70, 95, 15, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 2),
    (78, 'voo_silencioso', 'Voo Silencioso', 'Bate as asas sem nenhum som e se prepara para caçar. Aumenta o Ataque Especial e a Velocidade.', 11, 3, 0, 0, 10, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (79, 'eclipse_lunar', 'Eclipse Lunar', 'Apaga a lua e atravessa a fileira inteira com a escuridão, a até 4 hexágonos. Pode baixar a Defesa Especial.', 11, 2, 110, 90, 5, 0, 0, 1, false, 1, 1, 2, 4, true, NULL, NULL, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages") VALUES
    (50, 76, 6, 1, 10, NULL, NULL, NULL, NULL),
    (51, 77, 1, 1, 20, NULL, 9, NULL, NULL),
    (52, 78, 2, 1, 100, 2, NULL, 4, 1),
    (53, 78, 2, 2, 100, 2, NULL, 6, 1),
    (54, 79, 2, 1, 30, 1, NULL, 5, -1);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (20, 76, 1, 3),
    (20, 77, 1, 22),
    (21, 76, 1, 3),
    (21, 77, 1, 22),
    (21, 78, 1, 28),
    (21, 79, 1, 50),
    (22, 79, 2, 0),
    (22, 76, 1, 3),
    (22, 77, 1, 22),
    (22, 78, 1, 28);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
