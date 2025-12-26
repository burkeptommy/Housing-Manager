import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';

import { AuthModule } from '../auth';

import { PropertyController } from './property.controller';
import { PropertyService } from './property.service';

@Module({
  imports: [HttpModule, AuthModule],
  controllers: [PropertyController],
  providers: [PropertyService],
  exports: [PropertyService],
})
export class PropertyModule {}
