-- O inicial de Flora com a arte nova: o Browt, o Eagrow e o Sowingle viram o Seedlet, o Grovequill e o Arbornix, nos mesmos ids (.specs/seedlet-line/01-seedlet-line.md).

UPDATE "ecobeasts"."species" SET "slug" = 'seedlet', "name" = 'Seedlet', "height_m" = 0.4, "weight_kg" = 3.2,
    "description" = 'Filhote de quatro patas com uma crista de folhas novas. Quando fica contente, a ponta da cauda se abre como um broto.'
    WHERE "id" = 7;
UPDATE "ecobeasts"."species" SET "slug" = 'grovequill', "name" = 'Grovequill', "weight_kg" = 14.0,
    "description" = 'Corre entre as árvores com o pescoço esticado. O vento que passa pelas folhas da cauda o deixa mais rápido a cada passo.'
    WHERE "id" = 8;
UPDATE "ecobeasts"."species" SET "slug" = 'arbornix', "name" = 'Arbornix',
    "description" = 'Quando abre as asas de folhas, o bosque inteiro balança. Os losangos das penas brilham, e as folhas que ele solta voltam a brotar.'
    WHERE "id" = 9;
