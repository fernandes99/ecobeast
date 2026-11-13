-- As casas da cidade, ao lado das de hoje (.specs/town-art/02-houses.md).

INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (24, 'town_house', 'Casa (cidade)', 9);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (25, 'town_house_medium', 'Casa média (cidade)', 12);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (26, 'town_house_large', 'Casa grande (cidade)', 10);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (24, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (25, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (25, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (26, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (26, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (26, 1, -1, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
