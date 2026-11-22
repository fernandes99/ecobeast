-- Os itens no chão das ilhas e a missão "Encontre X item" (auralis/09).

ALTER TABLE "ecobeasts"."quests" ADD COLUMN "target_item_id" INTEGER;

CREATE TABLE "ecobeasts"."island_ground_items" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "key" INTEGER NOT NULL,
    "item_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,
    "once" BOOLEAN NOT NULL,
    "hidden" BOOLEAN NOT NULL,

    CONSTRAINT "island_ground_items_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "island_ground_items_key_check" CHECK ("key" > 0),
    CONSTRAINT "island_ground_items_quantity_check" CHECK ("quantity" BETWEEN 1 AND 99)
);

CREATE TABLE "ecobeasts"."player_ground_items" (
    "player_id" UUID NOT NULL,
    "island_id" INTEGER NOT NULL,
    "item_key" INTEGER NOT NULL,
    "picked_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "player_ground_items_pkey" PRIMARY KEY ("player_id","island_id","item_key")
);

CREATE INDEX "island_ground_items_item_id_idx" ON "ecobeasts"."island_ground_items"("item_id");
CREATE UNIQUE INDEX "island_ground_items_island_map_id_key_key" ON "ecobeasts"."island_ground_items"("island_map_id", "key");
CREATE UNIQUE INDEX "island_ground_items_island_map_id_q_r_key" ON "ecobeasts"."island_ground_items"("island_map_id", "q", "r");
CREATE INDEX "player_ground_items_island_id_idx" ON "ecobeasts"."player_ground_items"("island_id");
CREATE INDEX "quests_target_item_id_idx" ON "ecobeasts"."quests"("target_item_id");

ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_target_item_id_fkey" FOREIGN KEY ("target_item_id") REFERENCES "ecobeasts"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_ground_items" ADD CONSTRAINT "island_ground_items_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_ground_items" ADD CONSTRAINT "island_ground_items_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "ecobeasts"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_ground_items" ADD CONSTRAINT "player_ground_items_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_ground_items" ADD CONSTRAINT "player_ground_items_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."quests" DROP CONSTRAINT "quests_params_check";
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_params_check" CHECK (COALESCE(
    CASE "quest_type_id"
        WHEN 1 THEN "amount" > 0
        WHEN 2 THEN "amount" > 0
        WHEN 3 THEN "amount" BETWEEN 1 AND 100
        WHEN 4 THEN "place_name" IS NOT NULL
        WHEN 5 THEN "target_npc_id" IS NOT NULL
        WHEN 6 THEN "amount" > 0
        WHEN 7 THEN "species_id" IS NOT NULL AND ("amount" IS NULL OR "amount" > 0)
        WHEN 8 THEN "species_id" IS NOT NULL AND ("amount" IS NULL OR "amount" > 0)
        WHEN 9 THEN "target_npc_id" IS NOT NULL
        WHEN 10 THEN "target_item_id" IS NOT NULL AND ("amount" IS NULL OR "amount" > 0)
        ELSE false
    END, false
));

INSERT INTO "ecobeasts"."quest_types" ("id", "slug", "name", "description") VALUES
  (10, 'find_item', 'Encontre um item', 'Pede target_item_id e amount opcional (1): todo item dele ganho depois de aceitar, no chão, na Loja, na entrega de missão e no nível do Domador.');
