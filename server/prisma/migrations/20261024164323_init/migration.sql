-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "ecobeasts";

-- CreateEnum
CREATE TYPE "ecobeasts"."gender" AS ENUM ('male', 'female', 'none');

-- CreateEnum
CREATE TYPE "ecobeasts"."creature_location" AS ENUM ('party', 'storage');

-- CreateTable
CREATE TABLE "ecobeasts"."elements" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color_hex" TEXT NOT NULL,
    "is_rare" BOOLEAN NOT NULL,

    CONSTRAINT "elements_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."element_efficacy" (
    "attacker_element_id" INTEGER NOT NULL,
    "defender_element_id" INTEGER NOT NULL,
    "multiplier" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "element_efficacy_pkey" PRIMARY KEY ("attacker_element_id","defender_element_id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."stats" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "short_name" TEXT NOT NULL,
    "is_battle_only" BOOLEAN NOT NULL,

    CONSTRAINT "stats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."growth_rates" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "xp_multiplier" DOUBLE PRECISION NOT NULL,

    CONSTRAINT "growth_rates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."rarities" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "sort_order" INTEGER NOT NULL,

    CONSTRAINT "rarities_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."temperaments" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "increased_stat_id" INTEGER NOT NULL,
    "decreased_stat_id" INTEGER NOT NULL,

    CONSTRAINT "temperaments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."skill_categories" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "skill_categories_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."skill_targets" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "skill_targets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."skill_learn_methods" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "skill_learn_methods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."status_conditions" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "is_volatile" BOOLEAN NOT NULL,

    CONSTRAINT "status_conditions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."status_condition_immunities" (
    "status_condition_id" INTEGER NOT NULL,
    "element_id" INTEGER NOT NULL,

    CONSTRAINT "status_condition_immunities_pkey" PRIMARY KEY ("status_condition_id","element_id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."effect_types" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "effect_types_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."evolution_triggers" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,

    CONSTRAINT "evolution_triggers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."species" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "growth_rate_id" INTEGER NOT NULL,
    "rarity_id" INTEGER NOT NULL,
    "base_xp_yield" INTEGER NOT NULL,
    "capture_rate" INTEGER NOT NULL,
    "gender_ratio" DOUBLE PRECISION NOT NULL,
    "height_m" DOUBLE PRECISION NOT NULL,
    "weight_kg" DOUBLE PRECISION NOT NULL,
    "evolves_from_species_id" INTEGER,

    CONSTRAINT "species_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."species_elements" (
    "species_id" INTEGER NOT NULL,
    "slot" INTEGER NOT NULL,
    "element_id" INTEGER NOT NULL,

    CONSTRAINT "species_elements_pkey" PRIMARY KEY ("species_id","slot")
);

-- CreateTable
CREATE TABLE "ecobeasts"."species_stats" (
    "species_id" INTEGER NOT NULL,
    "stat_id" INTEGER NOT NULL,
    "base_value" INTEGER NOT NULL,
    "training_yield" INTEGER NOT NULL,

    CONSTRAINT "species_stats_pkey" PRIMARY KEY ("species_id","stat_id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."traits" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,

    CONSTRAINT "traits_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."species_traits" (
    "species_id" INTEGER NOT NULL,
    "trait_id" INTEGER NOT NULL,
    "slot" INTEGER NOT NULL,
    "is_hidden" BOOLEAN NOT NULL,

    CONSTRAINT "species_traits_pkey" PRIMARY KEY ("species_id","slot")
);

-- CreateTable
CREATE TABLE "ecobeasts"."evolutions" (
    "id" SERIAL NOT NULL,
    "species_id" INTEGER NOT NULL,
    "evolved_species_id" INTEGER NOT NULL,
    "evolution_trigger_id" INTEGER NOT NULL,
    "min_level" INTEGER,
    "item_id" INTEGER,
    "min_bond" INTEGER,
    "time_of_day" TEXT,
    "zone_id" INTEGER,

    CONSTRAINT "evolutions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."starter_options" (
    "species_id" INTEGER NOT NULL,
    "sort_order" INTEGER NOT NULL,

    CONSTRAINT "starter_options_pkey" PRIMARY KEY ("species_id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."skills" (
    "id" SERIAL NOT NULL,
    "slug" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT NOT NULL,
    "element_id" INTEGER NOT NULL,
    "skill_category_id" INTEGER NOT NULL,
    "power" INTEGER NOT NULL,
    "accuracy" INTEGER NOT NULL,
    "max_pp" INTEGER NOT NULL,
    "priority" INTEGER NOT NULL,
    "crit_stage" INTEGER NOT NULL,
    "skill_target_id" INTEGER NOT NULL,
    "makes_contact" BOOLEAN NOT NULL,
    "min_hits" INTEGER NOT NULL,
    "max_hits" INTEGER NOT NULL,

    CONSTRAINT "skills_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."skill_effects" (
    "id" SERIAL NOT NULL,
    "skill_id" INTEGER NOT NULL,
    "effect_type_id" INTEGER NOT NULL,
    "sort_order" INTEGER NOT NULL,
    "chance" INTEGER NOT NULL,
    "skill_target_id" INTEGER,
    "status_condition_id" INTEGER,
    "stat_id" INTEGER,
    "stages" INTEGER,
    "percent" INTEGER,
    "value" INTEGER,
    "weather_id" INTEGER,
    "min_turns" INTEGER,

    CONSTRAINT "skill_effects_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."species_skills" (
    "species_id" INTEGER NOT NULL,
    "skill_id" INTEGER NOT NULL,
    "skill_learn_method_id" INTEGER NOT NULL,
    "level" INTEGER,

    CONSTRAINT "species_skills_pkey" PRIMARY KEY ("species_id","skill_id","skill_learn_method_id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."players" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "level" INTEGER NOT NULL DEFAULT 1,
    "coins" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "players_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."creature_instances" (
    "uid" UUID NOT NULL,
    "player_id" UUID NOT NULL,
    "species_id" INTEGER NOT NULL,
    "nickname" TEXT,
    "level" INTEGER NOT NULL,
    "current_xp" INTEGER NOT NULL,
    "current_hp" INTEGER NOT NULL,
    "temperament_id" INTEGER NOT NULL,
    "trait_id" INTEGER NOT NULL,
    "gender" "ecobeasts"."gender" NOT NULL,
    "is_prismatic" BOOLEAN NOT NULL DEFAULT false,
    "bond" INTEGER NOT NULL,
    "held_item_id" INTEGER,
    "status_condition_id" INTEGER,
    "location" "ecobeasts"."creature_location" NOT NULL,
    "party_slot" INTEGER,
    "original_player_id" UUID NOT NULL,
    "caught_at" TIMESTAMPTZ(3) NOT NULL,
    "caught_zone_id" INTEGER,

    CONSTRAINT "creature_instances_pkey" PRIMARY KEY ("uid")
);

-- CreateTable
CREATE TABLE "ecobeasts"."creature_instance_stats" (
    "creature_uid" UUID NOT NULL,
    "stat_id" INTEGER NOT NULL,
    "genes" INTEGER NOT NULL,
    "training_points" INTEGER NOT NULL,

    CONSTRAINT "creature_instance_stats_pkey" PRIMARY KEY ("creature_uid","stat_id")
);

-- CreateTable
CREATE TABLE "ecobeasts"."creature_instance_skills" (
    "creature_uid" UUID NOT NULL,
    "slot" INTEGER NOT NULL,
    "skill_id" INTEGER NOT NULL,
    "current_pp" INTEGER NOT NULL,

    CONSTRAINT "creature_instance_skills_pkey" PRIMARY KEY ("creature_uid","slot")
);

-- CreateTable
CREATE TABLE "ecobeasts"."inventory_items" (
    "player_id" UUID NOT NULL,
    "item_id" INTEGER NOT NULL,
    "quantity" INTEGER NOT NULL,

    CONSTRAINT "inventory_items_pkey" PRIMARY KEY ("player_id","item_id")
);

-- CreateIndex
CREATE UNIQUE INDEX "elements_slug_key" ON "ecobeasts"."elements"("slug");

-- CreateIndex
CREATE INDEX "element_efficacy_defender_element_id_idx" ON "ecobeasts"."element_efficacy"("defender_element_id");

-- CreateIndex
CREATE UNIQUE INDEX "stats_slug_key" ON "ecobeasts"."stats"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "growth_rates_slug_key" ON "ecobeasts"."growth_rates"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "rarities_slug_key" ON "ecobeasts"."rarities"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "rarities_sort_order_key" ON "ecobeasts"."rarities"("sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "temperaments_slug_key" ON "ecobeasts"."temperaments"("slug");

-- CreateIndex
CREATE INDEX "temperaments_increased_stat_id_idx" ON "ecobeasts"."temperaments"("increased_stat_id");

-- CreateIndex
CREATE INDEX "temperaments_decreased_stat_id_idx" ON "ecobeasts"."temperaments"("decreased_stat_id");

-- CreateIndex
CREATE UNIQUE INDEX "skill_categories_slug_key" ON "ecobeasts"."skill_categories"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "skill_targets_slug_key" ON "ecobeasts"."skill_targets"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "skill_learn_methods_slug_key" ON "ecobeasts"."skill_learn_methods"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "status_conditions_slug_key" ON "ecobeasts"."status_conditions"("slug");

-- CreateIndex
CREATE INDEX "status_condition_immunities_element_id_idx" ON "ecobeasts"."status_condition_immunities"("element_id");

-- CreateIndex
CREATE UNIQUE INDEX "effect_types_slug_key" ON "ecobeasts"."effect_types"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "evolution_triggers_slug_key" ON "ecobeasts"."evolution_triggers"("slug");

-- CreateIndex
CREATE UNIQUE INDEX "species_slug_key" ON "ecobeasts"."species"("slug");

-- CreateIndex
CREATE INDEX "species_growth_rate_id_idx" ON "ecobeasts"."species"("growth_rate_id");

-- CreateIndex
CREATE INDEX "species_rarity_id_idx" ON "ecobeasts"."species"("rarity_id");

-- CreateIndex
CREATE INDEX "species_evolves_from_species_id_idx" ON "ecobeasts"."species"("evolves_from_species_id");

-- CreateIndex
CREATE INDEX "species_elements_element_id_idx" ON "ecobeasts"."species_elements"("element_id");

-- CreateIndex
CREATE INDEX "species_stats_stat_id_idx" ON "ecobeasts"."species_stats"("stat_id");

-- CreateIndex
CREATE UNIQUE INDEX "traits_slug_key" ON "ecobeasts"."traits"("slug");

-- CreateIndex
CREATE INDEX "species_traits_trait_id_idx" ON "ecobeasts"."species_traits"("trait_id");

-- CreateIndex
CREATE INDEX "evolutions_species_id_idx" ON "ecobeasts"."evolutions"("species_id");

-- CreateIndex
CREATE INDEX "evolutions_evolved_species_id_idx" ON "ecobeasts"."evolutions"("evolved_species_id");

-- CreateIndex
CREATE INDEX "evolutions_evolution_trigger_id_idx" ON "ecobeasts"."evolutions"("evolution_trigger_id");

-- CreateIndex
CREATE UNIQUE INDEX "starter_options_sort_order_key" ON "ecobeasts"."starter_options"("sort_order");

-- CreateIndex
CREATE UNIQUE INDEX "skills_slug_key" ON "ecobeasts"."skills"("slug");

-- CreateIndex
CREATE INDEX "skills_element_id_idx" ON "ecobeasts"."skills"("element_id");

-- CreateIndex
CREATE INDEX "skills_skill_category_id_idx" ON "ecobeasts"."skills"("skill_category_id");

-- CreateIndex
CREATE INDEX "skills_skill_target_id_idx" ON "ecobeasts"."skills"("skill_target_id");

-- CreateIndex
CREATE INDEX "skill_effects_effect_type_id_idx" ON "ecobeasts"."skill_effects"("effect_type_id");

-- CreateIndex
CREATE INDEX "skill_effects_skill_target_id_idx" ON "ecobeasts"."skill_effects"("skill_target_id");

-- CreateIndex
CREATE INDEX "skill_effects_status_condition_id_idx" ON "ecobeasts"."skill_effects"("status_condition_id");

-- CreateIndex
CREATE INDEX "skill_effects_stat_id_idx" ON "ecobeasts"."skill_effects"("stat_id");

-- CreateIndex
CREATE UNIQUE INDEX "skill_effects_skill_id_sort_order_key" ON "ecobeasts"."skill_effects"("skill_id", "sort_order");

-- CreateIndex
CREATE INDEX "species_skills_skill_id_idx" ON "ecobeasts"."species_skills"("skill_id");

-- CreateIndex
CREATE INDEX "species_skills_skill_learn_method_id_idx" ON "ecobeasts"."species_skills"("skill_learn_method_id");

-- CreateIndex
CREATE INDEX "creature_instances_species_id_idx" ON "ecobeasts"."creature_instances"("species_id");

-- CreateIndex
CREATE INDEX "creature_instances_temperament_id_idx" ON "ecobeasts"."creature_instances"("temperament_id");

-- CreateIndex
CREATE INDEX "creature_instances_trait_id_idx" ON "ecobeasts"."creature_instances"("trait_id");

-- CreateIndex
CREATE INDEX "creature_instances_status_condition_id_idx" ON "ecobeasts"."creature_instances"("status_condition_id");

-- CreateIndex
CREATE UNIQUE INDEX "creature_instances_player_id_party_slot_key" ON "ecobeasts"."creature_instances"("player_id", "party_slot");

-- CreateIndex
CREATE INDEX "creature_instance_stats_stat_id_idx" ON "ecobeasts"."creature_instance_stats"("stat_id");

-- CreateIndex
CREATE INDEX "creature_instance_skills_skill_id_idx" ON "ecobeasts"."creature_instance_skills"("skill_id");

-- AddForeignKey
ALTER TABLE "ecobeasts"."element_efficacy" ADD CONSTRAINT "element_efficacy_attacker_element_id_fkey" FOREIGN KEY ("attacker_element_id") REFERENCES "ecobeasts"."elements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."element_efficacy" ADD CONSTRAINT "element_efficacy_defender_element_id_fkey" FOREIGN KEY ("defender_element_id") REFERENCES "ecobeasts"."elements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."temperaments" ADD CONSTRAINT "temperaments_increased_stat_id_fkey" FOREIGN KEY ("increased_stat_id") REFERENCES "ecobeasts"."stats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."temperaments" ADD CONSTRAINT "temperaments_decreased_stat_id_fkey" FOREIGN KEY ("decreased_stat_id") REFERENCES "ecobeasts"."stats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."status_condition_immunities" ADD CONSTRAINT "status_condition_immunities_status_condition_id_fkey" FOREIGN KEY ("status_condition_id") REFERENCES "ecobeasts"."status_conditions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."status_condition_immunities" ADD CONSTRAINT "status_condition_immunities_element_id_fkey" FOREIGN KEY ("element_id") REFERENCES "ecobeasts"."elements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_growth_rate_id_fkey" FOREIGN KEY ("growth_rate_id") REFERENCES "ecobeasts"."growth_rates"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_rarity_id_fkey" FOREIGN KEY ("rarity_id") REFERENCES "ecobeasts"."rarities"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_evolves_from_species_id_fkey" FOREIGN KEY ("evolves_from_species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_elements" ADD CONSTRAINT "species_elements_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_elements" ADD CONSTRAINT "species_elements_element_id_fkey" FOREIGN KEY ("element_id") REFERENCES "ecobeasts"."elements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_stats" ADD CONSTRAINT "species_stats_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_stats" ADD CONSTRAINT "species_stats_stat_id_fkey" FOREIGN KEY ("stat_id") REFERENCES "ecobeasts"."stats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_traits" ADD CONSTRAINT "species_traits_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_traits" ADD CONSTRAINT "species_traits_trait_id_fkey" FOREIGN KEY ("trait_id") REFERENCES "ecobeasts"."traits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_evolved_species_id_fkey" FOREIGN KEY ("evolved_species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_evolution_trigger_id_fkey" FOREIGN KEY ("evolution_trigger_id") REFERENCES "ecobeasts"."evolution_triggers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."starter_options" ADD CONSTRAINT "starter_options_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_element_id_fkey" FOREIGN KEY ("element_id") REFERENCES "ecobeasts"."elements"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_skill_category_id_fkey" FOREIGN KEY ("skill_category_id") REFERENCES "ecobeasts"."skill_categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_skill_target_id_fkey" FOREIGN KEY ("skill_target_id") REFERENCES "ecobeasts"."skill_targets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_skill_id_fkey" FOREIGN KEY ("skill_id") REFERENCES "ecobeasts"."skills"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_effect_type_id_fkey" FOREIGN KEY ("effect_type_id") REFERENCES "ecobeasts"."effect_types"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_skill_target_id_fkey" FOREIGN KEY ("skill_target_id") REFERENCES "ecobeasts"."skill_targets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_status_condition_id_fkey" FOREIGN KEY ("status_condition_id") REFERENCES "ecobeasts"."status_conditions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_stat_id_fkey" FOREIGN KEY ("stat_id") REFERENCES "ecobeasts"."stats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_skills" ADD CONSTRAINT "species_skills_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_skills" ADD CONSTRAINT "species_skills_skill_id_fkey" FOREIGN KEY ("skill_id") REFERENCES "ecobeasts"."skills"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."species_skills" ADD CONSTRAINT "species_skills_skill_learn_method_id_fkey" FOREIGN KEY ("skill_learn_method_id") REFERENCES "ecobeasts"."skill_learn_methods"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_species_id_fkey" FOREIGN KEY ("species_id") REFERENCES "ecobeasts"."species"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_temperament_id_fkey" FOREIGN KEY ("temperament_id") REFERENCES "ecobeasts"."temperaments"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_trait_id_fkey" FOREIGN KEY ("trait_id") REFERENCES "ecobeasts"."traits"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_status_condition_id_fkey" FOREIGN KEY ("status_condition_id") REFERENCES "ecobeasts"."status_conditions"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instance_stats" ADD CONSTRAINT "creature_instance_stats_creature_uid_fkey" FOREIGN KEY ("creature_uid") REFERENCES "ecobeasts"."creature_instances"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instance_stats" ADD CONSTRAINT "creature_instance_stats_stat_id_fkey" FOREIGN KEY ("stat_id") REFERENCES "ecobeasts"."stats"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instance_skills" ADD CONSTRAINT "creature_instance_skills_creature_uid_fkey" FOREIGN KEY ("creature_uid") REFERENCES "ecobeasts"."creature_instances"("uid") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."creature_instance_skills" ADD CONSTRAINT "creature_instance_skills_skill_id_fkey" FOREIGN KEY ("skill_id") REFERENCES "ecobeasts"."skills"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ecobeasts"."inventory_items" ADD CONSTRAINT "inventory_items_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "ecobeasts"."players"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ─── Faixas de valor (CHECK) ───────────────────────────────────────────────
-- Escritas à mão: o Prisma não descreve CHECK no schema.prisma. As faixas são
-- as de client/core/data/catalog_schema.gd e .specs/backend-api/02-database-schema.md
-- (RF-07). Cada campo tem o comentário "CHECK" correspondente no schema.prisma.

-- Slugs
ALTER TABLE "ecobeasts"."elements" ADD CONSTRAINT "elements_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."stats" ADD CONSTRAINT "stats_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."growth_rates" ADD CONSTRAINT "growth_rates_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."rarities" ADD CONSTRAINT "rarities_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."temperaments" ADD CONSTRAINT "temperaments_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."skill_categories" ADD CONSTRAINT "skill_categories_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."skill_targets" ADD CONSTRAINT "skill_targets_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."skill_learn_methods" ADD CONSTRAINT "skill_learn_methods_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."status_conditions" ADD CONSTRAINT "status_conditions_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."effect_types" ADD CONSTRAINT "effect_types_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."evolution_triggers" ADD CONSTRAINT "evolution_triggers_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."traits" ADD CONSTRAINT "traits_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_slug_check" CHECK ("slug" ~ '^[a-z0-9_]+$');

-- Referência
ALTER TABLE "ecobeasts"."elements" ADD CONSTRAINT "elements_color_hex_check" CHECK ("color_hex" ~ '^#[0-9A-Fa-f]{6}$');
ALTER TABLE "ecobeasts"."element_efficacy" ADD CONSTRAINT "element_efficacy_multiplier_check" CHECK ("multiplier" IN (0, 0.5, 2));
ALTER TABLE "ecobeasts"."growth_rates" ADD CONSTRAINT "growth_rates_xp_multiplier_check" CHECK ("xp_multiplier" BETWEEN 0.1 AND 10);

-- Espécies
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_base_xp_yield_check" CHECK ("base_xp_yield" >= 1);
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_capture_rate_check" CHECK ("capture_rate" BETWEEN 3 AND 255);
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_gender_ratio_check" CHECK ("gender_ratio" BETWEEN -1 AND 1);
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_height_m_check" CHECK ("height_m" >= 0);
ALTER TABLE "ecobeasts"."species" ADD CONSTRAINT "species_weight_kg_check" CHECK ("weight_kg" >= 0);
ALTER TABLE "ecobeasts"."species_elements" ADD CONSTRAINT "species_elements_slot_check" CHECK ("slot" IN (1, 2));
ALTER TABLE "ecobeasts"."species_stats" ADD CONSTRAINT "species_stats_base_value_check" CHECK ("base_value" BETWEEN 1 AND 255);
ALTER TABLE "ecobeasts"."species_stats" ADD CONSTRAINT "species_stats_training_yield_check" CHECK ("training_yield" BETWEEN 0 AND 3);
ALTER TABLE "ecobeasts"."species_traits" ADD CONSTRAINT "species_traits_slot_check" CHECK ("slot" IN (1, 2, 3));
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_min_level_check" CHECK ("min_level" BETWEEN 1 AND 100);
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_min_bond_check" CHECK ("min_bond" BETWEEN 0 AND 255);
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_time_of_day_check" CHECK ("time_of_day" IN ('day', 'night'));
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_item_id_check" CHECK ("item_id" IS NULL);
ALTER TABLE "ecobeasts"."evolutions" ADD CONSTRAINT "evolutions_zone_id_check" CHECK ("zone_id" IS NULL);

-- Técnicas
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_power_check" CHECK ("power" BETWEEN 0 AND 250);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_accuracy_check" CHECK ("accuracy" BETWEEN 0 AND 100);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_max_pp_check" CHECK ("max_pp" BETWEEN 5 AND 40);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_priority_check" CHECK ("priority" BETWEEN -7 AND 5);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_crit_stage_check" CHECK ("crit_stage" BETWEEN 0 AND 3);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_min_hits_check" CHECK ("min_hits" BETWEEN 1 AND 10);
ALTER TABLE "ecobeasts"."skills" ADD CONSTRAINT "skills_max_hits_check" CHECK ("max_hits" BETWEEN 1 AND 10);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_sort_order_check" CHECK ("sort_order" >= 1);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_chance_check" CHECK ("chance" BETWEEN 1 AND 100);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_stages_check" CHECK ("stages" BETWEEN -6 AND 6);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_percent_check" CHECK ("percent" BETWEEN 1 AND 100);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_value_check" CHECK ("value" >= 1);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_min_turns_check" CHECK ("min_turns" >= 1);
ALTER TABLE "ecobeasts"."skill_effects" ADD CONSTRAINT "skill_effects_weather_id_check" CHECK ("weather_id" IS NULL);
ALTER TABLE "ecobeasts"."species_skills" ADD CONSTRAINT "species_skills_level_check" CHECK ("level" BETWEEN 0 AND 100);

-- Jogador
ALTER TABLE "ecobeasts"."players" ADD CONSTRAINT "players_level_check" CHECK ("level" BETWEEN 1 AND 100);
ALTER TABLE "ecobeasts"."players" ADD CONSTRAINT "players_coins_check" CHECK ("coins" >= 0);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_level_check" CHECK ("level" BETWEEN 1 AND 100);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_current_xp_check" CHECK ("current_xp" >= 0);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_current_hp_check" CHECK ("current_hp" >= 0);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_bond_check" CHECK ("bond" BETWEEN 0 AND 255);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_party_slot_check" CHECK ("party_slot" BETWEEN 1 AND 6);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_location_check" CHECK (("location" = 'party') = ("party_slot" IS NOT NULL));
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_held_item_id_check" CHECK ("held_item_id" IS NULL);
ALTER TABLE "ecobeasts"."creature_instances" ADD CONSTRAINT "creature_instances_caught_zone_id_check" CHECK ("caught_zone_id" IS NULL);
ALTER TABLE "ecobeasts"."creature_instance_stats" ADD CONSTRAINT "creature_instance_stats_genes_check" CHECK ("genes" BETWEEN 0 AND 31);
ALTER TABLE "ecobeasts"."creature_instance_stats" ADD CONSTRAINT "creature_instance_stats_training_points_check" CHECK ("training_points" BETWEEN 0 AND 252);
ALTER TABLE "ecobeasts"."creature_instance_skills" ADD CONSTRAINT "creature_instance_skills_slot_check" CHECK ("slot" BETWEEN 1 AND 4);
ALTER TABLE "ecobeasts"."creature_instance_skills" ADD CONSTRAINT "creature_instance_skills_current_pp_check" CHECK ("current_pp" >= 0);
ALTER TABLE "ecobeasts"."inventory_items" ADD CONSTRAINT "inventory_items_quantity_check" CHECK ("quantity" >= 1);
