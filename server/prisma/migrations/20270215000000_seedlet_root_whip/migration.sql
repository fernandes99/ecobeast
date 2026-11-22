-- seedlet-line/02: o Seedlet aprende o Chicote de Raiz no lugar da Bicada de Folha.
UPDATE "ecobeasts"."species_skills"
SET "skill_id" = 29
WHERE "species_id" = 7 AND "skill_id" = 58 AND "skill_learn_method_id" = 1;
