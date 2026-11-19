-- O Altar-portal, com o Veilmoth (variante 1) e vazio (variante 2) (.specs/portal-altar/01-portal-altar.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (101, 'portal_altar', 'Altar-portal', 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("id", "prop_type_id", "variant", "position", "closed", "points") VALUES
    (51, 101, 0, 0, true, ARRAY[-29, -12, -21, -4, 20, -4, 28, -12, 20, -19, -21, -19]);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));

INSERT INTO "ecobeasts"."prop_type_lights" ("id", "prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (150, 101, 1, 0, -1, -69, 10, 'a99bff'),
    (151, 101, 1, 1, -1, -39, 20, '7fe8ff'),
    (152, 101, 2, 0, -1, -69, 7, 'a99bff');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
