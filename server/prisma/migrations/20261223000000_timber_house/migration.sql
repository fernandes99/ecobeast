-- A casa enxaimel do pacote Glassblower's Workshop, em 8 cores (.specs/timber-house/01-timber-house.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (98, 'timber_house', 'Casa enxaimel', 8);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("id", "prop_type_id", "variant", "position", "closed", "points") VALUES
    (48, 98, 0, 0, true, ARRAY[-53, -3, 52, -3, 52, -44, -53, -44]);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));

INSERT INTO "ecobeasts"."prop_type_lights" ("id", "prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (143, 98, 0, 0, 0, -94, 11, 'ffcf70'),
    (144, 98, 0, 1, -19, -54, 9, 'ffcf70'),
    (145, 98, 0, 2, 19, -54, 9, 'ffcf70'),
    (146, 98, 0, 3, -25, -24, 9, 'ffcf70'),
    (147, 98, 0, 4, 24, -24, 9, 'ffcf70');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
