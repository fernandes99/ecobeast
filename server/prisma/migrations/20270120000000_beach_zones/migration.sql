-- A zona Coqueiral da Praia (.specs/beach-life/02-beach-zones.md).
-- O id 32 foi da zona Algas mortas, que o dono tirou antes do commit; fica sem uso.

UPDATE "ecobeasts"."biome_zones" SET "share" = 75, "sort_order" = 2 WHERE "id" = 10;

INSERT INTO "ecobeasts"."biome_zones" ("id", "slug", "biome_id", "name", "share", "sort_order") VALUES
    (31, 'beach_palms', 10, 'Coqueiral', 25, 1);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."biome_zones"', 'id'), GREATEST(32, (SELECT MAX("id") FROM "ecobeasts"."biome_zones")));
