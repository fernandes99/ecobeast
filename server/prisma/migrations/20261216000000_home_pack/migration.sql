-- A casa grande e a cerca de estacas do pacote Main Characters Home (.specs/home-pack/).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (95, 'big_house', 'Casa grande', 1);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("id", "prop_type_id", "variant", "position", "closed", "points") VALUES
    (45, 95, 0, 0, true, ARRAY[-60, -2, 61, -2, 61, -44, -60, -44]);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));

INSERT INTO "ecobeasts"."wall_types" ("id", "slug", "name", "visible") VALUES
    (4, 'picket_fence', 'Cerca de estacas', true);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."wall_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."wall_types"));
