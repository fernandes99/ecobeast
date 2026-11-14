-- As peças soltas das ilhas (.specs/free-props/01-prop-records.md).
CREATE TABLE "ecobeasts"."prop_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "variants" INTEGER NOT NULL,

    CONSTRAINT "prop_types_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."island_props" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "prop_type_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "dx" INTEGER NOT NULL,
    "dy" INTEGER NOT NULL,
    "variant" INTEGER NOT NULL,
    "mirrored" BOOLEAN NOT NULL,

    CONSTRAINT "island_props_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "prop_types_slug_key" ON "ecobeasts"."prop_types"("slug");
CREATE INDEX "island_props_island_map_id_idx" ON "ecobeasts"."island_props"("island_map_id");
CREATE INDEX "island_props_prop_type_id_idx" ON "ecobeasts"."island_props"("prop_type_id");

ALTER TABLE "ecobeasts"."island_props" ADD CONSTRAINT "island_props_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_props" ADD CONSTRAINT "island_props_prop_type_id_fkey" FOREIGN KEY ("prop_type_id") REFERENCES "ecobeasts"."prop_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."prop_types" ADD CONSTRAINT "prop_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."prop_types" ADD CONSTRAINT "prop_types_variants_check" CHECK ("variants" >= 1);
ALTER TABLE "ecobeasts"."island_props" ADD CONSTRAINT "island_props_variant_check" CHECK ("variant" >= 1);

-- Os primeiros tipos: as plantas e pedras do terreno e as decorações de rua.
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (1, 'tree', 'Árvore', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (2, 'pine', 'Pinheiro', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (3, 'bush', 'Arbusto', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (4, 'dark_bush', 'Arbusto escuro', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (5, 'tuft', 'Tufo de grama', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (6, 'flowers', 'Flores', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (7, 'fern', 'Samambaia', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (8, 'dry_shrub', 'Arbusto seco', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (9, 'dry_tuft', 'Tufo seco', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (10, 'moss', 'Musgo', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (11, 'pebbles', 'Pedrinhas', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (12, 'rock', 'Pedra', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (13, 'mossy_rock', 'Pedra com musgo', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (14, 'brown_rock', 'Pedra marrom', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (15, 'boulder', 'Rochedo', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (16, 'rock_pile', 'Monte de pedras', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (17, 'spire', 'Agulha de pedra', 4);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (18, 'lamp_post', 'Poste de luz', 2);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (19, 'sign', 'Placa', 2);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (20, 'flower_bed', 'Canteiro de flores', 3);
INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES (21, 'bench', 'Banco', 2);
SELECT setval('"ecobeasts"."prop_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

-- O Poste, a Placa, o Canteiro e o Banco viram peças soltas; os ids 36 a 39 não voltam.
DELETE FROM "ecobeasts"."map_object_types" WHERE "id" IN (36, 37, 38, 39);
