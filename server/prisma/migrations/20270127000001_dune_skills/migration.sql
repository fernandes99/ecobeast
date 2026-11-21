-- As Técnicas de escorpião da linha do Sandlurk (.specs/sandlurk-line/02-dune-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (98, 'pinca_firme', 'Pinça Firme', 'Agarra o alvo com as pinças e não solta. Ele fica Preso e não anda por duas vezes.', 15, 1, 55, 95, 15, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 2),
    (99, 'ferroada_paralisante', 'Ferroada Paralisante', 'Estica a cauda por cima das pinças e crava o ferrão no primeiro da linha, a até 2 hexágonos. Pode deixá-lo Paralisado.', 9, 1, 70, 100, 15, 0, 0, 1, true, 1, 1, 2, 2, false, NULL, NULL, 2),
    (100, 'enterrar', 'Enterrar', 'Afunda na areia e deixa só a carapaça de fora. Aumenta a Defesa e a Defesa Especial.', 15, 3, 0, 0, 10, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (101, 'bote_da_duna', 'Bote da Duna', 'Sai de repente da areia num bote só, depois de muito esperar. Acerta um ponto fraco com mais facilidade.', 15, 1, 95, 90, 10, 0, 1, 1, true, 1, 1, 1, 1, false, NULL, NULL, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages") VALUES
    (63, 98, 1, 1, 100, NULL, 8, NULL, NULL),
    (64, 99, 1, 1, 30, NULL, 3, NULL, NULL),
    (65, 100, 2, 1, 100, 2, NULL, 3, 1),
    (66, 100, 2, 2, 100, 2, NULL, 5, 1);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (29, 98, 1, 9),
    (29, 100, 1, 17),
    (29, 99, 1, 25),
    (30, 101, 2, 0),
    (30, 98, 1, 9),
    (30, 100, 1, 17),
    (30, 99, 1, 25),
    (30, 101, 1, 46);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
