-- A casinha enxaimel da imagem do dono, em 8 cores (.specs/timber-cottage/01-timber-cottage.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (100, 'timber_cottage', 'Casinha enxaimel', 8);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("id", "prop_type_id", "variant", "position", "closed", "points") VALUES
    (50, 100, 0, 0, true, ARRAY[-39, -2, 38, -2, 38, -16, -39, -16]);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));

INSERT INTO "ecobeasts"."prop_type_lights" ("id", "prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (148, 100, 0, 0, 20, -26, 9, 'ffcf70');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
