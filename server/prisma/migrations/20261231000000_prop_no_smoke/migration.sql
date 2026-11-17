-- A casa sem a fumaça da chaminé (.specs/chimney-smoke/01-smoke-toggle.md).

ALTER TABLE "ecobeasts"."island_props" ADD COLUMN "no_smoke" BOOLEAN NOT NULL DEFAULT false;
