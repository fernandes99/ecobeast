-- O Atordoado e as marcas que mudam atributos (.specs/puffcoo-line/01-field-rules.md).

CREATE TABLE "ecobeasts"."ground_effect_stats" (
    "ground_effect_id" INTEGER NOT NULL,
    "stat_id" INTEGER NOT NULL,
    "stages" INTEGER NOT NULL,

    CONSTRAINT "ground_effect_stats_pkey" PRIMARY KEY ("ground_effect_id","stat_id")
);

CREATE INDEX "ground_effect_stats_stat_id_idx" ON "ecobeasts"."ground_effect_stats"("stat_id");
ALTER TABLE "ecobeasts"."ground_effect_stats" ADD CONSTRAINT "ground_effect_stats_ground_effect_id_fkey" FOREIGN KEY ("ground_effect_id") REFERENCES "ecobeasts"."ground_effects"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."ground_effect_stats" ADD CONSTRAINT "ground_effect_stats_stat_id_fkey" FOREIGN KEY ("stat_id") REFERENCES "ecobeasts"."stats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "ecobeasts"."ground_effect_stats" ADD CONSTRAINT "ground_effect_stats_stages_check" CHECK ("stages" BETWEEN -6 AND 6 AND "stages" <> 0);

INSERT INTO "ecobeasts"."status_conditions" ("id", "slug", "name", "is_volatile") VALUES
    (9, 'dazed', 'Atordoado', true);
SELECT setval(pg_get_serial_sequence('"ecobeasts"."status_conditions"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."status_conditions"));

INSERT INTO "ecobeasts"."status_condition_immunities" ("status_condition_id", "element_id") VALUES
    (9, 6);

INSERT INTO "ecobeasts"."ground_effects" ("id", "slug", "name", "damage_percent", "status_condition_id", "color_hex") VALUES
    (2, 'feathers', 'Penas no ar', NULL, NULL, '#D9EFE8'),
    (3, 'whirlwind', 'Redemoinho', NULL, 9, '#7CC9B8');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."ground_effects"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."ground_effects"));

INSERT INTO "ecobeasts"."ground_effect_stats" ("ground_effect_id", "stat_id", "stages") VALUES
    (2, 7, -1),
    (2, 8, -1);
