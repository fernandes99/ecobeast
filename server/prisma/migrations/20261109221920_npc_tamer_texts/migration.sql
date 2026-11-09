-- CreateTable
CREATE TABLE "ecobeasts"."npc_tamer_names" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "npc_tamer_names_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."npc_tamer_greetings" (
    "id" SERIAL NOT NULL,
    "text" TEXT NOT NULL,

    CONSTRAINT "npc_tamer_greetings_pkey" PRIMARY KEY ("id")
);

-- Restrições escritas à mão: o Prisma não as acompanha.
ALTER TABLE "ecobeasts"."npc_tamer_names" ADD CONSTRAINT "npc_tamer_names_name_check" CHECK (char_length("name") BETWEEN 1 AND 20);
ALTER TABLE "ecobeasts"."npc_tamer_greetings" ADD CONSTRAINT "npc_tamer_greetings_text_check" CHECK (char_length("text") BETWEEN 1 AND 120);
