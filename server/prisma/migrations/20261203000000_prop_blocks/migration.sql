-- As linhas de bloqueio das peças soltas (.specs/free-objects/01-prop-blocks.md).

CREATE TABLE "ecobeasts"."prop_type_blocks" (
    "id" SERIAL NOT NULL,
    "prop_type_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "closed" BOOLEAN NOT NULL,
    "points" INTEGER[],

    CONSTRAINT "prop_type_blocks_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "prop_type_blocks_prop_type_id_position_key" ON "ecobeasts"."prop_type_blocks"("prop_type_id", "position");
ALTER TABLE "ecobeasts"."prop_type_blocks" ADD CONSTRAINT "prop_type_blocks_prop_type_id_fkey" FOREIGN KEY ("prop_type_id") REFERENCES "ecobeasts"."prop_types"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."prop_type_blocks" ADD CONSTRAINT "prop_type_blocks_points_check" CHECK ("points" IS NOT NULL AND array_length("points", 1) BETWEEN 4 AND 128 AND array_length("points", 1) % 2 = 0);

ALTER TABLE "ecobeasts"."island_props" ADD COLUMN "custom_block" BOOLEAN NOT NULL DEFAULT false;

CREATE TABLE "ecobeasts"."island_prop_blocks" (
    "id" SERIAL NOT NULL,
    "island_prop_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "closed" BOOLEAN NOT NULL,
    "points" INTEGER[],

    CONSTRAINT "island_prop_blocks_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "island_prop_blocks_island_prop_id_position_key" ON "ecobeasts"."island_prop_blocks"("island_prop_id", "position");
ALTER TABLE "ecobeasts"."island_prop_blocks" ADD CONSTRAINT "island_prop_blocks_island_prop_id_fkey" FOREIGN KEY ("island_prop_id") REFERENCES "ecobeasts"."island_props"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_prop_blocks" ADD CONSTRAINT "island_prop_blocks_points_check" CHECK ("points" IS NOT NULL AND array_length("points", 1) BETWEEN 4 AND 128 AND array_length("points", 1) % 2 = 0);
