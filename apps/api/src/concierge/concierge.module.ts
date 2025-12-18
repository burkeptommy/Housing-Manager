import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ConciergeService } from './concierge.service';
import { ConciergeController } from './concierge.controller';
import { AuthModule } from '../auth/auth.module';
import { AIClassifierService } from './services/ai-classifier.service';
import { TriageService } from './services/triage.service';
import { ExecutionPipelineService } from './services/execution-pipeline.service';

@Module({
  imports: [AuthModule, ConfigModule],
  controllers: [ConciergeController],
  providers: [
    ConciergeService,
    AIClassifierService,
    TriageService,
    ExecutionPipelineService,
  ],
  exports: [ConciergeService, TriageService, ExecutionPipelineService],
})
export class ConciergeModule {}
