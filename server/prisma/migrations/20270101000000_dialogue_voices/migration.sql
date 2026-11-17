-- As vozes da caixa de fala, uma por NPC (.specs/dialogue-voices/01-voice-catalog.md).

CREATE TABLE "ecobeasts"."voices" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "chars_per_second" INTEGER NOT NULL,
    "letters_per_blip" INTEGER NOT NULL,
    "pitch_variation" INTEGER NOT NULL,

    CONSTRAINT "voices_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "voices_slug_key" ON "ecobeasts"."voices"("slug");
ALTER TABLE "ecobeasts"."voices" ADD CONSTRAINT "voices_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."voices" ADD CONSTRAINT "voices_chars_per_second_check" CHECK ("chars_per_second" BETWEEN 20 AND 90);
ALTER TABLE "ecobeasts"."voices" ADD CONSTRAINT "voices_letters_per_blip_check" CHECK ("letters_per_blip" BETWEEN 1 AND 4);
ALTER TABLE "ecobeasts"."voices" ADD CONSTRAINT "voices_pitch_variation_check" CHECK ("pitch_variation" BETWEEN 0 AND 25);

INSERT INTO "ecobeasts"."voices" ("id", "slug", "name", "chars_per_second", "letters_per_blip", "pitch_variation") VALUES
    (1, 'narration', 'Narração', 50, 3, 4),
    (2, 'tamer', 'Domador', 60, 2, 5),
    (3, 'low', 'Grave', 42, 3, 5),
    (4, 'medium', 'Média', 52, 2, 4),
    (5, 'high', 'Aguda', 66, 2, 10),
    (6, 'chirp', 'Pio', 40, 3, 12);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."voices"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."voices"));

ALTER TABLE "ecobeasts"."npcs" ADD COLUMN "voice_id" INTEGER NOT NULL DEFAULT 4;
CREATE INDEX "npcs_voice_id_idx" ON "ecobeasts"."npcs"("voice_id");
ALTER TABLE "ecobeasts"."npcs" ADD CONSTRAINT "npcs_voice_id_fkey" FOREIGN KEY ("voice_id") REFERENCES "ecobeasts"."voices"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

UPDATE "ecobeasts"."npcs" SET "voice_id" = 6 WHERE "slug" IN ('village_ruvo', 'guard_ruvak', 'liora_puffcoo');
UPDATE "ecobeasts"."npcs" SET "voice_id" = 3 WHERE "slug" = 'grandpa';
UPDATE "ecobeasts"."npcs" SET "voice_id" = 5 WHERE "slug" = 'mira';
