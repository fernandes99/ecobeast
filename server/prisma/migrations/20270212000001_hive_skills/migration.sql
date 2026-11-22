-- A marca Melado e as Técnicas da abelha operária, o primeiro Controlador Arquiteto (.specs/bumbit-line/02-hive-skills.md).

INSERT INTO "ecobeasts"."ground_effects" ("id", "slug", "name", "damage_percent", "heal_percent", "status_condition_id", "color_hex") VALUES
    (12, 'honey', 'Melado', NULL, NULL, 8, '#E8A93A');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."ground_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."ground_effects"));

INSERT INTO "ecobeasts"."ground_effect_stats" ("ground_effect_id", "stat_id", "stages") VALUES
    (12, 6, -1);

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (128, 'mel_grudento', 'Mel Grudento', 'Espalha um mel grosso no chão a até 3 hexágonos. Quem termina a vez no Melado fica Preso e perde Velocidade.', 15, 3, 0, 0, 10, 0, 0, 1, false, 1, 1, 2, 3, false, 12, 4, 3),
    (129, 'zumbido', 'Zumbido', 'Bate as asas tão rápido que o zumbido atordoa todos à frente. Pode deixar os alvos Confusos.', 15, 2, 55, 100, 15, 0, 0, 1, false, 1, 1, 3, 1, false, NULL, NULL, 2),
    (130, 'nuvem_de_polen', 'Nuvem de Pólen', 'Sacode o pelo e solta uma nuvem de pólen à frente, a até 2 hexágonos. Baixa a Precisão dos alvos.', 3, 3, 0, 100, 15, 0, 0, 1, false, 1, 1, 3, 2, false, NULL, NULL, 2),
    (131, 'chuva_de_mel', 'Chuva de Mel', 'Lança uma chuva de mel pesado num inimigo a até 3 hexágonos. O mel que sobra deixa um Melado no chão.', 15, 2, 80, 95, 10, 0, 0, 1, false, 1, 1, 2, 3, false, 12, 3, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (92, 129, 1, 1, 30, NULL, 6, NULL, NULL, NULL),
    (93, 130, 2, 1, 100, 1, NULL, 7, -1, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (48, 130, 1, 6),
    (48, 129, 1, 11),
    (48, 128, 1, 24),
    (49, 130, 1, 6),
    (49, 129, 1, 11),
    (49, 128, 1, 20),
    (50, 131, 2, 0),
    (50, 130, 1, 6),
    (50, 129, 1, 11),
    (50, 128, 1, 20),
    (50, 131, 1, 42);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
