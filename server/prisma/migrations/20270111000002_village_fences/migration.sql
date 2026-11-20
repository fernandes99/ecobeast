-- A cerca de madeira e o muro de pedra da vila do Fantasy Dreamland Reborn (.specs/village-pack/03-village-fences.md).

INSERT INTO "ecobeasts"."wall_types" ("id", "slug", "name", "visible") VALUES
    (5, 'village_fence', 'Cerca da vila', true),
    (6, 'village_wall', 'Muro da vila', true);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."wall_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."wall_types"));
