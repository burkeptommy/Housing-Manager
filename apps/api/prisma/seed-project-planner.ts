import { PrismaClient, ProjectCategory } from '@prisma/client';
import * as h3 from 'h3-js';

const prisma = new PrismaClient();

// Project Templates with cost estimation data
const PROJECT_TEMPLATES = [
  // Kitchen Remodels
  {
    slug: 'kitchen_remodel_small',
    category: ProjectCategory.KITCHEN_REMODEL,
    name: 'Small Kitchen Remodel',
    description: 'Basic cabinet refacing, new countertops, and updated fixtures for kitchens under 100 sq ft.',
    baseMaterialCost: 75, // per sq ft
    laborHoursPerSqFt: 0.8,
    baseLaborRate: 75,
    complexityFactors: { cabinet_replacement: 1.3, appliance_upgrade: 1.15, structural_changes: 1.4 },
    minSqFt: 50,
    maxSqFt: 100,
    estimatedDaysMin: 14,
    estimatedDaysMax: 21,
    sortOrder: 1,
  },
  {
    slug: 'kitchen_remodel_medium',
    category: ProjectCategory.KITCHEN_REMODEL,
    name: 'Medium Kitchen Remodel',
    description: 'Full kitchen renovation including new cabinets, countertops, flooring, and appliances.',
    baseMaterialCost: 120,
    laborHoursPerSqFt: 1.0,
    baseLaborRate: 85,
    complexityFactors: { island_addition: 1.25, cabinet_replacement: 1.2, appliance_upgrade: 1.1 },
    minSqFt: 100,
    maxSqFt: 200,
    estimatedDaysMin: 21,
    estimatedDaysMax: 42,
    sortOrder: 2,
  },
  {
    slug: 'kitchen_remodel_large',
    category: ProjectCategory.KITCHEN_REMODEL,
    name: 'Large Kitchen Remodel',
    description: 'Premium kitchen transformation with custom cabinets, high-end finishes, and layout changes.',
    baseMaterialCost: 200,
    laborHoursPerSqFt: 1.2,
    baseLaborRate: 95,
    complexityFactors: { layout_changes: 1.35, custom_cabinets: 1.3, premium_appliances: 1.2 },
    minSqFt: 200,
    maxSqFt: 400,
    estimatedDaysMin: 42,
    estimatedDaysMax: 60,
    sortOrder: 3,
  },

  // Bathroom Remodels
  {
    slug: 'bathroom_remodel_guest',
    category: ProjectCategory.BATHROOM_REMODEL,
    name: 'Guest Bathroom Remodel',
    description: 'Update a small half or full bathroom with new fixtures, vanity, and flooring.',
    baseMaterialCost: 100,
    laborHoursPerSqFt: 1.5,
    baseLaborRate: 75,
    complexityFactors: { tile_work: 1.2, plumbing_reroute: 1.35 },
    minSqFt: 25,
    maxSqFt: 50,
    estimatedDaysMin: 7,
    estimatedDaysMax: 14,
    sortOrder: 4,
  },
  {
    slug: 'bathroom_remodel_master',
    category: ProjectCategory.BATHROOM_REMODEL,
    name: 'Master Bathroom Remodel',
    description: 'Full master bath renovation with walk-in shower, soaking tub, and double vanity.',
    baseMaterialCost: 175,
    laborHoursPerSqFt: 1.8,
    baseLaborRate: 85,
    complexityFactors: { walk_in_shower: 1.25, soaking_tub: 1.2, heated_floors: 1.15 },
    minSqFt: 75,
    maxSqFt: 150,
    estimatedDaysMin: 14,
    estimatedDaysMax: 28,
    sortOrder: 5,
  },

  // Deck & Patio
  {
    slug: 'deck_wood_standard',
    category: ProjectCategory.DECK_PATIO,
    name: 'Standard Wood Deck',
    description: 'Pressure-treated wood deck with basic railing system.',
    baseMaterialCost: 25,
    laborHoursPerSqFt: 0.25,
    baseLaborRate: 65,
    complexityFactors: { multi_level: 1.35, built_in_seating: 1.2, pergola: 1.25 },
    minSqFt: 100,
    maxSqFt: 500,
    estimatedDaysMin: 5,
    estimatedDaysMax: 14,
    sortOrder: 6,
  },
  {
    slug: 'deck_composite_premium',
    category: ProjectCategory.DECK_PATIO,
    name: 'Premium Composite Deck',
    description: 'Low-maintenance composite decking with aluminum railing and hidden fasteners.',
    baseMaterialCost: 45,
    laborHoursPerSqFt: 0.3,
    baseLaborRate: 75,
    complexityFactors: { multi_level: 1.3, lighting: 1.15, outdoor_kitchen: 1.4 },
    minSqFt: 150,
    maxSqFt: 800,
    estimatedDaysMin: 7,
    estimatedDaysMax: 21,
    sortOrder: 7,
  },
  {
    slug: 'patio_concrete',
    category: ProjectCategory.DECK_PATIO,
    name: 'Concrete Patio',
    description: 'Stamped or brushed concrete patio with optional fire pit area.',
    baseMaterialCost: 15,
    laborHoursPerSqFt: 0.15,
    baseLaborRate: 60,
    complexityFactors: { stamped_finish: 1.4, fire_pit: 1.25, outdoor_kitchen: 1.5 },
    minSqFt: 200,
    maxSqFt: 1000,
    estimatedDaysMin: 5,
    estimatedDaysMax: 10,
    sortOrder: 8,
  },

  // Landscaping
  {
    slug: 'landscaping_front_yard',
    category: ProjectCategory.LANDSCAPING,
    name: 'Front Yard Makeover',
    description: 'Complete front yard transformation with new plants, hardscape, and irrigation.',
    baseMaterialCost: 12,
    laborHoursPerSqFt: 0.1,
    baseLaborRate: 55,
    complexityFactors: { irrigation_system: 1.3, retaining_walls: 1.4, lighting: 1.2 },
    minSqFt: 500,
    maxSqFt: 2000,
    estimatedDaysMin: 5,
    estimatedDaysMax: 14,
    sortOrder: 9,
  },
  {
    slug: 'landscaping_backyard',
    category: ProjectCategory.LANDSCAPING,
    name: 'Backyard Oasis',
    description: 'Create an outdoor living space with plantings, paths, and entertainment areas.',
    baseMaterialCost: 18,
    laborHoursPerSqFt: 0.12,
    baseLaborRate: 55,
    complexityFactors: { water_feature: 1.35, outdoor_kitchen: 1.5, fire_pit: 1.2 },
    minSqFt: 1000,
    maxSqFt: 5000,
    estimatedDaysMin: 10,
    estimatedDaysMax: 30,
    sortOrder: 10,
  },

  // Roofing
  {
    slug: 'roof_asphalt_shingle',
    category: ProjectCategory.ROOF,
    name: 'Asphalt Shingle Roof',
    description: 'Complete roof replacement with architectural asphalt shingles.',
    baseMaterialCost: 5,
    laborHoursPerSqFt: 0.03,
    baseLaborRate: 70,
    complexityFactors: { steep_pitch: 1.3, multiple_stories: 1.2, complex_roof_line: 1.25 },
    minSqFt: 1000,
    maxSqFt: 3500,
    estimatedDaysMin: 2,
    estimatedDaysMax: 5,
    sortOrder: 11,
  },
  {
    slug: 'roof_metal',
    category: ProjectCategory.ROOF,
    name: 'Metal Roof',
    description: 'Standing seam or metal tile roofing for long-lasting protection.',
    baseMaterialCost: 12,
    laborHoursPerSqFt: 0.04,
    baseLaborRate: 80,
    complexityFactors: { steep_pitch: 1.25, complex_roof_line: 1.3 },
    minSqFt: 1000,
    maxSqFt: 3500,
    estimatedDaysMin: 3,
    estimatedDaysMax: 7,
    sortOrder: 12,
  },

  // Windows & Doors
  {
    slug: 'windows_replacement',
    category: ProjectCategory.WINDOWS_DOORS,
    name: 'Window Replacement',
    description: 'Replace existing windows with energy-efficient double or triple pane windows.',
    baseMaterialCost: 450, // per window
    laborHoursPerSqFt: null, // priced per unit, not sq ft
    baseLaborRate: 150, // per window
    complexityFactors: { bay_window: 2.0, skylight: 2.5, custom_size: 1.5 },
    minSqFt: null,
    maxSqFt: null,
    estimatedDaysMin: 1,
    estimatedDaysMax: 3,
    sortOrder: 13,
  },
  {
    slug: 'entry_door',
    category: ProjectCategory.WINDOWS_DOORS,
    name: 'Entry Door Replacement',
    description: 'New front entry door with frame, hardware, and weatherstripping.',
    baseMaterialCost: 1500,
    laborHoursPerSqFt: null,
    baseLaborRate: 400,
    complexityFactors: { sidelights: 1.5, transom: 1.3, custom: 2.0 },
    minSqFt: null,
    maxSqFt: null,
    estimatedDaysMin: 1,
    estimatedDaysMax: 1,
    sortOrder: 14,
  },

  // Flooring
  {
    slug: 'flooring_hardwood',
    category: ProjectCategory.FLOORING,
    name: 'Hardwood Flooring',
    description: 'Solid or engineered hardwood floor installation.',
    baseMaterialCost: 10,
    laborHoursPerSqFt: 0.08,
    baseLaborRate: 65,
    complexityFactors: { existing_removal: 1.2, stair_work: 1.4, refinish_existing: 0.6 },
    minSqFt: 200,
    maxSqFt: 2500,
    estimatedDaysMin: 3,
    estimatedDaysMax: 10,
    sortOrder: 15,
  },
  {
    slug: 'flooring_tile',
    category: ProjectCategory.FLOORING,
    name: 'Tile Flooring',
    description: 'Ceramic, porcelain, or natural stone tile installation.',
    baseMaterialCost: 12,
    laborHoursPerSqFt: 0.12,
    baseLaborRate: 70,
    complexityFactors: { large_format: 1.15, pattern_layout: 1.25, heated_floor: 1.3 },
    minSqFt: 100,
    maxSqFt: 1500,
    estimatedDaysMin: 3,
    estimatedDaysMax: 14,
    sortOrder: 16,
  },

  // Painting
  {
    slug: 'painting_interior',
    category: ProjectCategory.PAINTING,
    name: 'Interior Painting',
    description: 'Full interior paint with prep, primer, and two coats of premium paint.',
    baseMaterialCost: 1.5,
    laborHoursPerSqFt: 0.04,
    baseLaborRate: 50,
    complexityFactors: { high_ceilings: 1.25, trim_work: 1.2, wallpaper_removal: 1.35 },
    minSqFt: 500,
    maxSqFt: 4000,
    estimatedDaysMin: 3,
    estimatedDaysMax: 10,
    sortOrder: 17,
  },
  {
    slug: 'painting_exterior',
    category: ProjectCategory.PAINTING,
    name: 'Exterior Painting',
    description: 'Complete exterior paint including siding, trim, and fascia.',
    baseMaterialCost: 2,
    laborHoursPerSqFt: 0.05,
    baseLaborRate: 55,
    complexityFactors: { multi_story: 1.3, extensive_prep: 1.25, stucco: 1.15 },
    minSqFt: 1000,
    maxSqFt: 4000,
    estimatedDaysMin: 4,
    estimatedDaysMax: 10,
    sortOrder: 18,
  },

  // HVAC
  {
    slug: 'hvac_replacement',
    category: ProjectCategory.HVAC,
    name: 'HVAC System Replacement',
    description: 'Replace furnace and AC unit with high-efficiency system.',
    baseMaterialCost: 8000,
    laborHoursPerSqFt: null,
    baseLaborRate: 2500,
    complexityFactors: { ductwork_modification: 1.3, zone_system: 1.4, heat_pump: 1.2 },
    minSqFt: null,
    maxSqFt: null,
    estimatedDaysMin: 2,
    estimatedDaysMax: 4,
    sortOrder: 19,
  },

  // Electrical
  {
    slug: 'electrical_panel_upgrade',
    category: ProjectCategory.ELECTRICAL,
    name: 'Electrical Panel Upgrade',
    description: 'Upgrade main electrical panel to 200 amp service.',
    baseMaterialCost: 1500,
    laborHoursPerSqFt: null,
    baseLaborRate: 1500,
    complexityFactors: { permit_required: 1.1, whole_house_rewire: 3.0 },
    minSqFt: null,
    maxSqFt: null,
    estimatedDaysMin: 1,
    estimatedDaysMax: 2,
    sortOrder: 20,
  },

  // Plumbing
  {
    slug: 'water_heater_replacement',
    category: ProjectCategory.PLUMBING,
    name: 'Water Heater Replacement',
    description: 'Replace tank or tankless water heater with new unit.',
    baseMaterialCost: 1200,
    laborHoursPerSqFt: null,
    baseLaborRate: 600,
    complexityFactors: { tankless_conversion: 1.5, relocation: 1.4 },
    minSqFt: null,
    maxSqFt: null,
    estimatedDaysMin: 1,
    estimatedDaysMax: 1,
    sortOrder: 21,
  },

  // Fence
  {
    slug: 'fence_wood_privacy',
    category: ProjectCategory.FENCE,
    name: 'Wood Privacy Fence',
    description: '6-foot cedar or pressure-treated privacy fence.',
    baseMaterialCost: 25, // per linear ft
    laborHoursPerSqFt: 0.15,
    baseLaborRate: 55,
    complexityFactors: { gate: 1.3, sloped_terrain: 1.25, decorative_top: 1.15 },
    minSqFt: 50, // linear feet
    maxSqFt: 500,
    estimatedDaysMin: 2,
    estimatedDaysMax: 7,
    sortOrder: 22,
  },

  // Solar
  {
    slug: 'solar_panel_system',
    category: ProjectCategory.SOLAR,
    name: 'Solar Panel System',
    description: 'Grid-tied solar panel installation with inverter and monitoring.',
    baseMaterialCost: 2.50, // per watt
    laborHoursPerSqFt: null,
    baseLaborRate: 0.50, // per watt
    complexityFactors: { battery_backup: 1.5, complex_roof: 1.2, ground_mount: 1.3 },
    minSqFt: 3000, // watts
    maxSqFt: 15000,
    estimatedDaysMin: 2,
    estimatedDaysMax: 5,
    sortOrder: 23,
  },
];

// Regional Cost Indexes (H3 Resolution 5 = ~8km hexagons)
// These are representative H3 cells for major metros
const REGIONAL_COST_INDEXES = [
  // San Francisco Bay Area (1.8x multiplier)
  { lat: 37.7749, lng: -122.4194, regionName: 'San Francisco', stateCode: 'CA', multiplier: 1.80, laborMultiplier: 1.85 },
  { lat: 37.8044, lng: -122.2712, regionName: 'Oakland', stateCode: 'CA', multiplier: 1.65, laborMultiplier: 1.70 },
  { lat: 37.5485, lng: -122.0590, regionName: 'Fremont', stateCode: 'CA', multiplier: 1.60, laborMultiplier: 1.65 },
  { lat: 37.3861, lng: -122.0839, regionName: 'San Jose', stateCode: 'CA', multiplier: 1.70, laborMultiplier: 1.75 },
  { lat: 37.4419, lng: -122.1430, regionName: 'Palo Alto', stateCode: 'CA', multiplier: 1.85, laborMultiplier: 1.90 },

  // Los Angeles Area (1.5x)
  { lat: 34.0522, lng: -118.2437, regionName: 'Los Angeles', stateCode: 'CA', multiplier: 1.50, laborMultiplier: 1.55 },
  { lat: 33.6846, lng: -117.8265, regionName: 'Irvine', stateCode: 'CA', multiplier: 1.45, laborMultiplier: 1.50 },
  { lat: 34.0195, lng: -118.4912, regionName: 'Santa Monica', stateCode: 'CA', multiplier: 1.60, laborMultiplier: 1.65 },

  // New York Area (1.7x)
  { lat: 40.7128, lng: -74.0060, regionName: 'New York City', stateCode: 'NY', multiplier: 1.75, laborMultiplier: 1.85 },
  { lat: 40.7282, lng: -73.7949, regionName: 'Long Island', stateCode: 'NY', multiplier: 1.55, laborMultiplier: 1.60 },
  { lat: 40.4774, lng: -74.2591, regionName: 'New Jersey (North)', stateCode: 'NJ', multiplier: 1.50, laborMultiplier: 1.55 },

  // Texas (0.95x - lower than national average)
  { lat: 29.7604, lng: -95.3698, regionName: 'Houston', stateCode: 'TX', multiplier: 0.95, laborMultiplier: 0.90 },
  { lat: 32.7767, lng: -96.7970, regionName: 'Dallas', stateCode: 'TX', multiplier: 0.95, laborMultiplier: 0.92 },
  { lat: 30.2672, lng: -97.7431, regionName: 'Austin', stateCode: 'TX', multiplier: 1.05, laborMultiplier: 1.00 },
  { lat: 29.4241, lng: -98.4936, regionName: 'San Antonio', stateCode: 'TX', multiplier: 0.90, laborMultiplier: 0.88 },

  // Chicago Area (1.15x)
  { lat: 41.8781, lng: -87.6298, regionName: 'Chicago', stateCode: 'IL', multiplier: 1.15, laborMultiplier: 1.20 },
  { lat: 42.0451, lng: -87.6877, regionName: 'Evanston', stateCode: 'IL', multiplier: 1.20, laborMultiplier: 1.25 },

  // Denver (1.1x)
  { lat: 39.7392, lng: -104.9903, regionName: 'Denver', stateCode: 'CO', multiplier: 1.10, laborMultiplier: 1.12 },
  { lat: 39.8561, lng: -104.6737, regionName: 'Aurora', stateCode: 'CO', multiplier: 1.05, laborMultiplier: 1.08 },

  // Seattle (1.4x)
  { lat: 47.6062, lng: -122.3321, regionName: 'Seattle', stateCode: 'WA', multiplier: 1.40, laborMultiplier: 1.45 },
  { lat: 47.6101, lng: -122.2015, regionName: 'Bellevue', stateCode: 'WA', multiplier: 1.50, laborMultiplier: 1.55 },

  // Boston (1.45x)
  { lat: 42.3601, lng: -71.0589, regionName: 'Boston', stateCode: 'MA', multiplier: 1.45, laborMultiplier: 1.50 },
  { lat: 42.3736, lng: -71.1106, regionName: 'Cambridge', stateCode: 'MA', multiplier: 1.50, laborMultiplier: 1.55 },

  // Miami (1.2x)
  { lat: 25.7617, lng: -80.1918, regionName: 'Miami', stateCode: 'FL', multiplier: 1.20, laborMultiplier: 1.15 },
  { lat: 26.1224, lng: -80.1373, regionName: 'Fort Lauderdale', stateCode: 'FL', multiplier: 1.15, laborMultiplier: 1.10 },

  // Phoenix (0.98x)
  { lat: 33.4484, lng: -112.0740, regionName: 'Phoenix', stateCode: 'AZ', multiplier: 0.98, laborMultiplier: 0.95 },
  { lat: 33.4152, lng: -111.8315, regionName: 'Scottsdale', stateCode: 'AZ', multiplier: 1.10, laborMultiplier: 1.05 },

  // Atlanta (1.0x - national average)
  { lat: 33.7490, lng: -84.3880, regionName: 'Atlanta', stateCode: 'GA', multiplier: 1.00, laborMultiplier: 1.00 },
  { lat: 33.9519, lng: -84.5470, regionName: 'Marietta', stateCode: 'GA', multiplier: 0.95, laborMultiplier: 0.95 },
];

async function main() {
  console.log('🌱 Seeding Project Planner data...\n');

  // Seed Project Templates
  const templates = await Promise.all(
    PROJECT_TEMPLATES.map(async (t) => {
      return prisma.projectTemplate.upsert({
        where: { slug: t.slug },
        update: {
          name: t.name,
          description: t.description,
          baseMaterialCost: t.baseMaterialCost,
          laborHoursPerSqFt: t.laborHoursPerSqFt,
          baseLaborRate: t.baseLaborRate,
          complexityFactors: t.complexityFactors,
          minSqFt: t.minSqFt,
          maxSqFt: t.maxSqFt,
          estimatedDaysMin: t.estimatedDaysMin,
          estimatedDaysMax: t.estimatedDaysMax,
          sortOrder: t.sortOrder,
        },
        create: {
          slug: t.slug,
          category: t.category,
          name: t.name,
          description: t.description,
          baseMaterialCost: t.baseMaterialCost,
          laborHoursPerSqFt: t.laborHoursPerSqFt,
          baseLaborRate: t.baseLaborRate,
          complexityFactors: t.complexityFactors,
          minSqFt: t.minSqFt,
          maxSqFt: t.maxSqFt,
          estimatedDaysMin: t.estimatedDaysMin,
          estimatedDaysMax: t.estimatedDaysMax,
          sortOrder: t.sortOrder,
          isActive: true,
        },
      });
    })
  );
  console.log(`✅ Created ${templates.length} project templates`);

  // Seed Regional Cost Indexes
  let indexCount = 0;
  for (const region of REGIONAL_COST_INDEXES) {
    const h3Index = h3.latLngToCell(region.lat, region.lng, 5); // Resolution 5 for regional coverage

    await prisma.regionalCostIndex.upsert({
      where: {
        h3Index_effectiveFrom: {
          h3Index,
          effectiveFrom: new Date('2024-01-01'),
        },
      },
      update: {
        multiplier: region.multiplier,
        laborMultiplier: region.laborMultiplier,
        regionName: region.regionName,
        stateCode: region.stateCode,
      },
      create: {
        h3Index,
        h3Resolution: 5,
        multiplier: region.multiplier,
        laborMultiplier: region.laborMultiplier,
        regionName: region.regionName,
        stateCode: region.stateCode,
        effectiveFrom: new Date('2024-01-01'),
      },
    });
    indexCount++;
  }
  console.log(`✅ Created ${indexCount} regional cost indexes`);

  console.log('\n🎉 Project Planner seeding complete!\n');
  console.log('Summary:');
  console.log(`  - ${templates.length} project templates`);
  console.log(`  - ${indexCount} regional cost indexes`);
}

main()
  .catch((e) => {
    console.error('Error seeding project planner data:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
