import { Module } from '@nestjs/common';

import { UploadsController } from './uploads.controller';
import { UploadsService } from './uploads.service';
import { GcsStorageService } from './gcs-storage.service';

@Module({
  controllers: [UploadsController],
  providers: [UploadsService, GcsStorageService],
  exports: [UploadsService, GcsStorageService],
})
export class UploadsModule {}
