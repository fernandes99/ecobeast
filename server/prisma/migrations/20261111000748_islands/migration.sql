-- CreateTable
CREATE TABLE "ecobeasts"."building_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color_hex" TEXT NOT NULL,

    CONSTRAINT "building_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."islands" (
    "id" SERIAL NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "published_at" TIMESTAMPTZ(3),

    CONSTRAINT "islands_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."island_maps" (
    "id" SERIAL NOT NULL,
    "island_id" INTEGER NOT NULL,
    "kind" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "start_q" INTEGER NOT NULL,
    "start_r" INTEGER NOT NULL,
    "content_hash" TEXT NOT NULL,
    "updated_at" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "island_maps_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."island_tiles" (
    "island_map_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "biome_id" INTEGER NOT NULL,
    "shape" TEXT NOT NULL,
    "variant" INTEGER NOT NULL,
    "area_id" INTEGER,

    CONSTRAINT "island_tiles_pkey" PRIMARY KEY ("island_map_id","q","r")
);

-- CreateTable
CREATE TABLE "ecobeasts"."island_buildings" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "building_type_id" INTEGER NOT NULL,

    CONSTRAINT "island_buildings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."island_building_tiles" (
    "building_id" INTEGER NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,

    CONSTRAINT "island_building_tiles_pkey" PRIMARY KEY ("building_id","q","r")
);

-- CreateTable
CREATE TABLE "ecobeasts"."island_areas" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "color_hex" TEXT NOT NULL,

    CONSTRAINT "island_areas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."island_area_species" (
    "area_id" INTEGER NOT NULL,
    "species_id" INTEGER NOT NULL,
    "weight" INTEGER NOT NULL,
    "min_level" INTEGER NOT NULL,
    "max_level" INTEGER NOT NULL,

    CONSTRAINT "island_area_species_pkey" PRIMARY KEY ("area_id","species_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "building_types_slug_key" ON "ecobeasts"."building_types"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "island_maps_island_id_kind_key" ON "ecobeasts"."island_maps"("island_id", "kind");

-- CreateIndex
CREATE INDEX "island_tiles_biome_id_idx" ON "ecobeasts"."island_tiles"("biome_id");

-- CreateIndex
CREATE INDEX "island_tiles_area_id_idx" ON "ecobeasts"."island_tiles"("area_id");

-- CreateIndex
CREATE INDEX "island_buildings_island_map_id_idx" ON "ecobeasts"."island_buildings"("island_map_id");

-- CreateIndex
CREATE INDEX "island_buildings_building_type_id_idx" ON "ecobeasts"."island_buildings"("building_type_id");

-- CreateIndex
CREATE UNIQUE INDEX "island_building_tiles_island_map_id_q_r_key" ON "ecobeasts"."island_building_tiles"("island_map_id", "q", "r");

-- CreateIndex
CREATE INDEX "island_areas_island_map_id_idx" ON "ecobeasts"."island_areas"("island_map_id");

-- CreateIndex
CREATE INDEX "island_area_species_species_id_idx" ON "ecobeasts"."island_area_species"("species_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_maps" ADD CONSTRAINT "island_maps_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_biome_id_fkey" FOREIGN KEY ("biome_id") REFERENCES "ecobeasts"."biomes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "ecobeasts"."island_areas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_buildings" ADD CONSTRAINT "island_buildings_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_buildings" ADD CONSTRAINT "island_buildings_building_type_id_fkey" FOREIGN KEY ("building_type_id") REFERENCES "ecobeasts"."building_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_building_tiles" ADD CONSTRAINT "island_building_tiles_building_id_fkey" FOREIGN KEY ("building_id") REFERENCES "ecobeasts"."island_buildings"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_building_tiles" ADD CONSTRAINT "island_building_tiles_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_areas" ADD CONSTRAINT "island_areas_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_area_species" ADD CONSTRAINT "island_area_species_area_id_fkey" FOREIGN KEY ("area_id") REFERENCES "ecobeasts"."island_areas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_area_species" ADD CONSTRAINT "island_area_species_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Restrições escritas à mão: o Prisma não as acompanha (map-editor/01).
ALTER TABLE "ecobeasts"."building_types" ADD CONSTRAINT "building_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."building_types" ADD CONSTRAINT "building_types_color_hex_check" CHECK ("color_hex" ~ '^#[0-9A-Fa-f]{6}$');
ALTER TABLE "ecobeasts"."island_maps" ADD CONSTRAINT "island_maps_kind_check" CHECK ("kind" IN ('draft', 'published'));
ALTER TABLE "ecobeasts"."island_maps" ADD CONSTRAINT "island_maps_name_check" CHECK (char_length("name") BETWEEN 1 AND 40);
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_shape_check" CHECK ("shape" IN ('flat', 'hill', 'mont'));
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_variant_check" CHECK ("variant" BETWEEN 1 AND CASE WHEN "shape" = 'flat' THEN 6 ELSE 3 END);
ALTER TABLE "ecobeasts"."island_areas" ADD CONSTRAINT "island_areas_name_check" CHECK (char_length("name") BETWEEN 1 AND 40);
ALTER TABLE "ecobeasts"."island_areas" ADD CONSTRAINT "island_areas_color_hex_check" CHECK ("color_hex" ~ '^#[0-9A-Fa-f]{6}$');
ALTER TABLE "ecobeasts"."island_area_species" ADD CONSTRAINT "island_area_species_weight_check" CHECK ("weight" > 0);
ALTER TABLE "ecobeasts"."island_area_species" ADD CONSTRAINT "island_area_species_level_check" CHECK ("min_level" BETWEEN 1 AND 100 AND "max_level" BETWEEN 1 AND 100 AND "min_level" <= "max_level");
