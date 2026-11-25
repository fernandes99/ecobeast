-- Mais 5 rostos do Domador (.specs/tamer-looks/01-faces.md).
INSERT INTO "ecobeasts"."appearance_parts" ("id", "slug", "name", "appearance_slot_id", "body_type_id", "hair_cut") VALUES
    (18, 'face_3', 'Rosto 3', 1, NULL, 'none'),
    (19, 'face_4', 'Rosto 4', 1, NULL, 'none'),
    (20, 'face_5', 'Rosto 5', 1, NULL, 'none'),
    (21, 'face_6', 'Rosto 6', 1, NULL, 'none'),
    (22, 'face_7', 'Rosto 7', 1, NULL, 'none');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."appearance_parts"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."appearance_parts"));
