import { Module } from '@nestjs/common';

import { AuthModule } from '../auth';
import { FirebaseModule } from '../firebase';

import { UsersController, MeController, UserMeController, MeFeaturesController, HouseholdInvitesController, UserProfileController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  imports: [AuthModule, FirebaseModule.forRoot()],
  controllers: [UsersController, MeController, UserMeController, MeFeaturesController, HouseholdInvitesController, UserProfileController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
