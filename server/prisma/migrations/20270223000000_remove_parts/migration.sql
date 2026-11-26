-- Saem do catálogo o cabelo Comprido (6), a Jaqueta (11), a Regata (12), a Saia longa (23),
-- a Calça capri (24) e a Calça boca de sino (25), a pedido do dono (.specs/tamer-looks/06-fewer-parts.md).
-- Quem as vestia passa à peça mais parecida do mesmo lugar, com a mesma cor: o cabelo Curto,
-- a Camiseta, a Saia e a Calça. Os ids não voltam a ser usados.
UPDATE "ecobeasts"."player_appearance_parts"
SET "appearance_part_id" = CASE "appearance_part_id"
    WHEN 6 THEN 3
    WHEN 11 THEN 10
    WHEN 12 THEN 10
    WHEN 23 THEN 15
    ELSE 13
END
WHERE "appearance_part_id" IN (6, 11, 12, 23, 24, 25);

UPDATE "ecobeasts"."npc_appearance_parts"
SET "appearance_part_id" = CASE "appearance_part_id"
    WHEN 6 THEN 3
    WHEN 11 THEN 10
    WHEN 12 THEN 10
    WHEN 23 THEN 15
    ELSE 13
END
WHERE "appearance_part_id" IN (6, 11, 12, 23, 24, 25);

DELETE FROM "ecobeasts"."appearance_parts" WHERE "id" IN (6, 11, 12, 23, 24, 25);
