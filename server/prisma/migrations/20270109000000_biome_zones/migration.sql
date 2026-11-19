-- As zonas dos biomas e as exceções de nascimento por zona (.specs/biome-zones/01-zone-records.md).

CREATE TABLE "ecobeasts"."biome_zones" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "biome_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "share" INTEGER NOT NULL,
    "sort_order" INTEGER NOT NULL,

    CONSTRAINT "biome_zones_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "biome_zones_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$'),
    CONSTRAINT "biome_zones_name_check" CHECK (char_length("name") BETWEEN 1 AND 40),
    CONSTRAINT "biome_zones_share_check" CHECK ("share" BETWEEN 0 AND 100)
);

CREATE UNIQUE INDEX "biome_zones_slug_key" ON "ecobeasts"."biome_zones"("slug");
CREATE INDEX "biome_zones_biome_id_idx" ON "ecobeasts"."biome_zones"("biome_id");

ALTER TABLE "ecobeasts"."biome_zones" ADD CONSTRAINT "biome_zones_biome_id_fkey" FOREIGN KEY ("biome_id") REFERENCES "ecobeasts"."biomes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

CREATE TABLE "ecobeasts"."species_biome_zones" (
    "species_id" INTEGER NOT NULL,
    "biome_zone_id" INTEGER NOT NULL,
    "rate_percent" INTEGER NOT NULL,

    CONSTRAINT "species_biome_zones_pkey" PRIMARY KEY ("species_id","biome_zone_id"),
    CONSTRAINT "species_biome_zones_rate_percent_check" CHECK ("rate_percent" BETWEEN 0 AND 1000)
);

CREATE INDEX "species_biome_zones_biome_zone_id_idx" ON "ecobeasts"."species_biome_zones"("biome_zone_id");

ALTER TABLE "ecobeasts"."species_biome_zones" ADD CONSTRAINT "species_biome_zones_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."species_biome_zones" ADD CONSTRAINT "species_biome_zones_biome_zone_id_fkey" FOREIGN KEY ("biome_zone_id") REFERENCES "ecobeasts"."biome_zones"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- A Comum de cada bioma tem o id e o slug dele.
INSERT INTO "ecobeasts"."biome_zones" ("id", "slug", "biome_id", "name", "share", "sort_order") VALUES
    (1, 'temperate', 1, 'Comum', 40, 3),
    (2, 'boreal', 2, 'Comum', 40, 3),
    (3, 'stone', 3, 'Comum', 40, 1),
    (4, 'hill', 4, 'Comum', 40, 2),
    (5, 'mountain', 5, 'Comum', 100, 1),
    (6, 'wshallow', 6, 'Comum', 100, 1),
    (7, 'wdeep', 7, 'Comum', 100, 1),
    (8, 'desert', 8, 'Comum', 40, 2),
    (9, 'snow', 9, 'Comum', 40, 2),
    (10, 'beach', 10, 'Comum', 100, 1),
    (11, 'wford', 11, 'Comum', 100, 1),
    (12, 'temperate_clearing', 1, 'Clareira', 15, 1),
    (13, 'temperate_meadow', 1, 'Campo florido', 15, 2),
    (14, 'temperate_shrubland', 1, 'Arbustal', 15, 4),
    (15, 'temperate_woods', 1, 'Bosque', 15, 5),
    (16, 'boreal_clearing', 2, 'Clareira', 30, 1),
    (17, 'boreal_ferns', 2, 'Samambaial', 30, 2),
    (18, 'hill_scree', 4, 'Pedregal', 30, 1),
    (19, 'hill_dry_brush', 4, 'Mato seco', 30, 3),
    (20, 'stone_crags', 3, 'Rochedo', 60, 2),
    (21, 'desert_dunes', 8, 'Dunas', 30, 1),
    (22, 'desert_cacti', 8, 'Cactal', 30, 3),
    (23, 'snow_field', 9, 'Campo de neve', 30, 1),
    (24, 'snow_pines', 9, 'Pinheiral nevado', 30, 3);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."biome_zones"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."biome_zones"));

INSERT INTO "ecobeasts"."species_biome_zones" ("species_id", "biome_zone_id", "rate_percent")
SELECT "v"."species_id", "v"."biome_zone_id", "v"."rate_percent"
FROM (VALUES
    (1, 19, 200),
    (1, 21, 150),
    (1, 15, 50),
    (2, 18, 200),
    (2, 20, 150),
    (7, 15, 200),
    (7, 17, 200),
    (7, 12, 50),
    (8, 15, 200),
    (15, 12, 200),
    (15, 13, 200),
    (15, 16, 200),
    (15, 15, 50),
    (16, 13, 150)
) AS "v"("species_id", "biome_zone_id", "rate_percent")
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."species" WHERE "id" = "v"."species_id");
