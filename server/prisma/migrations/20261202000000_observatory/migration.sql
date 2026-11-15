-- O Observatório, um prédio de 3 hexágonos com a arte do dono (.specs/town-art/06-observatory.md).

INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (41, 'observatory', 'Observatório', 1);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (41, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (41, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (41, 1, -1, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
