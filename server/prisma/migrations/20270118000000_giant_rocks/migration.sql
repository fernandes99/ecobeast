-- As pedras gigantes da Montanha, com o bloqueio no pé (.specs/giant-rocks/01-rock-props.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (131, 'giant_crag', 'Rochedo', 3, 6),
    (132, 'giant_pinnacles', 'Pináculos', 1, 6),
    (133, 'giant_slab', 'Laje inclinada', 1, 6),
    (134, 'giant_boulders', 'Matacões', 1, 6),
    (135, 'giant_ridge', 'Crista', 1, 6),
    (136, 'snowy_crag', 'Rochedo com neve', 1, 6),
    (137, 'snowy_pinnacles', 'Pináculos com neve', 1, 6),
    (138, 'snowy_boulders', 'Matacões com neve', 1, 6);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (131, 0, 0, true, ARRAY[-30, -20, -15, -8, 15, -8, 30, -20, 15, -32, -15, -32]),
    (132, 0, 0, true, ARRAY[-22, -14, -11, -5, 11, -5, 22, -14, 11, -23, -11, -23]),
    (133, 0, 0, true, ARRAY[-42, -27, -21, -13, 21, -13, 42, -27, 21, -41, -21, -41]),
    (134, 0, 0, true, ARRAY[-30, -20, -15, -8, 15, -8, 30, -20, 15, -32, -15, -32]),
    (135, 0, 0, true, ARRAY[-54, -31, -27, -17, 27, -17, 54, -31, 27, -45, -27, -45]),
    (136, 0, 0, true, ARRAY[-30, -20, -15, -8, 15, -8, 30, -20, 15, -32, -15, -32]),
    (137, 0, 0, true, ARRAY[-22, -14, -11, -5, 11, -5, 22, -14, 11, -23, -11, -23]),
    (138, 0, 0, true, ARRAY[-30, -20, -15, -8, 15, -8, 30, -20, 15, -32, -15, -32]);
