-- As Técnicas de suporte da linha do Hopling (.specs/hopling-line/02-support-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (102, 'erva_da_bolsa', 'Erva da Bolsa', 'Tira uma erva da bolsa e trata um aliado a até 2 hexágonos, resmungando. Recupera metade do HP dele.', 13, 3, 0, 0, 10, 0, 0, 4, false, 1, 1, 1, 2, false, NULL, NULL, 2),
    (103, 'atadura_firme', 'Atadura Firme', 'Enrola uma atadura bem apertada num aliado a até 2 hexágonos. Aumenta a Defesa e a Defesa Especial dele.', 13, 3, 0, 0, 15, 0, 0, 4, false, 1, 1, 1, 2, false, NULL, NULL, 3),
    (104, 'cochilo', 'Cochilo', 'Fecha os olhos por um instante, enfim. Recupera metade do próprio HP.', 13, 3, 0, 0, 10, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (105, 'ninho_de_ervas', 'Ninho de Ervas', 'Espalha ervas no chão em volta de um aliado. Quem termina a vez ali recupera HP.', 13, 3, 0, 0, 5, 0, 0, 4, false, 1, 1, 1, 2, false, 10, 6, 4);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (67, 102, 3, 1, 100, NULL, NULL, NULL, NULL, 50),
    (68, 103, 2, 1, 100, 4, NULL, 3, 1, NULL),
    (69, 103, 2, 2, 100, 4, NULL, 5, 1, NULL),
    (70, 104, 3, 1, 100, NULL, NULL, NULL, NULL, 50);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (31, 102, 1, 5),
    (31, 103, 1, 17),
    (31, 104, 1, 22),
    (31, 105, 1, 26),
    (32, 102, 1, 5),
    (32, 103, 1, 17),
    (32, 104, 1, 22),
    (32, 105, 1, 26);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
