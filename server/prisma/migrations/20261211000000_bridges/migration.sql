-- Os estilos de ponte e as pontes das ilhas (.specs/bridges/01-bridge-records.md).

CREATE TABLE "ecobeasts"."bridge_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "bridge_types_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "bridge_types_slug_key" ON "ecobeasts"."bridge_types"("slug");
ALTER TABLE "ecobeasts"."bridge_types" ADD CONSTRAINT "bridge_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');

INSERT INTO "ecobeasts"."bridge_types" ("id", "slug", "name") VALUES
    (1, 'cobble_bridge', 'Ponte de pedra'),
    (2, 'brick_bridge', 'Ponte de tijolo'),
    (3, 'slate_bridge', 'Ponte de lajes'),
    (4, 'rope_bridge', 'Ponte de corda'),
    (5, 'wood_bridge', 'Ponte de madeira'),
    (6, 'terracotta_bridge', 'Ponte de terracota'),
    (7, 'pier_bridge', 'Ponte de balaústre'),
    (8, 'ice_bridge', 'Ponte de pedra clara');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."bridge_types"', 'id'), 8);

CREATE TABLE "ecobeasts"."island_bridges" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "bridge_type_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "points" INTEGER[],

    CONSTRAINT "island_bridges_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "island_bridges_bridge_type_id_idx" ON "ecobeasts"."island_bridges"("bridge_type_id");
CREATE UNIQUE INDEX "island_bridges_island_map_id_position_key" ON "ecobeasts"."island_bridges"("island_map_id", "position");

ALTER TABLE "ecobeasts"."island_bridges" ADD CONSTRAINT "island_bridges_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_bridges" ADD CONSTRAINT "island_bridges_bridge_type_id_fkey" FOREIGN KEY ("bridge_type_id") REFERENCES "ecobeasts"."bridge_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."island_bridges" ADD CONSTRAINT "island_bridges_points_check" CHECK ("points" IS NOT NULL AND array_length("points", 1) = 4);
