-- As dez Técnicas dos estados e das marcas novas, com as primeiras de Toxina (.specs/field-effects/03-field-skills.md).

INSERT INTO "ecobeasts"."skills" ("id", "slug", "name", "description", "element_id", "skill_category_id", "power", "accuracy", "max_pp", "priority", "crit_stage", "skill_target_id", "makes_contact", "min_hits", "max_hits", "area_shape_id", "range", "pierces", "ground_effect_id", "ground_turns", "cooldown") VALUES
    (66, 'esguicho', 'Esguicho', 'Esguicha água no primeiro da linha, a até 3 hexágonos, e o deixa Encharcado: ele sofre mais com Volt e menos com Fogo.', 2, 2, 40, 100, 25, 0, 0, 1, false, 1, 1, 2, 3, false, NULL, NULL, 0),
    (67, 'poca_d_agua', 'Poça d''Água', 'Alaga uma fileira. Quem para na poça fica Encharcado.', 2, 3, 0, 0, 10, 0, 0, 1, false, 1, 1, 2, 3, true, 11, 6, 3),
    (68, 'laco_de_raizes', 'Laço de Raízes', 'Enrola o alvo em raízes. Ele fica Preso e não anda por duas vezes.', 3, 1, 35, 95, 20, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 2),
    (69, 'brotar', 'Brotar', 'Faz brotar folhas num aliado, ou em si mesmo, que recupera um pouco de HP a cada vez.', 3, 3, 0, 0, 15, 0, 0, 4, false, 1, 1, 1, 2, false, NULL, NULL, 3),
    (70, 'semear_jardim', 'Semear Jardim', 'Semeia um jardim debaixo de um aliado, ou de si mesmo. Quem para nele recupera HP, até um inimigo.', 3, 3, 0, 0, 5, 0, 0, 4, false, 1, 1, 1, 2, false, 10, 6, 4),
    (71, 'lama_grudenta', 'Lama Grudenta', 'Joga lama na fileira inteira. Quem para no lamaçal fica mais lento.', 5, 2, 50, 95, 15, 0, 0, 1, false, 1, 1, 2, 3, true, 6, 6, 2),
    (72, 'areia_movedica', 'Areia Movediça', 'Afofa o chão de uma fileira. Quem para na areia fica Preso, menos quem voa.', 5, 3, 0, 0, 5, 0, 0, 1, false, 1, 1, 2, 3, true, 9, 6, 4),
    (73, 'chao_de_geada', 'Chão de Geada', 'Cobre uma fileira de geada. Quem para nela escorrega e perde Evasão.', 7, 3, 0, 0, 10, 0, 0, 1, false, 1, 1, 2, 3, true, 7, 8, 3),
    (74, 'espinho_venenoso', 'Espinho Venenoso', 'Espeta o alvo com um espinho venenoso. Pode deixá-lo Envenenado.', 9, 1, 40, 100, 25, 0, 0, 1, true, 1, 1, 1, 1, false, NULL, NULL, 0),
    (75, 'poca_toxica', 'Poça Tóxica', 'Derrama veneno numa fileira. Quem para na poça fica Envenenado.', 9, 3, 0, 0, 10, 0, 0, 1, false, 1, 1, 2, 3, true, 8, 6, 4);

INSERT INTO "ecobeasts"."skill_effects" ("id", "skill_id", "effect_type_id", "sort_order", "chance", "status_condition_id") VALUES
    (46, 66, 1, 1, 100, 10),
    (47, 68, 1, 1, 100, 8),
    (48, 69, 1, 1, 100, 11),
    (49, 74, 1, 1, 30, 2);

INSERT INTO "ecobeasts"."species_skills" ("species_id", "skill_id", "skill_learn_method_id", "level") VALUES
    (4, 66, 1, 16), (5, 66, 1, 16), (6, 66, 1, 16),
    (17, 66, 1, 7), (18, 66, 1, 7), (19, 66, 1, 7),
    (5, 67, 1, 30), (6, 67, 1, 30), (18, 67, 1, 30), (19, 67, 1, 30),
    (7, 68, 1, 16), (8, 68, 1, 16), (9, 68, 1, 16),
    (7, 69, 1, 22), (8, 69, 1, 22), (9, 69, 1, 22),
    (8, 70, 1, 40), (9, 70, 1, 40),
    (12, 71, 1, 22), (13, 71, 1, 22), (14, 71, 1, 22),
    (13, 72, 1, 36), (14, 72, 1, 36),
    (10, 73, 1, 20), (11, 73, 1, 20),
    (7, 74, 1, 4), (8, 74, 1, 4), (9, 74, 1, 4),
    (6, 75, 1, 38), (14, 75, 1, 44);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."skills"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skills"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."skill_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."skill_effects"));
