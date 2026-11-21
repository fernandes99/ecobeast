-- As pedras grandes de gelo da Geleira, na categoria Pedras, com o bloqueio no pé (.specs/glacier/02-ice-rocks.md).
-- O Arco de gelo bloqueia pelas duas pernas, uma linha em cada.

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (171, 'ice_block', 'Bloco de gelo', 2, 6),
    (172, 'ice_spires', 'Pináculos de gelo', 1, 6),
    (173, 'ice_arch', 'Arco de gelo', 1, 6),
    (174, 'trapped_rock', 'Rocha presa no gelo', 1, 6),
    (175, 'icicle_block', 'Bloco com sincelos', 1, 6),
    (176, 'ice_shelf', 'Laje de gelo', 1, 6);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (171, 0, 0, true, ARRAY[-26, -18, -13, -7, 13, -7, 26, -18, 13, -29, -13, -29]),
    (172, 0, 0, true, ARRAY[-29, -20, -15, -8, 14, -8, 29, -20, 14, -32, -15, -32]),
    (173, 0, 0, true, ARRAY[-41, -16, -36, -10, -26, -10, -21, -16, -26, -22, -36, -22]),
    (173, 0, 1, true, ARRAY[21, -16, 26, -10, 36, -10, 41, -16, 36, -22, 26, -22]),
    (174, 0, 0, true, ARRAY[-28, -19, -14, -8, 14, -8, 28, -19, 14, -30, -14, -30]),
    (175, 0, 0, true, ARRAY[-28, -19, -14, -8, 14, -8, 28, -19, 14, -30, -14, -30]),
    (176, 0, 0, true, ARRAY[-42, -26, -21, -12, 21, -12, 42, -26, 21, -40, -21, -40]);
