import { Controller, Get, Param, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { ApiDetailRoute, ApiListRoute } from '../../common/api-docs.js';
import { Page, PaginationQueryDto } from '../../common/pagination.js';
import { ResourceRef } from '../../common/resource-ref.js';
import {
  EvolutionChainDto,
  SpeciesDetailDto,
  SpeciesSkillsDto,
} from './species.dto.js';
import { SpeciesService } from './species.service.js';

@ApiTags('Espécies')
@Controller('species')
export class SpeciesController {
  constructor(private readonly species: SpeciesService) {}

  @Get()
  @ApiListRoute(
    'Lista as espécies',
    'As espécies do Bestiário em ordem de número, paginadas.',
  )
  list(@Query() query: PaginationQueryDto): Promise<Page<ResourceRef>> {
    return this.species.list(query);
  }

  @Get(':idOrSlug')
  @ApiDetailRoute(
    'Uma espécie',
    'Dados básicos: medidas, captura, curva de XP, raridade, Elementos, stats base e Traços. As Técnicas e a linha de Ascensão ficam nas rotas /skills e /evolutions.',
    () => SpeciesDetailDto,
    'fagulho',
  )
  detail(@Param('idOrSlug') idOrSlug: string): Promise<SpeciesDetailDto> {
    return this.species.detail(idOrSlug);
  }

  @Get(':idOrSlug/skills')
  @ApiDetailRoute(
    'Técnicas de uma espécie',
    'O que a espécie aprende: a Técnica, o método (por nível, ao ascender, ensinável) e o nível.',
    () => SpeciesSkillsDto,
    'fagulho',
  )
  skills(@Param('idOrSlug') idOrSlug: string): Promise<SpeciesSkillsDto> {
    return this.species.skills(idOrSlug);
  }

  @Get(':idOrSlug/evolutions')
  @ApiDetailRoute(
    'Linha de Ascensão de uma espécie',
    'A linha inteira, a partir da primeira forma; pedir qualquer espécie da linha devolve o mesmo resultado.',
    () => EvolutionChainDto,
    'brasalobo',
  )
  evolutions(@Param('idOrSlug') idOrSlug: string): Promise<EvolutionChainDto> {
    return this.species.evolutions(idOrSlug);
  }
}
