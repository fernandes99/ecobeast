-- As 8 trilhas de pedra, 3 delas com as pedras soltas sobre o bioma (.specs/ground-variety/02-stone-trails.md).

INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind", "hardness") VALUES
  (21, 'blue_cobble_trail', 'Seixos azuis', 'trail', 3),
  (22, 'cracked_earth_trail', 'Terra rachada', 'trail', 2),
  (23, 'sandstone_trail', 'Arenito', 'trail', 3),
  (24, 'slate_trail', 'Ardósia', 'trail', 3),
  (25, 'pale_cobble_trail', 'Seixos claros', 'trail', 3),
  (26, 'river_stones', 'Pedras de rio', 'trail', 3),
  (27, 'loose_slabs', 'Lajes soltas', 'trail', 3),
  (28, 'pebble_scatter', 'Pedrisco', 'trail', 2);
SELECT setval('"ecobeasts"."ground_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."ground_types"));
