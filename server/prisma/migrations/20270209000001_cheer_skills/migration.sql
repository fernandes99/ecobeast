-- As Técnicas da borboleta torcedora: a primeira Especial de Inseto e as primeiras que sobem o ataque de um aliado (.specs/budflit-line/02-cheer-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (125, 'po_cintilante', 'Pó Cintilante', 'Sacode as asas e joga um pó brilhante num inimigo a até 3 hexágonos. Pode deixar o alvo Confuso.', 15, 2, 50, 100, 25, 0, 0, 1, false, 1, 1, 1, 3, false, NULL, NULL, 0),
    (126, 'po_animador', 'Pó Animador', 'Espalha um pó cheiroso num aliado a até 2 hexágonos, ou em quem usou. Sobe o Ataque e o Ataque Especial.', 10, 3, 0, 0, 15, 0, 0, 4, false, 1, 1, 1, 2, false, NULL, NULL, 2),
    (127, 'ovacao', 'Ovação', 'Abre as asas, faz festa e chove confete num aliado a até 3 hexágonos, ou em quem usou. Sobe muito o Ataque e o Ataque Especial.', 10, 3, 0, 0, 5, 0, 0, 4, false, 1, 1, 1, 3, false, NULL, NULL, 4);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (87, 125, 1, 1, 10, NULL, 6, NULL, NULL, NULL),
    (88, 126, 2, 1, 100, 4, NULL, 2, 1, NULL),
    (89, 126, 2, 2, 100, 4, NULL, 4, 1, NULL),
    (90, 127, 2, 1, 100, 4, NULL, 2, 2, NULL),
    (91, 127, 2, 2, 100, 4, NULL, 4, 2, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (45, 125, 1, 5),
    (46, 125, 1, 5),
    (46, 126, 1, 16),
    (47, 127, 2, 0),
    (47, 125, 1, 5),
    (47, 126, 1, 16),
    (47, 127, 1, 40);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
