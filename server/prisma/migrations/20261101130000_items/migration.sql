-- CreateTable
CREATE TABLE "ecobeasts"."item_categories" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL,

    CONSTRAINT "item_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."items" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "item_category_id" INTEGER NOT NULL,
    "price" INTEGER NOT NULL,
    "sort_order" INTEGER NOT NULL,
    "capture_bonus" DOUBLE PRECISION,
    "heal_amount" INTEGER,
    "cures_status" BOOLEAN NOT NULL DEFAULT false,

    CONSTRAINT "items_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "item_categories_slug_key" ON "ecobeasts"."item_categories"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "item_categories_sort_order_key" ON "ecobeasts"."item_categories"("sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "items_slug_key" ON "ecobeasts"."items"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "items_sort_order_key" ON "ecobeasts"."items"("sort_order");

-- CreateIndex
CREATE INDEX "items_item_category_id_idx" ON "ecobeasts"."items"("item_category_id");

-- CreateIndex
CREATE INDEX "inventory_items_item_id_idx" ON "ecobeasts"."inventory_items"("item_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."items" ADD CONSTRAINT "items_item_category_id_fkey" FOREIGN KEY ("item_category_id") REFERENCES "ecobeasts"."item_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."inventory_items" ADD CONSTRAINT "inventory_items_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "ecobeasts"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Restrições escritas à mão: o Prisma não as acompanha.
ALTER TABLE "ecobeasts"."item_categories" ADD CONSTRAINT "item_categories_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."items" ADD CONSTRAINT "items_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."items" ADD CONSTRAINT "items_price_check" CHECK ("price" >= 1);
ALTER TABLE "ecobeasts"."items" ADD CONSTRAINT "items_capture_bonus_check" CHECK ("capture_bonus" > 0);
ALTER TABLE "ecobeasts"."items" ADD CONSTRAINT "items_heal_amount_check" CHECK ("heal_amount" >= 1);
