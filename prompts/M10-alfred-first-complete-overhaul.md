# M10: ALFRED-FIRST COMPLETE MOBILE OVERHAUL

## MASTER INSTRUCTIONS

This prompt contains 5 sequential phases. **CRITICAL RULES:**

1. **Run phases in order** - Phase 1, then Phase 2, etc.
2. **Do not proceed to the next phase until the current phase passes ALL tests**
3. **After each phase, report status and wait for confirmation before proceeding**
4. **If a phase fails, fix the issues before moving on**
5. **Test in iOS simulator after each phase - do NOT submit to TestFlight until all phases complete**

## PROJECT CONTEXT

- **Project:** Haven - AI-powered home management platform
- **Location:** `/Users/tomburke/Projects/Housing-Manager/`
- **Strategy:** Alfred-first, automation-first, zero-friction onboarding
- **Primary User Flow:** Signup → Immediate app access → Alfred captures data progressively

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 1: NEW SIGNUP FLOW & AUTO-DATA CAPTURE
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 1 OVERVIEW

Delete the old multi-step onboarding wizard. Replace with a streamlined signup that goes directly into the app while capturing data automatically in the background.

**New Philosophy:**
- Signup should take < 60 seconds
- User enters: email, password, name, address - that's it
- Everything else is auto-detected or progressively captured
- User lands in the app immediately with Alfred ready to help
- Old onboarding (scheduling calls, questionnaires) only for Haven tier and above

---

## PHASE 1.1: Delete Old Onboarding

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find and list all onboarding files
find app -name "*onboarding*" -type f
ls -la app/\(auth\)/onboarding/ 2>/dev/null || echo "No onboarding folder"

# Find onboarding context
cat src/contexts/onboarding-context.tsx 2>/dev/null | head -50 || echo "No onboarding context"
```

**Delete these files/folders if they exist:**
- `app/(auth)/onboarding/` entire folder
- `src/contexts/onboarding-context.tsx`
- Any references to onboarding wizard steps in other files

**Keep:**
- Basic auth screens (login, register)
- Address input component (we'll reuse it)

Remove all imports and references to deleted files from:
- `app/(auth)/_layout.tsx`
- `app/_layout.tsx`
- Any context providers

---

## PHASE 1.2: Update Database Schema

Update `apps/api/prisma/schema.prisma` - Add these fields to the Household model (merge with existing fields, don't duplicate):

```prisma
model Household {
  id                String   @id @default(cuid())
  name              String?
  
  // Property Address
  addressLine1      String
  addressLine2      String?
  city              String
  state             String
  zipCode           String
  latitude          Float?
  longitude         Float?
  
  // Property Details (from ATTOM)
  propertyType      String?
  yearBuilt         Int?
  squareFeet        Int?
  lotSizeAcres      Float?
  bedrooms          Int?
  bathrooms         Float?
  stories           Int?
  
  // Garage (from ATTOM)
  garageType        String?
  garageSpaces      Int?
  
  // Pool (from ATTOM)
  hasPool           Boolean  @default(false)
  poolType          String?
  
  // Heating & Cooling (from ATTOM)
  heatingType       String?
  heatingFuel       String?
  coolingType       String?
  
  // Water & Sewer (inferred + confirmed)
  waterSource       String?
  waterSourceConfirmed Boolean @default(false)
  waterProvider     String?
  waterAccountNum   String?
  sewerType         String?
  sewerTypeConfirmed Boolean @default(false)
  sewerProvider     String?
  
  // Utilities (ZIP lookup + Plaid confirmation)
  electricityProvider    String?
  electricityAccountNum  String?
  electricityConfirmed   Boolean @default(false)
  gasProvider            String?
  gasAccountNum          String?
  gasConfirmed           Boolean @default(false)
  
  // Heating Fuel Provider
  heatingFuelProvider    String?
  heatingFuelAccountNum  String?
  
  // Mortgage (from Plaid)
  mortgageProvider       String?
  mortgageMonthlyPayment Float?
  mortgageDetectedAt     DateTime?
  
  // Insurance (from Plaid)
  insuranceProvider      String?
  insurancePaymentAmount Float?
  insurancePaymentFreq   String?
  insuranceDetectedAt    DateTime?
  
  // Internet/Cable (from Plaid)
  internetProvider       String?
  cableProvider          String?
  
  // Home Health
  homeHealthScore        Int?     @default(85)
  
  // Data Capture Status
  attomDataFetched       Boolean  @default(false)
  plaidDataAnalyzed      Boolean  @default(false)
  initialSetupComplete   Boolean  @default(false)
  
  // Alfred Onboarding Progress
  alfredQuestionsAsked   Json?
  alfredDataGaps         Json?
  
  // Subscription
  subscriptionTier       String   @default("essentials")
  
  // Keep all existing relationships...
  createdAt       DateTime @default(now())
  updatedAt       DateTime @updatedAt
}
```

Also ensure these models exist (add if missing):

```prisma
model Zone {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  name          String
  type          String
  floor         String?
  description   String?
  icon          String?
  
  systems       System[]
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}

model System {
  id            String   @id @default(cuid())
  zoneId        String?
  zone          Zone?    @relation(fields: [zoneId], references: [id])
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  name          String
  type          String
  
  brand         String?
  model         String?
  serialNumber  String?
  installDate   DateTime?
  warrantyExpiry DateTime?
  estimatedAge  Int?
  
  maintenanceIntervalDays Int?
  lastServiceDate     DateTime?
  nextServiceDue      DateTime?
  
  preferredVendorId   String?
  notes         String?
  status        String   @default("good")
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
}

model Service {
  id            String   @id @default(cuid())
  householdId   String
  household     Household @relation(fields: [householdId], references: [id])
  
  name          String
  type          String
  
  vendorId      String?
  vendorName    String?
  vendorPhone   String?
  
  frequency     String?
  nextServiceDate DateTime?
  
  costPerService Float?
  monthlyCost    Float?
  
  contractStart  DateTime?
  contractEnd    DateTime?
  
  notes         String?
  
  createdAt     DateTime @default(now())
  updatedAt     DateTime @updatedAt
  
  @@unique([householdId, type])
}
```

Run migration:
```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/api
pnpm prisma migrate dev --name alfred-first-data-capture
pnpm prisma generate
```

---

## PHASE 1.3: Create Utility Provider Lookup

Create `apps/api/src/utilities/utility-providers.ts`:

```typescript
// Connecticut electricity providers by ZIP code
export const CT_ELECTRICITY_PROVIDERS: Record<string, string> = {
  // Eversource territory (majority of CT)
  '06001': 'Eversource', '06002': 'Eversource', '06010': 'Eversource',
  '06801': 'Eversource', // Bethel
  '06810': 'Eversource', // Danbury
  '06811': 'Eversource', // Danbury
  '06812': 'Eversource', // New Fairfield
  '06831': 'Eversource', // Greenwich
  '06840': 'Eversource', // New Canaan
  '06820': 'Eversource', // Darien
  '06830': 'Eversource', // Greenwich
  '06850': 'Eversource', // Norwalk
  '06851': 'Eversource', // Norwalk
  '06880': 'Eversource', // Westport
  '06897': 'Eversource', // Wilton
  '06470': 'Eversource', // Newtown
  '06482': 'Eversource', // Sandy Hook
  '06484': 'Eversource', // Shelton
  '06492': 'Eversource', // Wallingford
  
  // United Illuminating territory (Greater New Haven, Bridgeport)
  '06510': 'United Illuminating',
  '06511': 'United Illuminating',
  '06604': 'United Illuminating',
  '06605': 'United Illuminating',
  '06606': 'United Illuminating',
  '06607': 'United Illuminating',
};

// Default to Eversource for unlisted CT ZIP codes
export function getElectricityProvider(zipCode: string, state: string): string | null {
  if (state !== 'CT') return null;
  return CT_ELECTRICITY_PROVIDERS[zipCode] || 'Eversource';
}

// Connecticut gas providers
export const CT_GAS_PROVIDERS: Record<string, string> = {
  '06801': 'Eversource Gas',
  '06810': 'Eversource Gas',
  '06811': 'Eversource Gas',
  '06470': 'Eversource Gas',
};

export function getGasProvider(zipCode: string, state: string): string | null {
  if (state !== 'CT') return null;
  return CT_GAS_PROVIDERS[zipCode] || null;
}

// Infer septic vs sewer based on lot size and location
export function inferSewerType(lotSizeAcres: number | null, city: string, zipCode: string): { type: string; confidence: number } {
  // Urban areas almost always have municipal sewer
  const urbanZips = ['06510', '06511', '06604', '06605', '06606', '06607', '06901', '06902'];
  if (urbanZips.includes(zipCode)) {
    return { type: 'municipal', confidence: 0.95 };
  }
  
  // Lot size is the best indicator
  if (lotSizeAcres !== null) {
    if (lotSizeAcres >= 1.0) {
      return { type: 'septic', confidence: 0.85 };
    } else if (lotSizeAcres <= 0.25) {
      return { type: 'municipal', confidence: 0.80 };
    } else {
      return { type: 'unknown', confidence: 0.50 };
    }
  }
  
  return { type: 'unknown', confidence: 0.30 };
}

// Infer well vs municipal water (correlates strongly with sewer type)
export function inferWaterSource(lotSizeAcres: number | null, city: string, sewerType: string): { type: string; confidence: number } {
  // If we know sewer type, water source usually matches
  if (sewerType === 'septic') {
    return { type: 'well', confidence: 0.80 };
  } else if (sewerType === 'municipal') {
    return { type: 'municipal', confidence: 0.85 };
  }
  
  // Fallback to lot size
  if (lotSizeAcres !== null && lotSizeAcres >= 1.0) {
    return { type: 'well', confidence: 0.70 };
  }
  
  return { type: 'unknown', confidence: 0.30 };
}

// Get all utility providers for a location
export function getUtilityProviders(zipCode: string, city: string, state: string) {
  return {
    electricity: getElectricityProvider(zipCode, state),
    gas: getGasProvider(zipCode, state),
  };
}
```

---

## PHASE 1.4: Create Property Enrichment Service

Create `apps/api/src/property/property-enrichment.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { getUtilityProviders, inferSewerType, inferWaterSource } from '../utilities/utility-providers';

@Injectable()
export class PropertyEnrichmentService {
  constructor(private prisma: PrismaService) {}

  async enrichHouseholdFromAttom(householdId: string, attomData: any) {
    const property = attomData.property?.[0] || attomData;
    
    // Extract all available ATTOM data
    const enrichedData: any = {
      yearBuilt: property.summary?.yearBuilt || property.building?.summary?.yearBuilt,
      squareFeet: property.building?.size?.livingSize || property.building?.size?.universalSize,
      lotSizeAcres: property.lot?.lotSize1 ? property.lot.lotSize1 / 43560 : null,
      bedrooms: property.building?.rooms?.beds,
      bathrooms: property.building?.rooms?.bathsTotal,
      stories: property.building?.summary?.levels,
      propertyType: this.mapPropertyType(property.summary?.propClass),
      
      garageType: property.building?.parking?.garageType || null,
      garageSpaces: property.building?.parking?.garageSpaces || 0,
      
      hasPool: property.building?.features?.poolType !== null && 
               property.building?.features?.poolType !== 'None' &&
               property.building?.features?.poolType !== undefined,
      poolType: this.mapPoolType(property.building?.features?.poolType),
      
      heatingType: this.mapHeatingType(property.building?.construction?.heating),
      heatingFuel: this.mapHeatingFuel(property.building?.construction?.heatingFuel),
      coolingType: this.mapCoolingType(property.building?.construction?.airConditioning),
      
      attomDataFetched: true,
    };
    
    // Get utility providers based on location
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { zipCode: true, city: true, state: true },
    });
    
    if (household) {
      const utilities = getUtilityProviders(household.zipCode, household.city, household.state);
      enrichedData.electricityProvider = utilities.electricity;
      enrichedData.gasProvider = enrichedData.heatingFuel === 'natural-gas' ? utilities.gas : null;
      
      // Infer septic/sewer
      const sewerInference = inferSewerType(enrichedData.lotSizeAcres, household.city, household.zipCode);
      if (sewerInference.confidence >= 0.70) {
        enrichedData.sewerType = sewerInference.type;
      }
      
      // Infer well/municipal water
      const waterInference = inferWaterSource(enrichedData.lotSizeAcres, household.city, enrichedData.sewerType);
      if (waterInference.confidence >= 0.70) {
        enrichedData.waterSource = waterInference.type;
      }
    }
    
    // Update household with enriched data
    await this.prisma.household.update({
      where: { id: householdId },
      data: enrichedData,
    });
    
    // Auto-generate zones and systems
    await this.autoGenerateZonesAndSystems(householdId, enrichedData);
    
    // Identify data gaps for Alfred to ask about
    const dataGaps = this.identifyDataGaps(enrichedData);
    await this.prisma.household.update({
      where: { id: householdId },
      data: { alfredDataGaps: dataGaps },
    });
    
    return enrichedData;
  }
  
  async autoGenerateZonesAndSystems(householdId: string, propertyData: any) {
    // Check if zones already exist
    const existingZones = await this.prisma.zone.count({ where: { householdId } });
    if (existingZones > 0) {
      console.log('Zones already exist, skipping auto-generation');
      return;
    }
    
    const zones: any[] = [];
    
    // Always create these zones
    zones.push({ name: 'Kitchen', type: 'kitchen', floor: '1st Floor', icon: 'utensils' });
    zones.push({ name: 'Living Room', type: 'living', floor: '1st Floor', icon: 'sofa' });
    zones.push({ name: 'Exterior', type: 'exterior', floor: null, icon: 'home' });
    zones.push({ name: 'Basement', type: 'basement', floor: 'Basement', icon: 'archive' });
    
    // Bedrooms based on count
    const bedrooms = propertyData.bedrooms || 3;
    zones.push({ name: 'Primary Bedroom', type: 'bedroom', floor: '2nd Floor', icon: 'bed' });
    for (let i = 2; i <= Math.min(bedrooms, 6); i++) {
      zones.push({ name: `Bedroom ${i}`, type: 'bedroom', floor: '2nd Floor', icon: 'bed' });
    }
    
    // Bathrooms based on count
    const bathrooms = Math.floor(propertyData.bathrooms || 2);
    zones.push({ name: 'Primary Bathroom', type: 'bathroom', floor: '2nd Floor', icon: 'bath' });
    for (let i = 2; i <= Math.min(bathrooms, 5); i++) {
      const floor = i <= 2 ? '1st Floor' : '2nd Floor';
      zones.push({ name: `Bathroom ${i}`, type: 'bathroom', floor, icon: 'bath' });
    }
    
    // Garage if present
    if (propertyData.garageSpaces > 0) {
      zones.push({ 
        name: `${propertyData.garageSpaces}-Car Garage`, 
        type: 'garage', 
        floor: '1st Floor', 
        icon: 'car' 
      });
    }
    
    // Create zones in database
    const createdZones: Record<string, string> = {};
    for (const zone of zones) {
      const created = await this.prisma.zone.create({
        data: { householdId, ...zone },
      });
      createdZones[zone.type] = created.id;
    }
    
    // Auto-generate systems based on property data
    const basementZoneId = createdZones['basement'];
    const exteriorZoneId = createdZones['exterior'];
    const yearBuilt = propertyData.yearBuilt || 2000;
    const systemAge = new Date().getFullYear() - yearBuilt;
    
    const systems: any[] = [];
    
    // Heating system
    if (propertyData.heatingType || propertyData.heatingFuel) {
      systems.push({
        householdId,
        zoneId: basementZoneId,
        name: this.getHeatingSystemName(propertyData.heatingType, propertyData.heatingFuel),
        type: 'heating',
        estimatedAge: Math.min(systemAge, 25),
        maintenanceIntervalDays: 365,
        status: systemAge > 15 ? 'needs-attention' : 'good',
      });
      
      // Oil tank if oil heat
      if (propertyData.heatingFuel === 'oil') {
        systems.push({
          householdId,
          zoneId: basementZoneId,
          name: 'Oil Tank',
          type: 'fuel-storage',
          estimatedAge: Math.min(systemAge, 30),
          notes: 'Typical capacity: 275 gallons',
          status: systemAge > 20 ? 'needs-attention' : 'good',
        });
      }
    }
    
    // Cooling system
    if (propertyData.coolingType === 'central') {
      systems.push({
        householdId,
        zoneId: basementZoneId,
        name: 'Central Air Conditioning',
        type: 'cooling',
        estimatedAge: Math.min(systemAge, 20),
        maintenanceIntervalDays: 365,
        status: systemAge > 12 ? 'needs-attention' : 'good',
      });
    }
    
    // Water heater (every home has one)
    systems.push({
      householdId,
      zoneId: basementZoneId,
      name: 'Water Heater',
      type: 'plumbing',
      estimatedAge: Math.min(systemAge, 12),
      maintenanceIntervalDays: 365,
      status: systemAge > 10 ? 'needs-attention' : 'good',
    });
    
    // Well pump if well water
    if (propertyData.waterSource === 'well') {
      systems.push({
        householdId,
        zoneId: basementZoneId,
        name: 'Well Pump',
        type: 'plumbing',
        estimatedAge: Math.min(systemAge, 15),
        status: 'good',
      });
    }
    
    // Septic system if septic
    if (propertyData.sewerType === 'septic') {
      systems.push({
        householdId,
        zoneId: exteriorZoneId,
        name: 'Septic System',
        type: 'plumbing',
        maintenanceIntervalDays: 1095, // 3 years
        notes: 'Pump every 3-5 years',
        status: 'good',
      });
    }
    
    // Pool if present
    if (propertyData.hasPool) {
      systems.push({
        householdId,
        zoneId: exteriorZoneId,
        name: `${propertyData.poolType === 'inground' ? 'Inground' : 'Above Ground'} Pool`,
        type: 'pool',
        maintenanceIntervalDays: 7,
        status: 'good',
      });
    }
    
    // Create systems in database
    for (const system of systems) {
      await this.prisma.system.create({ data: system });
    }
    
    // Generate initial maintenance tasks
    await this.generateMaintenanceTasks(householdId, propertyData);
  }
  
  async generateMaintenanceTasks(householdId: string, propertyData: any) {
    // Check if tasks already exist
    const existingTasks = await this.prisma.maintenanceTask.count({ where: { householdId } });
    if (existingTasks > 0) {
      console.log('Maintenance tasks already exist, skipping auto-generation');
      return;
    }
    
    const now = new Date();
    const tasks: any[] = [];
    
    // HVAC service
    if (propertyData.heatingType || propertyData.coolingType) {
      tasks.push({
        householdId,
        name: 'HVAC Professional Service',
        description: 'Annual professional service for heating and cooling systems',
        frequency: 'Annually',
        intervalDays: 365,
        nextDue: this.getNextSeasonalDate('fall'),
        status: 'upcoming',
        estimatedCost: 150,
        intervalExplanation: 'Professional HVAC service twice yearly (spring for AC, fall for heating) ensures efficient operation and catches problems early.',
        checklistSteps: JSON.stringify([
          { id: '1', order: 1, title: 'Schedule service appointment', alfredCanHandle: true, completed: false },
          { id: '2', order: 2, title: 'Confirm technician arrival time', alfredCanHandle: true, completed: false },
          { id: '3', order: 3, title: 'Be present for service visit', alfredCanHandle: false, completed: false },
          { id: '4', order: 4, title: 'Review service report', alfredCanHandle: false, completed: false },
          { id: '5', order: 5, title: 'Address any recommended repairs', alfredCanHandle: true, completed: false },
        ]),
      });
    }
    
    // Oil delivery (if oil heat)
    if (propertyData.heatingFuel === 'oil') {
      tasks.push({
        householdId,
        name: 'Schedule Oil Delivery',
        description: 'Monitor oil levels and schedule delivery before running low',
        frequency: 'As needed',
        intervalDays: 60,
        nextDue: this.getNextSeasonalDate('fall'),
        status: 'upcoming',
        estimatedCost: 500,
        intervalExplanation: 'Oil tanks should be refilled when below 1/4 full to prevent sludge buildup and ensure consistent heating.',
        checklistSteps: JSON.stringify([
          { id: '1', order: 1, title: 'Check current oil tank level', alfredCanHandle: false, completed: false },
          { id: '2', order: 2, title: 'Compare prices from providers', alfredCanHandle: true, completed: false },
          { id: '3', order: 3, title: 'Schedule delivery date', alfredCanHandle: true, completed: false },
          { id: '4', order: 4, title: 'Confirm delivery appointment', alfredCanHandle: true, completed: false },
        ]),
      });
    }
    
    // Septic pumping (if septic)
    if (propertyData.sewerType === 'septic') {
      tasks.push({
        householdId,
        name: 'Septic Tank Pumping',
        description: 'Regular septic pumping prevents backups and system failure',
        frequency: 'Every 3 years',
        intervalDays: 1095,
        nextDue: new Date(now.getFullYear() + 1, 5, 1),
        status: 'upcoming',
        estimatedCost: 350,
        intervalExplanation: 'Septic tanks should be pumped every 3-5 years depending on household size. Neglecting this can lead to backups and expensive repairs.',
        checklistSteps: JSON.stringify([
          { id: '1', order: 1, title: 'Locate septic tank access', alfredCanHandle: false, completed: false },
          { id: '2', order: 2, title: 'Get quotes from septic services', alfredCanHandle: true, completed: false },
          { id: '3', order: 3, title: 'Schedule pumping appointment', alfredCanHandle: true, completed: false },
          { id: '4', order: 4, title: 'Be present for service', alfredCanHandle: false, completed: false },
          { id: '5', order: 5, title: 'Review inspection findings', alfredCanHandle: false, completed: false },
        ]),
      });
    }
    
    // Pool opening/closing (if pool)
    if (propertyData.hasPool) {
      tasks.push({
        householdId,
        name: 'Pool Opening',
        description: 'Spring pool opening and startup',
        frequency: 'Annually',
        intervalDays: 365,
        nextDue: this.getNextSeasonalDate('spring'),
        status: 'upcoming',
        estimatedCost: 300,
        intervalExplanation: 'Pool opening in spring includes removing cover, cleaning, balancing chemicals, and starting equipment.',
        checklistSteps: JSON.stringify([
          { id: '1', order: 1, title: 'Schedule pool opening service', alfredCanHandle: true, completed: false },
          { id: '2', order: 2, title: 'Remove and store pool cover', alfredCanHandle: false, completed: false },
          { id: '3', order: 3, title: 'Inspect and start equipment', alfredCanHandle: false, completed: false },
          { id: '4', order: 4, title: 'Balance water chemistry', alfredCanHandle: false, completed: false },
        ]),
      });
    }
    
    // Gutter cleaning (everyone)
    tasks.push({
      householdId,
      name: 'Clean Gutters',
      description: 'Remove debris from gutters and downspouts',
      frequency: 'Twice yearly',
      intervalDays: 180,
      nextDue: this.getNextSeasonalDate('fall'),
      status: 'upcoming',
      estimatedCost: 150,
      intervalExplanation: 'Gutters should be cleaned twice yearly (spring and fall) to prevent water damage and foundation issues.',
      checklistSteps: JSON.stringify([
        { id: '1', order: 1, title: 'Inspect gutters for debris', alfredCanHandle: false, completed: false },
        { id: '2', order: 2, title: 'Get quotes from gutter services', alfredCanHandle: true, completed: false },
        { id: '3', order: 3, title: 'Schedule cleaning appointment', alfredCanHandle: true, completed: false },
        { id: '4', order: 4, title: 'Verify downspouts are clear', alfredCanHandle: false, completed: false },
      ]),
    });
    
    // Smoke detector testing (everyone)
    tasks.push({
      householdId,
      name: 'Test Smoke & CO Detectors',
      description: 'Test all smoke and carbon monoxide detectors',
      frequency: 'Monthly',
      intervalDays: 30,
      nextDue: new Date(now.getFullYear(), now.getMonth() + 1, 1),
      status: 'upcoming',
      estimatedCost: 0,
      intervalExplanation: 'Smoke and CO detectors should be tested monthly and batteries replaced annually. These devices save lives.',
      checklistSteps: JSON.stringify([
        { id: '1', order: 1, title: 'Test all smoke detectors', alfredCanHandle: false, completed: false },
        { id: '2', order: 2, title: 'Test all CO detectors', alfredCanHandle: false, completed: false },
        { id: '3', order: 3, title: 'Replace batteries if needed', alfredCanHandle: false, completed: false },
        { id: '4', order: 4, title: 'Check expiration dates', alfredCanHandle: false, completed: false },
      ]),
    });
    
    // Create tasks in database
    for (const task of tasks) {
      await this.prisma.maintenanceTask.create({ data: task });
    }
  }
  
  identifyDataGaps(propertyData: any): string[] {
    const gaps: string[] = [];
    
    if (!propertyData.sewerType || propertyData.sewerType === 'unknown') {
      gaps.push('sewer_type');
    }
    if (!propertyData.waterSource || propertyData.waterSource === 'unknown') {
      gaps.push('water_source');
    }
    if (propertyData.heatingFuel === 'oil' && !propertyData.heatingFuelProvider) {
      gaps.push('oil_provider');
    }
    if (propertyData.heatingFuel === 'propane' && !propertyData.heatingFuelProvider) {
      gaps.push('propane_provider');
    }
    if (!propertyData.yearBuilt) {
      gaps.push('year_built');
    }
    
    gaps.push('plaid_analysis_pending');
    
    return gaps;
  }
  
  // Helper methods
  private mapPropertyType(propClass: string): string {
    const mapping: Record<string, string> = {
      'Single Family Residence': 'single-family',
      'Condominium': 'condo',
      'Townhouse': 'townhouse',
      'Multi-Family': 'multi-family',
    };
    return mapping[propClass] || 'single-family';
  }
  
  private mapHeatingType(heating: string): string | null {
    if (!heating) return null;
    const h = heating.toLowerCase();
    if (h.includes('forced air')) return 'forced-air';
    if (h.includes('hot water') || h.includes('hydronic')) return 'hot-water';
    if (h.includes('steam')) return 'steam';
    if (h.includes('radiant')) return 'radiant';
    if (h.includes('heat pump')) return 'heat-pump';
    if (h.includes('electric')) return 'electric';
    return 'other';
  }
  
  private mapHeatingFuel(fuel: string): string | null {
    if (!fuel) return null;
    const f = fuel.toLowerCase();
    if (f.includes('oil')) return 'oil';
    if (f.includes('gas') || f.includes('natural')) return 'natural-gas';
    if (f.includes('propane') || f.includes('lp')) return 'propane';
    if (f.includes('electric')) return 'electric';
    return 'other';
  }
  
  private mapCoolingType(cooling: string): string {
    if (!cooling) return 'none';
    const c = cooling.toLowerCase();
    if (c.includes('central')) return 'central';
    if (c.includes('window') || c.includes('wall')) return 'window';
    if (c.includes('none') || c === 'no') return 'none';
    return 'other';
  }
  
  private mapPoolType(poolType: string): string | null {
    if (!poolType || poolType === 'None') return null;
    const p = poolType.toLowerCase();
    if (p.includes('in ground') || p.includes('inground')) return 'inground';
    if (p.includes('above')) return 'above-ground';
    return 'other';
  }
  
  private getHeatingSystemName(heatingType: string, fuel: string): string {
    const fuelNames: Record<string, string> = {
      'oil': 'Oil',
      'natural-gas': 'Gas',
      'propane': 'Propane',
      'electric': 'Electric',
    };
    const typeNames: Record<string, string> = {
      'forced-air': 'Furnace',
      'hot-water': 'Boiler',
      'steam': 'Steam Boiler',
      'radiant': 'Radiant Heat',
      'heat-pump': 'Heat Pump',
      'electric': 'Electric Heat',
    };
    
    const fuelName = fuelNames[fuel] || '';
    const typeName = typeNames[heatingType] || 'Heating System';
    
    return `${fuelName} ${typeName}`.trim() || 'Heating System';
  }
  
  private getNextSeasonalDate(season: 'spring' | 'summer' | 'fall' | 'winter'): Date {
    const now = new Date();
    const year = now.getFullYear();
    
    const seasons = {
      spring: { month: 3, day: 15 },
      summer: { month: 5, day: 1 },
      fall: { month: 9, day: 15 },
      winter: { month: 11, day: 1 },
    };
    
    const target = seasons[season];
    let targetDate = new Date(year, target.month, target.day);
    
    if (targetDate < now) {
      targetDate = new Date(year + 1, target.month, target.day);
    }
    
    return targetDate;
  }
}
```

Create the module file `apps/api/src/property/property.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { PropertyEnrichmentService } from './property-enrichment.service';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  providers: [PropertyEnrichmentService],
  exports: [PropertyEnrichmentService],
})
export class PropertyModule {}
```

---

## PHASE 1.5: Create Simplified Registration Endpoint

Update or create the auth registration to include auto-enrichment.

In `apps/api/src/auth/auth.controller.ts`, add:

```typescript
@Post('register-simple')
async registerSimple(@Body() body: {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  address: {
    addressLine1: string;
    city: string;
    state: string;
    zipCode: string;
  };
}) {
  // 1. Create Firebase user
  const firebaseUser = await this.firebaseAdmin.auth().createUser({
    email: body.email,
    password: body.password,
    displayName: `${body.firstName} ${body.lastName}`,
  });
  
  // 2. Create household
  const household = await this.prisma.household.create({
    data: {
      name: `The ${body.lastName} Family`,
      addressLine1: body.address.addressLine1,
      city: body.address.city,
      state: body.address.state,
      zipCode: body.address.zipCode,
      subscriptionTier: 'essentials',
    },
  });
  
  // 3. Create user record
  const user = await this.prisma.user.create({
    data: {
      firebaseUid: firebaseUser.uid,
      email: body.email,
      firstName: body.firstName,
      lastName: body.lastName,
      householdId: household.id,
      role: 'owner',
    },
  });
  
  // 4. Create family member
  await this.prisma.familyMember.create({
    data: {
      householdId: household.id,
      firstName: body.firstName,
      lastName: body.lastName,
      email: body.email,
      role: 'owner',
      isAdult: true,
    },
  });
  
  // 5. Trigger ATTOM enrichment in background (async)
  this.enrichmentService.enrichHouseholdFromAttom(household.id, {}).catch(err => {
    console.error('ATTOM enrichment failed:', err);
  });
  
  return {
    user: {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
    },
    household: {
      id: household.id,
      name: household.name,
      address: body.address,
    },
    message: 'Account created successfully',
  };
}
```

---

## PHASE 1.6: Update Mobile Registration Screen

Create new simplified registration at `apps/mobile/app/(auth)/register.tsx`:

```tsx
import React, { useState } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  ActivityIndicator,
  StyleSheet,
} from 'react-native';
import { useRouter } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { colors } from '@/theme/colors';
import { useAuth } from '@/contexts/auth-context';

export default function RegisterScreen() {
  const router = useRouter();
  const { register } = useAuth();
  
  const [step, setStep] = useState<'info' | 'address'>('info');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // Form state
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [addressLine1, setAddressLine1] = useState('');
  const [city, setCity] = useState('');
  const [state, setState] = useState('');
  const [zipCode, setZipCode] = useState('');
  
  const handleContinue = () => {
    if (!firstName || !lastName || !email || !password) {
      setError('Please fill in all fields');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }
    setError(null);
    setStep('address');
  };
  
  const handleRegister = async () => {
    if (!addressLine1 || !city || !state || !zipCode) {
      setError('Please fill in your complete address');
      return;
    }
    
    setLoading(true);
    setError(null);
    
    try {
      await register({
        email,
        password,
        firstName,
        lastName,
        address: { addressLine1, city, state, zipCode },
      });
      
      // Go directly to main app - Alfred will greet them
      router.replace('/(tabs)');
    } catch (err: any) {
      setError(err.message || 'Registration failed');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* Header */}
        <View style={styles.header}>
          <Text style={styles.title}>
            {step === 'info' ? 'Create Account' : 'Your Home'}
          </Text>
          <Text style={styles.subtitle}>
            {step === 'info'
              ? "Let's get you set up in 60 seconds"
              : "Where should Alfred manage?"
            }
          </Text>
        </View>
        
        {error && (
          <View style={styles.errorBox}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}
        
        {step === 'info' ? (
          <>
            {/* Name Row */}
            <View style={styles.row}>
              <View style={styles.halfField}>
                <Text style={styles.label}>First Name</Text>
                <TextInput
                  style={styles.input}
                  placeholder="John"
                  placeholderTextColor={colors.text.tertiary}
                  value={firstName}
                  onChangeText={setFirstName}
                  autoCapitalize="words"
                />
              </View>
              <View style={styles.halfField}>
                <Text style={styles.label}>Last Name</Text>
                <TextInput
                  style={styles.input}
                  placeholder="Smith"
                  placeholderTextColor={colors.text.tertiary}
                  value={lastName}
                  onChangeText={setLastName}
                  autoCapitalize="words"
                />
              </View>
            </View>
            
            {/* Email */}
            <View style={styles.field}>
              <Text style={styles.label}>Email</Text>
              <TextInput
                style={styles.input}
                placeholder="john@example.com"
                placeholderTextColor={colors.text.tertiary}
                value={email}
                onChangeText={setEmail}
                autoCapitalize="none"
                keyboardType="email-address"
              />
            </View>
            
            {/* Password */}
            <View style={styles.field}>
              <Text style={styles.label}>Password</Text>
              <TextInput
                style={styles.input}
                placeholder="At least 6 characters"
                placeholderTextColor={colors.text.tertiary}
                value={password}
                onChangeText={setPassword}
                secureTextEntry
              />
            </View>
            
            {/* Continue Button */}
            <TouchableOpacity style={styles.primaryButton} onPress={handleContinue}>
              <Text style={styles.primaryButtonText}>Continue</Text>
            </TouchableOpacity>
          </>
        ) : (
          <>
            {/* Address */}
            <View style={styles.field}>
              <Text style={styles.label}>Street Address</Text>
              <TextInput
                style={styles.input}
                placeholder="123 Main Street"
                placeholderTextColor={colors.text.tertiary}
                value={addressLine1}
                onChangeText={setAddressLine1}
              />
            </View>
            
            {/* City, State, ZIP Row */}
            <View style={styles.field}>
              <Text style={styles.label}>City</Text>
              <TextInput
                style={styles.input}
                placeholder="Bethel"
                placeholderTextColor={colors.text.tertiary}
                value={city}
                onChangeText={setCity}
              />
            </View>
            
            <View style={styles.row}>
              <View style={styles.halfField}>
                <Text style={styles.label}>State</Text>
                <TextInput
                  style={styles.input}
                  placeholder="CT"
                  placeholderTextColor={colors.text.tertiary}
                  value={state}
                  onChangeText={setState}
                  autoCapitalize="characters"
                  maxLength={2}
                />
              </View>
              <View style={styles.halfField}>
                <Text style={styles.label}>ZIP Code</Text>
                <TextInput
                  style={styles.input}
                  placeholder="06801"
                  placeholderTextColor={colors.text.tertiary}
                  value={zipCode}
                  onChangeText={setZipCode}
                  keyboardType="number-pad"
                  maxLength={5}
                />
              </View>
            </View>
            
            {/* What Happens Next */}
            <View style={styles.infoCard}>
              <Text style={styles.infoTitle}>What happens next?</Text>
              <Text style={styles.infoText}>
                Alfred will automatically find information about your home and set up your maintenance schedule. You'll be ready to go in seconds!
              </Text>
            </View>
            
            {/* Register Button */}
            <TouchableOpacity
              style={[styles.primaryButton, styles.champagneButton, loading && styles.buttonDisabled]}
              onPress={handleRegister}
              disabled={loading}
            >
              {loading ? (
                <ActivityIndicator color="#FFFFFF" />
              ) : (
                <Text style={styles.primaryButtonText}>Create My Account</Text>
              )}
            </TouchableOpacity>
            
            {/* Back Button */}
            <TouchableOpacity style={styles.backButton} onPress={() => setStep('info')}>
              <Text style={styles.backButtonText}>← Back</Text>
            </TouchableOpacity>
          </>
        )}
        
        {/* Login Link */}
        <View style={styles.loginLink}>
          <Text style={styles.loginLinkText}>Already have an account? </Text>
          <TouchableOpacity onPress={() => router.push('/(auth)/login')}>
            <Text style={styles.loginLinkButton}>Sign In</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  scrollContent: {
    flexGrow: 1,
    padding: 24,
  },
  header: {
    marginTop: 60,
    marginBottom: 32,
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
    color: colors.text.primary,
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: colors.text.secondary,
  },
  errorBox: {
    backgroundColor: '#FEE2E2',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
  },
  errorText: {
    color: '#DC2626',
  },
  row: {
    flexDirection: 'row',
    gap: 12,
    marginBottom: 16,
  },
  halfField: {
    flex: 1,
  },
  field: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '500',
    color: colors.text.secondary,
    marginBottom: 6,
  },
  input: {
    backgroundColor: colors.background.secondary,
    borderRadius: 12,
    padding: 16,
    fontSize: 16,
    color: colors.text.primary,
  },
  primaryButton: {
    backgroundColor: colors.navy[900],
    borderRadius: 12,
    padding: 16,
    alignItems: 'center',
    marginTop: 8,
  },
  champagneButton: {
    backgroundColor: colors.champagne[500],
  },
  buttonDisabled: {
    opacity: 0.7,
  },
  primaryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  backButton: {
    marginTop: 16,
    alignItems: 'center',
  },
  backButtonText: {
    color: colors.text.secondary,
  },
  infoCard: {
    backgroundColor: colors.champagne[100],
    borderRadius: 12,
    padding: 16,
    marginTop: 8,
    marginBottom: 16,
  },
  infoTitle: {
    fontSize: 14,
    fontWeight: '600',
    color: colors.navy[900],
    marginBottom: 8,
  },
  infoText: {
    color: colors.navy[700],
    fontSize: 13,
    lineHeight: 20,
  },
  loginLink: {
    flexDirection: 'row',
    justifyContent: 'center',
    marginTop: 32,
  },
  loginLinkText: {
    color: colors.text.secondary,
  },
  loginLinkButton: {
    color: colors.champagne[600],
    fontWeight: '600',
  },
});
```

---

## PHASE 1.7: Update Auth Context for New Registration

Update `apps/mobile/src/contexts/auth-context.tsx` to support the new registration flow:

Add a register function that calls the new endpoint:

```typescript
const register = async (data: {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  address: {
    addressLine1: string;
    city: string;
    state: string;
    zipCode: string;
  };
}) => {
  try {
    // Call the simplified registration endpoint
    const response = await api.post('/auth/register-simple', data);
    
    // Sign in with Firebase
    const userCredential = await signInWithEmailAndPassword(
      auth,
      data.email,
      data.password
    );
    
    // Get token and set auth state
    const token = await userCredential.user.getIdToken();
    await SecureStore.setItemAsync('authToken', token);
    
    setUser(response.data.user);
    setHouseholdId(response.data.household.id);
    setIsAuthenticated(true);
    
    return response.data;
  } catch (error: any) {
    console.error('Registration error:', error);
    throw new Error(error.response?.data?.message || 'Registration failed');
  }
};
```

Make sure to export `register` in the context value.

---

## PHASE 1.8: Deploy and Test Phase 1

```bash
# Deploy API changes
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

# Wait for deployment to complete
sleep 60

# Test in simulator
cd apps/mobile
npx expo start --clear --ios
```

### PHASE 1 TEST CHECKLIST

Test each item and mark as PASS or FAIL:

1. [ ] Old onboarding screens are removed
2. [ ] New 2-step registration screen works
3. [ ] Can enter name, email, password on step 1
4. [ ] Can enter address on step 2
5. [ ] Account creates successfully
6. [ ] User goes directly to main app (tabs), NOT old onboarding
7. [ ] Household is created with correct address
8. [ ] Zones are auto-generated (Kitchen, Living Room, Bedrooms, etc.)
9. [ ] Systems are auto-generated based on property data
10. [ ] Maintenance tasks are auto-created
11. [ ] No crashes or red error screens

**PHASE 1 STATUS:** [ PASS / FAIL ]

If FAIL, fix the issues before proceeding to Phase 2.

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 2: PLAID TRANSACTION INTELLIGENCE  
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 2 OVERVIEW

After user connects their bank via Plaid, analyze transactions to automatically detect:
- Mortgage provider and payment amount
- Insurance provider and payment
- Utility providers (confirming ZIP lookup)
- Oil/propane deliveries
- Service providers (landscaping, pool, cleaning)

---

## PHASE 2.1: Create Transaction Analyzer Service

Create `apps/api/src/plaid/transaction-analyzer.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface AnalyzedTransaction {
  type: 'mortgage' | 'insurance' | 'electricity' | 'gas' | 'water' | 'sewer' | 
        'oil' | 'propane' | 'internet' | 'cable' | 'landscaping' | 'pool' | 
        'pest-control' | 'cleaning' | 'security' | 'other';
  provider: string;
  amount: number;
  frequency: 'monthly' | 'quarterly' | 'annually' | 'one-time';
  confidence: number;
  transactionIds: string[];
}

@Injectable()
export class TransactionAnalyzerService {
  constructor(private prisma: PrismaService) {}

  // Merchant name patterns for categorization
  private patterns: Record<string, RegExp[]> = {
    mortgage: [
      /quicken|rocket\s*mortgage/i,
      /wells\s*fargo.*mtg|wells\s*fargo.*mortgage/i,
      /chase.*mortgage|jpmorgan.*mtg/i,
      /bank\s*of\s*america.*mtg|boa.*mortgage/i,
      /us\s*bank.*mortgage/i,
      /pnc.*mortgage/i,
      /citizens.*mortgage/i,
      /mr\s*cooper/i,
      /pennymac/i,
      /freedom\s*mortgage/i,
      /loancare/i,
      /nationstar/i,
      /caliber\s*home/i,
      /newrez/i,
    ],
    insurance: [
      /state\s*farm/i,
      /allstate/i,
      /geico/i,
      /progressive/i,
      /liberty\s*mutual/i,
      /travelers/i,
      /nationwide/i,
      /farmers\s*ins/i,
      /usaa/i,
      /amica/i,
      /hartford/i,
      /chubb/i,
    ],
    electricity: [
      /eversource/i,
      /united\s*illuminating|^ui\s/i,
      /con\s*edison|coned/i,
      /pseg|pse&g/i,
      /national\s*grid/i,
      /duke\s*energy/i,
    ],
    gas: [
      /eversource.*gas/i,
      /southern\s*ct\s*gas/i,
      /cng|connecticut\s*natural/i,
      /yankee\s*gas/i,
    ],
    water: [
      /aquarion/i,
      /american\s*water/i,
      /ct\s*water|connecticut\s*water/i,
    ],
    oil: [
      /oil|fuel|petroleum|energy.*oil/i,
      /petro/i,
      /dead\s*river/i,
      /sprague/i,
      /mirabito/i,
    ],
    propane: [
      /propane/i,
      /amerigas/i,
      /ferrellgas/i,
      /suburban\s*propane/i,
    ],
    internet: [
      /comcast|xfinity/i,
      /verizon.*fios|fios/i,
      /at&t|att.*internet/i,
      /spectrum|charter/i,
      /optimum|altice/i,
    ],
    landscaping: [
      /landscap/i,
      /lawn\s*(care|service|maint)/i,
      /trugreen/i,
    ],
    pool: [
      /pool\s*(service|supply|care|cleaning)/i,
      /leslie.*pool/i,
    ],
    'pest-control': [
      /orkin/i,
      /terminix/i,
      /pest\s*(control|service)/i,
    ],
    cleaning: [
      /maid|merry\s*maids|molly\s*maid/i,
      /cleaning\s*service/i,
    ],
    security: [
      /adt/i,
      /vivint/i,
      /simplisafe/i,
      /ring.*protect/i,
    ],
  };

  async analyzeTransactions(householdId: string, transactions: any[]): Promise<AnalyzedTransaction[]> {
    const analyzed: AnalyzedTransaction[] = [];
    const groupedByMerchant: Record<string, any[]> = {};
    
    // Group transactions by merchant
    for (const tx of transactions) {
      const merchantKey = this.normalizeMerchant(tx.merchant_name || tx.name);
      if (!groupedByMerchant[merchantKey]) {
        groupedByMerchant[merchantKey] = [];
      }
      groupedByMerchant[merchantKey].push(tx);
    }
    
    // Analyze each merchant group
    for (const [merchant, txs] of Object.entries(groupedByMerchant)) {
      const type = this.categorizeTransaction(merchant, txs[0]);
      if (type === 'other') continue;
      
      const amounts = txs.map(t => Math.abs(t.amount));
      const avgAmount = amounts.reduce((a, b) => a + b, 0) / amounts.length;
      const frequency = this.detectFrequency(txs);
      
      analyzed.push({
        type,
        provider: this.cleanMerchantName(merchant),
        amount: Math.round(avgAmount * 100) / 100,
        frequency,
        confidence: this.calculateConfidence(type, txs, avgAmount),
        transactionIds: txs.map(t => t.transaction_id),
      });
    }
    
    return analyzed;
  }

  async applyAnalysisToHousehold(householdId: string, analysis: AnalyzedTransaction[]) {
    const updates: any = {
      plaidDataAnalyzed: true,
    };
    
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredDataGaps: true },
    });
    
    let dataGaps = (household?.alfredDataGaps as string[]) || [];
    dataGaps = dataGaps.filter(g => g !== 'plaid_analysis_pending');
    
    for (const item of analysis) {
      if (item.confidence < 0.6) continue;
      
      switch (item.type) {
        case 'mortgage':
          updates.mortgageProvider = item.provider;
          updates.mortgageMonthlyPayment = item.amount;
          updates.mortgageDetectedAt = new Date();
          break;
          
        case 'insurance':
          updates.insuranceProvider = item.provider;
          updates.insurancePaymentAmount = item.amount;
          updates.insurancePaymentFreq = item.frequency;
          updates.insuranceDetectedAt = new Date();
          break;
          
        case 'electricity':
          updates.electricityProvider = item.provider;
          updates.electricityConfirmed = true;
          break;
          
        case 'gas':
          updates.gasProvider = item.provider;
          updates.gasConfirmed = true;
          break;
          
        case 'water':
          updates.waterProvider = item.provider;
          updates.waterSource = 'municipal';
          updates.waterSourceConfirmed = true;
          dataGaps = dataGaps.filter(g => g !== 'water_source');
          break;
          
        case 'oil':
          updates.heatingFuelProvider = item.provider;
          dataGaps = dataGaps.filter(g => g !== 'oil_provider');
          break;
          
        case 'propane':
          updates.heatingFuelProvider = item.provider;
          dataGaps = dataGaps.filter(g => g !== 'propane_provider');
          break;
          
        case 'internet':
          updates.internetProvider = item.provider;
          break;
      }
      
      // Create service records for service providers
      if (['landscaping', 'pool', 'pest-control', 'cleaning', 'security'].includes(item.type)) {
        await this.prisma.service.upsert({
          where: {
            householdId_type: { householdId, type: item.type },
          },
          create: {
            householdId,
            name: this.getServiceName(item.type),
            type: item.type,
            vendorName: item.provider,
            monthlyCost: item.frequency === 'monthly' ? item.amount : null,
            costPerService: item.frequency !== 'monthly' ? item.amount : null,
            frequency: item.frequency,
          },
          update: {
            vendorName: item.provider,
            monthlyCost: item.frequency === 'monthly' ? item.amount : null,
          },
        });
      }
    }
    
    // Infer no water bill = likely well
    const hasWaterBill = analysis.some(a => a.type === 'water');
    if (!hasWaterBill && !updates.waterSourceConfirmed) {
      if (!dataGaps.includes('water_source_no_bill')) {
        dataGaps.push('water_source_no_bill');
      }
    }
    
    // Infer no sewer bill = likely septic
    const hasSewerBill = analysis.some(a => a.type === 'sewer');
    if (!hasSewerBill) {
      if (!dataGaps.includes('sewer_type_no_bill')) {
        dataGaps.push('sewer_type_no_bill');
      }
    }
    
    updates.alfredDataGaps = dataGaps;
    
    await this.prisma.household.update({
      where: { id: householdId },
      data: updates,
    });
    
    return analysis;
  }
  
  // Helper methods
  private normalizeMerchant(name: string): string {
    return (name || '')
      .toLowerCase()
      .replace(/[^a-z0-9\s]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }
  
  private cleanMerchantName(merchant: string): string {
    return merchant
      .split(' ')
      .map(word => word.charAt(0).toUpperCase() + word.slice(1))
      .join(' ');
  }
  
  private categorizeTransaction(merchant: string, tx: any): AnalyzedTransaction['type'] {
    const name = merchant.toLowerCase();
    
    for (const [type, patterns] of Object.entries(this.patterns)) {
      for (const pattern of patterns) {
        if (pattern.test(name)) {
          return type as AnalyzedTransaction['type'];
        }
      }
    }
    
    return 'other';
  }
  
  private detectFrequency(transactions: any[]): AnalyzedTransaction['frequency'] {
    if (transactions.length < 2) return 'one-time';
    
    const dates = transactions.map(t => new Date(t.date).getTime()).sort();
    let totalDays = 0;
    for (let i = 1; i < dates.length; i++) {
      totalDays += (dates[i] - dates[i - 1]) / (1000 * 60 * 60 * 24);
    }
    const avgDays = totalDays / (dates.length - 1);
    
    if (avgDays <= 35) return 'monthly';
    if (avgDays <= 100) return 'quarterly';
    if (avgDays <= 400) return 'annually';
    return 'one-time';
  }
  
  private calculateConfidence(type: string, transactions: any[], avgAmount: number): number {
    let confidence = 0.5;
    
    if (transactions.length >= 6) confidence += 0.2;
    else if (transactions.length >= 3) confidence += 0.1;
    
    const amounts = transactions.map(t => Math.abs(t.amount));
    const avg = amounts.reduce((a, b) => a + b, 0) / amounts.length;
    const variance = Math.sqrt(
      amounts.reduce((sum, n) => sum + Math.pow(n - avg, 2), 0) / amounts.length
    );
    
    if (variance < 10) confidence += 0.15;
    else if (variance < 50) confidence += 0.05;
    
    if (['mortgage', 'electricity', 'gas'].includes(type)) {
      confidence += 0.1;
    }
    
    return Math.min(confidence, 0.95);
  }
  
  private getServiceName(type: string): string {
    const names: Record<string, string> = {
      'landscaping': 'Lawn & Landscaping',
      'pool': 'Pool Service',
      'pest-control': 'Pest Control',
      'cleaning': 'House Cleaning',
      'security': 'Security Monitoring',
    };
    return names[type] || type;
  }
}
```

---

## PHASE 2.2: Integrate with Plaid Service

Update the Plaid service to run transaction analysis after bank connection.

In `apps/api/src/plaid/plaid.service.ts`, add:

```typescript
import { TransactionAnalyzerService } from './transaction-analyzer.service';

// In constructor
constructor(
  private prisma: PrismaService,
  private transactionAnalyzer: TransactionAnalyzerService,
) {}

// Add method to analyze after token exchange
async analyzeTransactionsForHousehold(householdId: string) {
  // Get last 90 days of transactions
  const transactions = await this.getTransactions(householdId, 90);
  
  // Analyze
  const analysis = await this.transactionAnalyzer.analyzeTransactions(householdId, transactions);
  
  // Apply to household
  await this.transactionAnalyzer.applyAnalysisToHousehold(householdId, analysis);
  
  return analysis;
}
```

---

## PHASE 2.3: Deploy and Test Phase 2

```bash
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
```

### PHASE 2 TEST CHECKLIST

1. [ ] Transaction analyzer service is created
2. [ ] Plaid service can trigger analysis
3. [ ] Mortgage is detected from transactions
4. [ ] Insurance is detected from transactions
5. [ ] Utility providers are confirmed
6. [ ] Service providers are detected
7. [ ] Data gaps are updated correctly

**PHASE 2 STATUS:** [ PASS / FAIL ]

If FAIL, fix the issues before proceeding to Phase 3.

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 3: PROGRESSIVE ALFRED QUESTIONS
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 3 OVERVIEW

Alfred fills data gaps by asking questions naturally over time - not all at once. Questions feel conversational, not like a form.

---

## PHASE 3.1: Create Alfred Questions Service

Create `apps/api/src/alfred/alfred-questions.service.ts`:

```typescript
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

interface AlfredQuestion {
  id: string;
  dataGap: string;
  question: string;
  followUp?: string;
  responseType: 'choice' | 'text' | 'confirm';
  choices?: { label: string; value: string }[];
  priority: number;
  contextTrigger?: string;
}

@Injectable()
export class AlfredQuestionsService {
  constructor(private prisma: PrismaService) {}

  private questions: AlfredQuestion[] = [
    {
      id: 'water_source',
      dataGap: 'water_source',
      question: "Quick question about your home - do you have town water or a private well?",
      responseType: 'choice',
      choices: [
        { label: '💧 Town/Municipal Water', value: 'municipal' },
        { label: '🪣 Private Well', value: 'well' },
      ],
      priority: 1,
    },
    {
      id: 'water_source_no_bill',
      dataGap: 'water_source_no_bill',
      question: "I noticed you don't have a water bill in your bank transactions. Do you have a private well?",
      responseType: 'choice',
      choices: [
        { label: 'Yes, we have a well', value: 'well' },
        { label: 'No, we have town water', value: 'municipal' },
      ],
      priority: 1,
    },
    {
      id: 'sewer_type',
      dataGap: 'sewer_type',
      question: "Is your home on town sewer or do you have a septic system?",
      responseType: 'choice',
      choices: [
        { label: '🏛️ Town Sewer', value: 'municipal' },
        { label: '🕳️ Septic System', value: 'septic' },
      ],
      priority: 1,
    },
    {
      id: 'sewer_type_no_bill',
      dataGap: 'sewer_type_no_bill',
      question: "I don't see a sewer bill in your transactions. Does your home have a septic system?",
      responseType: 'choice',
      choices: [
        { label: 'Yes, we have septic', value: 'septic' },
        { label: 'No, we have town sewer', value: 'municipal' },
      ],
      priority: 1,
    },
    {
      id: 'oil_provider',
      dataGap: 'oil_provider',
      question: "I see you have oil heat. Who delivers your heating oil? I can help track prices and schedule deliveries.",
      responseType: 'text',
      followUp: "Just type the company name, or say 'not sure' and I can help you find one.",
      priority: 2,
    },
    {
      id: 'propane_provider',
      dataGap: 'propane_provider',
      question: "Who's your propane supplier? I can monitor your usage and help schedule refills.",
      responseType: 'text',
      priority: 2,
    },
    {
      id: 'year_built',
      dataGap: 'year_built',
      question: "Do you know approximately when your home was built? This helps me estimate when systems might need attention.",
      responseType: 'text',
      followUp: "Just a rough year is fine, like '1985' or 'early 2000s'.",
      priority: 3,
    },
  ];

  async getNextQuestion(householdId: string, conversationContext?: string): Promise<AlfredQuestion | null> {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { 
        alfredDataGaps: true, 
        alfredQuestionsAsked: true,
      },
    });
    
    if (!household) return null;
    
    const dataGaps = (household.alfredDataGaps as string[]) || [];
    const questionsAsked = (household.alfredQuestionsAsked as string[]) || [];
    
    let candidates = this.questions.filter(q => 
      dataGaps.includes(q.dataGap) && 
      !questionsAsked.includes(q.id)
    );
    
    if (conversationContext) {
      const contextMatches = candidates.filter(q => {
        if (!q.contextTrigger) return false;
        const regex = new RegExp(q.contextTrigger, 'i');
        return regex.test(conversationContext);
      });
      
      if (contextMatches.length > 0) {
        contextMatches.sort((a, b) => a.priority - b.priority);
        return contextMatches[0];
      }
    }
    
    candidates.sort((a, b) => a.priority - b.priority);
    return candidates[0] || null;
  }

  async markQuestionAsked(householdId: string, questionId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredQuestionsAsked: true },
    });
    
    const questionsAsked = (household?.alfredQuestionsAsked as string[]) || [];
    if (!questionsAsked.includes(questionId)) {
      questionsAsked.push(questionId);
      await this.prisma.household.update({
        where: { id: householdId },
        data: { alfredQuestionsAsked: questionsAsked },
      });
    }
  }

  async processAnswer(householdId: string, questionId: string, answer: string) {
    const question = this.questions.find(q => q.id === questionId);
    if (!question) return { success: false, error: 'Question not found' };
    
    const updates: any = {};
    let removeGap: string | null = null;
    
    switch (questionId) {
      case 'water_source':
      case 'water_source_no_bill':
        updates.waterSource = answer;
        updates.waterSourceConfirmed = true;
        removeGap = question.dataGap;
        break;
        
      case 'sewer_type':
      case 'sewer_type_no_bill':
        updates.sewerType = answer;
        updates.sewerTypeConfirmed = true;
        removeGap = question.dataGap;
        
        if (answer === 'septic') {
          await this.createSepticTask(householdId);
        }
        break;
        
      case 'oil_provider':
        if (answer.toLowerCase() !== 'not sure') {
          updates.heatingFuelProvider = answer;
        }
        removeGap = 'oil_provider';
        break;
        
      case 'propane_provider':
        if (answer.toLowerCase() !== 'not sure') {
          updates.heatingFuelProvider = answer;
        }
        removeGap = 'propane_provider';
        break;
        
      case 'year_built':
        const year = parseInt(answer);
        if (year > 1800 && year <= new Date().getFullYear()) {
          updates.yearBuilt = year;
        }
        removeGap = 'year_built';
        break;
    }
    
    if (Object.keys(updates).length > 0) {
      await this.prisma.household.update({
        where: { id: householdId },
        data: updates,
      });
    }
    
    if (removeGap) {
      await this.removeDataGap(householdId, removeGap);
    }
    
    await this.markQuestionAsked(householdId, questionId);
    
    return { success: true };
  }

  private async removeDataGap(householdId: string, gap: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
      select: { alfredDataGaps: true },
    });
    
    let dataGaps = (household?.alfredDataGaps as string[]) || [];
    dataGaps = dataGaps.filter(g => g !== gap);
    
    await this.prisma.household.update({
      where: { id: householdId },
      data: { alfredDataGaps: dataGaps },
    });
  }

  private async createSepticTask(householdId: string) {
    const existingTask = await this.prisma.maintenanceTask.findFirst({
      where: { householdId, name: { contains: 'Septic' } },
    });
    
    if (!existingTask) {
      await this.prisma.maintenanceTask.create({
        data: {
          householdId,
          name: 'Septic Tank Pumping',
          description: 'Regular septic pumping prevents backups and system failure',
          frequency: 'Every 3 years',
          intervalDays: 1095,
          nextDue: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
          status: 'upcoming',
          estimatedCost: 350,
          intervalExplanation: 'Septic tanks should be pumped every 3-5 years depending on household size.',
          checklistSteps: JSON.stringify([
            { id: '1', order: 1, title: 'Locate septic tank access', alfredCanHandle: false, completed: false },
            { id: '2', order: 2, title: 'Get quotes from septic services', alfredCanHandle: true, completed: false },
            { id: '3', order: 3, title: 'Schedule pumping appointment', alfredCanHandle: true, completed: false },
            { id: '4', order: 4, title: 'Be present for service', alfredCanHandle: false, completed: false },
            { id: '5', order: 5, title: 'Review inspection findings', alfredCanHandle: false, completed: false },
          ]),
        },
      });
    }
  }
}
```

---

## PHASE 3.2: Create API Endpoint for Questions

Add to `apps/api/src/alfred/alfred.controller.ts`:

```typescript
@Get('next-question/:householdId')
@UseGuards(FirebaseAuthGuard)
async getNextQuestion(
  @Param('householdId') householdId: string,
  @Query('context') context?: string,
) {
  return this.questionsService.getNextQuestion(householdId, context);
}

@Post('answer-question')
@UseGuards(FirebaseAuthGuard)
async answerQuestion(
  @Body() body: { householdId: string; questionId: string; answer: string },
) {
  return this.questionsService.processAnswer(
    body.householdId,
    body.questionId,
    body.answer,
  );
}
```

---

## PHASE 3.3: Update Alfred Chat to Show Questions

Update the Alfred screen to display questions with choice buttons when appropriate.

In `apps/mobile/app/(tabs)/alfred/index.tsx` or equivalent:

When Alfred's response includes a `pendingQuestion`, render choice buttons:

```tsx
{message.pendingQuestion && message.pendingQuestion.responseType === 'choice' && (
  <View style={styles.choicesContainer}>
    {message.pendingQuestion.choices.map((choice) => (
      <TouchableOpacity
        key={choice.value}
        style={styles.choiceButton}
        onPress={() => handleQuestionAnswer(message.pendingQuestion.id, choice.value)}
      >
        <Text style={styles.choiceText}>{choice.label}</Text>
      </TouchableOpacity>
    ))}
  </View>
)}
```

---

## PHASE 3.4: Deploy and Test Phase 3

```bash
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616
```

### PHASE 3 TEST CHECKLIST

1. [ ] Alfred questions service is created
2. [ ] API endpoint returns next question
3. [ ] Questions appear in Alfred chat
4. [ ] Choice buttons render correctly
5. [ ] Answers are saved to household
6. [ ] Data gaps are removed after answering
7. [ ] New maintenance tasks created when appropriate (e.g., septic)

**PHASE 3 STATUS:** [ PASS / FAIL ]

If FAIL, fix the issues before proceeding to Phase 4.

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 4: YOUR HOME DASHBOARD (MOBILE)
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 4 OVERVIEW

Create the "Home" tab that displays all auto-captured data. Pre-populated, never empty. Edit capabilities for corrections.

---

## PHASE 4.1: Create Home Dashboard API Endpoint

Create `apps/api/src/home/home.controller.ts`:

```typescript
import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FirebaseAuthGuard } from '../auth/firebase-auth.guard';

@Controller('home')
export class HomeController {
  constructor(private prisma: PrismaService) {}

  @Get('dashboard/:householdId')
  @UseGuards(FirebaseAuthGuard)
  async getDashboard(@Param('householdId') householdId: string) {
    const household = await this.prisma.household.findUnique({
      where: { id: householdId },
    });
    
    const zones = await this.prisma.zone.findMany({
      where: { householdId },
      include: {
        systems: { select: { id: true, status: true } },
      },
    });
    
    const systems = await this.prisma.system.findMany({
      where: { householdId },
      orderBy: { nextServiceDue: 'asc' },
      take: 10,
    });
    
    const services = await this.prisma.service.findMany({
      where: { householdId },
    });
    
    const upcomingMaintenance = await this.prisma.maintenanceTask.findMany({
      where: {
        householdId,
        status: { in: ['upcoming', 'due', 'overdue'] },
      },
      orderBy: { nextDue: 'asc' },
      take: 5,
    });
    
    return {
      household,
      zones: zones.map(z => ({
        ...z,
        systemCount: z.systems.length,
        needsAttention: z.systems.filter(s => s.status !== 'good').length,
      })),
      systems,
      services,
      utilities: {
        electricity: {
          provider: household?.electricityProvider,
          confirmed: household?.electricityConfirmed,
        },
        gas: {
          provider: household?.gasProvider,
          confirmed: household?.gasConfirmed,
        },
        water: {
          source: household?.waterSource,
          provider: household?.waterProvider,
          confirmed: household?.waterSourceConfirmed,
        },
        sewer: {
          type: household?.sewerType,
          provider: household?.sewerProvider,
          confirmed: household?.sewerTypeConfirmed,
        },
        heatingFuel: {
          type: household?.heatingFuel,
          provider: household?.heatingFuelProvider,
        },
      },
      upcomingMaintenance,
    };
  }
}
```

Create `apps/api/src/home/home.module.ts`:

```typescript
import { Module } from '@nestjs/common';
import { HomeController } from './home.controller';
import { PrismaModule } from '../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [HomeController],
})
export class HomeModule {}
```

Register in app.module.ts.

---

## PHASE 4.2: Create Home Dashboard Screen

Create `apps/mobile/app/(tabs)/home/index.tsx` with the full dashboard UI showing:

- Property header with address
- Quick stats (year built, sqft, beds, baths)
- Utilities section
- Zones grid
- Active services
- Upcoming maintenance
- "Ask Alfred" card

(Full implementation as provided in earlier prompts - use the detailed code from the Your Home Dashboard prompt)

---

## PHASE 4.3: Deploy and Test Phase 4

```bash
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

cd apps/mobile
npx expo start --clear --ios
```

### PHASE 4 TEST CHECKLIST

1. [ ] Home dashboard API returns data
2. [ ] Home tab displays property header
3. [ ] Quick stats show correct values
4. [ ] Utilities section shows providers
5. [ ] Zones grid displays with system counts
6. [ ] Services section shows detected services
7. [ ] Upcoming maintenance links work
8. [ ] "Ask Alfred" card navigates correctly

**PHASE 4 STATUS:** [ PASS / FAIL ]

If FAIL, fix the issues before proceeding to Phase 5.

---

# ═══════════════════════════════════════════════════════════════════════════════
# PHASE 5: ENHANCED MAINTENANCE WITH CHECKLISTS
# ═══════════════════════════════════════════════════════════════════════════════

## PHASE 5 OVERVIEW

Transform maintenance into an Alfred-powered action center with checklists and one-tap delegation.

---

## PHASE 5.1: Fix All "Sarah" References

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Find all Sarah references
grep -rn "Sarah\|sarah" app/ src/ --include="*.tsx" --include="*.ts"

# Replace all with Alfred or appropriate text
```

Replace:
- "Ask Sarah" → "Ask Alfred"
- "Sarah Chen" → "Alfred" (for Essentials tier)
- Any sarah@ emails → appropriate addresses

---

## PHASE 5.2: Update Maintenance Detail Screen

Update `apps/mobile/app/(tabs)/maintenance/[id].tsx` to show:

- System info card with linked system
- "Why This Matters" explanation card
- Checklist steps with checkboxes
- "Have Alfred Do It" buttons on automatable steps
- "Have Alfred Handle Everything" primary action

(Full implementation as provided in earlier prompts)

---

## PHASE 5.3: Deploy and Test Phase 5

```bash
cd /Users/tomburke/Projects/Housing-Manager
gcloud builds submit --config=cloudbuild-api.yaml --project=home-manager-480616

cd apps/mobile
npx expo start --clear --ios
```

### PHASE 5 TEST CHECKLIST

1. [ ] All "Sarah" references replaced with "Alfred"
2. [ ] Maintenance list shows progress on tasks
3. [ ] Maintenance detail shows system context
4. [ ] "Why This Matters" explanation displays
5. [ ] Checklist steps work (toggle complete)
6. [ ] "Have Alfred Do It" navigates with context
7. [ ] "Have Alfred Handle Everything" works

**PHASE 5 STATUS:** [ PASS / FAIL ]

---

# ═══════════════════════════════════════════════════════════════════════════════
# FINAL VALIDATION
# ═══════════════════════════════════════════════════════════════════════════════

## ALL PHASES COMPLETE CHECKLIST

Before submitting to TestFlight, verify:

1. [ ] Phase 1: New signup flow works, old onboarding removed
2. [ ] Phase 2: Plaid transaction analysis works
3. [ ] Phase 3: Alfred progressive questions work
4. [ ] Phase 4: Home dashboard displays all data
5. [ ] Phase 5: Maintenance checklists work with Alfred integration
6. [ ] No crashes in simulator
7. [ ] All tabs navigate correctly
8. [ ] No "Sarah" references remain
9. [ ] No red error screens

## SUBMIT TO TESTFLIGHT

Only after all phases pass:

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile

# Increment build number in app.json
# Change buildNumber from current to next

# Build and submit
eas build --platform ios --profile production --auto-submit
```

---

# END OF PROMPT FILE
