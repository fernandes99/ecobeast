-- Os Domadores das ilhas do Arquipélago, a equipe fixa e as vitórias do jogador (.specs/auralis/04-island-tamers.md).

ALTER TABLE "ecobeasts"."islands" ADD COLUMN "required_tamer_wins" INTEGER;
ALTER TABLE "ecobeasts"."islands" ADD CONSTRAINT "islands_required_tamer_wins_check" CHECK ("required_tamer_wins" > 0);

CREATE TABLE "ecobeasts"."tamers" (
    "id" SERIAL NOT NULL,
    "npc_id" INTEGER NOT NULL,
    "island_id" INTEGER NOT NULL,
    "size" INTEGER NOT NULL DEFAULT 1,
    "counts_for_unlock" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "tamers_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "tamers_size_check" CHECK ("size" BETWEEN 1 AND 3)
);

CREATE TABLE "ecobeasts"."tamer_creatures" (
    "tamer_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "species_id" INTEGER NOT NULL,
    "level" INTEGER NOT NULL,

    CONSTRAINT "tamer_creatures_pkey" PRIMARY KEY ("tamer_id","position"),
    CONSTRAINT "tamer_creatures_position_check" CHECK ("position" BETWEEN 1 AND 6),
    CONSTRAINT "tamer_creatures_level_check" CHECK ("level" BETWEEN 1 AND 100)
);

CREATE TABLE "ecobeasts"."player_tamer_wins" (
    "player_id" UUID NOT NULL,
    "tamer_id" INTEGER NOT NULL,
    "wins" INTEGER NOT NULL DEFAULT 1,
    "first_won_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "player_tamer_wins_pkey" PRIMARY KEY ("player_id","tamer_id"),
    CONSTRAINT "player_tamer_wins_wins_check" CHECK ("wins" >= 1)
);

CREATE UNIQUE INDEX "tamers_npc_id_key" ON "ecobeasts"."tamers"("npc_id");
CREATE INDEX "tamers_island_id_idx" ON "ecobeasts"."tamers"("island_id");
CREATE INDEX "tamer_creatures_species_id_idx" ON "ecobeasts"."tamer_creatures"("species_id");
CREATE INDEX "player_tamer_wins_tamer_id_idx" ON "ecobeasts"."player_tamer_wins"("tamer_id");

ALTER TABLE "ecobeasts"."tamers" ADD CONSTRAINT "tamers_npc_id_fkey" FOREIGN KEY ("npc_id") REFERENCES "ecobeasts"."npcs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."tamers" ADD CONSTRAINT "tamers_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."tamer_creatures" ADD CONSTRAINT "tamer_creatures_tamer_id_fkey" FOREIGN KEY ("tamer_id") REFERENCES "ecobeasts"."tamers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."tamer_creatures" ADD CONSTRAINT "tamer_creatures_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_tamer_wins" ADD CONSTRAINT "player_tamer_wins_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_tamer_wins" ADD CONSTRAINT "player_tamer_wins_tamer_id_fkey" FOREIGN KEY ("tamer_id") REFERENCES "ecobeasts"."tamers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
