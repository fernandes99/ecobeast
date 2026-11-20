-- As primeiras Técnicas de Inseto e de Luz, para a linha do Prayling (.specs/prayling-line/03-insect-light-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (84, 'golpe_de_foice', 'Golpe de Foice', 'Corta com a foice dobrada, rápido como um bote. Acerta um golpe crítico com mais facilidade.', 15, 1, 55, 100, 25, 0, 1, 1, true, 1, 1, 1, 1, false, NULL, NULL, 0),
    (85, 'emboscada', 'Emboscada', 'Espera imóvel e ataca de surpresa. Pode deixar o alvo Amedrontado.', 15, 1, 75, 100, 15, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 2),
    (86, 'danca_da_foice', 'Dança da Foice', 'Afia as foices num movimento lento e preciso. Aumenta muito o Ataque.', 15, 3, 0, 0, 10, 0, 0, 2, false, 1, 1, 1, 1, false, NULL, NULL, 3),
    (87, 'raio_de_sol', 'Raio de Sol', 'Junta a luz do sol nas asas e dispara um raio no primeiro da linha, a até 3 hexágonos. Pode deixar o alvo Atordoado.', 12, 2, 70, 100, 15, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 1),
    (88, 'lamina_solar', 'Lâmina Solar', 'Golpeia com a foice acesa como o sol, que ofusca o alvo. Pode baixar a Precisão.', 12, 1, 90, 95, 10, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 2);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages") VALUES
    (58, 85, 6, 1, 30, NULL, NULL, NULL, NULL),
    (59, 86, 2, 1, 100, 2, NULL, 2, 2),
    (60, 87, 1, 1, 20, NULL, 9, NULL, NULL),
    (61, 88, 2, 1, 30, 1, NULL, 7, -1);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (25, 84, 1, 9),
    (26, 84, 1, 9),
    (26, 85, 1, 20),
    (26, 86, 1, 30),
    (27, 88, 2, 0),
    (27, 84, 1, 9),
    (27, 85, 1, 20),
    (27, 86, 1, 30),
    (27, 87, 1, 40),
    (28, 84, 1, 9),
    (28, 85, 1, 20),
    (28, 86, 1, 30);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
