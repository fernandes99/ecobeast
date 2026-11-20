-- As casas da vila do tileset Village do Fantasy Dreamland Reborn, em 8 cores (.specs/village-pack/01-village-houses.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (102, 'village_cottage', 'Casinha da vila', 8),
    (103, 'village_house', 'Casa da vila', 8),
    (104, 'village_wing_house', 'Casa de ala comprida', 8),
    (105, 'village_manor', 'Casa grande da vila', 8),
    (106, 'village_longhouse', 'Casa comprida da vila', 8),
    (107, 'village_townhouse', 'Sobrado da vila', 8),
    (108, 'village_large_townhouse', 'Sobrado grande da vila', 8),
    (109, 'village_long_townhouse', 'Sobrado comprido da vila', 8),
    (110, 'village_twin_house', 'Casa de dois frontões', 8),
    (111, 'village_row_house', 'Casa de três frontões', 8);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));
INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (102, 0, 0, true, ARRAY[-28, -2, 27, -2, 27, -14, -28, -14]),
    (103, 0, 0, true, ARRAY[-42, -2, 43, -2, 43, -14, -42, -14]),
    (104, 0, 0, true, ARRAY[-50, -2, 51, -2, 51, -14, -50, -14]),
    (105, 0, 0, true, ARRAY[-58, -2, 57, -2, 57, -14, -58, -14]),
    (106, 0, 0, true, ARRAY[-74, -2, 73, -2, 73, -14, -74, -14]),
    (107, 0, 0, true, ARRAY[-28, -2, 27, -2, 27, -14, -28, -14]),
    (108, 0, 0, true, ARRAY[-58, -2, 57, -2, 57, -14, -58, -14]),
    (109, 0, 0, true, ARRAY[-74, -2, 73, -2, 73, -14, -74, -14]),
    (110, 0, 0, true, ARRAY[-76, -2, 75, -2, 75, -14, -76, -14]),
    (111, 0, 0, true, ARRAY[-124, -2, 123, -2, 123, -14, -124, -14]);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
INSERT INTO "ecobeasts"."prop_type_lights" ("prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (103, 0, 0, -32, -31, 8, 'ffcf70'),
    (104, 0, 0, 23, -66, 8, 'ffcf70'),
    (104, 0, 1, -32, -31, 8, 'ffcf70'),
    (105, 0, 0, -1, -66, 8, 'ffcf70'),
    (105, 0, 1, -48, -31, 8, 'ffcf70'),
    (105, 0, 2, 46, -31, 8, 'ffcf70'),
    (106, 0, 0, -1, -66, 8, 'ffcf70'),
    (106, 0, 1, -56, -31, 8, 'ffcf70'),
    (106, 0, 2, 54, -31, 8, 'ffcf70'),
    (107, 0, 0, -1, -86, 8, 'ffcf70'),
    (107, 0, 1, -1, -40, 8, 'ffcf70'),
    (108, 0, 0, -1, -86, 8, 'ffcf70'),
    (108, 0, 1, -48, -55, 8, 'ffcf70'),
    (108, 0, 2, 46, -55, 8, 'ffcf70'),
    (108, 0, 3, -1, -40, 8, 'ffcf70'),
    (108, 0, 4, -48, -31, 8, 'ffcf70'),
    (108, 0, 5, 46, -31, 8, 'ffcf70'),
    (109, 0, 0, -1, -86, 8, 'ffcf70'),
    (109, 0, 1, -56, -55, 8, 'ffcf70'),
    (109, 0, 2, 54, -55, 8, 'ffcf70'),
    (109, 0, 3, -1, -40, 8, 'ffcf70'),
    (109, 0, 4, -56, -31, 8, 'ffcf70'),
    (109, 0, 5, 54, -31, 8, 'ffcf70'),
    (110, 0, 0, -49, -66, 8, 'ffcf70'),
    (110, 0, 1, 47, -66, 8, 'ffcf70'),
    (110, 0, 2, -1, -31, 8, 'ffcf70'),
    (111, 0, 0, -97, -66, 8, 'ffcf70'),
    (111, 0, 1, -1, -66, 8, 'ffcf70'),
    (111, 0, 2, 95, -66, 8, 'ffcf70'),
    (111, 0, 3, -49, -31, 8, 'ffcf70'),
    (111, 0, 4, 47, -31, 8, 'ffcf70');
