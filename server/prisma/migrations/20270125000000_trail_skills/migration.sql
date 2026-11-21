-- As Técnicas de rastro: linha reta sem atravessar, com marca até o primeiro inimigo (.specs/board-battle/34-trail-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (89, 'cometa_de_brasa', 'Cometa de Brasa', 'Lança um cometa de brasa no primeiro da linha, a até 4 hexágonos, e deixa o chão em chamas por onde passou. Pode deixar o alvo Queimado.', 1, 2, 60, 95, 15, 0, 0, 1, false, 1, 1, 2, 4, false, 1, 4, 2),
    (90, 'jato_gotejante', 'Jato Gotejante', 'Dispara um jato que vai pingando até o primeiro da linha, a até 4 hexágonos. Quem para nas gotas fica Encharcado.', 2, 2, 45, 100, 20, 0, 0, 1, false, 1, 1, 2, 4, false, 11, 4, 1),
    (91, 'faisca_rastejante', 'Faísca Rastejante', 'Uma faísca corre rente ao chão até o primeiro da linha, a até 3 hexágonos, e deixa o caminho eletrificado. Quem para nele fica Paralisado, menos quem é de Volt.', 4, 2, 40, 100, 10, 0, 0, 1, false, 1, 1, 2, 3, false, 5, 3, 4),
    (92, 'semente_saltitante', 'Semente Saltitante', 'Atira uma semente que quica até o primeiro da linha, a até 3 hexágonos, e deixa espinhos brotando por onde passou.', 3, 1, 45, 100, 20, 0, 0, 1, false, 1, 1, 2, 3, false, 4, 4, 1),
    (93, 'cometa_de_polen', 'Cometa de Pólen', 'Lança um cometa de pólen no primeiro da linha, a até 4 hexágonos. Por onde ele passa nasce um jardim, que cura quem para nele, até o inimigo.', 3, 2, 40, 100, 10, 0, 0, 1, false, 1, 1, 2, 4, false, 10, 4, 3),
    (94, 'bola_de_lama', 'Bola de Lama', 'Arremessa uma bola de lama no primeiro da linha, a até 3 hexágonos, que respinga pelo caminho. Quem para no lamaçal fica mais lento.', 5, 2, 55, 95, 15, 0, 0, 1, false, 1, 1, 2, 3, false, 6, 4, 1),
    (95, 'estaca_de_gelo', 'Estaca de Gelo', 'Atira uma estaca de gelo no primeiro da linha, a até 4 hexágonos, que deixa geada por onde passou. Quem para nela escorrega e perde Evasão.', 7, 1, 65, 95, 15, 0, 0, 1, false, 1, 1, 2, 4, false, 7, 4, 2),
    (96, 'dardo_gotejante', 'Dardo Gotejante', 'Atira um dardo que pinga veneno até o primeiro da linha, a até 3 hexágonos. Quem para nas gotas fica Envenenado.', 9, 1, 35, 100, 15, 0, 0, 1, false, 1, 1, 2, 3, false, 8, 4, 3),
    (97, 'pena_riscante', 'Pena Riscante', 'Atira uma pena que risca o ar até o primeiro da linha, a até 4 hexágonos, e deixa penas soltas no caminho. Quem para nelas perde Precisão e Evasão.', 6, 2, 45, 100, 20, 0, 0, 1, false, 1, 1, 2, 4, false, 2, 3, 1);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "skill_target_id", "status_condition_id", "stat_id", "stages") VALUES
    (62, 89, 1, 1, 10, NULL, 1, NULL, NULL);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (1, 89, 1, 22),
    (2, 89, 1, 22),
    (3, 89, 1, 22),
    (4, 90, 1, 22),
    (5, 90, 1, 22),
    (6, 90, 1, 22),
    (17, 90, 1, 20),
    (18, 90, 1, 20),
    (19, 90, 1, 20),
    (18, 91, 1, 32),
    (19, 91, 1, 32),
    (7, 92, 1, 27),
    (8, 92, 1, 27),
    (9, 92, 1, 27),
    (8, 93, 1, 44),
    (9, 93, 1, 44),
    (12, 94, 1, 14),
    (13, 94, 1, 14),
    (14, 94, 1, 14),
    (10, 95, 1, 30),
    (11, 95, 1, 30),
    (23, 96, 1, 22),
    (24, 96, 1, 22),
    (15, 97, 1, 15),
    (16, 97, 1, 15),
    (20, 97, 1, 26),
    (21, 97, 1, 26),
    (22, 97, 1, 26);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
