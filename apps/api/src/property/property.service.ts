import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { ConfigService } from '@nestjs/config';
import { firstValueFrom } from 'rxjs';

export interface PropertyEnrichmentResult {
  success: boolean;
  data?: {
    address: {
      addressLine1: string;
      city: string;
      state: string;
      zipCode: string;
      plus4: string;
      formattedAddress: string;
    };
    property: {
      bedrooms: number | null;
      bathrooms: number | null;
      squareFeet: number | null;
      yearBuilt: number | null;
      lotSizeAcres: number | null;
      lotSizeSqFt: number | null;
      propertyType: string | null;
      stories: number | null;
      pool: boolean;
      garage: string | null;
      garageSqFt: number | null;
      roofType: string | null;
      hvacType: string | null;
      foundation: string | null;
      exteriorWalls: string | null;
    };
    valuation: {
      estimatedValue: number | null;
      assessedValue: number | null;
      taxAmount: number | null;
      taxYear: number | null;
    };
    parcel: {
      apn: string | null;
      fipsCode: string | null;
      county: string | null;
      legalDescription: string | null;
    };
  };
  error?: string;
  rawResponse?: unknown;
}

@Injectable()
export class PropertyService {
  private readonly logger = new Logger(PropertyService.name);
  private readonly melissaApiKey: string;
  private readonly melissaBaseUrl = 'https://property.melissadata.net/v4/WEB/LookupProperty';

  constructor(
    private readonly httpService: HttpService,
    private readonly configService: ConfigService,
  ) {
    this.melissaApiKey = this.configService.get<string>('MELISSA_API_KEY') || '';
  }

  async enrichProperty(
    addressLine1: string,
    city?: string,
    state?: string,
    zip?: string,
  ): Promise<PropertyEnrichmentResult> {
    if (!this.melissaApiKey) {
      this.logger.warn('Melissa API key not configured');
      return {
        success: false,
        error: 'Property enrichment service not configured',
      };
    }

    try {
      const params: Record<string, string> = {
        id: this.melissaApiKey,
        format: 'json',
        addressline1: addressLine1,
      };

      if (city) params.city = city;
      if (state) params.state = state;
      if (zip) params.zip = zip;

      this.logger.debug(`Fetching property data for: ${addressLine1}`);

      const response = await firstValueFrom(
        this.httpService.get(this.melissaBaseUrl, { params }),
      );

      const data = response.data;

      // Log raw response for debugging
      this.logger.debug(`Melissa API response: ${JSON.stringify(data)}`);

      // Check for API errors
      if (!data || data.TransmissionResults?.includes('GE')) {
        return {
          success: false,
          error: 'Failed to fetch property data',
          rawResponse: data,
        };
      }

      // Check if we have property records
      const records = data.Records;
      if (!records || records.length === 0) {
        return {
          success: false,
          error: 'No property data found for this address',
          rawResponse: data,
        };
      }

      const record = records[0];
      const parsedAddress = record.ParsedAddress || {};
      const propertyData = record.PropertyInfo || {};
      const parcelData = record.ParcelInfo || {};
      const taxData = record.TaxInfo || {};

      return {
        success: true,
        data: {
          address: {
            addressLine1: parsedAddress.AddressLine1 || addressLine1,
            city: parsedAddress.City || city || '',
            state: parsedAddress.State || state || '',
            zipCode: parsedAddress.Zip || zip || '',
            plus4: parsedAddress.Plus4 || '',
            formattedAddress: record.FormattedAddress || addressLine1,
          },
          property: {
            bedrooms: this.parseNumber(propertyData.Bedrooms),
            bathrooms: this.parseFloat(propertyData.Bathrooms),
            squareFeet: this.parseNumber(propertyData.BuildingSquareFeet || propertyData.LivingArea),
            yearBuilt: this.parseNumber(propertyData.YearBuilt),
            lotSizeAcres: this.parseFloat(propertyData.LotSizeAcres),
            lotSizeSqFt: this.parseNumber(propertyData.LotSizeSqFt),
            propertyType: propertyData.PropertyType || null,
            stories: this.parseNumber(propertyData.Stories),
            pool: propertyData.Pool === 'Y' || propertyData.Pool === 'Yes',
            garage: propertyData.GarageType || null,
            garageSqFt: this.parseNumber(propertyData.GarageSqFt),
            roofType: propertyData.RoofType || null,
            hvacType: propertyData.HvacType || propertyData.HeatingType || null,
            foundation: propertyData.FoundationType || null,
            exteriorWalls: propertyData.ExteriorWalls || null,
          },
          valuation: {
            estimatedValue: this.parseNumber(propertyData.EstimatedValue || taxData.MarketValue),
            assessedValue: this.parseNumber(taxData.AssessedValue),
            taxAmount: this.parseFloat(taxData.TaxAmount),
            taxYear: this.parseNumber(taxData.TaxYear),
          },
          parcel: {
            apn: parcelData.APN || null,
            fipsCode: parcelData.FipsCode || null,
            county: parcelData.County || null,
            legalDescription: parcelData.LegalDescription || null,
          },
        },
        rawResponse: data,
      };
    } catch (error) {
      this.logger.error(`Error fetching property data: ${error}`);
      return {
        success: false,
        error: error instanceof Error ? error.message : 'Unknown error occurred',
      };
    }
  }

  private parseNumber(value: string | number | undefined | null): number | null {
    if (value === undefined || value === null || value === '') return null;
    const num = typeof value === 'number' ? value : parseInt(value, 10);
    return isNaN(num) ? null : num;
  }

  private parseFloat(value: string | number | undefined | null): number | null {
    if (value === undefined || value === null || value === '') return null;
    const num = typeof value === 'number' ? value : parseFloat(value);
    return isNaN(num) ? null : num;
  }
}
