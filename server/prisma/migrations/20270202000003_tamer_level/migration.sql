-- O XP e o nível do Domador, de 1 a 99 (.specs/tamer-level/01-tamer-xp-server.md).

ALTER TABLE "ecobeasts"."players" ADD COLUMN "xp" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "ecobeasts"."players" ADD CONSTRAINT "players_xp_check" CHECK ("xp" >= 0);

CREATE TABLE "ecobeasts"."tamer_levels" (
    "level" INTEGER NOT NULL,
    "xp_total" INTEGER NOT NULL,
    "reward_coins" INTEGER NOT NULL DEFAULT 0,
    "reward_item_id" INTEGER,
    "reward_item_quantity" INTEGER,

    CONSTRAINT "tamer_levels_pkey" PRIMARY KEY ("level")
);

CREATE INDEX "tamer_levels_reward_item_id_idx" ON "ecobeasts"."tamer_levels"("reward_item_id");
ALTER TABLE "ecobeasts"."tamer_levels" ADD CONSTRAINT "tamer_levels_reward_item_id_fkey" FOREIGN KEY ("reward_item_id") REFERENCES "ecobeasts"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."tamer_levels" ADD CONSTRAINT "tamer_levels_level_check" CHECK ("level" >= 1);
ALTER TABLE "ecobeasts"."tamer_levels" ADD CONSTRAINT "tamer_levels_xp_total_check" CHECK ("xp_total" >= 0);
ALTER TABLE "ecobeasts"."tamer_levels" ADD CONSTRAINT "tamer_levels_reward_coins_check" CHECK ("reward_coins" >= 0);
ALTER TABLE "ecobeasts"."tamer_levels" ADD CONSTRAINT "tamer_levels_reward_item_quantity_check" CHECK ("reward_item_quantity" >= 1);
ALTER TABLE "ecobeasts"."tamer_levels" ADD CONSTRAINT "tamer_levels_reward_item_check" CHECK (("reward_item_id" IS NULL) = ("reward_item_quantity" IS NULL));

-- A curva e as recompensas são propostas a revisar: 40 × (n − 1) + 0,8 × (n − 1)³,
-- 50 + 10 × n moedas, 3 Esferas de Vínculo nos múltiplos de 5 e 3 Reforçadas nos de 10.
INSERT INTO "ecobeasts"."tamer_levels" ("level", "xp_total", "reward_coins", "reward_item_id", "reward_item_quantity")
SELECT
    n,
    round(40 * (n - 1) + 0.8 * power(n - 1, 3))::integer,
    CASE WHEN n = 1 THEN 0 ELSE 50 + 10 * n END,
    CASE WHEN n % 10 = 0 THEN 2 WHEN n % 5 = 0 THEN 1 END,
    CASE WHEN n % 5 = 0 THEN 3 END
FROM generate_series(1, 99) AS n;

CREATE TABLE "ecobeasts"."tamer_xp_sources" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "amount" INTEGER NOT NULL,

    CONSTRAINT "tamer_xp_sources_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "tamer_xp_sources_slug_key" ON "ecobeasts"."tamer_xp_sources"("slug");
ALTER TABLE "ecobeasts"."tamer_xp_sources" ADD CONSTRAINT "tamer_xp_sources_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."tamer_xp_sources" ADD CONSTRAINT "tamer_xp_sources_amount_check" CHECK ("amount" >= 0);

INSERT INTO "ecobeasts"."tamer_xp_sources" ("id", "slug", "name", "amount") VALUES
    (1, 'battle_xp_percent', 'Parte do XP da luta (%)', 10),
    (2, 'new_species', 'Primeira captura de uma espécie', 100),
    (3, 'tamer_win', 'Vitória contra um Domador NPC', 50),
    (4, 'island_tamer_win', 'Primeira vitória contra um Domador da ilha', 150),
    (5, 'island_tamer_rematch', 'Revanche vencida contra um Domador da ilha', 15),
    (6, 'quest', 'Missão entregue', 100),
    (7, 'arena', 'Arena ganha', 500),
    (8, 'island_unlocked', 'Ilha aberta', 1000);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."tamer_xp_sources"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."tamer_xp_sources"));
