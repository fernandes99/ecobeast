-- A ordem das ilhas no Arquipélago, o que cada uma destrava e as ilhas abertas do jogador (.specs/auralis/01-unlock-config.md).

ALTER TABLE "ecobeasts"."islands" ADD COLUMN "archipelago_order" INTEGER;
ALTER TABLE "ecobeasts"."islands" ADD CONSTRAINT "islands_archipelago_order_check" CHECK ("archipelago_order" > 0);
CREATE UNIQUE INDEX "islands_archipelago_order_key" ON "ecobeasts"."islands"("archipelago_order");

CREATE TABLE "ecobeasts"."island_unlock_biomes" (
    "island_id" INTEGER NOT NULL,
    "biome_id" INTEGER NOT NULL,

    CONSTRAINT "island_unlock_biomes_pkey" PRIMARY KEY ("island_id","biome_id")
);

CREATE TABLE "ecobeasts"."island_unlock_species" (
    "island_id" INTEGER NOT NULL,
    "species_id" INTEGER NOT NULL,
    "random_only" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "island_unlock_species_pkey" PRIMARY KEY ("island_id","species_id")
);

CREATE TABLE "ecobeasts"."player_islands" (
    "player_id" UUID NOT NULL,
    "island_id" INTEGER NOT NULL,
    "unlocked_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "player_islands_pkey" PRIMARY KEY ("player_id","island_id")
);

CREATE INDEX "island_unlock_biomes_biome_id_idx" ON "ecobeasts"."island_unlock_biomes"("biome_id");
CREATE INDEX "island_unlock_species_species_id_idx" ON "ecobeasts"."island_unlock_species"("species_id");
CREATE INDEX "player_islands_island_id_idx" ON "ecobeasts"."player_islands"("island_id");

ALTER TABLE "ecobeasts"."island_unlock_biomes" ADD CONSTRAINT "island_unlock_biomes_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_unlock_biomes" ADD CONSTRAINT "island_unlock_biomes_biome_id_fkey" FOREIGN KEY ("biome_id") REFERENCES "ecobeasts"."biomes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_unlock_species" ADD CONSTRAINT "island_unlock_species_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_unlock_species" ADD CONSTRAINT "island_unlock_species_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_islands" ADD CONSTRAINT "player_islands_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_islands" ADD CONSTRAINT "player_islands_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Liora é a 1ª ilha, e as listas começam pelo que ela já tem, para o dono ajustar no painel.
UPDATE "ecobeasts"."islands" SET "archipelago_order" = 1 WHERE "id" = 1199;

INSERT INTO "ecobeasts"."island_unlock_biomes" ("island_id", "biome_id")
SELECT DISTINCT m."island_id", t."biome_id"
FROM "ecobeasts"."island_maps" m
JOIN "ecobeasts"."island_tiles" t ON t."island_map_id" = m."id"
WHERE m."island_id" = 1199 AND m."kind" = 'published';

INSERT INTO "ecobeasts"."island_unlock_species" ("island_id", "species_id")
SELECT DISTINCT m."island_id", s."species_id"
FROM "ecobeasts"."island_maps" m
JOIN "ecobeasts"."island_areas" a ON a."island_map_id" = m."id"
JOIN "ecobeasts"."island_area_species" s ON s."area_id" = a."id"
WHERE m."island_id" = 1199 AND m."kind" = 'published';
