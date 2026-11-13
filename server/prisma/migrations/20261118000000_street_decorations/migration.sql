-- As decorações de rua da cidade (.specs/town-art/04-street-decorations.md).

INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (36, 'lamp_post', 'Poste de luz', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (37, 'sign', 'Placa', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (38, 'flower_bed', 'Canteiro de flores', 3);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (39, 'bench', 'Banco', 2);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (36, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (37, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (38, 0, 0, false);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (39, 0, 0, true);
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
