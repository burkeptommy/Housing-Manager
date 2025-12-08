import { Module } from '@nestjs/common';

import { AuthModule } from '../auth';

import { HomeProfilesController } from './home-profiles.controller';
import { HomeProfilesService } from './home-profiles.service';

@Module({
  imports: [AuthModule],
  controllers: [HomeProfilesController],
  providers: [HomeProfilesService],
  exports: [HomeProfilesService],
})
export class HomeProfilesModule {}
