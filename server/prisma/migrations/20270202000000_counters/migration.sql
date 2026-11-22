-- Os números do Domador no Perfil (.specs/player-stats/01-counters-server.md).

CREATE TABLE "ecobeasts"."counters" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "subject" TEXT NOT NULL,

    CONSTRAINT "counters_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "counters_slug_key" ON "ecobeasts"."counters"("slug");
ALTER TABLE "ecobeasts"."counters" ADD CONSTRAINT "counters_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."counters" ADD CONSTRAINT "counters_subject_check" CHECK ("subject" IN ('none', 'element', 'day_phase', 'biome'));

INSERT INTO "ecobeasts"."counters" ("id", "slug", "name", "subject") VALUES
    (1, 'wins_wild', 'Vitórias contra selvagens', 'none'),
    (2, 'wins_tamer', 'Vitórias contra Domadores', 'none'),
    (3, 'defeats', 'Derrotas', 'none'),
    (4, 'captures', 'Capturas', 'none'),
    (5, 'spheres_used', 'Esferas usadas', 'none'),
    (6, 'captures_first_sphere', 'Na primeira Esfera', 'none'),
    (7, 'captures_by_element', 'Capturas por Elemento', 'element'),
    (8, 'captures_by_day_phase', 'Capturas por parte do dia', 'day_phase'),
    (9, 'hexes_walked', 'Hexágonos andados', 'none'),
    (10, 'biome_hexes', 'Hexágonos por bioma', 'biome'),
    (11, 'maps_explored', 'Mapas explorados', 'none'),
    (12, 'xp_gained', 'XP ganho', 'none'),
    (13, 'coins_earned', 'Moedas ganhas', 'none'),
    (14, 'coins_spent', 'Moedas gastas', 'none'),
    (15, 'heals', 'Curas no Refúgio', 'none'),
    (16, 'play_seconds', 'Tempo jogado', 'none'),
    (17, 'play_days', 'Dias jogados', 'none'),
    (18, 'play_streak', 'Dias seguidos', 'none');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."counters"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."counters"));

CREATE TABLE "ecobeasts"."player_counters" (
    "player_id" UUID NOT NULL,
    "counter_id" INTEGER NOT NULL,
    "subject_id" INTEGER NOT NULL DEFAULT 0,
    "value" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "player_counters_pkey" PRIMARY KEY ("player_id","counter_id","subject_id")
);

CREATE INDEX "player_counters_ranking_idx" ON "ecobeasts"."player_counters"("counter_id", "subject_id", "value" DESC);
ALTER TABLE "ecobeasts"."player_counters" ADD CONSTRAINT "player_counters_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_counters" ADD CONSTRAINT "player_counters_counter_id_fkey" FOREIGN KEY ("counter_id") REFERENCES "ecobeasts"."counters"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."player_counters" ADD CONSTRAINT "player_counters_value_check" CHECK ("value" >= 0);

ALTER TABLE "ecobeasts"."creature_instances" ADD COLUMN "battles" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_battles_check" CHECK ("battles" >= 0);

ALTER TABLE "ecobeasts"."players" ADD COLUMN "last_ping_at" TIMESTAMPTZ(3),
ADD COLUMN "last_play_day" DATE;
