-- A alga boiando (a amarela) sai do jogo a pedido do dono, com as peças dela postas nas ilhas (.specs/sea-life/05-less-water-detail.md).

DELETE FROM "ecobeasts"."island_props" WHERE "prop_type_id" = 145;
DELETE FROM "ecobeasts"."prop_types" WHERE "id" = 145;
