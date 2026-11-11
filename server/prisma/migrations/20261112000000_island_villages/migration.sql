-- As construções viram ações (.specs/island-villages/01, RF-02 e RF-04).
ALTER TABLE "ecobeasts"."building_types" RENAME TO "action_types";
ALTER TABLE "ecobeasts"."action_types" RENAME CONSTRAINT "building_types_pkey" TO "action_types_pkey";
ALTER TABLE "ecobeasts"."action_types" RENAME CONSTRAINT "building_types_slug_check" TO "action_types_slug_check";
ALTER TABLE "ecobeasts"."action_types" RENAME CONSTRAINT "building_types_color_hex_check" TO "action_types_color_hex_check";
ALTER INDEX "ecobeasts"."building_types_slug_key" RENAME TO "action_types_slug_key";
ALTER SEQUENCE "ecobeasts"."building_types_id_seq" RENAME TO "action_types_id_seq";
ALTER TABLE "ecobeasts"."action_types" ADD COLUMN "kind" TEXT NOT NULL DEFAULT 'open_screen';
ALTER TABLE "ecobeasts"."action_types" ALTER COLUMN "kind" DROP DEFAULT;

ALTER TABLE "ecobeasts"."island_buildings" RENAME TO "island_actions";
ALTER TABLE "ecobeasts"."island_actions" RENAME COLUMN "building_type_id" TO "action_type_id";
ALTER TABLE "ecobeasts"."island_actions" RENAME CONSTRAINT "island_buildings_pkey" TO "island_actions_pkey";
ALTER TABLE "ecobeasts"."island_actions" RENAME CONSTRAINT "island_buildings_island_map_id_fkey" TO "island_actions_island_map_id_fkey";
ALTER TABLE "ecobeasts"."island_actions" RENAME CONSTRAINT "island_buildings_building_type_id_fkey" TO "island_actions_action_type_id_fkey";
ALTER INDEX "ecobeasts"."island_buildings_island_map_id_idx" RENAME TO "island_actions_island_map_id_idx";
ALTER INDEX "ecobeasts"."island_buildings_building_type_id_idx" RENAME TO "island_actions_action_type_id_idx";
ALTER SEQUENCE "ecobeasts"."island_buildings_id_seq" RENAME TO "island_actions_id_seq";

ALTER TABLE "ecobeasts"."island_building_tiles" RENAME TO "island_action_tiles";
ALTER TABLE "ecobeasts"."island_action_tiles" RENAME COLUMN "building_id" TO "action_id";
ALTER TABLE "ecobeasts"."island_action_tiles" RENAME CONSTRAINT "island_building_tiles_pkey" TO "island_action_tiles_pkey";
ALTER TABLE "ecobeasts"."island_action_tiles" RENAME CONSTRAINT "island_building_tiles_building_id_fkey" TO "island_action_tiles_action_id_fkey";
ALTER TABLE "ecobeasts"."island_action_tiles" RENAME CONSTRAINT "island_building_tiles_island_map_id_fkey" TO "island_action_tiles_island_map_id_fkey";
ALTER INDEX "ecobeasts"."island_building_tiles_island_map_id_q_r_key" RENAME TO "island_action_tiles_island_map_id_q_r_key";

-- O chão e os objetos (.specs/island-villages/architecture.md).
ALTER TABLE "ecobeasts"."island_tiles" ADD COLUMN "ground_type_id" INTEGER;

CREATE TABLE "ecobeasts"."ground_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "kind" TEXT NOT NULL,

    CONSTRAINT "ground_types_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."map_object_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "variants" INTEGER NOT NULL,

    CONSTRAINT "map_object_types_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."map_object_type_tiles" (
    "object_type_id" INTEGER NOT NULL,
    "dq" INTEGER NOT NULL,
    "dr" INTEGER NOT NULL,
    "blocks" BOOLEAN NOT NULL,

    CONSTRAINT "map_object_type_tiles_pkey" PRIMARY KEY ("object_type_id","dq","dr")
);

CREATE TABLE "ecobeasts"."island_objects" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "object_type_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "variant" INTEGER NOT NULL,
    "mirrored" BOOLEAN NOT NULL,

    CONSTRAINT "island_objects_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."island_object_tiles" (
    "object_id" INTEGER NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "blocks" BOOLEAN NOT NULL,

    CONSTRAINT "island_object_tiles_pkey" PRIMARY KEY ("object_id","q","r")
);

CREATE UNIQUE INDEX "ground_types_slug_key" ON "ecobeasts"."ground_types"("slug");
CREATE UNIQUE INDEX "map_object_types_slug_key" ON "ecobeasts"."map_object_types"("slug");
CREATE INDEX "island_objects_island_map_id_idx" ON "ecobeasts"."island_objects"("island_map_id");
CREATE INDEX "island_objects_object_type_id_idx" ON "ecobeasts"."island_objects"("object_type_id");
CREATE UNIQUE INDEX "island_object_tiles_island_map_id_q_r_key" ON "ecobeasts"."island_object_tiles"("island_map_id", "q", "r");
CREATE INDEX "island_tiles_ground_type_id_idx" ON "ecobeasts"."island_tiles"("ground_type_id");

ALTER TABLE "ecobeasts"."map_object_type_tiles" ADD CONSTRAINT "map_object_type_tiles_object_type_id_fkey" FOREIGN KEY ("object_type_id") REFERENCES "ecobeasts"."map_object_types"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_tiles" ADD CONSTRAINT "island_tiles_ground_type_id_fkey" FOREIGN KEY ("ground_type_id") REFERENCES "ecobeasts"."ground_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_objects" ADD CONSTRAINT "island_objects_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_objects" ADD CONSTRAINT "island_objects_object_type_id_fkey" FOREIGN KEY ("object_type_id") REFERENCES "ecobeasts"."map_object_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_object_tiles" ADD CONSTRAINT "island_object_tiles_object_id_fkey" FOREIGN KEY ("object_id") REFERENCES "ecobeasts"."island_objects"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_object_tiles" ADD CONSTRAINT "island_object_tiles_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Restrições escritas à mão: o Prisma não as acompanha (island-villages/01).
ALTER TABLE "ecobeasts"."action_types" ADD CONSTRAINT "action_types_kind_check" CHECK ("kind" IN ('open_screen'));
ALTER TABLE "ecobeasts"."ground_types" ADD CONSTRAINT "ground_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."ground_types" ADD CONSTRAINT "ground_types_kind_check" CHECK ("kind" IN ('trail', 'floor'));
ALTER TABLE "ecobeasts"."map_object_types" ADD CONSTRAINT "map_object_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."map_object_types" ADD CONSTRAINT "map_object_types_variants_check" CHECK ("variants" >= 1);
ALTER TABLE "ecobeasts"."island_objects" ADD CONSTRAINT "island_objects_variant_check" CHECK ("variant" >= 1);

-- As linhas iniciais: o banco já está carregado, e o seed só enche tabela vazia.
INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind") VALUES (1, 'dirt_trail', 'Trilha de terra', 'trail');
INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind") VALUES (2, 'stone_trail', 'Trilha de pedra', 'trail');
INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind") VALUES (3, 'cobble_floor', 'Praça de pedra', 'floor');
INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind") VALUES (4, 'dirt_floor', 'Chão de terra', 'floor');
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (1, 'house', 'Casa', 4);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (2, 'farmhouse', 'Casa com horta', 4);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (3, 'windmill', 'Moinho', 3);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (4, 'castle', 'Castelo', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (5, 'big_tree', 'Árvore grande', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (6, 'big_rock', 'Pedra grande', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (7, 'garden', 'Horta', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (8, 'fence', 'Cerca', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (9, 'well', 'Poço', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (10, 'market_stall', 'Barraca de feira', 3);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (11, 'cart', 'Carroça', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (12, 'bridge', 'Ponte', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (13, 'beast_stable', 'Estábulo de Ecobeasts', 2);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (14, 'treehouse', 'Casa na árvore', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (15, 'nest', 'Ninho grande', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (16, 'trough', 'Bebedouro', 1);
INSERT INTO "ecobeasts"."map_object_types" ("id", "slug", "name", "variants") VALUES (17, 'rune_shrine', 'Santuário de runas', 1);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (1, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (2, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (2, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (3, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (3, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (4, 0, 0, false);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (4, 0, -1, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (4, 1, -1, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (4, 1, -2, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (5, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (5, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (5, 1, -1, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (6, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (6, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (7, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (8, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (9, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (10, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (11, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (12, 0, 0, false);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (13, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (13, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (14, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (14, 1, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (15, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (16, 0, 0, true);
INSERT INTO "ecobeasts"."map_object_type_tiles" ("object_type_id", "dq", "dr", "blocks") VALUES (17, 0, 0, true);
SELECT setval('"ecobeasts"."ground_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."ground_types"));
SELECT setval('"ecobeasts"."map_object_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."map_object_types"));
