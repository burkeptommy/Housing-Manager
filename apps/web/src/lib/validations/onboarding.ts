import { z } from 'zod';

// Step 1: Basic Home Info
export const basicInfoSchema = z.object({
  name: z.string().min(1, 'Home name is required').max(100),
  propertyType: z.enum([
    'SINGLE_FAMILY',
    'TOWNHOUSE',
    'CONDO',
    'APARTMENT',
    'MULTI_FAMILY',
    'MOBILE_HOME',
    'OTHER',
  ]),
  addressLine1: z.string().min(1, 'Address is required').max(200),
  addressLine2: z.string().max(200).optional(),
  city: z.string().min(1, 'City is required').max(100),
  state: z.string().min(2, 'State is required').max(2),
  postalCode: z.string().min(5, 'Valid ZIP code required').max(10),
  yearBuilt: z.coerce.number().min(1800).max(new Date().getFullYear()).optional(),
  bedrooms: z.coerce.number().min(0).max(20).optional(),
  bathrooms: z.coerce.number().min(0).max(20).optional(),
  squareFeet: z.coerce.number().min(100).max(100000).optional(),
});

export type BasicInfoData = z.infer<typeof basicInfoSchema>;

// Step 2: Systems Overview
export const systemsSchema = z.object({
  hvacType: z.string().optional(),
  hvacAge: z.coerce.number().min(0).max(50).optional(),
  roofType: z.string().optional(),
  roofAge: z.coerce.number().min(0).max(100).optional(),
  waterHeaterType: z.string().optional(),
  waterHeaterAge: z.coerce.number().min(0).max(30).optional(),
  septicOrSewer: z.enum(['septic', 'sewer']).optional(),
  septicLastServiced: z.string().optional(),
  electricalPanelAmps: z.coerce.number().min(60).max(400).optional(),
  hasPool: z.boolean().optional(),
  hasSprinklerSystem: z.boolean().optional(),
  hasSecuritySystem: z.boolean().optional(),
  hasSmartHome: z.boolean().optional(),
});

export type SystemsData = z.infer<typeof systemsSchema>;

// Step 3: Pain Points
export const painPointOptions = [
  { value: 'maintenance_scheduling', label: 'Maintenance scheduling' },
  { value: 'finding_vendors', label: 'Finding reliable vendors' },
  { value: 'tracking_bills', label: 'Keeping track of bills' },
  { value: 'household_supplies', label: 'Household supplies' },
  { value: 'pet_care', label: 'Pet care' },
  { value: 'vehicle_maintenance', label: 'Vehicle maintenance' },
] as const;

export const painPointsSchema = z.object({
  painPoints: z.array(
    z.enum([
      'maintenance_scheduling',
      'finding_vendors',
      'tracking_bills',
      'household_supplies',
      'pet_care',
      'vehicle_maintenance',
    ])
  ),
});

export type PainPointsData = z.infer<typeof painPointsSchema>;

// Step 4: Communication Preferences
export const communicationOptions = [
  { value: 'email', label: 'Email', description: 'Get updates via email' },
  { value: 'sms', label: 'SMS', description: 'Get text message alerts' },
  { value: 'app', label: 'App notifications', description: 'In-app push notifications' },
] as const;

export const communicationSchema = z.object({
  communicationChannels: z
    .array(z.enum(['sms', 'email', 'app']))
    .min(1, 'Select at least one communication channel'),
});

export type CommunicationData = z.infer<typeof communicationSchema>;

// Combined onboarding data
export const fullOnboardingSchema = basicInfoSchema
  .merge(z.object({ systems: systemsSchema }))
  .merge(painPointsSchema)
  .merge(communicationSchema);

export type FullOnboardingData = z.infer<typeof fullOnboardingSchema>;

// Property type options
export const propertyTypeOptions = [
  { value: 'SINGLE_FAMILY', label: 'Single Family Home' },
  { value: 'TOWNHOUSE', label: 'Townhouse' },
  { value: 'CONDO', label: 'Condo' },
  { value: 'APARTMENT', label: 'Apartment' },
  { value: 'MULTI_FAMILY', label: 'Multi-Family' },
  { value: 'MOBILE_HOME', label: 'Mobile Home' },
  { value: 'OTHER', label: 'Other' },
] as const;

// HVAC type options
export const hvacTypeOptions = [
  { value: 'central_ac', label: 'Central A/C' },
  { value: 'heat_pump', label: 'Heat Pump' },
  { value: 'furnace', label: 'Furnace' },
  { value: 'boiler', label: 'Boiler' },
  { value: 'mini_split', label: 'Mini-Split' },
  { value: 'window_units', label: 'Window Units' },
  { value: 'none', label: 'None' },
] as const;

// Roof type options
export const roofTypeOptions = [
  { value: 'asphalt_shingle', label: 'Asphalt Shingle' },
  { value: 'metal', label: 'Metal' },
  { value: 'tile', label: 'Tile' },
  { value: 'slate', label: 'Slate' },
  { value: 'flat', label: 'Flat/Built-up' },
  { value: 'wood_shake', label: 'Wood Shake' },
  { value: 'other', label: 'Other' },
] as const;

// Water heater type options
export const waterHeaterTypeOptions = [
  { value: 'tank_gas', label: 'Tank (Gas)' },
  { value: 'tank_electric', label: 'Tank (Electric)' },
  { value: 'tankless_gas', label: 'Tankless (Gas)' },
  { value: 'tankless_electric', label: 'Tankless (Electric)' },
  { value: 'heat_pump', label: 'Heat Pump' },
  { value: 'solar', label: 'Solar' },
] as const;

// US States
export const usStates = [
  { value: 'AL', label: 'Alabama' },
  { value: 'AK', label: 'Alaska' },
  { value: 'AZ', label: 'Arizona' },
  { value: 'AR', label: 'Arkansas' },
  { value: 'CA', label: 'California' },
  { value: 'CO', label: 'Colorado' },
  { value: 'CT', label: 'Connecticut' },
  { value: 'DE', label: 'Delaware' },
  { value: 'FL', label: 'Florida' },
  { value: 'GA', label: 'Georgia' },
  { value: 'HI', label: 'Hawaii' },
  { value: 'ID', label: 'Idaho' },
  { value: 'IL', label: 'Illinois' },
  { value: 'IN', label: 'Indiana' },
  { value: 'IA', label: 'Iowa' },
  { value: 'KS', label: 'Kansas' },
  { value: 'KY', label: 'Kentucky' },
  { value: 'LA', label: 'Louisiana' },
  { value: 'ME', label: 'Maine' },
  { value: 'MD', label: 'Maryland' },
  { value: 'MA', label: 'Massachusetts' },
  { value: 'MI', label: 'Michigan' },
  { value: 'MN', label: 'Minnesota' },
  { value: 'MS', label: 'Mississippi' },
  { value: 'MO', label: 'Missouri' },
  { value: 'MT', label: 'Montana' },
  { value: 'NE', label: 'Nebraska' },
  { value: 'NV', label: 'Nevada' },
  { value: 'NH', label: 'New Hampshire' },
  { value: 'NJ', label: 'New Jersey' },
  { value: 'NM', label: 'New Mexico' },
  { value: 'NY', label: 'New York' },
  { value: 'NC', label: 'North Carolina' },
  { value: 'ND', label: 'North Dakota' },
  { value: 'OH', label: 'Ohio' },
  { value: 'OK', label: 'Oklahoma' },
  { value: 'OR', label: 'Oregon' },
  { value: 'PA', label: 'Pennsylvania' },
  { value: 'RI', label: 'Rhode Island' },
  { value: 'SC', label: 'South Carolina' },
  { value: 'SD', label: 'South Dakota' },
  { value: 'TN', label: 'Tennessee' },
  { value: 'TX', label: 'Texas' },
  { value: 'UT', label: 'Utah' },
  { value: 'VT', label: 'Vermont' },
  { value: 'VA', label: 'Virginia' },
  { value: 'WA', label: 'Washington' },
  { value: 'WV', label: 'West Virginia' },
  { value: 'WI', label: 'Wisconsin' },
  { value: 'WY', label: 'Wyoming' },
  { value: 'DC', label: 'Washington D.C.' },
] as const;
