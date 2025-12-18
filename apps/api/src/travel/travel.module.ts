import { Module } from '@nestjs/common';
import { TravelController } from './travel.controller';
import { TravelInternalController } from './travel-internal.controller';
import {
  TravelProfileService,
  TripService,
  ProposalService,
  ItineraryService,
  VacationModeService,
} from './services';
import { PrismaModule } from '../prisma/prisma.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [PrismaModule, AuthModule],
  controllers: [TravelController, TravelInternalController],
  providers: [
    TravelProfileService,
    TripService,
    ProposalService,
    ItineraryService,
    VacationModeService,
  ],
  exports: [
    TravelProfileService,
    TripService,
    ProposalService,
    ItineraryService,
    VacationModeService,
  ],
})
export class TravelModule {}
