-- As primeiras Técnicas de Arcano, da linha do Veilmoth (.specs/veilmoth-line/02-arcane-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (110, 'po_arcano', 'Pó Arcano', 'Sacode as asas e sopra um pó violeta brilhante num inimigo a até 3 hexágonos.', 14, 2, 40, 100, 25, 0, 0, 1, false, 1, 1, 1, 3, false, NULL, NULL, 0),
    (111, 'olhar_do_veu', 'Olhar do Véu', 'Abre os olhos-portal das asas, e o alvo a até 3 hexágonos se perde olhando para dentro deles. Deixa Atordoado.', 14, 3, 0, 90, 15, 0, 0, 1, false, 1, 1, 1, 3, false, NULL, NULL, 3),
    (112, 'vortice_do_portal', 'Vórtice do Portal', 'Abre um portal giratório que puxa tudo na linha, a até 4 hexágonos. Pode deixar o alvo Atordoado.', 14, 2, 90, 95, 10, 0, 0, 1, false, 1, 1, 2, 4, false, NULL, NULL, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (74, 111, 1, 1, 100, NULL, 9, NULL, NULL, NULL),
    (75, 112, 1, 1, 20, NULL, 9, NULL, NULL, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (36, 110, 1, 1),
    (36, 111, 1, 9),
    (37, 112, 2, 0),
    (37, 110, 1, 1),
    (37, 111, 1, 9),
    (37, 112, 1, 38);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
