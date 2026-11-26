-- Mais 2 calçados do Domador (.specs/tamer-looks/03-shoes.md).
INSERT INTO "ecobeasts"."appearance_parts" ("id", "slug", "name", "appearance_slot_id", "body_type_id", "hair_cut") VALUES
    (26, 'rain_boots', 'Galocha', 3, NULL, 'none'),
    (27, 'dress_shoes', 'Sapato', 3, NULL, 'none');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."appearance_parts"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."appearance_parts"));
