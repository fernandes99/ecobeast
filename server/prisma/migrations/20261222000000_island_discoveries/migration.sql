-- CreateTable
CREATE TABLE "ecobeasts"."island_discoveries" (
    "player_id" UUID NOT NULL,
    "island_id" INTEGER NOT NULL,
    "q" INTEGER NOT NULL,
    "r" INTEGER NOT NULL,
    "discovered_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "island_discoveries_pkey" PRIMARY KEY ("player_id","island_id","q","r")
);

-- CreateIndex
CREATE INDEX "island_discoveries_island_id_idx" ON "ecobeasts"."island_discoveries"("island_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_discoveries" ADD CONSTRAINT "island_discoveries_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."island_discoveries" ADD CONSTRAINT "island_discoveries_island_id_fkey" FOREIGN KEY ("island_id") REFERENCES "ecobeasts"."islands"("id") ON DELETE CASCADE ON UPDATE CASCADE;
