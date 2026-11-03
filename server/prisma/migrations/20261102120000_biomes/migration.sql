-- CreateTable
CREATE TABLE "ecobeasts"."biomes" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "biomes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."species_biomes" (
    "species_id" INTEGER NOT NULL,
    "biome_id" INTEGER NOT NULL,
    "rate" INTEGER NOT NULL,

    CONSTRAINT "species_biomes_pkey" PRIMARY KEY ("species_id","biome_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "biomes_slug_key" ON "ecobeasts"."biomes"("slug");

-- CreateIndex
CREATE INDEX "species_biomes_biome_id_idx" ON "ecobeasts"."species_biomes"("biome_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_biomes" ADD CONSTRAINT "species_biomes_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_biomes" ADD CONSTRAINT "species_biomes_biome_id_fkey" FOREIGN KEY ("biome_id") REFERENCES "ecobeasts"."biomes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Restrições escritas à mão: o Prisma não as acompanha.
ALTER TABLE "ecobeasts"."biomes" ADD CONSTRAINT "biomes_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."species_biomes" ADD CONSTRAINT "species_biomes_rate_check" CHECK ("rate" BETWEEN 0 AND 100);
