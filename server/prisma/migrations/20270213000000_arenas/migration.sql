-- As Arenas das ilhas do Arquipélago e os emblemas do jogador (.specs/auralis/05-arenas.md).

CREATE TABLE "ecobeasts"."arenas" (
    "id" SERIAL NOT NULL,
    "island_id" INTEGER NOT NULL,
    "position" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "interior_id" INTEGER NOT NULL,
    "boss_tamer_id" INTEGER NOT NULL,

    CONSTRAINT "arenas_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "arenas_position_check" CHECK ("position" > 0),
    CONSTRAINT "arenas_name_check" CHECK (char_length("name") BETWEEN 1 AND 40)
);

CREATE TABLE "ecobeasts"."player_arenas" (
    "player_id" UUID NOT NULL,
    "arena_id" INTEGER NOT NULL,
    "won_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "player_arenas_pkey" PRIMARY KEY ("player_id","arena_id")
);

CREATE UNIQUE INDEX "arenas_boss_tamer_id_key" ON "ecobeasts"."arenas"("boss_tamer_id");
CREATE INDEX "arenas_interior_id_idx" ON "ecobeasts"."arenas"("interior_id");
CREATE UNIQUE INDEX "arenas_island_id_position_key" ON "ecobeasts"."arenas"("island_id", "position");
CREATE INDEX "player_arenas_arena_id_idx" ON "ecobeasts"."player_arenas"("arena_id");

ALTER TABLE "ecobeasts"."arenas" ADD CONSTRAINT "arenas_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."arenas" ADD CONSTRAINT "arenas_interior_id_fkey" FOREIGN KEY ("interior_id") REFERENCES "ecobeasts"."interiors"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."arenas" ADD CONSTRAINT "arenas_boss_tamer_id_fkey" FOREIGN KEY ("boss_tamer_id") REFERENCES "ecobeasts"."tamers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_arenas" ADD CONSTRAINT "player_arenas_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_arenas" ADD CONSTRAINT "player_arenas_arena_id_fkey" FOREIGN KEY ("arena_id") REFERENCES "ecobeasts"."arenas"("id") ON DELETE CASCADE ON UPDATE CASCADE;
