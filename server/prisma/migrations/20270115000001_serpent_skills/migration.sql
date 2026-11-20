-- As Técnicas de serpente da linha do Snekit (.specs/snekit-line/02-serpent-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (80, 'bote', 'Bote', 'Dá um bote rápido e certeiro no alvo. Acerta um ponto fraco com mais facilidade.', 13, 1, 60, 100, 20, 0, 1, 1, true, 1, 1, 1, 1, false, NULL, NULL, 0),
    (81, 'presa_venenosa', 'Presa Venenosa', 'Crava as presas cheias de veneno no alvo. Pode deixá-lo Envenenado.', 9, 1, 75, 100, 15, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 1),
    (82, 'constricao', 'Constrição', 'Enrola o corpo no alvo e aperta. Ele fica Preso e não anda por duas vezes.', 13, 1, 50, 95, 15, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 2),
    (83, 'cuspe_acido', 'Cuspe Ácido', 'Cospe ácido no primeiro da linha, a até 3 hexágonos. Pode baixar a Defesa Especial.', 9, 2, 50, 100, 20, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 1);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages") VALUES
    (55, 81, 1, 1, 30, NULL, 2, NULL, NULL),
    (56, 82, 1, 1, 100, NULL, 8, NULL, NULL),
    (57, 83, 2, 1, 30, 1, NULL, 5, -1);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (23, 80, 1, 9),
    (23, 82, 1, 18),
    (23, 83, 1, 26),
    (24, 80, 1, 9),
    (24, 82, 1, 18),
    (24, 83, 1, 26),
    (24, 81, 1, 40);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
