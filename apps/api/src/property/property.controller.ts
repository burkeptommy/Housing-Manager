import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase';
import { PropertyService, PropertyLookupResult } from './property.service';

@Controller('property')
@UseGuards(FirebaseAuthGuard)
export class PropertyController {
  constructor(private readonly propertyService: PropertyService) {}

  @Get('lookup')
  async lookupProperty(
    @Query('street') street: string,
    @Query('city') city: string,
    @Query('state') state: string,
    @Query('zip') zip: string,
  ): Promise<PropertyLookupResult> {
    if (!street || !city || !state || !zip) {
      return {
        success: false,
        data: null,
        error: 'street, city, state, and zip are required',
      };
    }

    return this.propertyService.lookupByAddress(street, city, state, zip);
  }
}
