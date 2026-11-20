-- Os objetos da vila do tileset Village do Fantasy Dreamland Reborn (.specs/village-pack/02-village-objects.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (112, 'village_fountain', 'Fonte da vila', 4),
    (113, 'village_well', 'Poço de pedra', 4),
    (114, 'village_tank', 'Tanque de tábuas', 2),
    (115, 'village_trough', 'Cocho', 2),
    (116, 'village_crate', 'Caixote', 7),
    (117, 'village_bench', 'Banco da vila', 5),
    (118, 'village_table', 'Mesa da vila', 4),
    (119, 'village_chair', 'Cadeira', 7),
    (120, 'village_signpost', 'Placa de direção', 4),
    (121, 'village_board', 'Placa de madeira', 6),
    (122, 'village_shop_sign', 'Placa de loja', 10),
    (123, 'village_lantern', 'Lanterna pendurada', 2),
    (124, 'village_ladder', 'Escada de mão', 3),
    (125, 'village_firewood', 'Lenha', 4),
    (126, 'village_wheat', 'Trigo', 3),
    (127, 'village_garden_bed', 'Canteiro de terra', 3),
    (128, 'village_flower', 'Flor da vila', 5);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));
INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (112, 1, 0, true, ARRAY[-30, -2, 29, -2, 29, -62, -30, -62]),
    (112, 2, 0, true, ARRAY[-30, -2, 29, -2, 29, -62, -30, -62]),
    (112, 3, 0, true, ARRAY[-22, -2, 21, -2, 21, -46, -22, -46]),
    (112, 4, 0, true, ARRAY[-22, -2, 21, -2, 21, -49, -22, -49]),
    (113, 0, 0, true, ARRAY[-12, -2, 11, -2, 11, -26, -12, -26]),
    (114, 0, 0, true, ARRAY[-13, -2, 13, -2, 13, -16, -13, -16]),
    (115, 0, 0, true, ARRAY[-14, -2, 13, -2, 13, -14, -14, -14]),
    (116, 6, 0, true, ARRAY[-14, -2, 13, -2, 13, -12, -14, -12]),
    (116, 7, 0, true, ARRAY[-14, -2, 13, -2, 13, -12, -14, -12]),
    (117, 3, 0, true, ARRAY[-14, -2, 13, -2, 13, -12, -14, -12]),
    (125, 3, 0, true, ARRAY[-10, -2, 10, -2, 10, -14, -10, -14]),
    (126, 1, 0, true, ARRAY[-20, -2, 19, -2, 19, -16, -20, -16]);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
INSERT INTO "ecobeasts"."prop_type_lights" ("prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (123, 1, 0, 5, -14, 18, 'ffd890');
