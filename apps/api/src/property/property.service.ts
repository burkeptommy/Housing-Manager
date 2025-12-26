import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

export interface PropertyDetails {
  // Basic Info
  bedrooms: number | null;
  bathrooms: number | null;
  bathsFull: number | null;
  bathsHalf: number | null;
  squareFeet: number | null;
  lotSizeSquareFeet: number | null;
  lotSizeAcres: number | null;
  yearBuilt: number | null;

  // Property Type
  propertyType: string | null;
  propertySubType: string | null;

  // Building Details
  stories: number | null;
  constructionType: string | null;
  foundationType: string | null;
  roofType: string | null;
  roofMaterial: string | null;
  exteriorWalls: string | null;

  // Systems (HVAC)
  heatingType: string | null;
  heatingFuel: string | null;
  coolingType: string | null;

  // Utilities
  waterType: string | null;
  sewerType: string | null;

  // Features
  fireplaces: number | null;
  garage: string | null;
  garageSpaces: number | null;
  pool: boolean | null;
  poolType: string | null;

  // Additional Rooms
  totalRooms: number | null;
  basementType: string | null;

  // Valuation
  assessedValue: number | null;
  marketValue: number | null;
  taxAmount: number | null;

  // Sale Info
  lastSalePrice: number | null;
  lastSaleDate: string | null;

  // Location
  verifiedAddress: string | null;
  latitude: number | null;
  longitude: number | null;
}

export interface PropertyLookupResult {
  success: boolean;
  data: PropertyDetails | null;
  error?: string;
}

@Injectable()
export class PropertyService {
  private readonly logger = new Logger(PropertyService.name);
  private readonly attomApiKey: string;
  private readonly baseUrl = 'https://api.gateway.attomdata.com/propertyapi/v1.0.0';

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.attomApiKey = this.configService.get<string>('ATTOM_API_KEY') || '';
    if (!this.attomApiKey) {
      this.logger.warn('ATTOM_API_KEY not configured - property lookup disabled');
    }
  }

  async lookupByAddress(
    street: string,
    city: string,
    state: string,
    zip: string,
  ): Promise<PropertyLookupResult> {
    if (!this.attomApiKey) {
      return { success: false, data: null, error: 'Property lookup not configured' };
    }

    try {
      // Format address for ATTOM API
      const address1 = encodeURIComponent(street);
      const address2 = encodeURIComponent(`${city}, ${state} ${zip}`);

      const url = `${this.baseUrl}/property/expandedprofile?address1=${address1}&address2=${address2}`;

      this.logger.log(`Looking up property: ${street}, ${city}, ${state} ${zip}`);

      const response = await firstValueFrom(
        this.httpService.get(url, {
          headers: {
            'Accept': 'application/json',
            'APIKey': this.attomApiKey,
          },
          timeout: 15000,
        })
      );

      const data = response.data;

      // Check for ATTOM status
      if (!data || data.status?.code !== 0) {
        const errorMsg = data?.status?.msg || 'Property not found';
        this.logger.warn(`ATTOM API returned: ${errorMsg}`);
        return { success: false, data: null, error: errorMsg };
      }

      // Extract property from response
      const property = data.property?.[0];
      if (!property) {
        return { success: false, data: null, error: 'No property data returned' };
      }

      // Parse the ATTOM response into our format
      const propertyDetails = this.parseAttomProperty(property);

      this.logger.log(`Property found: ${propertyDetails.bedrooms} bed, ${propertyDetails.bathrooms} bath, ${propertyDetails.squareFeet} sqft`);

      return { success: true, data: propertyDetails };
    } catch (error: any) {
      this.logger.error('ATTOM property lookup failed:', error.message);

      // Check for specific ATTOM error responses
      if (error.response?.data?.status) {
        return {
          success: false,
          data: null,
          error: error.response.data.status.msg || 'ATTOM API error'
        };
      }

      return {
        success: false,
        data: null,
        error: error.message || 'Property lookup failed'
      };
    }
  }

  private parseAttomProperty(property: any): PropertyDetails {
    const building = property.building || {};
    const lot = property.lot || {};
    const utilities = property.utilities || {};
    const summary = property.summary || {};
    const rooms = building.rooms || {};
    const interior = building.interior || {};
    const construction = building.construction || {};
    const parking = building.parking || {};
    const assessment = property.assessment || {};
    const sale = property.sale || {};
    const location = property.location || {};
    const address = property.address || {};
    const buildingSize = building.size || {};
    const buildingSummary = building.summary || {};

    const parsedInt = (val: any): number | null => {
      if (val === undefined || val === null || val === '') return null;
      const num = parseInt(String(val), 10);
      return isNaN(num) ? null : num;
    };

    const parsedFloat = (val: any): number | null => {
      if (val === undefined || val === null || val === '') return null;
      const num = parseFloat(String(val));
      return isNaN(num) ? null : num;
    };

    return {
      // Basic Info
      bedrooms: parsedInt(rooms.beds),
      bathrooms: parsedFloat(rooms.bathsTotal),
      bathsFull: parsedInt(rooms.bathsFull),
      bathsHalf: parsedInt(rooms.bathsPartial),
      squareFeet: parsedInt(buildingSize.livingSize) || parsedInt(buildingSize.universalSize),
      lotSizeSquareFeet: parsedInt(lot.lotSize2),
      lotSizeAcres: parsedFloat(lot.lotSize1),
      yearBuilt: parsedInt(summary.yearBuilt),

      // Property Type
      propertyType: summary.propType || summary.propertyType || null,
      propertySubType: summary.propSubType || null,

      // Building Details
      stories: parsedFloat(buildingSummary.levels),
      constructionType: construction.condition || null,
      foundationType: null, // Not in this response
      roofType: null, // Not in this response
      roofMaterial: null,
      exteriorWalls: construction.wallType || null,

      // Systems (HVAC)
      heatingType: utilities.heatingType || null,
      heatingFuel: utilities.heatingFuel || null,
      coolingType: utilities.coolingType || null,

      // Utilities
      waterType: null,
      sewerType: null,

      // Features
      fireplaces: parsedInt(interior.fplcCount),
      garage: parking.garageType || null,
      garageSpaces: parsedInt(parking.garageSize),
      pool: lot.poolType ? !lot.poolType.toLowerCase().includes('no pool') : null,
      poolType: lot.poolType || null,

      // Additional Rooms
      totalRooms: parsedInt(rooms.roomsTotal),
      basementType: null,

      // Valuation
      assessedValue: parsedInt(assessment.assessed?.assdTtlValue),
      marketValue: parsedInt(assessment.market?.mktTtlValue),
      taxAmount: parsedInt(assessment.tax?.taxAmt),

      // Sale Info
      lastSalePrice: parsedInt(sale.amount?.saleAmt),
      lastSaleDate: sale.saleTransDate || null,

      // Location
      verifiedAddress: address.oneLine || null,
      latitude: parsedFloat(location.latitude),
      longitude: parsedFloat(location.longitude),
    };
  }
}
