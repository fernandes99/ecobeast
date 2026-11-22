-- As Técnicas de estática da linha do Fuzzap, as primeiras Físicas de Volt (.specs/fuzzap-line/02-volt-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (118, 'choque_de_pelo', 'Choque de Pelo', 'Esbarra no inimigo com o pelo cheio de estática. Pode deixar o alvo Paralisado.', 4, 1, 40, 100, 30, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 0),
    (119, 'estatica', 'Estática', 'Arrepia o pelo e solta uma descarga num inimigo a até 2 hexágonos. Deixa o alvo Paralisado.', 4, 3, 0, 90, 20, 0, 0, 1, false, 1, 1, 1, 2, false, NULL, NULL, 3),
    (120, 'investida_faiscante', 'Investida Faiscante', 'Corre soltando faíscas e se joga no inimigo. Pode deixar o alvo Paralisado.', 4, 1, 80, 95, 15, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 2),
    (121, 'avalanche_estatica', 'Avalanche Estática', 'Sacode a cauda de cristal e derruba neve carregada num leque à frente, a até 2 hexágonos. O chão fica coberto de geada.', 7, 1, 95, 90, 10, 0, 0, 1, false, 1, 1, 3, 2, false, 7, 4, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (80, 118, 1, 1, 20, NULL, 3, NULL, NULL, NULL),
    (81, 119, 1, 1, 100, NULL, 3, NULL, NULL, NULL),
    (82, 120, 1, 1, 30, NULL, 3, NULL, NULL, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (41, 118, 1, 1),
    (41, 119, 1, 10),
    (41, 120, 1, 20),
    (42, 121, 2, 0),
    (42, 118, 1, 1),
    (42, 119, 1, 10),
    (42, 120, 1, 20),
    (42, 121, 1, 38);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
