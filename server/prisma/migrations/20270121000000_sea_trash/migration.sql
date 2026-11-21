-- O lixo da água redesenhado: a rede vira a bota velha e o caixote vira o galão, e os nomes ficam mais claros (.specs/sea-life/04-trash-and-density.md).

UPDATE "ecobeasts"."prop_types" SET "name" = 'Garrafa PET' WHERE "id" = 146;
UPDATE "ecobeasts"."prop_types" SET "name" = 'Lata de refrigerante' WHERE "id" = 147;
UPDATE "ecobeasts"."prop_types" SET "name" = 'Sacola plástica' WHERE "id" = 148;
UPDATE "ecobeasts"."prop_types" SET "slug" = 'old_boot', "name" = 'Bota velha' WHERE "id" = 149;
UPDATE "ecobeasts"."prop_types" SET "slug" = 'jug', "name" = 'Galão' WHERE "id" = 151;
