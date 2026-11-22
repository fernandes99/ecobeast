-- As decorações do Vulcão e a crosta da lava viram peças soltas, na categoria Vulcão (.specs/volcano/01-volcano-art.md).
-- A rachadura de lava bloqueia pela borda da crosta, numa linha fechada por variante, e acende à noite.

INSERT INTO "ecobeasts"."prop_categories" ("id", "slug", "name") VALUES
    (16, 'volcano', 'Vulcão');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_categories"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_categories"));

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (177, 'basalt_pebbles', 'Pedrinhas de basalto', 4, 16),
    (178, 'lava_crack', 'Rachadura de lava', 4, 16),
    (179, 'fumarole', 'Fumarola', 4, 16),
    (180, 'burnt_tree', 'Árvore queimada', 4, 16),
    (181, 'ash_patch', 'Cinza', 4, 16),
    (182, 'obsidian', 'Obsidiana', 4, 16),
    (183, 'lava_crust', 'Crosta de lava', 4, 16);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (178, 1, 0, true, ARRAY[-22, -11, -17, -14, -12, -17, -7, -19, -2, -20, 3, -22, 8, -24, 13, -25, 18, -27, 21, -26, 21, -21, 18, -19, 13, -16, 8, -13, 3, -11, -2, -8, -7, -8, -12, -6, -17, -5, -22, -7]),
    (178, 2, 0, true, ARRAY[-20, -11, -15, -13, -10, -15, -5, -17, 0, -18, 5, -20, 10, -22, 15, -23, 19, -22, 19, -18, 15, -14, 10, -10, 5, -5, 0, -5, -5, -7, -10, -6, -15, -6, -20, -7]),
    (178, 3, 0, true, ARRAY[-17, -11, -12, -14, -7, -14, -2, -14, 3, -13, 8, -13, 13, -11, 16, -9, 16, -4, 13, -2, 8, -1, 3, 0, -2, 0, -7, -2, -12, -3, -17, -6]),
    (178, 4, 0, true, ARRAY[-23, -10, -18, -11, -13, -10, -8, -10, -3, -10, 2, -13, 7, -14, 12, -16, 17, -15, 22, -14, 22, -10, 17, -8, 12, -7, 7, -4, 2, -2, -3, -1, -8, 0, -13, -1, -18, -3, -23, -6]);

INSERT INTO "ecobeasts"."prop_type_lights" ("prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (178, 1, 0, -1, -16, 26, 'ff9a3c'),
    (178, 2, 0, 1, -14, 26, 'ff9a3c'),
    (178, 3, 0, 0, -8, 26, 'ff9a3c'),
    (178, 4, 0, -1, -8, 26, 'ff9a3c');
