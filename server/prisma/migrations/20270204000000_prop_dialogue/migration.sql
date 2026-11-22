-- A fala da peça solta (.specs/prop-dialogue/01-prop-dialogue.md).

ALTER TABLE "ecobeasts"."island_props" ADD COLUMN "dialogue" TEXT NOT NULL DEFAULT '';

ALTER TABLE "ecobeasts"."island_props" ADD CONSTRAINT "island_props_dialogue_check" CHECK (char_length("dialogue") <= 2000);
