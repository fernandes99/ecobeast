-- As categorias das peças soltas, para a ferramenta Peças do editor (.specs/editor-ui/01-prop-categories.md).

CREATE TABLE "ecobeasts"."prop_categories" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "prop_categories_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "prop_categories_slug_key" ON "ecobeasts"."prop_categories"("slug");
ALTER TABLE "ecobeasts"."prop_categories" ADD CONSTRAINT "prop_categories_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');

INSERT INTO "ecobeasts"."prop_categories" ("id", "slug", "name") VALUES
    (1, 'houses', 'Casas'),
    (2, 'buildings', 'Prédios'),
    (3, 'trees', 'Árvores'),
    (4, 'plants', 'Plantas'),
    (5, 'flowers', 'Flores'),
    (6, 'rocks', 'Pedras'),
    (7, 'wood', 'Troncos e galhos'),
    (8, 'beach', 'Praia'),
    (9, 'lights', 'Iluminação'),
    (10, 'objects', 'Objetos'),
    (11, 'signs', 'Placas'),
    (12, 'water', 'Água'),
    (13, 'garden', 'Jardim e plantação');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_categories"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_categories"));

ALTER TABLE "ecobeasts"."prop_types" ADD COLUMN "prop_category_id" INTEGER NOT NULL DEFAULT 10;
CREATE INDEX "prop_types_prop_category_id_idx" ON "ecobeasts"."prop_types"("prop_category_id");
ALTER TABLE "ecobeasts"."prop_types" ADD CONSTRAINT "prop_types_prop_category_id_fkey" FOREIGN KEY ("prop_category_id") REFERENCES "ecobeasts"."prop_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 1 WHERE "id" IN (24, 25, 26, 95, 96, 97, 98, 99, 100, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 2 WHERE "id" IN (22, 23, 27, 101);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 3 WHERE "id" IN (1, 2, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 63, 67, 68, 69);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 4 WHERE "id" IN (3, 4, 5, 7, 8, 9, 10, 40, 42, 43, 46, 47, 48, 49, 50, 51, 52, 61, 65, 66, 73, 74, 76, 77, 78, 83, 86, 89);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 5 WHERE "id" IN (6, 44, 45, 75, 80, 84, 128);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 6 WHERE "id" IN (11, 12, 13, 14, 15, 16, 17, 53, 54, 55, 56, 57, 58, 59, 60, 62, 64, 81, 82, 88);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 7 WHERE "id" IN (39, 41, 70, 71, 72, 79, 85, 87, 90);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 8 WHERE "id" IN (91, 92, 93, 94);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 9 WHERE "id" IN (18, 123);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 10 WHERE "id" IN (21, 116, 117, 118, 119, 124, 125);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 11 WHERE "id" IN (19, 120, 121, 122, 129, 130);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 12 WHERE "id" IN (112, 113, 114, 115);
UPDATE "ecobeasts"."prop_types" SET "prop_category_id" = 13 WHERE "id" IN (20, 126, 127);
