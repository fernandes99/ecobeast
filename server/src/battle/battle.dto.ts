import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsIn, IsInt, ValidateIf } from 'class-validator';
import type {
  BattleAction,
  BattleEvent,
  BattlePhase,
  BattleResult,
  StageSlug,
} from '../domain/battle/types.js';
import { InventorySlotDto, SkillSlotDto } from '../player/player.dto.js';

export const INVALID_ENEMY = 'Esse inimigo não existe.';
export const INVALID_ACTION = 'Ação inválida.';

export type CapturedTo = 'party' | 'storage';

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

export class StartBattleBodyDto {
  @ApiProperty({ description: 'Id da espécie do inimigo.', example: 1 })
  @IsInt({ message: INVALID_ENEMY })
  species_id: number;

  @ApiProperty({ description: 'Nível do inimigo, de 1 a 100.', example: 5 })
  // Um erro por vez: a validação junta as mensagens numa frase só.
  @ValidateIf((body: StartBattleBodyDto) => Number.isInteger(body.species_id))
  @IsInt({ message: INVALID_ENEMY })
  level: number;
}

export class BattleActionBodyDto {
  @ApiProperty({
    description:
      '`skill` usa uma Técnica; `emergency` é o golpe de quem está sem PP; ' +
      '`flee` tenta fugir; `switch` põe outro Ecobeast em campo, gastando a ' +
      'rodada em `choose_action`; `item` usa um item e gasta a rodada; ' +
      '`capture` tenta capturar o inimigo com uma Esfera.',
    enum: ACTION_TYPES,
    example: 'skill',
  })
  @IsIn(ACTION_TYPES, { message: INVALID_ACTION })
  type: BattleAction['type'];

  @ApiPropertyOptional({
    description: 'Só em `skill`: o slot da Técnica, de 1 a 4.',
    example: 1,
  })
  @ValidateIf((body: BattleActionBodyDto) => body.type === 'skill')
  @IsInt({ message: INVALID_ACTION })
  slot?: number;

  @ApiPropertyOptional({
    description:
      'Em `switch` e `item`: a posição do Ecobeast na equipe, a partir de 0.',
    example: 1,
  })
  @ValidateIf((body: BattleActionBodyDto) =>
    ['switch', 'item'].includes(body.type),
  )
  @IsInt({ message: INVALID_ACTION })
  team_index?: number;

  @ApiPropertyOptional({
    description: 'Em `item` e `capture`: o item.',
    example: 4,
  })
  @ValidateIf((body: BattleActionBodyDto) =>
    ['item', 'capture'].includes(body.type),
  )
  @IsInt({ message: INVALID_ACTION })
  item_id?: number;
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
    description: 'A posição em `team` de quem está em campo.',
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
      'Só quem está em campo: Técnicas, Traço e reservas ficam ocultos.',
    type: () => EnemyCreatureDto,
  })
  active: EnemyCreatureDto;

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
}
