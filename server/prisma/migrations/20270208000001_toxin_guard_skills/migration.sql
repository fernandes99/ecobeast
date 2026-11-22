-- As Técnicas do sapo do néctar, as primeiras de Toxina que protegem (.specs/nectoad-line/02-toxin-guard-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (122, 'lingua_acida', 'Língua Ácida', 'Estica a língua grudenta num inimigo a até 2 hexágonos. Pode deixar o alvo Envenenado.', 9, 1, 60, 100, 20, 0, 0, 1, true, 1, 1, 1, 2, false, NULL, NULL, 1),
    (123, 'pele_de_nectar', 'Pele de Néctar', 'Cobre a pele de néctar grosso. Sobe a Defesa e a Defesa Especial e deixa quem usou Brotando.', 9, 3, 0, 0, 10, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (124, 'abraco_da_flor', 'Abraço da Flor', 'Agarra o inimigo com as patas e as pétalas e aperta forte. O néctar que escorre deixa uma Poça Tóxica no chão.', 9, 1, 90, 90, 10, 0, 0, 1, true, 1, 1, 1, 1, false, 8, 4, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (83, 122, 1, 1, 30, NULL, 2, NULL, NULL, NULL),
    (84, 123, 2, 1, 100, 2, NULL, 3, 1, NULL),
    (85, 123, 2, 2, 100, 2, NULL, 5, 1, NULL),
    (86, 123, 1, 3, 100, NULL, 11, NULL, NULL, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (43, 122, 1, 12),
    (43, 123, 1, 18),
    (44, 124, 2, 0),
    (44, 122, 1, 12),
    (44, 123, 1, 18),
    (44, 124, 1, 36);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
