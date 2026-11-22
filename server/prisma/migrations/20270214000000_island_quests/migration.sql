-- As missões das ilhas, com os 9 tipos base (.specs/auralis/06-island-quests.md).

ALTER TABLE "ecobeasts"."islands" ADD COLUMN "required_quests" INTEGER;
ALTER TABLE "ecobeasts"."islands" ADD CONSTRAINT "islands_required_quests_check" CHECK ("required_quests" > 0);

CREATE TABLE "ecobeasts"."quest_types" (
    "id" INTEGER NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "quest_types_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "quest_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$')
);

CREATE TABLE "ecobeasts"."quests" (
    "id" SERIAL NOT NULL,
    "island_id" INTEGER NOT NULL,
    "npc_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "quest_type_id" INTEGER NOT NULL,
    "amount" INTEGER,
    "species_id" INTEGER,
    "target_npc_id" INTEGER,
    "place_name" TEXT,
    "title" TEXT,
    "coins" INTEGER NOT NULL DEFAULT 0,
    "item_id" INTEGER,
    "item_quantity" INTEGER,
    "counts_for_unlock" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "quests_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "quests_position_check" CHECK ("position" > 0),
    CONSTRAINT "quests_place_name_check" CHECK (char_length("place_name") BETWEEN 1 AND 40),
    CONSTRAINT "quests_title_check" CHECK (char_length("title") BETWEEN 1 AND 60),
    CONSTRAINT "quests_coins_check" CHECK ("coins" >= 0),
    CONSTRAINT "quests_item_check" CHECK (
        ("item_id" IS NULL AND "item_quantity" IS NULL)
        OR ("item_id" IS NOT NULL AND "item_quantity" >= 1)
    ),
    -- COALESCE: um parâmetro nulo daria NULL, e o CHECK aceitaria.
    CONSTRAINT "quests_params_check" CHECK (COALESCE(
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
            ELSE false
        END, false
    ))
);

CREATE TABLE "ecobeasts"."quest_tiles" (
    "quest_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,

    CONSTRAINT "quest_tiles_pkey" PRIMARY KEY ("quest_id","q","r")
);

CREATE TABLE "ecobeasts"."player_quests" (
    "player_id" UUID NOT NULL,
    "quest_id" INTEGER NOT NULL,
    "progress" INTEGER NOT NULL DEFAULT 0,
    "accepted_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "claimed_at" TIMESTAMPTZ(3),

    CONSTRAINT "player_quests_pkey" PRIMARY KEY ("player_id","quest_id"),
    CONSTRAINT "player_quests_progress_check" CHECK ("progress" >= 0)
);

CREATE UNIQUE INDEX "quest_types_slug_key" ON "ecobeasts"."quest_types"("slug");
CREATE INDEX "quests_npc_id_idx" ON "ecobeasts"."quests"("npc_id");
CREATE INDEX "quests_quest_type_id_idx" ON "ecobeasts"."quests"("quest_type_id");
CREATE INDEX "quests_species_id_idx" ON "ecobeasts"."quests"("species_id");
CREATE INDEX "quests_target_npc_id_idx" ON "ecobeasts"."quests"("target_npc_id");
CREATE INDEX "quests_item_id_idx" ON "ecobeasts"."quests"("item_id");
CREATE UNIQUE INDEX "quests_island_id_npc_id_position_key" ON "ecobeasts"."quests"("island_id", "npc_id", "position");
CREATE INDEX "player_quests_quest_id_idx" ON "ecobeasts"."player_quests"("quest_id");

ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_npc_id_fkey" FOREIGN KEY ("npc_id") REFERENCES "ecobeasts"."npcs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_quest_type_id_fkey" FOREIGN KEY ("quest_type_id") REFERENCES "ecobeasts"."quest_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_target_npc_id_fkey" FOREIGN KEY ("target_npc_id") REFERENCES "ecobeasts"."npcs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "ecobeasts"."items"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quest_tiles" ADD CONSTRAINT "quest_tiles_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "ecobeasts"."quests"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_quests" ADD CONSTRAINT "player_quests_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_quests" ADD CONSTRAINT "player_quests_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "ecobeasts"."quests"("id") ON DELETE CASCADE ON UPDATE CASCADE;

INSERT INTO "ecobeasts"."quest_types" ("id", "slug", "name", "description") VALUES
  (1, 'capture_any', 'Capture N Ecobeasts', 'Pede amount: as capturas depois de aceitar, em qualquer mapa.'),
  (2, 'defeat_any', 'Derrote N Ecobeasts', 'Pede amount: os inimigos derrubados, selvagens ou de Domadores.'),
  (3, 'explore_percent', 'Explore N% da ilha', 'Pede amount de 1 a 100: o descoberto da ilha da missão, contando o de antes.'),
  (4, 'reach_place', 'Vá até um lugar', 'Pede place_name e os hexágonos em quest_tiles: pisar num deles.'),
  (5, 'talk_npc', 'Fale com um NPC', 'Pede target_npc_id: a conversa com ele, num mapa onde ele está posto.'),
  (6, 'stay_minutes', 'Fique na ilha por N minutos', 'Pede amount em minutos: o tempo do sinal de cada minuto na ilha da missão.'),
  (7, 'find_species', 'Encontre um Ecobeast', 'Pede species_id e amount opcional (1): as lutas com a espécie do lado inimigo.'),
  (8, 'defeat_species', 'Derrote um Ecobeast', 'Pede species_id e amount opcional (1): os da espécie derrubados.'),
  (9, 'defeat_tamer', 'Derrote um Domador', 'Pede target_npc_id, um Domador da ilha: a vitória contra ele, a primeira ou uma revanche.');
