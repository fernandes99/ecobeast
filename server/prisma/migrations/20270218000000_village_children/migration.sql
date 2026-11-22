-- Os corpos de criança, só de NPC, e as crianças da vila (.specs/village-crowd/02-children.md).

ALTER TABLE "ecobeasts"."body_types" ADD COLUMN "adult_body_type_id" INTEGER;
ALTER TABLE "ecobeasts"."body_types" ADD CONSTRAINT "body_types_adult_body_type_id_fkey" FOREIGN KEY ("adult_body_type_id") REFERENCES "ecobeasts"."body_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
CREATE INDEX "body_types_adult_body_type_id_idx" ON "ecobeasts"."body_types"("adult_body_type_id");

INSERT INTO "ecobeasts"."body_types" ("id", "slug", "name", "adult_body_type_id") VALUES
    (3, 'boy', 'Menino', 1),
    (4, 'girl', 'Menina', 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."body_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."body_types"));

INSERT INTO "ecobeasts"."npcs" ("id", "slug", "name", "description", "sprite", "body_type_id", "skin_palette_id", "voice_id", "default_dialogue") VALUES
    (17, 'villager_juca', 'Juca', 'Criança da Vila Raiz.', NULL, 3, 5, 5, 'Aposto que eu corro mais rápido que o seu Ecobeast!'),
    (18, 'villager_nina', 'Nina', 'Criança da Vila Raiz.', NULL, 4, 7, 5, 'Quando eu crescer, vou ter um Ecobeast de cada Elemento!'),
    (19, 'villager_bia', 'Bia', 'Criança da Vila Raiz.', NULL, 4, 1, 5, 'Psiu! Tem um Puffcoo dormindo ali. Não acorda ele!');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."npcs"', 'id'), GREATEST((SELECT MAX("id") FROM "ecobeasts"."npcs"), (SELECT last_value FROM "ecobeasts"."npcs_id_seq")));

INSERT INTO "ecobeasts"."npc_appearance_parts" ("npc_id", "appearance_slot_id", "appearance_part_id", "palette_id") VALUES
    (17, 1, 1, NULL),
    (17, 2, 14, 3),
    (17, 3, 16, 24),
    (17, 4, 10, 16),
    (17, 5, 4, 2),
    (17, 6, 7, 3),
    (18, 1, 1, NULL),
    (18, 2, 15, 20),
    (18, 3, 16, 18),
    (18, 4, 12, 21),
    (18, 5, 5, 9),
    (19, 1, 2, NULL),
    (19, 2, 14, 19),
    (19, 3, 17, 22),
    (19, 4, 10, 18),
    (19, 5, 6, 10);
