-- Os prédios da Arena, montados pelos tiles do Fantasy Dreamland Reborn, na categoria Prédios
-- (.specs/arena-buildings/01-arena-props.md). O coliseu tem o aberto (1) e o fechado (2).
-- Os braseiros da frente acendem à noite.

INSERT INTO "ecobeasts"."prop_types" ("id", "slug", "name", "variants", "prop_category_id") VALUES
    (190, 'arena_fortress', 'Arena fortaleza', 1, 2),
    (191, 'arena_coliseum', 'Arena coliseu', 2, 2);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_types"));

SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_blocks"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_blocks"));
INSERT INTO "ecobeasts"."prop_type_blocks" ("prop_type_id", "variant", "position", "closed", "points") VALUES
    (190, 0, 0, true, ARRAY[-120, -14, -72, -14, -72, -20, -54, -20, -54, -2, -38, -2, -38, -10, 38, -10, 38, -2, 54, -2, 54, -20, 72, -20, 72, -14, 120, -14, 120, -65, -120, -65]),
    (191, 0, 0, true, ARRAY[-80, -120, 80, -120, 102, -98, 102, -24, 80, -2, -80, -2, -102, -24, -102, -98]);

SELECT setval(pg_get_serial_sequence('"ecobeasts"."prop_type_lights"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."prop_type_lights"));
INSERT INTO "ecobeasts"."prop_type_lights" ("prop_type_id", "variant", "position", "x", "y", "radius", "color") VALUES
    (190, 0, 0, -46, -18, 22, 'ff9a3c'),
    (190, 0, 1, 46, -18, 22, 'ff9a3c'),
    (191, 0, 0, -34, -16, 22, 'ff9a3c'),
    (191, 0, 1, 34, -16, 22, 'ff9a3c');
