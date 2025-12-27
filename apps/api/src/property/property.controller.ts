import { Controller, Get, Post, Body, Query, UseGuards } from '@nestjs/common';
import { FirebaseAuthGuard } from '../firebase';
import { PropertyService, PropertyLookupResult, PropertyDetails } from './property.service';
import { ChecklistGeneratorService, ChecklistItem } from './checklist-generator.service';

interface GenerateChecklistRequest {
  street: string;
  city: string;
  state: string;
  zip: string;
  propertyData?: PropertyDetails;
}

interface GenerateChecklistResponse {
  success: boolean;
  checklist: ChecklistItem[];
  summary: {
    totalQuestions: number;
    highPriority: number;
    categories: string[];
    highlights: string[];
  };
  error?: string;
}

@Controller('property')
@UseGuards(FirebaseAuthGuard)
export class PropertyController {
  constructor(
    private readonly propertyService: PropertyService,
    private readonly checklistGeneratorService: ChecklistGeneratorService,
  ) {}

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

  /**
   * Generate a smart checklist for a property based on ATTOM data.
   * If propertyData is not provided, we'll fetch it from ATTOM.
   */
  @Post('checklist/generate')
  async generateChecklist(
    @Body() data: GenerateChecklistRequest,
  ): Promise<GenerateChecklistResponse> {
    const { street, city, state, zip, propertyData } = data;

    if (!street || !city || !state || !zip) {
      return {
        success: false,
        checklist: [],
        summary: { totalQuestions: 0, highPriority: 0, categories: [], highlights: [] },
        error: 'street, city, state, and zip are required',
      };
    }

    try {
      // Use provided property data or fetch from ATTOM
      let property: PropertyDetails | null = propertyData || null;

      if (!property) {
        const lookupResult = await this.propertyService.lookupByAddress(
          street,
          city,
          state,
          zip,
        );
        property = lookupResult.data;
      }

      // Generate checklist even if we don't have property data
      // (will just use default questions)
      const checklist = this.checklistGeneratorService.generateChecklist(
        property || {} as PropertyDetails,
        state,
        city,
      );

      const summary = this.checklistGeneratorService.getChecklistSummary(
        property || {} as PropertyDetails,
      );

      return {
        success: true,
        checklist,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        checklist: [],
        summary: { totalQuestions: 0, highPriority: 0, categories: [], highlights: [] },
        error: error.message || 'Failed to generate checklist',
      };
    }
  }

  /**
   * Get a checklist preview (summary only) without generating the full checklist
   */
  @Get('checklist/preview')
  async getChecklistPreview(
    @Query('street') street: string,
    @Query('city') city: string,
    @Query('state') state: string,
    @Query('zip') zip: string,
  ): Promise<{
    success: boolean;
    summary?: {
      totalQuestions: number;
      highPriority: number;
      categories: string[];
      highlights: string[];
    };
    error?: string;
  }> {
    if (!street || !city || !state || !zip) {
      return {
        success: false,
        error: 'street, city, state, and zip are required',
      };
    }

    try {
      const lookupResult = await this.propertyService.lookupByAddress(
        street,
        city,
        state,
        zip,
      );

      const summary = this.checklistGeneratorService.getChecklistSummary(
        lookupResult.data || {} as PropertyDetails,
      );

      return {
        success: true,
        summary,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Failed to get checklist preview',
      };
    }
  }
}
