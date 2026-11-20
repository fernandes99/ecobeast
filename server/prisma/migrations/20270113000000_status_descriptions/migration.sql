-- A descrição de cada estado da luta (.specs/status-descriptions/01-status-text.md).

ALTER TABLE "ecobeasts"."status_conditions" ADD COLUMN "description" TEXT NOT NULL DEFAULT '';

UPDATE "ecobeasts"."status_conditions" SET "description" = 'Perde 1/16 do HP máximo no fim de cada vez, e as Técnicas físicas dele causam metade do dano. A chance de captura fica 1,5 vez maior.' WHERE "id" = 1;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Perde 1/8 do HP máximo no fim de cada vez. A chance de captura fica 1,5 vez maior.' WHERE "id" = 2;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'A Velocidade cai pela metade, e em cada vez há 25% de chance de não agir. A chance de captura fica 1,5 vez maior.' WHERE "id" = 3;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Não age por 1 a 3 vezes, sorteadas ao adormecer e de novo ao voltar ao campo, e depois acorda. A chance de captura fica 2,5 vezes maior.' WHERE "id" = 4;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Não age, e em cada vez há 20% de chance de descongelar e agir. A chance de captura fica 2,5 vezes maior.' WHERE "id" = 5;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Por 2 a 5 vezes, há 33% de chance de se golpear em vez de agir, com um golpe físico de Poder 40.' WHERE "id" = 6;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Perde a próxima vez.' WHERE "id" = 7;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Por 2 vezes, não anda nem pode ser trocado, e o time dele não pode fugir.' WHERE "id" = 8;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Não anda na próxima vez, mas ainda pode agir.' WHERE "id" = 9;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Por 3 vezes, recebe 1,5 vez o dano das Técnicas de Volt e metade do das de Fogo.' WHERE "id" = 10;
UPDATE "ecobeasts"."status_conditions" SET "description" = 'Recupera 1/16 do HP máximo no fim de cada vez, por 5 vezes.' WHERE "id" = 11;

ALTER TABLE "ecobeasts"."status_conditions" ALTER COLUMN "description" DROP DEFAULT;
