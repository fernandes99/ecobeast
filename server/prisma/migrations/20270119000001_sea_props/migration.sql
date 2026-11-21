-- Os 13 tipos de decoração da água viram peças soltas, na categoria Mar (.specs/sea-life/03-sea-props.md).

INSERT INTO "ecobeasts"."prop_categories" ("id", "slug", "name") VALUES
    (14, 'sea', 'Mar');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_categories"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_categories"));

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (139, 'seagrass', 'Capim-marinho', 4, 14),
    (140, 'kelp', 'Alga longa', 4, 14),
    (141, 'algae_patch', 'Tapete de algas', 4, 14),
    (142, 'sea_rock', 'Pedra no mar', 4, 14),
    (143, 'sunken_rock', 'Pedra submersa', 4, 14),
    (144, 'sea_stack', 'Rochedo no mar', 4, 14),
    (145, 'floating_weed', 'Alga boiando', 4, 14),
    (146, 'bottle', 'Garrafa', 4, 14),
    (147, 'can', 'Lata', 4, 14),
    (148, 'plastic_bag', 'Saco plástico', 4, 14),
    (149, 'fishing_net', 'Rede de pesca', 4, 14),
    (150, 'tire', 'Pneu', 4, 14),
    (151, 'crate', 'Caixote boiando', 4, 14);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));
