-- Os NPCs das ilhas (.specs/island-npcs/01-npc-records.md).
CREATE TABLE "ecobeasts"."npcs" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "sprite" TEXT NOT NULL,

    CONSTRAINT "npcs_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."island_npcs" (
    "id" SERIAL NOT NULL,
    "island_map_id" INTEGER NOT NULL,
    "npc_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "still" BOOLEAN NOT NULL,
    "dialogue" TEXT NOT NULL,
    "action_type_id" INTEGER,

    CONSTRAINT "island_npcs_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "ecobeasts"."island_npc_tiles" (
    "island_npc_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,

    CONSTRAINT "island_npc_tiles_pkey" PRIMARY KEY ("island_npc_id","q","r")
);

CREATE UNIQUE INDEX "npcs_slug_key" ON "ecobeasts"."npcs"("slug");
CREATE INDEX "island_npcs_island_map_id_idx" ON "ecobeasts"."island_npcs"("island_map_id");
CREATE INDEX "island_npcs_npc_id_idx" ON "ecobeasts"."island_npcs"("npc_id");
CREATE INDEX "island_npcs_action_type_id_idx" ON "ecobeasts"."island_npcs"("action_type_id");

ALTER TABLE "ecobeasts"."island_npcs" ADD CONSTRAINT "island_npcs_island_map_id_fkey" FOREIGN KEY ("island_map_id") REFERENCES "ecobeasts"."island_maps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_npcs" ADD CONSTRAINT "island_npcs_npc_id_fkey" FOREIGN KEY ("npc_id") REFERENCES "ecobeasts"."npcs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_npcs" ADD CONSTRAINT "island_npcs_action_type_id_fkey" FOREIGN KEY ("action_type_id") REFERENCES "ecobeasts"."action_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."island_npc_tiles" ADD CONSTRAINT "island_npc_tiles_island_npc_id_fkey" FOREIGN KEY ("island_npc_id") REFERENCES "ecobeasts"."island_npcs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ecobeasts"."npcs" ADD CONSTRAINT "npcs_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."npcs" ADD CONSTRAINT "npcs_sprite_check" CHECK ("sprite" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."island_npcs" ADD CONSTRAINT "island_npcs_dialogue_check" CHECK (char_length("dialogue") <= 2000);

-- Os primeiros NPCs, para testar.
INSERT INTO "ecobeasts"."npcs" ("id", "slug", "name", "description", "sprite") VALUES (1, 'village_ruvo', 'Ruvo da vila', 'Mora na vila e conhece todo mundo.', 'ruvo');
INSERT INTO "ecobeasts"."npcs" ("id", "slug", "name", "description", "sprite") VALUES (2, 'guard_ruvak', 'Ruvak, o guardião', 'Vigia a entrada da vila.', 'ruvak');
SELECT setval('"ecobeasts"."npcs_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."npcs"));
