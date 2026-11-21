-- As zonas de lixo viram uma mancha pequena no mar, sorteada pelo gerador, e não uma faixa do bioma (.specs/sea-life/06-trash-patches.md).

UPDATE "ecobeasts"."biome_zones" SET "share" = 0 WHERE "id" IN (27, 30);
