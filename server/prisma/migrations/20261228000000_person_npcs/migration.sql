-- Os NPCs pessoas: um NPC tem o sprite de um Ecobeast ou a aparência do Domador (.specs/liora-intro/02-person-npcs.md).

ALTER TABLE "ecobeasts"."npcs" ALTER COLUMN "sprite" DROP NOT NULL;
ALTER TABLE "ecobeasts"."npcs" ADD COLUMN "body_type_id" INTEGER;
ALTER TABLE "ecobeasts"."npcs" ADD COLUMN "skin_palette_id" INTEGER;
ALTER TABLE "ecobeasts"."npcs" ADD CONSTRAINT "npcs_body_type_id_fkey" FOREIGN KEY ("body_type_id") REFERENCES "ecobeasts"."body_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."npcs" ADD CONSTRAINT "npcs_skin_palette_id_fkey" FOREIGN KEY ("skin_palette_id") REFERENCES "ecobeasts"."palettes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX "npcs_body_type_id_idx" ON "ecobeasts"."npcs"("body_type_id");
CREATE INDEX "npcs_skin_palette_id_idx" ON "ecobeasts"."npcs"("skin_palette_id");
ALTER TABLE "ecobeasts"."npcs" ADD CONSTRAINT "npcs_look_check" CHECK (
    ("sprite" IS NULL) <> ("body_type_id" IS NULL)
    AND ("skin_palette_id" IS NULL) = ("body_type_id" IS NULL)
);

CREATE TABLE "ecobeasts"."npc_appearance_parts" (
    "npc_id" INTEGER NOT NULL,
    "appearance_slot_id" INTEGER NOT NULL,
    "appearance_part_id" INTEGER NOT NULL,
    "palette_id" INTEGER,

    CONSTRAINT "npc_appearance_parts_pkey" PRIMARY KEY ("npc_id","appearance_slot_id")
);
CREATE INDEX "npc_appearance_parts_appearance_slot_id_idx" ON "ecobeasts"."npc_appearance_parts"("appearance_slot_id");
CREATE INDEX "npc_appearance_parts_appearance_part_id_idx" ON "ecobeasts"."npc_appearance_parts"("appearance_part_id");
CREATE INDEX "npc_appearance_parts_palette_id_idx" ON "ecobeasts"."npc_appearance_parts"("palette_id");
ALTER TABLE "ecobeasts"."npc_appearance_parts" ADD CONSTRAINT "npc_appearance_parts_npc_id_fkey" FOREIGN KEY ("npc_id") REFERENCES "ecobeasts"."npcs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."npc_appearance_parts" ADD CONSTRAINT "npc_appearance_parts_appearance_slot_id_fkey" FOREIGN KEY ("appearance_slot_id") REFERENCES "ecobeasts"."appearance_slots"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."npc_appearance_parts" ADD CONSTRAINT "npc_appearance_parts_appearance_part_id_fkey" FOREIGN KEY ("appearance_part_id") REFERENCES "ecobeasts"."appearance_parts"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."npc_appearance_parts" ADD CONSTRAINT "npc_appearance_parts_palette_id_fkey" FOREIGN KEY ("palette_id") REFERENCES "ecobeasts"."palettes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

INSERT INTO "ecobeasts"."npcs" ("id", "slug", "name", "description", "sprite", "body_type_id", "skin_palette_id") VALUES
    (3, 'grandpa', 'Avô', 'O avô do Domador, que mora na Vila Raiz.', NULL, 1, 4),
    (4, 'mira', 'Mira', 'Amiga de infância do Domador, de volta do Instituto Meridian.', NULL, 2, 1),
    (5, 'refuge_keeper', 'Responsável do Refúgio', 'Cuida do Refúgio da Vila Raiz e dos Ecobeasts jovens.', NULL, 1, 6);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."npcs"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."npcs"));

INSERT INTO "ecobeasts"."npc_appearance_parts" ("npc_id", "appearance_slot_id", "appearance_part_id", "palette_id") VALUES
    (3, 1, 1, NULL),
    (3, 2, 13, 23),
    (3, 3, 17, 22),
    (3, 4, 11, 19),
    (3, 5, 3, 12),
    (4, 1, 2, NULL),
    (4, 2, 15, 3),
    (4, 3, 16, 24),
    (4, 4, 11, 20),
    (4, 5, 5, 10),
    (5, 1, 1, NULL),
    (5, 2, 13, 24),
    (5, 3, 16, 16),
    (5, 4, 10, 16),
    (5, 5, 4, 9);
