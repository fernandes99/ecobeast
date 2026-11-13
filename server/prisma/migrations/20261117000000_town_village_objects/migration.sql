-- Os objetos de vila da cidade, ao lado dos de hoje (.specs/town-art/03-village-objects.md).

INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (27, 'town_windmill', 'Moinho (cidade)', 3);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (28, 'town_garden', 'Horta (cidade)', 6);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (29, 'town_fence', 'Cerca (cidade)', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (30, 'town_well', 'Poço (cidade)', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (31, 'town_market_stall', 'Barraca de feira (cidade)', 3);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (32, 'town_cart', 'Carroça (cidade)', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (33, 'town_beast_stable', 'Estábulo de Ecobeasts (cidade)', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (34, 'town_trough', 'Bebedouro (cidade)', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (35, 'town_rune_shrine', 'Santuário de runas (cidade)', 4);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (27, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (27, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (28, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (29, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (30, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (31, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (32, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (33, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (33, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (34, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (35, 0, 0, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
