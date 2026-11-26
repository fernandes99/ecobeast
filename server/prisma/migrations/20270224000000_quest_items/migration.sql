-- Os itens de missão (auralis/11): sem preço, o item não está à venda.
ALTER TABLE "ecobeasts"."items" ALTER COLUMN "price" DROP NOT NULL;

INSERT INTO "ecobeasts"."item_categories" ("id", "slug", "name", "sort_order") VALUES
    (3, 'quest', 'Missão', 3);

INSERT INTO "ecobeasts"."items" ("id", "slug", "name", "description", "item_category_id", "price", "sort_order", "capture_bonus", "heal_amount", "cures_status") VALUES
    (7, 'old_key', 'Chave Antiga', 'Uma chave de bronze gasta. Abre alguma porta esquecida.', 3, NULL, 7, NULL, NULL, false),
    (8, 'old_scroll', 'Pergaminho Antigo', 'Um rolo de papel amarelado, com uma letra difícil de ler.', 3, NULL, 8, NULL, NULL, false),
    (9, 'torn_map', 'Mapa Rasgado', 'Um pedaço de mapa com um caminho marcado.', 3, NULL, 9, NULL, NULL, false),
    (10, 'parcel', 'Encomenda', 'Uma caixa bem amarrada, à espera de quem a receba.', 3, NULL, 10, NULL, NULL, false),
    (11, 'clay_pot', 'Pote de Barro', 'Um pote pesado e bem fechado. Melhor não abrir.', 3, NULL, 11, NULL, NULL, false),
    (12, 'golden_acorn', 'Bolota Dourada', 'Uma bolota que brilha como ouro. Os Ecobeasts do bosque adoram.', 3, NULL, 12, NULL, NULL, false),
    (13, 'crimson_flower', 'Flor Rubra', 'Uma flor vermelha rara, que só abre em lugares tranquilos.', 3, NULL, 13, NULL, NULL, false),
    (14, 'rare_shell', 'Concha Rara', 'Uma concha dourada. Encostada no ouvido, ainda se ouve o mar.', 3, NULL, 14, NULL, NULL, false),
    (15, 'blue_feather', 'Pena Azul', 'Uma pena leve e azul, perdida por alguma ave.', 3, NULL, 15, NULL, NULL, false),
    (16, 'tide_pearl', 'Pérola da Maré', 'Uma pérola clara, polida pelas ondas.', 3, NULL, 16, NULL, NULL, false);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."items"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."items"));
SELECT setval(pg_get_serial_sequence('"ecobeasts"."item_categories"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."item_categories"));
