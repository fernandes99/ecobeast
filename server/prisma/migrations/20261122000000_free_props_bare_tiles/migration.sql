-- free-props/05: o hexágono sem as decorações naturais sorteadas do bioma.
ALTER TABLE "ecobeasts"."island_tiles" ADD COLUMN "bare" BOOLEAN NOT NULL DEFAULT false;
