-- Alcance, forma e marca no chão das Técnicas (.specs/board-battle/01-skill-areas.md).

-- CreateTable
CREATE TABLE "ecobeasts"."area_shapes" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "area_shapes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."ground_effects" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "damage_percent" INTEGER,
    "status_condition_id" INTEGER,
    "color_hex" TEXT NOT NULL,

    CONSTRAINT "ground_effects_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "area_shapes_slug_key" ON "ecobeasts"."area_shapes"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "ground_effects_slug_key" ON "ecobeasts"."ground_effects"("slug");

-- CreateIndex
CREATE INDEX "ground_effects_status_condition_id_idx" ON "ecobeasts"."ground_effects"("status_condition_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."ground_effects" ADD CONSTRAINT "ground_effects_status_condition_id_fkey" FOREIGN KEY ("status_condition_id") REFERENCES "ecobeasts"."status_conditions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- As linhas vêm aqui, e não só da carga inicial: ela só preenche tabelas vazias,
-- e a coluna area_shape_id das Técnicas já existentes precisa da forma 1.
INSERT INTO "ecobeasts"."area_shapes" ("id", "slug", "name") VALUES
    (1, 'single', 'Um alvo'),
    (2, 'line', 'Linha reta');
INSERT INTO "ecobeasts"."ground_effects" ("id", "slug", "name", "damage_percent", "status_condition_id", "color_hex") VALUES
    (1, 'fire', 'Chão em chamas', 6, NULL, '#E8622C');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."area_shapes"', 'id'), 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."ground_effects"', 'id'), 1);

-- AlterTable
ALTER TABLE "ecobeasts"."skills" ADD COLUMN     "area_shape_id" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "range" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "pierces" BOOLEAN NOT NULL DEFAULT false,
ADD COLUMN     "ground_effect_id" INTEGER,
ADD COLUMN     "ground_turns" INTEGER;

-- CreateIndex
CREATE INDEX "skills_area_shape_id_idx" ON "ecobeasts"."skills"("area_shape_id");

-- CreateIndex
CREATE INDEX "skills_ground_effect_id_idx" ON "ecobeasts"."skills"("ground_effect_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_area_shape_id_fkey" FOREIGN KEY ("area_shape_id") REFERENCES "ecobeasts"."area_shapes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_ground_effect_id_fkey" FOREIGN KEY ("ground_effect_id") REFERENCES "ecobeasts"."ground_effects"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- As duas primeiras formas (_a revisar_). As outras Técnicas ficam no padrão:
-- um alvo, alcance 1, sem atravessar e sem marca.
UPDATE "ecobeasts"."skills" SET "area_shape_id" = 2, "range" = 3 WHERE "slug" = 'faisca_rapida';
UPDATE "ecobeasts"."skills" SET "range" = 3, "ground_effect_id" = 1, "ground_turns" = 6 WHERE "slug" = 'chama_espiral';

-- Restrições escritas à mão: o Prisma não as acompanha.
ALTER TABLE "ecobeasts"."area_shapes" ADD CONSTRAINT "area_shapes_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."ground_effects" ADD CONSTRAINT "ground_effects_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."ground_effects" ADD CONSTRAINT "ground_effects_damage_percent_check" CHECK ("damage_percent" BETWEEN 1 AND 100);
ALTER TABLE "ecobeasts"."ground_effects" ADD CONSTRAINT "ground_effects_color_hex_check" CHECK ("color_hex" ~ '^#[0-9A-Fa-f]{6}$');
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_range_check" CHECK ("range" BETWEEN 1 AND 6);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_ground_turns_check" CHECK ("ground_turns" BETWEEN 1 AND 20);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_ground_pair_check" CHECK (("ground_effect_id" IS NULL) = ("ground_turns" IS NULL));
