-- As primeiras Técnicas de Volt e a marca Maré Elétrica, para a linha do Tidebud (.specs/tidebud-line/02-volt-skills.md).

INSERT INTO "ecobeasts"."ground_effects" ("id", "slug", "name", "damage_percent", "status_condition_id", "color_hex") VALUES
    (5, 'electric_tide', 'Maré Elétrica', NULL, 3, '#3FA9F5');

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (62, 'faisca_de_alga', 'Faísca de Alga', 'Solta uma faísca pelas folhas no primeiro da linha, a até 3 hexágonos. Pode deixar o alvo Paralisado.', 4, 2, 40, 100, 25, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 0),
    (63, 'corrente_viva', 'Corrente Viva', 'Uma corrente elétrica corre pela água e atravessa a fileira inteira, a até 4 hexágonos. Pode deixar Paralisado.', 4, 2, 75, 95, 15, 0, 0, 1, false, 1, 1, 2, 4, true, NULL, NULL, 2),
    (64, 'mare_eletrica', 'Maré Elétrica', 'Eletrifica a água numa fileira. Quem para nela fica Paralisado, menos quem é de Volt.', 4, 3, 0, 0, 10, 0, 0, 1, false, 1, 1, 2, 3, true, 5, 4, 3),
    (65, 'tempestade_de_algas', 'Tempestade de Algas', 'Chama uma tempestade de raios que varre a fileira inteira, a até 5 hexágonos. Tem boa chance de deixar Paralisado.', 4, 2, 110, 90, 5, 0, 0, 1, false, 1, 1, 2, 5, true, NULL, NULL, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "status_condition_id") VALUES
    (43, 62, 1, 1, 10, 3),
    (44, 63, 1, 1, 10, 3),
    (45, 65, 1, 1, 30, 3);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (17, 62, 1, 3),
    (18, 63, 2, 0),
    (18, 62, 1, 3),
    (18, 64, 1, 26),
    (19, 65, 2, 0),
    (19, 63, 1, 1),
    (19, 62, 1, 3),
    (19, 64, 1, 26);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."ground_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."ground_effects"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
