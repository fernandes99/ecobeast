-- A Fonte, para a praça dos carimbos (.specs/free-props/04-stamps.md).

INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (40, 'fountain', 'Fonte', 1);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (40, 0, 0, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
