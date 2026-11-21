-- A área Triângulo (board-battle/33), e a Chama Espiral passa a usá-la.
INSERT INTO "ecobeasts"."area_shapes" ("id", "slug", "name") VALUES
    (3, 'triangle', 'Triângulo');

SELECT setval(pg_get_serial_sequence('"ecobeasts"."area_shapes"', 'id'), 3);

UPDATE "ecobeasts"."skills"
SET "area_shape_id" = 3,
    "description" = 'Envolve 3 hexágonos numa espiral de fogo, com 10% de chance de deixar cada alvo Queimado.'
WHERE "slug" = 'chama_espiral';
