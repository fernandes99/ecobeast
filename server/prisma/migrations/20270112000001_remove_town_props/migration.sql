-- Saem do jogo o Poste de luz, a Placa, o prédio da Loja, as 3 casas da cidade e o
-- Observatório, pedidos pelo dono (.specs/prop-cleanup/01-remove-town-props.md). As peças
-- postas saem junto (em Liora, 12 postes e 2 placas), com as linhas de bloqueio delas;
-- as linhas de bloqueio e as luzes dos tipos saem pela cascata.

DELETE FROM "ecobeasts"."island_props" WHERE "prop_type_id" IN (18, 19, 23, 24, 25, 26, 27);
DELETE FROM "ecobeasts"."prop_types" WHERE "id" IN (18, 19, 23, 24, 25, 26, 27);
