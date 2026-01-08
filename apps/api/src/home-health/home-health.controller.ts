import { Controller, Get, UseGuards, Request, Query } from '@nestjs/common';
import { HomeHealthService } from './home-health.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('home-health')
@UseGuards(JwtAuthGuard)
export class HomeHealthController {
  constructor(private homeHealthService: HomeHealthService) {}

  @Get()
  async getHealthScore(
    @Request() req: any,
    @Query('householdId') householdId?: string,
  ) {
    // Use provided householdId or fall back to user's household
    const hId = householdId || req.user?.householdId;
    if (!hId) {
      return {
        score: 0,
        maxScore: 100,
        grade: 'Unknown',
        factors: [],
        recommendations: ['No household found'],
      };
    }
    return this.homeHealthService.calculateHealthScore(hId);
  }
}
