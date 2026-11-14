-- vegetation-brush/01: ficam só 6 objetos de grade. Os objetos de ilha dos tipos
-- apagados saem antes, porque a chave para o tipo é RESTRICT; os hexágonos de cada
-- um saem junto pelo CASCADE.
DELETE FROM "ecobeasts"."island_objects"
WHERE "object_type_id" NOT IN (21, 22, 24, 25, 26, 29);

DELETE FROM "ecobeasts"."map_object_types"
WHERE "id" NOT IN (21, 22, 24, 25, 26, 29);
