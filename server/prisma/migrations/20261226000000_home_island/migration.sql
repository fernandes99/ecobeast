-- A ilha casa e a ação Viagem (.specs/home-island/01-home-and-travel-data.md).

ALTER TABLE "ecobeasts"."islands" ADD COLUMN "is_home" BOOLEAN NOT NULL DEFAULT false;
CREATE UNIQUE INDEX "islands_one_home" ON "ecobeasts"."islands" ("is_home") WHERE "is_home";

INSERT INTO "ecobeasts"."action_types" ("id", "slug", "name", "color_hex", "kind") VALUES
    (5, 'travel', 'Viagem', '#3FA7A0', 'open_screen');
SELECT setval(pg_get_serial_sequence('"ecobeasts"."action_types"', 'id'), (SELECT MAX("id") FROM "ecobeasts"."action_types"));
