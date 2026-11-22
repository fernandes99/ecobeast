-- As conversas da missão: início, durante e fim, e a cena do início (auralis/10).

ALTER TABLE "ecobeasts"."quests" ADD COLUMN "offer_scene" TEXT;
ALTER TABLE "ecobeasts"."quests" ADD CONSTRAINT "quests_offer_scene_check" CHECK ("offer_scene" ~ '^[a-z0-9_]{1,64}$');

CREATE TABLE "ecobeasts"."quest_dialogue_steps" (
    "id" SERIAL NOT NULL,
    "quest_id" INTEGER NOT NULL,
    "stage" SMALLINT NOT NULL,
    "option_id" INTEGER,
    "position" SMALLINT NOT NULL,
    "kind" SMALLINT NOT NULL,
    "speaker" SMALLINT,
    "text" TEXT,

    CONSTRAINT "quest_dialogue_steps_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "quest_dialogue_steps_stage_check" CHECK ("stage" BETWEEN 1 AND 3),
    CONSTRAINT "quest_dialogue_steps_position_check" CHECK ("position" > 0),
    CONSTRAINT "quest_dialogue_steps_kind_check" CHECK (COALESCE(CASE "kind"
        WHEN 1 THEN "speaker" BETWEEN 1 AND 3 AND char_length("text") BETWEEN 1 AND 300
        WHEN 2 THEN "speaker" IS NULL AND "text" IS NULL
        ELSE FALSE
    END, FALSE))
);

CREATE TABLE "ecobeasts"."quest_dialogue_options" (
    "id" SERIAL NOT NULL,
    "step_id" INTEGER NOT NULL,
    "position" SMALLINT NOT NULL,
    "text" TEXT NOT NULL,
    "outcome" SMALLINT,

    CONSTRAINT "quest_dialogue_options_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "quest_dialogue_options_position_check" CHECK ("position" BETWEEN 1 AND 4),
    CONSTRAINT "quest_dialogue_options_text_check" CHECK (char_length("text") BETWEEN 1 AND 40),
    CONSTRAINT "quest_dialogue_options_outcome_check" CHECK ("outcome" BETWEEN 1 AND 2)
);

CREATE INDEX "quest_dialogue_steps_quest_id_idx" ON "ecobeasts"."quest_dialogue_steps"("quest_id");
CREATE INDEX "quest_dialogue_steps_option_id_idx" ON "ecobeasts"."quest_dialogue_steps"("option_id");
CREATE UNIQUE INDEX "quest_dialogue_options_step_id_position_key" ON "ecobeasts"."quest_dialogue_options"("step_id", "position");

ALTER TABLE "ecobeasts"."quest_dialogue_steps" ADD CONSTRAINT "quest_dialogue_steps_quest_id_fkey" FOREIGN KEY ("quest_id") REFERENCES "ecobeasts"."quests"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quest_dialogue_steps" ADD CONSTRAINT "quest_dialogue_steps_option_id_fkey" FOREIGN KEY ("option_id") REFERENCES "ecobeasts"."quest_dialogue_options"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."quest_dialogue_options" ADD CONSTRAINT "quest_dialogue_options_step_id_fkey" FOREIGN KEY ("step_id") REFERENCES "ecobeasts"."quest_dialogue_steps"("id") ON DELETE CASCADE ON UPDATE CASCADE;
