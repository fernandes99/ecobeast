-- A casinha de pedra da imagem do dono, em 8 cores (.specs/stone-cottage/01-stone-cottage.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (99, 'stone_cottage', 'Casinha de pedra', 8);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

INSERT INTO "ecobeasts"."prop_type_blocks" ("id", "prop_type_id", "variant", "position", "closed", "points") VALUES
    (49, 99, 0, 0, true, ARRAY[-21, -2, 20, -2, 20, -16, -21, -16]);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));
