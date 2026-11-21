-- As decorações da Geleira e a placa de gelo do Lago gelado viram peças soltas, na categoria Geleira (.specs/glacier/01-glacier-art.md).

INSERT INTO "ecobeasts"."prop_categories" ("id", "slug", "name") VALUES
    (15, 'glacier', 'Geleira');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_categories"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_categories"));

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (165, 'ice_crack', 'Rachadura no gelo', 4, 15),
    (166, 'ice_bubbles', 'Bolhas no gelo', 4, 15),
    (167, 'ice_chips', 'Lascas de gelo', 4, 15),
    (168, 'snow_drift', 'Neve soprada', 4, 15),
    (169, 'frozen_fish', 'Peixe no gelo', 4, 15),
    (170, 'ice_floe', 'Placa de gelo', 4, 15);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));
