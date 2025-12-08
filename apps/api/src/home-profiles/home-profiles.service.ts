import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';

import { PrismaService } from '../prisma';

import { UpsertHomeProfileDto, HomeProfileDto } from './dto';

@Injectable()
export class HomeProfilesService {
  constructor(private readonly prisma: PrismaService) {}

  async upsert(householdId: string, dto: UpsertHomeProfileDto): Promise<HomeProfileDto> {
    // Check if household exists
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });

    if (!household) {
      throw new NotFoundException(`Household with ID ${householdId} not found`);
    }

    const data: Prisma.HomeProfileCreateInput = {
      household: { connect: { id: householdId } },
      propertyType: dto.propertyType,
      addressLine1: dto.addressLine1,
      addressLine2: dto.addressLine2,
      city: dto.city,
      state: dto.state,
      postalCode: dto.postalCode,
      country: dto.country || 'US',
      squareFeet: dto.squareFeet,
      lotSize: dto.lotSize,
      yearBuilt: dto.yearBuilt,
      bedrooms: dto.bedrooms,
      bathrooms: dto.bathrooms,
      stories: dto.stories,
      garageSpaces: dto.garageSpaces,
      purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : null,
      purchasePrice: dto.purchasePrice,
      currentValue: dto.currentValue,
      notes: dto.notes,
    };

    const profile = await this.prisma.homeProfile.upsert({
      where: { householdId },
      create: data,
      update: {
        propertyType: dto.propertyType,
        addressLine1: dto.addressLine1,
        addressLine2: dto.addressLine2,
        city: dto.city,
        state: dto.state,
        postalCode: dto.postalCode,
        country: dto.country || 'US',
        squareFeet: dto.squareFeet,
        lotSize: dto.lotSize,
        yearBuilt: dto.yearBuilt,
        bedrooms: dto.bedrooms,
        bathrooms: dto.bathrooms,
        stories: dto.stories,
        garageSpaces: dto.garageSpaces,
        purchaseDate: dto.purchaseDate ? new Date(dto.purchaseDate) : null,
        purchasePrice: dto.purchasePrice,
        currentValue: dto.currentValue,
        notes: dto.notes,
      },
    });

    return this.mapToDto(profile);
  }

  async findByHouseholdId(householdId: string): Promise<HomeProfileDto | null> {
    const profile = await this.prisma.homeProfile.findUnique({
      where: { householdId },
    });

    return profile ? this.mapToDto(profile) : null;
  }

  private mapToDto(profile: Prisma.HomeProfileGetPayload<object>): HomeProfileDto {
    return {
      id: profile.id,
      householdId: profile.householdId,
      propertyType: profile.propertyType,
      addressLine1: profile.addressLine1,
      addressLine2: profile.addressLine2,
      city: profile.city,
      state: profile.state,
      postalCode: profile.postalCode,
      country: profile.country,
      squareFeet: profile.squareFeet,
      lotSize: profile.lotSize ? Number(profile.lotSize) : null,
      yearBuilt: profile.yearBuilt,
      bedrooms: profile.bedrooms,
      bathrooms: profile.bathrooms ? Number(profile.bathrooms) : null,
      stories: profile.stories,
      garageSpaces: profile.garageSpaces,
      purchaseDate: profile.purchaseDate,
      purchasePrice: profile.purchasePrice ? Number(profile.purchasePrice) : null,
      currentValue: profile.currentValue ? Number(profile.currentValue) : null,
      notes: profile.notes,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    };
  }
}
