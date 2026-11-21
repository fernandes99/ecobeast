-- As Técnicas de Luz da linha do Glimshell (.specs/glimshell-line/02-light-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (106, 'lampejo', 'Lampejo', 'Solta um brilho rápido da pedra do casco num inimigo a até 3 hexágonos.', 12, 2, 40, 100, 25, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 0),
    (107, 'casco_prismatico', 'Casco Prismático', 'Recolhe-se no casco, que brilha e desvia a energia. Aumenta muito a Defesa Especial.', 12, 3, 0, 0, 10, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (108, 'halo_protetor', 'Halo Protetor', 'Projeta um halo de luz em volta de um aliado a até 2 hexágonos. Aumenta muito a Defesa Especial dele.', 12, 3, 0, 0, 15, 0, 0, 4, false, 1, 1, 1, 2, false, NULL, NULL, 3),
    (109, 'raio_prismatico', 'Raio Prismático', 'Junta a luz no casco e dispara um raio de arco-íris a até 4 hexágonos. Pode baixar o Ataque Especial do alvo.', 12, 2, 90, 95, 10, 0, 0, 1, false, 1, 1, 2, 4, false, NULL, NULL, 3);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages", "percent") VALUES
    (71, 107, 2, 1, 100, 2, NULL, 5, 2, NULL),
    (72, 108, 2, 1, 100, 4, NULL, 5, 2, NULL),
    (73, 109, 2, 1, 30, 1, NULL, 4, -1, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (33, 106, 1, 1),
    (33, 107, 1, 7),
    (33, 108, 1, 22),
    (34, 108, 2, 0),
    (34, 106, 1, 1),
    (34, 107, 1, 7),
    (34, 108, 1, 22),
    (34, 109, 1, 40),
    (35, 109, 2, 0),
    (35, 106, 1, 1),
    (35, 107, 1, 7),
    (35, 108, 1, 22),
    (35, 109, 1, 40);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
