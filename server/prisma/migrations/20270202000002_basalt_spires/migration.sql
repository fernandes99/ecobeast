-- Os picos de basalto do Vulcão, na categoria Vulcão, com o bloqueio no pé (.specs/volcano/02-basalt-spires.md).
-- O Pico com veio de lava acende o veio à noite.

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (184, 'basalt_spire', 'Pico de basalto', 1, 16),
    (185, 'basalt_twin', 'Picos gêmeos', 1, 16),
    (186, 'basalt_crown', 'Coroa de picos', 1, 16),
    (187, 'basalt_columns', 'Colunas de basalto', 1, 16),
    (188, 'lava_vein_spire', 'Pico com veio de lava', 1, 16),
    (189, 'ash_boulder', 'Rochedo de cinza', 1, 16);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (184, 0, 0, true, ARRAY[-22, -14, -11, -5, 11, -5, 22, -14, 11, -23, -11, -23]),
    (185, 0, 0, true, ARRAY[-25, -16, -13, -6, 12, -6, 25, -16, 12, -26, -13, -26]),
    (186, 0, 0, true, ARRAY[-34, -24, -17, -10, 17, -10, 34, -24, 17, -38, -17, -38]),
    (187, 0, 0, true, ARRAY[-33, -22, -17, -9, 16, -9, 33, -22, 16, -35, -17, -35]),
    (188, 0, 0, true, ARRAY[-24, -16, -12, -6, 12, -6, 24, -16, 12, -26, -12, -26]),
    (189, 0, 0, true, ARRAY[-32, -22, -16, -9, 16, -9, 32, -22, 16, -35, -16, -35]);

INSERT INTO "ecobeasts"."prop_type_lights" ("prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (188, 1, 0, 0, -70, 30, 'ff9a3c');
