-- A ação de uma peça solta (.specs/free-objects/03-prop-actions.md).

ALTER TABLE "ecobeasts"."island_props" ADD COLUMN "action_type_id" INTEGER;

CREATE INDEX "island_props_action_type_id_idx" ON "ecobeasts"."island_props"("action_type_id");
ALTER TABLE "ecobeasts"."island_props" ADD CONSTRAINT "island_props_action_type_id_fkey" FOREIGN KEY ("action_type_id") REFERENCES "ecobeasts"."action_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
