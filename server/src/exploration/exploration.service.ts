import { ConflictException, Injectable } from '@nestjs/common';
import { secureRandom } from '../common/secure-random.js';
import { generateMap } from '../domain/exploration/map-generator.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ExplorationResponseDto } from './exploration.dto.js';

export const NO_PLAYER = 'Crie seu Domador primeiro.';
const SEED_RANGE = 2 ** 32;

/** Gera um mapa por exploração; nada fica guardado (wild-battle/02). */
@Injectable()
export class ExplorationService {
  constructor(private readonly prisma: PrismaService) {}

  async start(userId: string): Promise<ExplorationResponseDto> {
    const team = await this.prisma.creatureInstance.count({
      where: { playerId: userId, location: 'party' },
    });
    if (team === 0) throw new ConflictException(NO_PLAYER);
    return { map: generateMap(Math.floor(secureRandom() * SEED_RANGE)) };
  }
}
