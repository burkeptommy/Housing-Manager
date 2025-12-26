import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase';
import { PropertyService, PropertyEnrichmentResult } from './property.service';

@Controller('property')
@UseGuards(FirebaseAuthGuard)
export class PropertyController {
  constructor(private readonly propertyService: PropertyService) {}

  @Get('enrich')
  async enrichProperty(
    @Query('addressLine1') addressLine1: string,
    @Query('city') city?: string,
    @Query('state') state?: string,
    @Query('zip') zip?: string,
  ): Promise<PropertyEnrichmentResult> {
    if (!addressLine1) {
      return {
        success: false,
        error: 'addressLine1 is required',
      };
    }

    return this.propertyService.enrichProperty(addressLine1, city, state, zip);
  }
}
