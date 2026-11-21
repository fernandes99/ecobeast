-- Os coqueiros da Praia viram peças soltas, na categoria Praia (.specs/beach-life/03-beach-props.md).
-- Os ids 154 a 164 foram dos objetos gerais e das algas mortas, que o dono tirou antes do commit; ficam sem uso.

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (152, 'coconut_palm', 'Coqueiro', 4, 8),
    (153, 'young_palm', 'Coqueiro novo', 4, 8);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), GREATEST(164, (SELECT MAX("id") FROM "ecobeasts"."prop_types")));
