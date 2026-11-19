-- game-data/07: o Elemento Mente (id 10) passa a se chamar Psíquico; o slug `mind` não muda.
UPDATE "ecobeasts"."elements" SET "name" = 'Psíquico' WHERE "id" = 10;
