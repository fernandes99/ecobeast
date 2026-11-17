-- O Puffcoo que o Domador observa no campo, na primeira cena da introdução (.specs/liora-intro/04-intro-scenes.md).

INSERT INTO "ecobeasts"."npcs" ("id", "slug", "name", "description", "sprite", "body_type_id", "skin_palette_id") VALUES
    (6, 'liora_puffcoo', 'Puffcoo', 'O Ecobeast que o Domador observa no campo.', 'puffcoo', NULL, NULL);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."npcs"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."npcs"));
