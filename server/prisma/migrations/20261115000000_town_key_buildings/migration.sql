-- As construções-chave como objetos (.specs/town-art/01-key-buildings.md).

INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (21, 'refuge_building', 'Prédio do Refúgio', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (22, 'shop_building', 'Prédio da Loja', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (23, 'arena_building', 'Prédio da Arena', 1);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (21, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (21, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (21, 1, -1, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (22, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (22, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (22, 1, -1, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (23, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (23, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (23, 2, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (23, 1, -1, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (23, 2, -1, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
