-- As trilhas de terra clara e escura, ao lado da Trilha de terra (.specs/ground-variety/03-dirt-tones.md).

INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind", "hardness") VALUES
  (29, 'light_dirt_trail', 'Trilha de terra clara', 'trail', 1),
  (30, 'dark_dirt_trail', 'Trilha de terra escura', 'trail', 1);
SELECT setval('"ecobeasts"."ground_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."ground_types"));
