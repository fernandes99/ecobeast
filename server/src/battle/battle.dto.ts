import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsOptional, ValidateIf } from 'class-validator';
import type {
  BattlePhase,
  BattleResult,
  CapturedTo,
  StageSlug,
} from '../domain/battle/types.js';
import type { StatBlock } from '../domain/rules/types.js';
import {
  InventorySlotDto,
  SkillSlotDto,
  STAT_BLOCK,
} from '../player/player.dto.js';

export const NO_BATTLE = 'Nenhuma batalha em andamento.';
export const INVALID_ENEMY = 'Esse inimigo não existe.';
export const INVALID_ACTION = 'Ação inválida.';
export const INVALID_POSITION = 'Posição inválida.';
export const NO_EXPLORATION = 'Essa exploração acabou. Saia e entre de novo.';
export const UNREACHABLE = 'Você não chegou até aí.';
export const NOTHING_HERE = 'Nada por aqui.';
export const NO_TAMER_HERE = 'Nenhum Domador por aqui.';
export const TAMER_WAITING = 'Um Domador está esperando você aqui.';
export const NO_CHALLENGER = 'Nenhum Domador quer lutar agora.';
/** No máximo, a equipe inteira de um Domador. */
export const MAX_TEST_ENEMIES = 6;

export type { CapturedTo };

const STAGES = {
  type: 'object',
  properties: {
    atk: { type: 'integer' },
    def: { type: 'integer' },
    sp_atk: { type: 'integer' },
    sp_def: { type: 'integer' },
    spd: { type: 'integer' },
    accuracy: { type: 'integer' },
    evasion: { type: 'integer' },
  },
  description: 'Estágios, de -6 a +6.',
  example: {
    atk: 1,
    def: 0,
    sp_atk: 0,
    sp_def: 0,
    spd: 0,
    accuracy: 0,
    evasion: 0,
  },
} as const;

export class TestEnemyDto {
  @ApiProperty({ description: 'Id da espécie do inimigo.', example: 1 })
  @IsInt({ message: INVALID_ENEMY })
  species_id: number;

  @ApiProperty({ description: 'Nível do inimigo, de 1 a 100.', example: 5 })
  // Um erro por vez: a validação junta as mensagens numa frase só.
  @ValidateIf((body: TestEnemyDto) => Number.isInteger(body.species_id))
  @IsInt({ message: INVALID_ENEMY })
  level: number;
}

export class StartWildBodyDto {
  @ApiProperty({ description: 'Coluna onde o Domador está.', example: 3 })
  @IsInt({ message: INVALID_POSITION })
  q: number;

  @ApiProperty({ description: 'Linha onde o Domador está.', example: -2 })
  // Um erro por vez: a validação junta as mensagens numa frase só.
  @ValidateIf((body: StartWildBodyDto) => Number.isInteger(body.q))
  @IsInt({ message: INVALID_POSITION })
  r: number;

  @ApiPropertyOptional({
    description:
      'Depuração: todo golpe do jogador que acerta derruba o inimigo. Só vale com ' +
      '`ENABLE_TEST_BATTLE` ligada; sem ela, é ignorado.',
    example: false,
  })
  @IsOptional()
  @IsBoolean({ message: INVALID_POSITION })
  god?: boolean;
}

export class EnemyCreatureDto {
  @ApiProperty({ example: 7 })
  species_id: number;

  @ApiProperty({ example: 4 })
  level: number;

  @ApiProperty({ example: 9 })
  hp: number;

  @ApiProperty({ example: 18 })
  max_hp: number;

  @ApiProperty({
    description: 'burn, poison, paralysis, sleep ou freeze.',
    type: 'string',
    nullable: true,
    example: null,
  })
  status: string | null;

  @ApiProperty({ example: false })
  confused: boolean;

  @ApiProperty(STAGES)
  stages: Record<StageSlug, number>;
}

export class PlayerCreatureDto extends EnemyCreatureDto {
  @ApiProperty({ example: '0b5c2f4e-8d1a-4c3b-9e7f-1a2b3c4d5e6f' })
  uid: string;

  @ApiProperty({ type: () => [SkillSlotDto] })
  skills: SkillSlotDto[];
}

export class PlayerSideDto {
  @ApiProperty({
    description:
      'Por vaga em campo, da esquerda para a direita: a posição em `team` de ' +
      'quem está ali, ou nulo com a vaga vazia.',
    type: 'array',
    items: { type: 'integer', nullable: true },
    example: [0],
  })
  active_indices: (number | null)[];

  @ApiProperty({
    description:
      'No `choose_next`, as vagas que esperam quem entra. Vazio nas outras fases.',
    type: [Number],
    example: [],
  })
  pending_positions: number[];

  @ApiProperty({
    description:
      'Obsoleto: a primeira vaga ocupada de `active_indices`. Sai na battle-slots/02.',
    example: 0,
  })
  active_index: number;

  @ApiProperty({ type: () => [PlayerCreatureDto] })
  team: PlayerCreatureDto[];

  @ApiProperty({
    description:
      'O que resta na Mochila, descontando o que já foi usado na luta.',
    type: () => [InventorySlotDto],
  })
  items: InventorySlotDto[];
}

export class EnemySideDto {
  @ApiProperty({
    description:
      'Por vaga em campo, quem está ali, ou nulo com a vaga vazia. Técnicas, ' +
      'Traço e reservas ficam ocultos.',
    type: () => [EnemyCreatureDto],
  })
  actives: (EnemyCreatureDto | null)[];

  @ApiProperty({
    description: 'Obsoleto: o primeiro de `actives`. Sai na battle-slots/02.',
    type: () => EnemyCreatureDto,
    nullable: true,
  })
  active: EnemyCreatureDto | null;

  @ApiProperty({ example: 1 })
  team_size: number;

  @ApiProperty({ example: 0 })
  fainted: number;
}

export class BattleDto {
  @ApiProperty({
    description:
      '`choose_action` espera uma ação; `choose_next` espera um `switch`; `ended` terminou.',
    enum: ['choose_action', 'choose_next', 'ended'],
    example: 'choose_action',
  })
  phase: BattlePhase;

  @ApiProperty({
    enum: ['victory', 'defeat', 'fled', 'captured'],
    nullable: true,
    example: null,
  })
  result: BattleResult | null;

  @ApiProperty({ example: 3 })
  turn: number;

  @ApiProperty({ example: true })
  can_flee: boolean;

  @ApiProperty({ type: () => PlayerSideDto })
  player: PlayerSideDto;

  @ApiProperty({ type: () => EnemySideDto })
  enemy: EnemySideDto;
}

export class EvolutionOfferDto {
  @ApiProperty({
    description: 'A espécie em que ele pode evoluir.',
    example: 2,
  })
  species_id: number;
}

/** .specs/progression/architecture.md, "Contrato". */
export class CreatureProgressDto {
  @ApiProperty({ example: '7f9c2a1e-…' })
  uid: string;

  @ApiProperty({ description: 'Índice na equipe da luta.', example: 0 })
  team_index: number;

  @ApiProperty({ description: 'XP ganho nesta luta.', example: 42 })
  xp_gained: number;

  @ApiProperty({ example: 11 })
  level_before: number;

  @ApiProperty({ example: 12 })
  level_after: number;

  @ApiProperty({ description: 'XP total, já gravado.', example: 1750 })
  current_xp: number;

  @ApiProperty({ description: 'XP total do nível atual.', example: 1728 })
  level_xp: number;

  @ApiProperty({
    description: 'XP total do próximo nível. Nulo no nível máximo.',
    type: 'integer',
    nullable: true,
    example: 2197,
  })
  next_level_xp: number | null;

  @ApiProperty({ ...STAT_BLOCK, description: 'Stats no nível de antes.' })
  stats_before: StatBlock;

  @ApiProperty({ ...STAT_BLOCK, description: 'Stats no nível novo.' })
  stats_after: StatBlock;

  @ApiProperty({
    type: () => EvolutionOfferDto,
    nullable: true,
    description: 'A evolução oferecida. Nula quando não há.',
    example: null,
  })
  evolution: EvolutionOfferDto | null;

  @ApiProperty({
    description: 'Técnicas aprendidas com vaga, já gravadas.',
    type: [Number],
    example: [],
  })
  learned_skill_ids: number[];

  @ApiProperty({
    description: 'Técnicas que esperam a escolha do jogador.',
    type: [Number],
    example: [],
  })
  pending_skill_ids: number[];
}
