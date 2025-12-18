import { Injectable, Logger, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreatePetDto, UpdatePetDto, CreatePetVetRecordDto } from '../dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class PetService {
  private readonly logger = new Logger(PetService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Create a new pet for a household
   */
  async create(householdId: string, dto: CreatePetDto) {
    return this.prisma.pet.create({
      data: {
        householdId,
        ...dto,
        weight: dto.weight ? new Prisma.Decimal(dto.weight) : undefined,
      },
    });
  }

  /**
   * Get all pets for a household
   */
  async findAllByHousehold(householdId: string, includeInactive = false) {
    return this.prisma.pet.findMany({
      where: {
        householdId,
        ...(includeInactive ? {} : { isActive: true }),
      },
      include: {
        vetRecords: {
          orderBy: { visitDate: 'desc' },
          take: 3,
        },
      },
      orderBy: { name: 'asc' },
    });
  }

  /**
   * Get a single pet by ID
   */
  async findOne(id: string, householdId: string) {
    const pet = await this.prisma.pet.findUnique({
      where: { id },
      include: {
        vetRecords: {
          orderBy: { visitDate: 'desc' },
        },
        events: {
          where: {
            startDate: { gte: new Date() },
          },
          orderBy: { startDate: 'asc' },
          take: 5,
        },
      },
    });

    if (!pet) {
      throw new NotFoundException('Pet not found');
    }

    if (pet.householdId !== householdId) {
      throw new ForbiddenException('Access denied');
    }

    return pet;
  }

  /**
   * Update a pet
   */
  async update(id: string, householdId: string, dto: UpdatePetDto) {
    await this.findOne(id, householdId);

    return this.prisma.pet.update({
      where: { id },
      data: {
        ...dto,
        weight: dto.weight ? new Prisma.Decimal(dto.weight) : undefined,
      },
    });
  }

  /**
   * Delete (archive) a pet
   */
  async remove(id: string, householdId: string) {
    await this.findOne(id, householdId);

    return this.prisma.pet.update({
      where: { id },
      data: { isActive: false },
    });
  }

  /**
   * Add a vet record
   */
  async addVetRecord(petId: string, householdId: string, dto: CreatePetVetRecordDto) {
    await this.findOne(petId, householdId);

    const record = await this.prisma.petVetRecord.create({
      data: {
        petId,
        ...dto,
        weight: dto.weight ? new Prisma.Decimal(dto.weight) : undefined,
        cost: dto.cost ? new Prisma.Decimal(dto.cost) : undefined,
        prescriptions: dto.prescriptions as Prisma.InputJsonValue,
      },
    });

    // Update pet weight if provided
    if (dto.weight) {
      await this.prisma.pet.update({
        where: { id: petId },
        data: { weight: new Prisma.Decimal(dto.weight) },
      });
    }

    return record;
  }

  /**
   * Get vet records for a pet
   */
  async getVetRecords(petId: string, householdId: string) {
    await this.findOne(petId, householdId);

    return this.prisma.petVetRecord.findMany({
      where: { petId },
      orderBy: { visitDate: 'desc' },
    });
  }

  /**
   * Get pet passport (summary for pet sitters)
   */
  async getPetPassport(id: string, householdId: string) {
    const pet = await this.findOne(id, householdId);

    // Get latest vaccinations
    const recentVetRecords = await this.prisma.petVetRecord.findMany({
      where: {
        petId: id,
        vaccinationsGiven: { isEmpty: false },
      },
      orderBy: { visitDate: 'desc' },
      take: 10,
    });

    // Compile vaccination history
    const vaccinations: Record<string, { date: Date; nextDue?: Date }> = {};
    for (const record of recentVetRecords) {
      for (const vax of record.vaccinationsGiven) {
        if (!vaccinations[vax] || record.visitDate > vaccinations[vax].date) {
          vaccinations[vax] = {
            date: record.visitDate,
            nextDue: record.nextVaccinationDate || undefined,
          };
        }
      }
    }

    return {
      id: pet.id,
      name: pet.name,
      type: pet.type,
      breed: pet.breed,
      color: pet.color,
      size: pet.size,
      weight: pet.weight,
      birthday: pet.birthday,
      gender: pet.gender,
      microchipId: pet.microchipId,
      isSpayedNeutered: pet.isSpayedNeutered,
      photoUrls: pet.photoUrls,

      // Vet info
      vetClinic: {
        name: pet.vetClinicName,
        phone: pet.vetClinicPhone,
        address: pet.vetClinicAddress,
        email: pet.vetClinicEmail,
        primaryVet: pet.primaryVetName,
      },

      // Insurance
      insurance: pet.insuranceProvider ? {
        provider: pet.insuranceProvider,
        policyNumber: pet.insurancePolicyNum,
        expires: pet.insuranceExpires,
      } : null,

      // Health
      allergies: pet.allergies,
      medications: pet.medications,
      specialNeeds: pet.specialNeeds,
      vaccinations,

      // Diet
      diet: {
        foodBrand: pet.foodBrand,
        foodType: pet.foodType,
        feedingSchedule: pet.feedingSchedule,
        dietaryNotes: pet.dietaryNotes,
      },

      // Care
      careInstructions: pet.careInstructions,
      emergencyContact: pet.emergencyContact,
      behavioralNotes: pet.behavioralNotes,
    };
  }

  /**
   * Check for pet care alerts
   */
  async getCareAlerts(householdId: string) {
    const pets = await this.prisma.pet.findMany({
      where: {
        householdId,
        isActive: true,
      },
      include: {
        vetRecords: {
          orderBy: { visitDate: 'desc' },
          take: 1,
        },
      },
    });

    const alerts: Array<{
      petId: string;
      petName: string;
      type: string;
      message: string;
      severity: 'low' | 'medium' | 'high';
    }> = [];

    const now = new Date();

    for (const pet of pets) {
      // Check for upcoming vaccinations
      const latestRecord = pet.vetRecords[0];
      if (latestRecord?.nextVaccinationDate) {
        const daysUntil = (latestRecord.nextVaccinationDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntil <= 0) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'VACCINATION',
            message: `Vaccination overdue`,
            severity: 'high',
          });
        } else if (daysUntil <= 14) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'VACCINATION',
            message: `Vaccination due in ${Math.ceil(daysUntil)} days`,
            severity: 'medium',
          });
        }
      }

      // Check license expiration
      if (pet.licenseExpires) {
        const daysUntilExpiry = (pet.licenseExpires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilExpiry <= 0) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'LICENSE',
            message: `License expired`,
            severity: 'high',
          });
        } else if (daysUntilExpiry <= 30) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'LICENSE',
            message: `License expires in ${Math.ceil(daysUntilExpiry)} days`,
            severity: 'medium',
          });
        }
      }

      // Check insurance expiration
      if (pet.insuranceExpires) {
        const daysUntilExpiry = (pet.insuranceExpires.getTime() - now.getTime()) / (1000 * 60 * 60 * 24);
        if (daysUntilExpiry <= 0) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'INSURANCE',
            message: `Insurance expired`,
            severity: 'medium',
          });
        } else if (daysUntilExpiry <= 30) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'INSURANCE',
            message: `Insurance expires in ${Math.ceil(daysUntilExpiry)} days`,
            severity: 'low',
          });
        }
      }

      // Check for annual checkup (if no vet visit in past year)
      if (pet.vetRecords.length > 0) {
        const daysSinceLastVisit = (now.getTime() - latestRecord.visitDate.getTime()) / (1000 * 60 * 60 * 24);
        if (daysSinceLastVisit > 365) {
          alerts.push({
            petId: pet.id,
            petName: pet.name,
            type: 'CHECKUP',
            message: `Annual checkup overdue (last visit: ${latestRecord.visitDate.toLocaleDateString()})`,
            severity: 'medium',
          });
        }
      } else {
        alerts.push({
          petId: pet.id,
          petName: pet.name,
          type: 'CHECKUP',
          message: `No vet records on file`,
          severity: 'low',
        });
      }
    }

    return alerts.sort((a, b) => {
      const severityOrder = { high: 0, medium: 1, low: 2 };
      return severityOrder[a.severity] - severityOrder[b.severity];
    });
  }
}
