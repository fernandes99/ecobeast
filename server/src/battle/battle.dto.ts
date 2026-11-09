import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsBoolean,
  IsIn,
  IsInt,
  IsOptional,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import { MAX_SLOTS } from '../domain/battle/field.js';
import type {
  BattleAction,
  BattleEvent,
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

export const INVALID_ENEMY = 'Esse inimigo não existe.';
export const INVALID_ACTION = 'Ação inválida.';
export const INVALID_POSITION = 'Posição inválida.';
export const NO_EXPLORATION = 'Essa exploração acabou. Saia e entre de novo.';
export const UNREACHABLE = 'Você não chegou até aí.';
export const NOTHING_HERE = 'Nada por aqui.';
export const NO_TAMER_HERE = 'Nenhum Domador por aqui.';
export const TAMER_WAITING = 'Um Domador está esperando você aqui.';
export const NO_CHALLENGER = 'Nenhum Domador quer lutar agora.';
export const ENEMIES_OR_SPECIES = 'Use species_id ou enemies.';
/** No máximo, a equipe inteira de um Domador. */
export const MAX_TEST_ENEMIES = 6;

export type { CapturedTo };

const ACTION_TYPES: BattleAction['type'][] = [
  'skill',
  'emergency',
  'flee',
  'switch',
  'item',
  'capture',
];

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

export class StartBattleBodyDto {
  @ApiPropertyOptional({
    description: 'Id da espécie do inimigo, sem `enemies`.',
    example: 1,
  })
  @ValidateIf((body: StartBattleBodyDto) => body.enemies === undefined)
  @IsInt({ message: INVALID_ENEMY })
  species_id?: number;

  @ApiPropertyOptional({
    description: 'Nível do inimigo, de 1 a 100, sem `enemies`.',
    example: 5,
  })
  @ValidateIf(
    (body: StartBattleBodyDto) =>
      body.enemies === undefined && Number.isInteger(body.species_id),
  )
  @IsInt({ message: INVALID_ENEMY })
  level?: number;

  @ApiPropertyOptional({
    description:
      'A equipe inimiga, de 1 a 6, no lugar de `species_id` e `level`.',
    type: () => [TestEnemyDto],
  })
  @IsOptional()
  @IsArray({ message: INVALID_ENEMY })
  @ArrayMinSize(1, { message: INVALID_ENEMY })
  @ArrayMaxSize(MAX_TEST_ENEMIES, { message: INVALID_ENEMY })
  @ValidateNested({ each: true })
  @Type(() => TestEnemyDto)
  enemies?: TestEnemyDto[];

  @ApiPropertyOptional({
    description: `Vagas em campo de cada lado, de 1 a ${MAX_SLOTS}. 1 sem ela.`,
    example: 2,
  })
  @IsOptional()
  @IsInt({ message: INVALID_ENEMY })
  @Min(1, { message: INVALID_ENEMY })
  @Max(MAX_SLOTS, { message: INVALID_ENEMY })
  slots?: number;
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

export class BattleActionItemDto {
  @ApiProperty({
    description:
      '`skill` usa uma Técnica; `emergency` é o golpe de quem está sem PP; ' +
      '`flee` tenta fugir; `switch` põe outro Ecobeast em campo, gastando a ' +
      'rodada em `choose_action`; `item` usa um item e gasta a rodada; ' +
      '`capture` tenta capturar o inimigo com uma Esfera.',
    enum: ACTION_TYPES,
    example: 'skill',
  })
  // Num corpo com `actions`, o tipo vem em cada uma delas.
  @ValidateIf((body: { actions?: unknown }) => body.actions === undefined)
  @IsIn(ACTION_TYPES, { message: INVALID_ACTION })
  type: BattleAction['type'];

  @ApiPropertyOptional({
    description: 'A vaga em campo de quem age, a partir de 0. 0 sem ela.',
    example: 0,
  })
  @IsOptional()
  @IsInt({ message: INVALID_ACTION })
  position?: number;

  @ApiPropertyOptional({
    description:
      'Em `skill`, `emergency` e `capture`: a vaga do adversário. Só é ' +
      'obrigatória com mais de um adversário de pé.',
    example: 1,
  })
  @IsOptional()
  @IsInt({ message: INVALID_ACTION })
  target?: number;

  @ApiPropertyOptional({
    description: 'Só em `skill`: o slot da Técnica, de 1 a 4.',
    example: 1,
  })
  @ValidateIf((body: BattleActionItemDto) => body.type === 'skill')
  @IsInt({ message: INVALID_ACTION })
  slot?: number;

  @ApiPropertyOptional({
    description:
      'Em `switch` e `item`: a posição do Ecobeast na equipe, a partir de 0.',
    example: 1,
  })
  @ValidateIf((body: BattleActionItemDto) =>
    ['switch', 'item'].includes(body.type),
  )
  @IsInt({ message: INVALID_ACTION })
  team_index?: number;

  @ApiPropertyOptional({
    description: 'Em `item` e `capture`: o item.',
    example: 4,
  })
  @ValidateIf((body: BattleActionItemDto) =>
    ['item', 'capture'].includes(body.type),
  )
  @IsInt({ message: INVALID_ACTION })
  item_id?: number;
}

/** Uma ação por vaga (battle-slots/architecture.md, "Ações"), ou o corpo antigo, de uma ação só. */
export class BattleActionBodyDto extends BattleActionItemDto {
  @ApiPropertyOptional({
    description:
      'Uma ação por Ecobeast de pé em campo. Sem ela, o próprio corpo é a ' +
      'ação da posição 0, como antes das vagas.',
    type: () => [BattleActionItemDto],
  })
  @IsOptional()
  @IsArray({ message: INVALID_ACTION })
  @ArrayMinSize(1, { message: INVALID_ACTION })
  @ArrayMaxSize(MAX_SLOTS, { message: INVALID_ACTION })
  @ValidateNested({ each: true })
  @Type(() => BattleActionItemDto)
  actions?: BattleActionItemDto[];
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

export class BattleResponseDto {
  @ApiProperty({ type: () => BattleDto })
  battle: BattleDto;

  @ApiProperty({
    description:
      'O que aconteceu, em ordem, só desta chamada. Cada evento tem `type` e os ' +
      'campos do seu tipo, descritos em `.specs/battle-core/architecture.md`.',
    type: 'array',
    items: { type: 'object' },
    example: [
      { type: 'skill_used', side: 'player', skill_id: 1 },
      {
        type: 'damage',
        side: 'enemy',
        damage: 5,
        hp: 13,
        multiplier: 1,
        is_critical: false,
      },
    ],
  })
  events: BattleEvent[];

  @ApiProperty({
    description:
      'Para onde foi o Ecobeast capturado: a equipe ou o Santuário. Nulo em ' +
      'qualquer outra resposta.',
    enum: ['party', 'storage'],
    nullable: true,
    example: null,
  })
  captured_to: CapturedTo | null;

  @ApiProperty({
    description:
      'O Ecobeast que saiu do mapa para esta luta. Nulo em qualquer resposta ' +
      'que não seja o começo de um encontro selvagem.',
    type: 'integer',
    nullable: true,
    example: null,
  })
  spawn_id: number | null;

  @ApiProperty({
    description:
      'Na resposta que termina a luta com vitória, quem recebeu XP, na ordem ' +
      'da equipe. Vazio em qualquer outra resposta.',
    type: () => [CreatureProgressDto],
  })
  progression: CreatureProgressDto[];
}
