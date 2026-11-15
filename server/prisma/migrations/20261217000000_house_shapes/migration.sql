-- As casas do pacote Main Characters Home em 8 cores, a pequena e o sobrado pequeno (.specs/home-pack/03-house-shapes.md).

UPDATE "ecobeasts"."prop_types" SET "variants" = 8 WHERE "id" = 95;

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (96, 'small_house', 'Casa pequena', 8),
    (97, 'small_townhouse', 'Sobrado pequeno', 8);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("id", "prop_type_id", "variant", "position", "closed", "points") VALUES
    (46, 96, 0, 0, true, ARRAY[-45, -2, 43, -2, 43, -44, -45, -44]),
    (47, 97, 0, 0, true, ARRAY[-45, -2, 43, -2, 43, -44, -45, -44]);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));
