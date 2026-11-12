import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  ArrayMinSize,
  IsArray,
  IsDefined,
  IsIn,
  IsInt,
  IsOptional,
  Max,
  Min,
  ValidateIf,
  ValidateNested,
} from 'class-validator';
import {
  BattleDto,
  CreatureProgressDto,
  EnemySideDto,
  INVALID_ACTION,
  INVALID_ENEMY,
  MAX_TEST_ENEMIES,
  PlayerSideDto,
  TestEnemyDto,
  type CapturedTo,
} from '../battle/battle.dto.js';
import { MAX_SLOTS } from '../domain/battle/field.js';
import type { BattleEvent, SideSlug } from '../domain/battle/types.js';
import type { BoardAction } from '../domain/board/types.js';

const ACTION_TYPES: BoardAction['type'][] = [
  'skill',
  'emergency',
  'item',
  'switch',
  'capture',
  'flee',
  'wait',
];

export class HexCoordDto {
  @ApiProperty({ description: 'Coordenada axial q.', example: 0 })
  @IsInt({ message: INVALID_ACTION })
  q: number;

  @ApiProperty({ description: 'Coordenada axial r.', example: 5 })
  @IsInt({ message: INVALID_ACTION })
  r: number;
}

export class StartBoardBattleBodyDto {
  @ApiProperty({
    description: `A equipe inimiga, de 1 a ${MAX_TEST_ENEMIES}.`,
    type: () => [TestEnemyDto],
  })
  @IsArray({ message: INVALID_ENEMY })
  @ArrayMinSize(1, { message: INVALID_ENEMY })
  @ArrayMaxSize(MAX_TEST_ENEMIES, { message: INVALID_ENEMY })
  @ValidateNested({ each: true })
  @Type(() => TestEnemyDto)
  enemies: TestEnemyDto[];

  @ApiPropertyOptional({
    description: `Vagas de cada lado no tabuleiro, de 1 a ${MAX_SLOTS}. 1 sem ela.`,
    example: 2,
  })
  @IsOptional()
  @IsInt({ message: INVALID_ENEMY })
  @Min(1, { message: INVALID_ENEMY })
  @Max(MAX_SLOTS, { message: INVALID_ENEMY })
  slots?: number;
}

export class BoardActionDto {
  @ApiProperty({
    description:
      '`skill` usa uma Técnica; `emergency` é o golpe de quem está sem PP; ' +
      '`item` usa um item; `switch` troca o Ecobeast; `capture` tenta a ' +
      'captura com uma Esfera; `flee` tenta fugir; `wait` só passa a vez.',
    enum: ACTION_TYPES,
    example: 'skill',
  })
  @IsIn(ACTION_TYPES, { message: INVALID_ACTION })
  type: BoardAction['type'];

  @ApiPropertyOptional({
    description: 'Só em `skill`: o slot da Técnica, de 1 a 4.',
    example: 1,
  })
  @ValidateIf((body: BoardActionDto) => body.type === 'skill')
  @IsInt({ message: INVALID_ACTION })
  slot?: number;

  @ApiPropertyOptional({
    description: 'Em `switch` e `item`: a posição do Ecobeast na equipe.',
    example: 1,
  })
  @ValidateIf((body: BoardActionDto) => ['switch', 'item'].includes(body.type))
  @IsInt({ message: INVALID_ACTION })
  team_index?: number;

  @ApiPropertyOptional({
    description: 'Em `item` e `capture`: o item.',
    example: 4,
  })
  @ValidateIf((body: BoardActionDto) => ['item', 'capture'].includes(body.type))
  @IsInt({ message: INVALID_ACTION })
  item_id?: number;

  @ApiPropertyOptional({
    description:
      'Em `skill` e `emergency`, o hexágono alvo (obrigatório com mais de um ' +
      'selvagem no tabuleiro); em `capture`, o hexágono do selvagem.',
    type: () => HexCoordDto,
  })
  @ValidateIf(
    (body: BoardActionDto) =>
      body.type === 'capture' || body.target !== undefined,
  )
  // O objeto aninhado ausente passa pela validação dele: sem isto, vira 500.
  @IsDefined({ message: INVALID_ACTION })
  @ValidateNested({ message: INVALID_ACTION })
  @Type(() => HexCoordDto)
  target?: HexCoordDto;
}

export class BoardEntryDto {
  @ApiProperty({ description: 'A vaga que espera quem entra.', example: 0 })
  @IsInt({ message: INVALID_ACTION })
  position: number;

  @ApiProperty({
    description: 'Quem entra, pela posição na equipe.',
    example: 2,
  })
  @IsInt({ message: INVALID_ACTION })
  team_index: number;

  @ApiProperty({
    description: 'Um dos `entry_cells`.',
    type: () => HexCoordDto,
  })
  @IsDefined({ message: INVALID_ACTION })
  @ValidateNested({ message: INVALID_ACTION })
  @Type(() => HexCoordDto)
  cell: HexCoordDto;
}

export class BoardVezBodyDto {
  @ApiPropertyOptional({
    description: 'A vaga de quem joga; tem de ser o primeiro da fila.',
    example: 0,
  })
  @ValidateIf((body: BoardVezBodyDto) => body.entries === undefined)
  @IsInt({ message: INVALID_ACTION })
  position?: number;

  @ApiPropertyOptional({
    description: 'Onde o Ecobeast para, a até 3 passos por hexágonos livres.',
    type: () => HexCoordDto,
  })
  @IsOptional()
  @ValidateNested({ message: INVALID_ACTION })
  @Type(() => HexCoordDto)
  move?: HexCoordDto;

  @ApiPropertyOptional({ type: () => BoardActionDto })
  @ValidateIf((body: BoardVezBodyDto) => body.entries === undefined)
  @IsDefined({ message: INVALID_ACTION })
  @ValidateNested({ message: INVALID_ACTION })
  @Type(() => BoardActionDto)
  action?: BoardActionDto;

  @ApiPropertyOptional({
    description: 'No `choose_next`: quem entra em cada vaga pendente, e onde.',
    type: () => [BoardEntryDto],
  })
  @IsOptional()
  @IsArray({ message: INVALID_ACTION })
  @ArrayMinSize(1, { message: INVALID_ACTION })
  @ArrayMaxSize(MAX_SLOTS, { message: INVALID_ACTION })
  @ValidateNested({ each: true })
  @Type(() => BoardEntryDto)
  entries?: BoardEntryDto[];
}

export class BoardZonesDto {
  @ApiProperty({ type: () => [HexCoordDto] })
  player: HexCoordDto[];

  @ApiProperty({ type: () => [HexCoordDto] })
  enemy: HexCoordDto[];
}

export class BoardDto {
  @ApiProperty({
    description: 'Os hexágonos do tabuleiro, em coordenadas axiais.',
    type: () => [HexCoordDto],
  })
  cells: HexCoordDto[];

  @ApiProperty({
    description: 'A área de largada de cada lado, a linha da frente primeiro.',
    type: () => BoardZonesDto,
  })
  zones: BoardZonesDto;
}

export class GroundMarkDto extends HexCoordDto {
  @ApiProperty({ example: 1 })
  ground_effect_id: number;

  @ApiProperty({ description: 'Vezes da fila que ainda faltam.', example: 5 })
  remaining: number;
}

export class QueueSpotDto {
  @ApiProperty({ enum: ['player', 'enemy'], example: 'player' })
  side: SideSlug;

  @ApiProperty({ example: 0 })
  position: number;
}

const CELLS_BY_SLOT = {
  description:
    'Por vaga: onde está quem ocupa a vaga, ou nulo fora do tabuleiro.',
  type: 'array',
  items: {
    type: 'object',
    nullable: true,
    properties: { q: { type: 'integer' }, r: { type: 'integer' } },
  },
  example: [{ q: 0, r: 5 }],
} as const;

export class BoardPlayerSideDto extends PlayerSideDto {
  @ApiProperty(CELLS_BY_SLOT)
  cells: (HexCoordDto | null)[];

  @ApiProperty({
    description:
      'No `choose_next`: onde quem entra pode ficar. Vazio nas outras fases.',
    type: () => [HexCoordDto],
  })
  entry_cells: HexCoordDto[];
}

export class BoardEnemySideDto extends EnemySideDto {
  @ApiProperty(CELLS_BY_SLOT)
  cells: (HexCoordDto | null)[];
}

export class BattleTamerDto {
  @ApiProperty({
    description: 'Id do nome, em `npc_tamer_names`.',
    example: 4,
  })
  name_id: number;

  @ApiProperty({
    description:
      'De onde o Domador veio: `map`, do hexágono do jogador, ou `challenge`, ' +
      'do Desafiar do Hub.',
    enum: ['map', 'challenge'],
    example: 'map',
  })
  source: 'map' | 'challenge';
}

export class BoardBattleDto extends BattleDto {
  @ApiProperty({ example: 1 })
  round: number;

  @ApiProperty({ type: () => BoardDto })
  board: BoardDto;

  @ApiProperty({ type: () => [GroundMarkDto] })
  marks: GroundMarkDto[];

  @ApiProperty({
    description:
      'O que falta da rodada, na ordem. O primeiro é quem joga agora.',
    type: () => [QueueSpotDto],
  })
  queue: QueueSpotDto[];

  @ApiProperty({ type: () => BoardPlayerSideDto })
  declare player: BoardPlayerSideDto;

  @ApiProperty({ type: () => BoardEnemySideDto })
  declare enemy: BoardEnemySideDto;

  @ApiProperty({
    description: 'O Domador NPC adversário; nulo contra selvagem.',
    type: () => BattleTamerDto,
    nullable: true,
  })
  tamer: BattleTamerDto | null;
}

export class BoardBattleResponseDto {
  @ApiProperty({ type: () => BoardBattleDto })
  battle: BoardBattleDto;

  @ApiProperty({
    description:
      'O que aconteceu, em ordem, desde a vez anterior do jogador, com as ' +
      'vezes dos selvagens. Os eventos estão em `.specs/board-battle/architecture.md`.',
    type: 'array',
    items: { type: 'object' },
    example: [
      { type: 'vez_started', side: 'player', position: 0 },
      { type: 'moved', side: 'player', position: 0, path: [{ q: 0, r: 4 }] },
    ],
  })
  events: BattleEvent[];

  @ApiProperty({
    description:
      'Para onde foi o último capturado, no fim da luta. Nulo nas outras.',
    enum: ['party', 'storage'],
    nullable: true,
    example: null,
  })
  captured_to: CapturedTo | null;

  @ApiProperty({
    description:
      'No começo de um encontro selvagem, o Ecobeast que saiu do mapa.',
    type: 'integer',
    nullable: true,
    example: null,
  })
  spawn_id: number | null;

  @ApiProperty({
    description:
      'No começo de uma luta contra Domador do mapa, o Domador que saiu do mapa.',
    type: 'integer',
    nullable: true,
    example: null,
  })
  tamer_id: number | null;

  @ApiProperty({
    description: 'Na vitória, quem recebeu XP. Vazio nas outras respostas.',
    type: () => [CreatureProgressDto],
  })
  progression: CreatureProgressDto[];

  @ApiProperty({
    description:
      'As espécies que ficaram capturadas pela primeira vez no Bestiário nesta ' +
      'resposta: só no fim de uma luta com captura. Vazio nas outras.',
    type: [Number],
    example: [],
  })
  registered_species_ids: number[];
}
