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
  private readonly batchDataApiKey: string;
  private readonly baseUrl = 'https://api.batchdata.com/api/v1';

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.batchDataApiKey = this.configService.get<string>('BATCHDATA_API_KEY') || '';
    if (!this.batchDataApiKey) {
      this.logger.warn('BATCHDATA_API_KEY not configured - property lookup disabled');
    }
  }

  async lookupByAddress(
    street: string,
    city: string,
    state: string,
    zip: string,
  ): Promise<PropertyLookupResult> {
    if (!this.batchDataApiKey) {
      return { success: false, data: null, error: 'Property lookup not configured' };
    }

    try {
      const url = `${this.baseUrl}/property/lookup/all-attributes`;

      this.logger.log(`Looking up property: ${street}, ${city}, ${state} ${zip}`);

      const response = await firstValueFrom(
        this.httpService.post(url, {
          requests: [
            {
              address: {
                street,
                city,
                state,
                zip,
              },
            },
          ],
        }, {
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${this.batchDataApiKey}`,
          },
          timeout: 15000,
        })
      );

      const data = response.data;

      // Log full raw response at debug level for field discovery
      this.logger.debug('BatchData raw response:', JSON.stringify(data));

      // Check BatchData response status
      if (!data || data.status?.code !== 200) {
        const errorMsg = data?.status?.message || 'Property not found';
        this.logger.warn(`BatchData API returned: ${errorMsg}`);
        return { success: false, data: null, error: errorMsg };
      }

      // Extract property from response
      const property = data.results?.properties?.[0];
      if (!property) {
        return { success: false, data: null, error: 'No property data returned' };
      }

      // Parse the BatchData response into our format
      const propertyDetails = this.parseBatchDataProperty(property);

      this.logger.log(`Property found: ${propertyDetails.bedrooms} bed, ${propertyDetails.bathrooms} bath, ${propertyDetails.squareFeet} sqft`);

      return { success: true, data: propertyDetails };
    } catch (error: any) {
      this.logger.error('BatchData property lookup failed:', error.message);

      // Check for specific BatchData error responses
      if (error.response?.data?.status) {
        return {
          success: false,
          data: null,
          error: error.response.data.status.message || 'BatchData API error'
        };
      }

      return {
        success: false,
        data: null,
        error: error.message || 'Property lookup failed'
      };
    }
  }

  private parseBatchDataProperty(property: any): PropertyDetails {
    const building = property.building || {};
    const lot = property.lot || {};
    const utilities = property.utilities || {};
    const general = property.general || {};
    const assessment = property.assessment || {};
    const address = property.address || {};
    const deedHistory: any[] = property.deedHistory || [];
    const tax = property.tax || {};

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

    // Find last sale with a non-zero price from deed history
    const lastSale = [...deedHistory]
      .reverse()
      .find((d: any) => d.salePrice && Number(d.salePrice) > 0);

    const lotSizeSqFt = parsedInt(lot.lotSizeSquareFeet);
    const lotAcres = parsedFloat(lot.lotSizeAcres) ??
      (lotSizeSqFt ? Math.round((lotSizeSqFt / 43560) * 100) / 100 : null);

    const fullBaths = parsedInt(building.fullBathroomCount);
    const calculatedBaths = parsedFloat(building.calculatedBathroomCount) ?? parsedFloat(building.bathroomCount);
    const halfBaths = (calculatedBaths !== null && fullBaths !== null)
      ? Math.round(calculatedBaths - fullBaths)
      : null;

    const poolVal = building.pool || '';
    const hasPool = poolVal && typeof poolVal === 'string'
      ? poolVal.toLowerCase().includes('pool') && !poolVal.toLowerCase().includes('no pool')
      : null;

    return {
      // Basic Info
      bedrooms: parsedInt(building.bedroomCount) ??
        (parsedInt(building.roomCount) !== null && parsedInt(building.bathroomCount) !== null
          ? (parsedInt(building.roomCount)! - parsedInt(building.bathroomCount)!)
          : null),
      bathrooms: calculatedBaths ?? parsedFloat(building.bathroomCount),
      bathsFull: fullBaths,
      bathsHalf: halfBaths,
      squareFeet: parsedInt(building.livingAreaSquareFeet) ?? parsedInt(building.totalBuildingAreaSquareFeet),
      lotSizeSquareFeet: lotSizeSqFt,
      lotSizeAcres: lotAcres,
      yearBuilt: parsedInt(building.yearBuilt),

      // Property Type
      propertyType: general.propertyTypeCategory || null,
      propertySubType: general.propertyTypeDetail || null,

      // Building Details
      stories: parsedFloat(building.storyCount),
      constructionType: building.constructionType || null,
      foundationType: building.foundationType || null,
      roofType: building.roofType || null,
      roofMaterial: building.roofCover || null,
      exteriorWalls: building.exteriorWalls || null,

      // Systems (HVAC)
      heatingType: building.heatSource || null,
      heatingFuel: building.heatFuel || null,
      coolingType: building.airConditioningSource || null,

      // Utilities
      waterType: building.waterSource || utilities.waterSource || null,
      sewerType: building.sewerType || utilities.sewerType || null,

      // Features
      fireplaces: parsedInt(building.fireplaceCount),
      garage: building.garage || null,
      garageSpaces: parsedInt(building.garageParkingSpaceCount),
      pool: hasPool,
      poolType: poolVal || null,

      // Additional Rooms
      totalRooms: parsedInt(building.roomCount),
      basementType: building.basementType || null,

      // Valuation
      assessedValue: parsedInt(assessment.totalAssessedValue),
      marketValue: parsedInt(assessment.totalMarketValue),
      taxAmount: parsedInt(tax.totalTaxAmount) ?? parsedInt(assessment.taxAmount),

      // Sale Info
      lastSalePrice: lastSale ? parsedInt(lastSale.salePrice) : null,
      lastSaleDate: lastSale?.saleDate || null,

      // Location
      verifiedAddress: address.street || null,
      latitude: parsedFloat(address.latitude),
      longitude: parsedFloat(address.longitude),
    };
  }
}
