import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Client, GeocodeResult } from '@googlemaps/google-maps-services-js';
import { H3Service } from './h3.service';

export interface GeocodingResult {
  lat: number;
  lng: number;
  h3Index: string;
  formattedAddress: string;
  city?: string;
  state?: string;
  country?: string;
}

@Injectable()
export class GeocodingService {
  private readonly logger = new Logger(GeocodingService.name);
  private readonly client: Client;
  private readonly apiKey: string | undefined;

  constructor(
    private readonly configService: ConfigService,
    private readonly h3Service: H3Service,
  ) {
    this.client = new Client({});
    this.apiKey = this.configService.get<string>('GOOGLE_MAPS_API_KEY');
  }

  /**
   * Geocode an address and return coordinates with H3 index
   */
  async geocodeAddress(address: string): Promise<GeocodingResult | null> {
    if (!this.apiKey) {
      this.logger.warn('Google Maps API key not configured. Geocoding disabled.');
      return null;
    }

    try {
      const response = await this.client.geocode({
        params: {
          address,
          key: this.apiKey,
        },
      });

      if (response.data.results.length === 0) {
        this.logger.warn(`No geocoding results for address: ${address}`);
        return null;
      }

      const result = response.data.results[0];
      const { lat, lng } = result.geometry.location;
      const h3Index = this.h3Service.getH3Index(lat, lng);

      // Extract address components
      const city = this.extractAddressComponent(result, 'locality');
      const state = this.extractAddressComponent(result, 'administrative_area_level_1');
      const country = this.extractAddressComponent(result, 'country');

      return {
        lat,
        lng,
        h3Index,
        formattedAddress: result.formatted_address,
        city,
        state,
        country,
      };
    } catch (error) {
      this.logger.error(`Geocoding error for address "${address}":`, error);
      return null;
    }
  }

  /**
   * Geocode a full address from components
   */
  async geocodeFromComponents(
    addressLine1: string,
    city: string,
    state: string,
    postalCode: string,
    country: string = 'US',
  ): Promise<GeocodingResult | null> {
    const fullAddress = `${addressLine1}, ${city}, ${state} ${postalCode}, ${country}`;
    return this.geocodeAddress(fullAddress);
  }

  /**
   * Extract a specific address component from geocoding result
   */
  private extractAddressComponent(
    result: GeocodeResult,
    type: string,
  ): string | undefined {
    const component = result.address_components?.find((c) =>
      (c.types as string[]).includes(type),
    );
    return component?.long_name;
  }

  /**
   * Get H3 index for existing lat/lng coordinates
   */
  getH3IndexForCoordinates(lat: number, lng: number): string {
    return this.h3Service.getH3Index(lat, lng);
  }

  /**
   * Check if geocoding is available (API key configured)
   */
  isGeocodingAvailable(): boolean {
    return !!this.apiKey;
  }
}
