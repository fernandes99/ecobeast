-- O efeito recoil passa a se chamar Contragolpe (2026-11-20, pedido do dono).
UPDATE "ecobeasts"."effect_types" SET "name" = 'Contragolpe' WHERE "slug" = 'recoil';
