-- Os 12 tipos novos de chão e de caminho (.specs/ground-variety/01-ground-types.md).

INSERT INTO "ecobeasts"."ground_types" ("id", "slug", "name", "kind", "hardness") VALUES
  (9, 'wood_planks', 'Tábuas de madeira', 'floor', 2),
  (10, 'brick_floor', 'Tijolos', 'floor', 3),
  (11, 'flagstone_floor', 'Lajotas', 'floor', 3),
  (12, 'marble_floor', 'Mármore', 'floor', 3),
  (13, 'mossy_trail', 'Pedra com musgo', 'trail', 3),
  (14, 'basalt_floor', 'Basalto rachado', 'floor', 3),
  (15, 'shell_trail', 'Conchas', 'trail', 2),
  (16, 'tilled_soil', 'Terra arada', 'floor', 1),
  (17, 'straw_floor', 'Palha', 'floor', 1),
  (18, 'mud_trail', 'Lama', 'trail', 1),
  (19, 'leaf_trail', 'Folhas secas', 'trail', 1),
  (20, 'snow_trail', 'Neve pisada', 'trail', 1);
SELECT setval('"ecobeasts"."ground_types_id_seq"', (SELECT MAX("id") FROM "ecobeasts"."ground_types"));
