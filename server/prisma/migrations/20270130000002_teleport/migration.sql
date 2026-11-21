-- O Teleporte, que leva qualquer Ecobeast do campo a um hexágono vazio (.specs/veilmoth-line/03-teleport.md).

INSERT INTO "ecobeasts"."skill_targets" ("id", "slug", "name") VALUES (5, 'any', 'Qualquer Ecobeast');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_targets"', 'id'), GREATEST((SELECT max("id") FROM "ecobeasts"."skill_targets"), (SELECT last_value FROM "ecobeasts"."skill_targets_id_seq")));

INSERT INTO "ecobeasts"."effect_types" ("id", "slug", "name") VALUES (12, 'teleport', 'Teleportar');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."effect_types"', 'id'), GREATEST((SELECT max("id") FROM "ecobeasts"."effect_types"), (SELECT last_value FROM "ecobeasts"."effect_types_id_seq")));

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (113, 'teleporte', 'Teleporte', 'Desfaz em pó violeta um Ecobeast do campo (ele mesmo, um aliado ou um inimigo), que reaparece em qualquer hexágono vazio.', 14, 3, 0, 0, 5, 0, 0, 5, false, 1, 1, 1, 1, false, NULL, NULL, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (76, 113, 12, 1, 100, 5, NULL, NULL, NULL, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (36, 113, 1, 20),
    (37, 113, 1, 20);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
