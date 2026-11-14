-- A aparência do Domador (.specs/tamer-appearance/01-appearance-records.md).
CREATE TABLE "ecobeasts"."body_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "body_types_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."appearance_slots" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "layer" INTEGER NOT NULL,
    "palette_kind" TEXT,
    "required" BOOLEAN NOT NULL,

    CONSTRAINT "appearance_slots_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."appearance_parts" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "appearance_slot_id" INTEGER NOT NULL,
    "body_type_id" INTEGER,
    "hair_cut" TEXT NOT NULL DEFAULT 'none',

    CONSTRAINT "appearance_parts_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."palettes" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "color_1_hex" TEXT NOT NULL,
    "color_2_hex" TEXT NOT NULL,
    "color_3_hex" TEXT NOT NULL,
    "color_4_hex" TEXT NOT NULL,

    CONSTRAINT "palettes_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."player_appearance_parts" (
    "player_id" UUID NOT NULL,
    "appearance_slot_id" INTEGER NOT NULL,
    "appearance_part_id" INTEGER NOT NULL,
    "palette_id" INTEGER,

    CONSTRAINT "player_appearance_parts_pkey" PRIMARY KEY ("player_id","appearance_slot_id")
);

CREATE UNIQUE INDEX "body_types_slug_key" ON "ecobeasts"."body_types"("slug");
CREATE UNIQUE INDEX "appearance_slots_slug_key" ON "ecobeasts"."appearance_slots"("slug");
CREATE UNIQUE INDEX "appearance_slots_layer_key" ON "ecobeasts"."appearance_slots"("layer");
CREATE UNIQUE INDEX "appearance_parts_slug_key" ON "ecobeasts"."appearance_parts"("slug");
CREATE INDEX "appearance_parts_appearance_slot_id_idx" ON "ecobeasts"."appearance_parts"("appearance_slot_id");
CREATE INDEX "appearance_parts_body_type_id_idx" ON "ecobeasts"."appearance_parts"("body_type_id");
CREATE UNIQUE INDEX "palettes_slug_key" ON "ecobeasts"."palettes"("slug");
CREATE INDEX "player_appearance_parts_appearance_slot_id_idx" ON "ecobeasts"."player_appearance_parts"("appearance_slot_id");
CREATE INDEX "player_appearance_parts_appearance_part_id_idx" ON "ecobeasts"."player_appearance_parts"("appearance_part_id");
CREATE INDEX "player_appearance_parts_palette_id_idx" ON "ecobeasts"."player_appearance_parts"("palette_id");

ALTER TABLE "ecobeasts"."appearance_parts" ADD CONSTRAINT "appearance_parts_appearance_slot_id_fkey" FOREIGN KEY ("appearance_slot_id") REFERENCES "ecobeasts"."appearance_slots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."appearance_parts" ADD CONSTRAINT "appearance_parts_body_type_id_fkey" FOREIGN KEY ("body_type_id") REFERENCES "ecobeasts"."body_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_appearance_parts" ADD CONSTRAINT "player_appearance_parts_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_appearance_parts" ADD CONSTRAINT "player_appearance_parts_appearance_slot_id_fkey" FOREIGN KEY ("appearance_slot_id") REFERENCES "ecobeasts"."appearance_slots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_appearance_parts" ADD CONSTRAINT "player_appearance_parts_appearance_part_id_fkey" FOREIGN KEY ("appearance_part_id") REFERENCES "ecobeasts"."appearance_parts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_appearance_parts" ADD CONSTRAINT "player_appearance_parts_palette_id_fkey" FOREIGN KEY ("palette_id") REFERENCES "ecobeasts"."palettes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."body_types" ADD CONSTRAINT "body_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."appearance_slots" ADD CONSTRAINT "appearance_slots_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."appearance_slots" ADD CONSTRAINT "appearance_slots_layer_check" CHECK ("layer" >= 1);
ALTER TABLE "ecobeasts"."appearance_slots" ADD CONSTRAINT "appearance_slots_palette_kind_check" CHECK ("palette_kind" IN ('skin', 'hair', 'cloth'));
ALTER TABLE "ecobeasts"."appearance_parts" ADD CONSTRAINT "appearance_parts_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."appearance_parts" ADD CONSTRAINT "appearance_parts_hair_cut_check" CHECK ("hair_cut" IN ('none', 'top', 'all'));
ALTER TABLE "ecobeasts"."palettes" ADD CONSTRAINT "palettes_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."palettes" ADD CONSTRAINT "palettes_kind_check" CHECK ("kind" IN ('skin', 'hair', 'cloth'));
ALTER TABLE "ecobeasts"."palettes" ADD CONSTRAINT "palettes_colors_check" CHECK (
    "color_1_hex" ~ '^#[0-9a-f]{6}$' AND "color_2_hex" ~ '^#[0-9a-f]{6}$'
    AND "color_3_hex" ~ '^#[0-9a-f]{6}$' AND "color_4_hex" ~ '^#[0-9a-f]{6}$'
);

-- O mínimo para a aparência padrão existir; o guarda-roupa vem na fase 4.
INSERT INTO "ecobeasts"."body_types" ("id", "slug", "name") VALUES
    (1, 'male', 'Masculino'),
    (2, 'female', 'Feminino');
INSERT INTO "ecobeasts"."appearance_slots" ("id", "slug", "name", "layer", "palette_kind", "required") VALUES
    (1, 'face', 'Rosto', 1, NULL, true),
    (2, 'bottom', 'Parte de baixo', 2, 'cloth', false),
    (3, 'shoes', 'Calçado', 3, 'cloth', false),
    (4, 'top', 'Parte de cima', 4, 'cloth', false),
    (5, 'hair', 'Cabelo', 5, 'hair', false),
    (6, 'headwear', 'Chapéu', 6, 'cloth', false);
INSERT INTO "ecobeasts"."palettes" ("id", "slug", "name", "kind", "color_1_hex", "color_2_hex", "color_3_hex", "color_4_hex") VALUES
    (1, 'skin_1', 'Pele 1', 'skin', '#f6d3b3', '#e3ad86', '#c4845f', '#8f5a3e'),
    (2, 'hair_brown', 'Castanho', 'hair', '#8a5a3a', '#6b4329', '#4e2f1c', '#301b10'),
    (3, 'cloth_blue', 'Azul', 'cloth', '#6fa8dc', '#4a82bf', '#345f99', '#22406b');
INSERT INTO "ecobeasts"."appearance_parts" ("id", "slug", "name", "appearance_slot_id", "body_type_id", "hair_cut") VALUES
    (1, 'face_1', 'Rosto 1', 1, NULL, 'none');
SELECT setval('"ecobeasts"."body_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."body_types"));
SELECT setval('"ecobeasts"."appearance_slots_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."appearance_slots"));
SELECT setval('"ecobeasts"."palettes_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."palettes"));
SELECT setval('"ecobeasts"."appearance_parts_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."appearance_parts"));

-- Quem já tem Domador fica com o corpo 1, a pele 1 e o rosto 1.
ALTER TABLE "ecobeasts"."players" ADD COLUMN "body_type_id" INTEGER NOT NULL DEFAULT 1,
    ADD COLUMN "skin_palette_id" INTEGER NOT NULL DEFAULT 1;
CREATE INDEX "players_body_type_id_idx" ON "ecobeasts"."players"("body_type_id");
CREATE INDEX "players_skin_palette_id_idx" ON "ecobeasts"."players"("skin_palette_id");
ALTER TABLE "ecobeasts"."players" ADD CONSTRAINT "players_body_type_id_fkey" FOREIGN KEY ("body_type_id") REFERENCES "ecobeasts"."body_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."players" ADD CONSTRAINT "players_skin_palette_id_fkey" FOREIGN KEY ("skin_palette_id") REFERENCES "ecobeasts"."palettes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
INSERT INTO "ecobeasts"."player_appearance_parts" ("player_id", "appearance_slot_id", "appearance_part_id", "palette_id")
    SELECT "id", 1, 1, NULL FROM "ecobeasts"."players";
