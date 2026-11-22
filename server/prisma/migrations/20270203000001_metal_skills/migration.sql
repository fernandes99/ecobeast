-- As Técnicas de Metal da linha do Snelt (.specs/snelt-line/02-metal-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (114, 'estilhaco', 'Estilhaço', 'Atira uma lasca de ferro quente da concha num inimigo a até 3 hexágonos.', 8, 2, 40, 100, 25, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 0),
    (115, 'jato_de_escoria', 'Jato de Escória', 'Cospe um jato de escória fervendo a até 3 hexágonos. Pode deixar o alvo Queimado.', 8, 2, 75, 95, 15, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 2),
    (116, 'tempera', 'Têmpera', 'Esquenta e esfria a concha de uma vez só, até ela ficar perfeita. Aumenta a Defesa e o Ataque Especial.', 8, 3, 0, 0, 15, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (117, 'metal_fundido', 'Metal Fundido', 'Abre a fornalha e despeja metal derretido num leque à frente, a até 2 hexágonos. O chão fica em chamas.', 8, 2, 110, 85, 5, 0, 0, 1, false, 1, 1, 3, 2, false, 1, 4, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (77, 115, 1, 1, 20, NULL, 1, NULL, NULL, NULL),
    (78, 116, 2, 1, 100, 2, NULL, 3, 1, NULL),
    (79, 116, 2, 2, 100, 2, NULL, 4, 1, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (38, 114, 1, 1),
    (38, 116, 1, 12),
    (38, 115, 1, 20),
    (39, 114, 1, 1),
    (39, 116, 1, 12),
    (39, 115, 1, 20),
    (40, 117, 2, 0),
    (40, 114, 1, 1),
    (40, 116, 1, 12),
    (40, 115, 1, 20),
    (40, 117, 1, 44);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
