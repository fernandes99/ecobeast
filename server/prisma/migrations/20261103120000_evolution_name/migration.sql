-- O dono trocou "Ascensão" por "Evolução" no jogo (.specs/progression/01-xp-and-levels.md, RF-12).
UPDATE "ecobeasts"."skill_learn_methods" SET "name" = 'Ao evoluir' WHERE "slug" = 'evolution';
