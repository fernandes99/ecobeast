-- Os tipos de parede e as paredes das ilhas (.specs/free-fences/01-wall-records.md).

CREATE TABLE "ecobeasts"."wall_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "visible" BOOLEAN NOT NULL,

    CONSTRAINT "wall_types_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "wall_types_slug_key" ON "ecobeasts"."wall_types"("slug");
ALTER TABLE "ecobeasts"."wall_types" ADD CONSTRAINT "wall_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');

INSERT INTO "ecobeasts"."wall_types" ("id", "slug", "name", "visible") VALUES
    (1, 'wood_fence', 'Cerca de madeira', true),
    (2, 'stone_fence', 'Muro de pedra', true),
    (3, 'invisible_wall', 'Parede invisível', false);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."wall_types"', 'id'), 3);

CREATE TABLE "ecobeasts"."island_walls" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "wall_type_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "points" INTEGER[],

    CONSTRAINT "island_walls_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "island_walls_wall_type_id_idx" ON "ecobeasts"."island_walls"("wall_type_id");
CREATE UNIQUE INDEX "island_walls_island_map_id_position_key" ON "ecobeasts"."island_walls"("island_map_id", "position");

ALTER TABLE "ecobeasts"."island_walls" ADD CONSTRAINT "island_walls_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_walls" ADD CONSTRAINT "island_walls_wall_type_id_fkey" FOREIGN KEY ("wall_type_id") REFERENCES "ecobeasts"."wall_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."island_walls" ADD CONSTRAINT "island_walls_points_check" CHECK ("points" IS NOT NULL AND array_length("points", 1) BETWEEN 4 AND 256 AND array_length("points", 1) % 2 = 0);
