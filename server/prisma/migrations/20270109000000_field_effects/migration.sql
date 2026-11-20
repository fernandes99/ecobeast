-- Os estados Encharcado e Brotando, o Preso para o Vento, a marca que cura e as seis marcas novas (.specs/field-effects/01-field-rules.md).

ALTER TABLE "ecobeasts"."ground_effects" ADD COLUMN "heal_percent" INTEGER;
ALTER TABLE "ecobeasts"."ground_effects" ADD CONSTRAINT "ground_effects_heal_percent_check" CHECK ("heal_percent" BETWEEN 1 AND 100);

INSERT INTO "ecobeasts"."status_conditions" ("id", "slug", "name", "is_volatile") VALUES
    (10, 'soaked', 'Encharcado', true),
    (11, 'sprouting', 'Brotando', true);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."status_conditions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."status_conditions"));

INSERT INTO "ecobeasts"."status_condition_immunities" ("status_condition_id", "element_id") VALUES
    (8, 6);

INSERT INTO "ecobeasts"."ground_effects" ("id", "slug", "name", "damage_percent", "heal_percent", "status_condition_id", "color_hex") VALUES
    (6, 'mud', 'Lamaçal', NULL, NULL, NULL, '#7A5A3A'),
    (7, 'frost', 'Geada', NULL, NULL, NULL, '#CFEFFF'),
    (8, 'toxic_pool', 'Poça Tóxica', NULL, NULL, 2, '#8E44AD'),
    (9, 'quicksand', 'Areia Movediça', NULL, NULL, 8, '#D9B26F'),
    (10, 'garden', 'Jardim', NULL, 6, NULL, '#7FCB6B'),
    (11, 'puddle', 'Poça d''Água', NULL, NULL, 10, '#4A90D9');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."ground_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."ground_effects"));

INSERT INTO "ecobeasts"."ground_effect_stats" ("ground_effect_id", "stat_id", "stages") VALUES
    (6, 6, -1),
    (7, 8, -1);
