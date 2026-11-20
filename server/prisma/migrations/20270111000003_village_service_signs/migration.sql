-- A Placa do Refúgio (o + gravado, vermelho, branco e verde) e a Placa da Loja (.specs/village-pack/04-service-signs.md).

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants") VALUES
    (129, 'village_refuge_sign', 'Placa do Refúgio', 4),
    (130, 'village_store_sign', 'Placa da Loja', 1);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));
