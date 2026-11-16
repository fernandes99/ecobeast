-- As partes do dia do relógio do mundo (.specs/day-night/01-world-clock.md).

CREATE TABLE "ecobeasts"."day_phases" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "start_minute" INTEGER NOT NULL,

    CONSTRAINT "day_phases_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "day_phases_slug_key" ON "ecobeasts"."day_phases"("slug");
CREATE UNIQUE INDEX "day_phases_start_minute_key" ON "ecobeasts"."day_phases"("start_minute");
ALTER TABLE "ecobeasts"."day_phases" ADD CONSTRAINT "day_phases_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."day_phases" ADD CONSTRAINT "day_phases_start_minute_check" CHECK ("start_minute" BETWEEN 0 AND 1439);

INSERT INTO "ecobeasts"."day_phases" ("id", "slug", "name", "start_minute") VALUES
    (1, 'morning', 'Manhã', 360),
    (2, 'afternoon', 'Tarde', 720),
    (3, 'dusk', 'Final de tarde', 1020),
    (4, 'night', 'Noite', 1140);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."day_phases"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."day_phases"));
