-- CreateTable
CREATE TABLE "ecobeasts"."player_story_marks" (
    "player_id" UUID NOT NULL,
    "mark" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "player_story_marks_pkey" PRIMARY KEY ("player_id","mark")
);

-- AddForeignKey
ALTER TABLE "ecobeasts"."player_story_marks" ADD CONSTRAINT "player_story_marks_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CHECK (story/01)
ALTER TABLE "ecobeasts"."player_story_marks" ADD CONSTRAINT "player_story_marks_mark_check" CHECK ("mark" ~ '^[a-z0-9_]{1,48}$');
