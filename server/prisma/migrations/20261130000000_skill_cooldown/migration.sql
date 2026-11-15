-- skill-cooldown/01: o countdown de cada Técnica, em rodadas, e 3 Técnicas por Ecobeast.
ALTER TABLE "ecobeasts"."skills" ADD COLUMN "cooldown" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_cooldown_check" CHECK ("cooldown" BETWEEN 0 AND 5);

-- Valores iniciais pelo poder (a revisar): sem dano 2; até 50, 0; até 80, 1; até 110, 2; acima, 3.
UPDATE "ecobeasts"."skills" SET "cooldown" = CASE
    WHEN "power" = 0 THEN 2
    WHEN "power" <= 50 THEN 0
    WHEN "power" <= 80 THEN 1
    WHEN "power" <= 110 THEN 2
    ELSE 3
END;

-- A vaga 4 é a última aprendida, e sai.
DELETE FROM "ecobeasts"."creature_instance_skills" WHERE "slot" = 4;
ALTER TABLE "ecobeasts"."creature_instance_skills" DROP CONSTRAINT "creature_instance_skills_slot_check";
ALTER TABLE "ecobeasts"."creature_instance_skills" ADD CONSTRAINT "creature_instance_skills_slot_check" CHECK ("slot" BETWEEN 1 AND 3);
