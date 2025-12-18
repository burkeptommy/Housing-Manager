import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma';
import { FirebaseModule } from '../firebase';
import { ProjectPlannerController } from './project-planner.controller';
import {
  ProjectTemplateService,
  EstimationService,
  ProjectIdeaService,
  CommunityIntelligenceService,
  RecommendationService,
} from './services';

@Module({
  imports: [PrismaModule, FirebaseModule],
  controllers: [ProjectPlannerController],
  providers: [
    ProjectTemplateService,
    EstimationService,
    ProjectIdeaService,
    CommunityIntelligenceService,
    RecommendationService,
  ],
  exports: [
    ProjectTemplateService,
    EstimationService,
    ProjectIdeaService,
    CommunityIntelligenceService,
    RecommendationService,
  ],
})
export class ProjectPlannerModule {}
