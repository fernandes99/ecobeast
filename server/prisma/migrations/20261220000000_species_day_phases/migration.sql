-- As partes do dia em que cada Ecobeast nasce (.specs/day-phase-spawns/01-phase-spawns.md).

CREATE TABLE "ecobeasts"."species_day_phases" (
    "species_id" INTEGER NOT NULL,
    "day_phase_id" INTEGER NOT NULL,

    CONSTRAINT "species_day_phases_pkey" PRIMARY KEY ("species_id","day_phase_id")
);

CREATE INDEX "species_day_phases_day_phase_id_idx" ON "ecobeasts"."species_day_phases"("day_phase_id");

ALTER TABLE "ecobeasts"."species_day_phases" ADD CONSTRAINT "species_day_phases_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."species_day_phases" ADD CONSTRAINT "species_day_phases_day_phase_id_fkey" FOREIGN KEY ("day_phase_id") REFERENCES "ecobeasts"."day_phases"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Todo Ecobeast que já existe nasce nas 4 partes do dia, como antes.
INSERT INTO "ecobeasts"."species_day_phases" ("species_id", "day_phase_id")
SELECT "species"."id", "day_phases"."id"
FROM "ecobeasts"."species" CROSS JOIN "ecobeasts"."day_phases";
