-- Os traços de caminho das ilhas (.specs/free-trails/03-trail-records.md).

CREATE TABLE "ecobeasts"."island_trails" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "ground_type_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "width" SMALLINT NOT NULL,
    "points" INTEGER[],

    CONSTRAINT "island_trails_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "island_trails_ground_type_id_idx" ON "ecobeasts"."island_trails"("ground_type_id");
CREATE UNIQUE INDEX "island_trails_island_map_id_position_key" ON "ecobeasts"."island_trails"("island_map_id", "position");

ALTER TABLE "ecobeasts"."island_trails" ADD CONSTRAINT "island_trails_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_trails" ADD CONSTRAINT "island_trails_ground_type_id_fkey" FOREIGN KEY ("ground_type_id") REFERENCES "ecobeasts"."ground_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."island_trails" ADD CONSTRAINT "island_trails_width_check" CHECK ("width" BETWEEN 8 AND 64);
ALTER TABLE "ecobeasts"."island_trails" ADD CONSTRAINT "island_trails_points_check" CHECK ("points" IS NOT NULL AND array_length("points", 1) BETWEEN 4 AND 512 AND array_length("points", 1) % 2 = 0);
