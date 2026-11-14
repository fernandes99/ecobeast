-- A conversão de nome do Prisma é mecânica: color1Hex vira color1_hex (tamer-appearance/01).
ALTER TABLE "ecobeasts"."palettes" RENAME COLUMN "color_1_hex" TO "color1_hex";
ALTER TABLE "ecobeasts"."palettes" RENAME COLUMN "color_2_hex" TO "color2_hex";
ALTER TABLE "ecobeasts"."palettes" RENAME COLUMN "color_3_hex" TO "color3_hex";
ALTER TABLE "ecobeasts"."palettes" RENAME COLUMN "color_4_hex" TO "color4_hex";
