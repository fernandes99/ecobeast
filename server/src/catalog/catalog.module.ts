import { Module } from '@nestjs/common';
import { ElementsController } from './elements/elements.resource.js';
import {
  EffectTypesController,
  EvolutionTriggersController,
  GrowthRatesController,
  RaritiesController,
  SkillCategoriesController,
  SkillLearnMethodsController,
  SkillTargetsController,
  StatsController,
  StatusConditionsController,
  TemperamentsController,
} from './reference/reference.resources.js';
import { SkillsController } from './skills/skills.resource.js';
import { SpeciesModule } from './species/species.module.js';
import { StartersController } from './starters/starters.controller.js';
import { TraitsController } from './traits/traits.resource.js';

/** Todas as rotas de leitura do catálogo (backend-api/04 e 05). */
@Module({
  imports: [SpeciesModule],
  controllers: [
    SkillsController,
    ElementsController,
    TraitsController,
    TemperamentsController,
    StatsController,
    GrowthRatesController,
    RaritiesController,
    StatusConditionsController,
    SkillCategoriesController,
    SkillTargetsController,
    SkillLearnMethodsController,
    EffectTypesController,
    EvolutionTriggersController,
    StartersController,
  ],
})
export class CatalogModule {}
