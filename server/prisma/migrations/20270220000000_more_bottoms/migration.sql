-- Mais 3 partes de baixo do Domador (.specs/tamer-looks/02-bottoms.md).
INSERT INTO "ecobeasts"."appearance_parts" ("id", "slug", "name", "appearance_slot_id", "body_type_id", "hair_cut") VALUES
    (23, 'long_skirt', 'Saia longa', 2, 2, 'none'),
    (24, 'capri_pants', 'Calça capri', 2, NULL, 'none'),
    (25, 'flared_pants', 'Calça boca de sino', 2, NULL, 'none');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."appearance_parts"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."appearance_parts"));
