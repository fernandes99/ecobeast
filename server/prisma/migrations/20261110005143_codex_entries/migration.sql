-- CreateTable
CREATE TABLE "ecobeasts"."codex_entries" (
    "player_id" UUID NOT NULL,
    "species_id" INTEGER NOT NULL,
    "seen_at" TIMESTAMPTZ(3) NOT NULL,
    "caught_at" TIMESTAMPTZ(3),

    CONSTRAINT "codex_entries_pkey" PRIMARY KEY ("player_id","species_id")
);

-- CreateIndex
CREATE INDEX "codex_entries_species_id_idx" ON "ecobeasts"."codex_entries"("species_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."codex_entries" ADD CONSTRAINT "codex_entries_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."codex_entries" ADD CONSTRAINT "codex_entries_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Restrição escrita à mão: o Prisma não a acompanha.
ALTER TABLE "ecobeasts"."codex_entries" ADD CONSTRAINT "codex_entries_caught_at_check" CHECK ("caught_at" IS NULL OR "caught_at" >= "seen_at");

-- Carga de quem já joga (.specs/codex/01-codex-records.md, RF-02): as espécies
-- que cada Domador tem hoje ficam capturadas, desde o primeiro Ecobeast delas.
INSERT INTO "ecobeasts"."codex_entries" ("player_id", "species_id", "seen_at", "caught_at")
SELECT "player_id", "species_id", min("caught_at"), min("caught_at")
FROM "ecobeasts"."creature_instances"
GROUP BY "player_id", "species_id";

-- Os iniciais que ele não tem ficam vistos, desde a criação do Domador.
INSERT INTO "ecobeasts"."codex_entries" ("player_id", "species_id", "seen_at", "caught_at")
SELECT p."id", o."species_id", p."created_at", NULL
FROM "ecobeasts"."players" p
CROSS JOIN "ecobeasts"."starter_options" o
WHERE EXISTS (SELECT 1 FROM "ecobeasts"."creature_instances" c WHERE c."player_id" = p."id")
ON CONFLICT ("player_id", "species_id") DO NOTHING;
