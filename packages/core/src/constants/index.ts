import type { VendorCategory, BillingFrequency, PaymentResponsibility, MaintenanceCategory } from '../types';

// ============================================================================
// BILL CATEGORY GROUPS
// ============================================================================

export interface BillCategoryItem {
  category: VendorCategory;
  label: string;
}

export interface BillCategoryGroup {
  key: string;
  label: string;
  icon: string;
  items: BillCategoryItem[];
}

export const BILL_CATEGORY_GROUPS: BillCategoryGroup[] = [
  {
    key: 'housing',
    label: 'Housing',
    icon: '🏠',
    items: [
      { category: 'MORTGAGE', label: 'Mortgage' },
      { category: 'HOA', label: 'HOA Fees' },
      { category: 'PROPERTY_TAX', label: 'Property Tax' },
    ],
  },
  {
    key: 'utilities',
    label: 'Utilities',
    icon: '⚡',
    items: [
      { category: 'ELECTRIC', label: 'Electric' },
      { category: 'GAS', label: 'Gas' },
      { category: 'WATER_SEWER', label: 'Water & Sewer' },
      { category: 'TRASH', label: 'Trash' },
      { category: 'INTERNET', label: 'Internet' },
      { category: 'CABLE', label: 'Cable/TV' },
      { category: 'MOBILE', label: 'Mobile Phone' },
    ],
  },
  {
    key: 'insurance',
    label: 'Insurance',
    icon: '🛡️',
    items: [
      { category: 'HOME_INSURANCE', label: 'Home Insurance' },
      { category: 'AUTO_INSURANCE', label: 'Auto Insurance' },
      { category: 'HEALTH_INSURANCE', label: 'Health Insurance' },
      { category: 'LIFE_INSURANCE', label: 'Life Insurance' },
      { category: 'PET_INSURANCE', label: 'Pet Insurance' },
    ],
  },
  {
    key: 'loans',
    label: 'Loans & Debt',
    icon: '💳',
    items: [
      { category: 'CREDIT_CARD', label: 'Credit Card' },
      { category: 'STUDENT_LOAN', label: 'Student Loans' },
      { category: 'VEHICLE_LOAN', label: 'Vehicle Loan' },
      { category: 'PERSONAL_LOAN', label: 'Personal Loan' },
      { category: 'HELOC', label: 'HELOC' },
    ],
  },
  {
    key: 'services',
    label: 'Services & Subscriptions',
    icon: '📦',
    items: [
      { category: 'SECURITY_MONITORING', label: 'Security Monitoring' },
      { category: 'PEST_CONTROL', label: 'Pest Control' },
      { category: 'LAWN_CARE', label: 'Lawn Care' },
      { category: 'LANDSCAPING', label: 'Landscaping' },
      { category: 'HOME_WARRANTY', label: 'Home Warranty' },
      { category: 'CLEANING', label: 'Cleaning Service' },
      { category: 'GYM', label: 'Gym/Fitness' },
      { category: 'STREAMING', label: 'Streaming Services' },
    ],
  },
];

// ============================================================================
// BILLING FREQUENCY OPTIONS
// ============================================================================

export interface BillingFrequencyOption {
  value: BillingFrequency;
  label: string;
}

export const BILLING_FREQUENCY_OPTIONS: BillingFrequencyOption[] = [
  { value: 'WEEKLY', label: 'Weekly' },
  { value: 'BIWEEKLY', label: 'Bi-weekly' },
  { value: 'MONTHLY', label: 'Monthly' },
  { value: 'QUARTERLY', label: 'Quarterly' },
  { value: 'SEMIANNUALLY', label: 'Semi-annually' },
  { value: 'ANNUAL', label: 'Annually' },
  { value: 'OTHER', label: 'Other' },
];

// ============================================================================
// PAYMENT RESPONSIBILITY OPTIONS
// ============================================================================

export interface PaymentResponsibilityOption {
  value: PaymentResponsibility;
  label: string;
  description: string;
}

export const PAYMENT_RESPONSIBILITY_OPTIONS: PaymentResponsibilityOption[] = [
  {
    value: 'VENDOR_AUTOPAY',
    label: 'Autopay is set up',
    description: 'Just track and remind me',
  },
  {
    value: 'OWNER_PAYS_DIRECT',
    label: 'I pay manually',
    description: 'Remind me when due',
  },
  {
    value: 'HAVEN_PAYS_ON_BEHALF',
    label: 'Haven handles payment',
    description: 'Roll into my monthly bill',
  },
];

// ============================================================================
// VENDOR CATEGORY LABELS
// ============================================================================

export const VENDOR_CATEGORY_LABELS: Record<VendorCategory, string> = {
  MORTGAGE: 'Mortgage',
  HOA: 'HOA',
  PROPERTY_TAX: 'Property Tax',
  ELECTRIC: 'Electric',
  GAS: 'Gas',
  WATER_SEWER: 'Water & Sewer',
  TRASH: 'Trash',
  INTERNET: 'Internet',
  MOBILE: 'Mobile',
  CABLE: 'Cable',
  HOME_INSURANCE: 'Home Insurance',
  AUTO_INSURANCE: 'Auto Insurance',
  HEALTH_INSURANCE: 'Health Insurance',
  LIFE_INSURANCE: 'Life Insurance',
  PET_INSURANCE: 'Pet Insurance',
  CREDIT_CARD: 'Credit Card',
  STUDENT_LOAN: 'Student Loan',
  PERSONAL_LOAN: 'Personal Loan',
  VEHICLE_LOAN: 'Vehicle Loan',
  HELOC: 'HELOC',
  STREAMING: 'Streaming',
  GYM: 'Gym',
  SECURITY_MONITORING: 'Security',
  PEST_CONTROL: 'Pest Control',
  LAWN_CARE: 'Lawn Care',
  LANDSCAPING: 'Landscaping',
  HOME_WARRANTY: 'Home Warranty',
  CLEANING: 'Cleaning',
  WINDOW_WASHING: 'Window Washing',
  GUTTER_CLEANING: 'Gutter Cleaning',
  HVAC_SERVICE: 'HVAC Service',
  FILTER_SERVICE: 'Filter Service',
  CHIMNEY_SWEEP: 'Chimney Sweep',
  SEPTIC_SERVICE: 'Septic Service',
  POOL_SERVICE: 'Pool Service',
  SNOW_REMOVAL: 'Snow Removal',
  HANDYMAN: 'Handyman',
  OTHER: 'Other',
};

// ============================================================================
// MAINTENANCE CATEGORY LABELS
// ============================================================================

export interface MaintenanceCategoryInfo {
  label: string;
  icon: string;
}

export const MAINTENANCE_CATEGORY_INFO: Record<MaintenanceCategory, MaintenanceCategoryInfo> = {
  HVAC: { label: 'HVAC', icon: '❄️' },
  PLUMBING: { label: 'Plumbing', icon: '🔧' },
  ROOF_GUTTER: { label: 'Roof & Gutters', icon: '🏠' },
  CHIMNEY: { label: 'Chimney', icon: '🔥' },
  SEPTIC: { label: 'Septic', icon: '🚽' },
  LANDSCAPING: { label: 'Landscaping', icon: '🌳' },
  PEST: { label: 'Pest Control', icon: '🐜' },
  POOL: { label: 'Pool', icon: '🏊' },
  SAFETY: { label: 'Safety', icon: '🛡️' },
  CLEANING: { label: 'Cleaning', icon: '✨' },
  APPLIANCES: { label: 'Appliances', icon: '🔌' },
  EXTERIOR: { label: 'Exterior', icon: '🏡' },
  INTERIOR: { label: 'Interior', icon: '🛋️' },
  GENERAL: { label: 'General', icon: '📋' },
};

// ============================================================================
// MAINTENANCE FREQUENCY LABELS
// ============================================================================

export const MAINTENANCE_FREQUENCY_LABELS: Record<number, string> = {
  1: 'Monthly',
  3: 'Quarterly',
  6: 'Every 6 months',
  12: 'Annually',
  24: 'Every 2 years',
  36: 'Every 3 years',
};

// ============================================================================
// PROPERTY FEATURES
// ============================================================================

export interface PropertyFeatureOption {
  key: string;
  label: string;
  description: string;
}

export const PROPERTY_FEATURE_OPTIONS: PropertyFeatureOption[] = [
  { key: 'hasCentralAc', label: 'Central A/C', description: 'Central air conditioning system' },
  { key: 'hasGasHeat', label: 'Gas Heat', description: 'Natural gas heating' },
  { key: 'hasOilHeat', label: 'Oil Heat', description: 'Oil-fired heating system' },
  { key: 'hasFireplace', label: 'Fireplace/Chimney', description: 'Wood or gas fireplace' },
  { key: 'hasSeptic', label: 'Septic System', description: 'Private septic tank' },
  { key: 'hasWellWater', label: 'Well Water', description: 'Private well water supply' },
  { key: 'hasPool', label: 'Swimming Pool', description: 'In-ground or above-ground pool' },
  { key: 'hasGenerator', label: 'Generator', description: 'Backup power generator' },
  { key: 'hasLawn', label: 'Lawn/Yard', description: 'Needs regular mowing' },
  { key: 'hasDriveway', label: 'Driveway', description: 'May need snow removal' },
];

// ============================================================================
// PROPERTY TYPE OPTIONS
// ============================================================================

export interface PropertyTypeOption {
  value: string;
  label: string;
}

export const PROPERTY_TYPE_OPTIONS: PropertyTypeOption[] = [
  { value: 'SINGLE_FAMILY', label: 'Single Family Home' },
  { value: 'TOWNHOUSE', label: 'Townhouse' },
  { value: 'CONDO', label: 'Condo' },
  { value: 'APARTMENT', label: 'Apartment' },
  { value: 'MULTI_FAMILY', label: 'Multi-Family' },
  { value: 'MOBILE_HOME', label: 'Mobile Home' },
  { value: 'OTHER', label: 'Other' },
];

// ============================================================================
// US STATES
// ============================================================================

export interface StateOption {
  value: string;
  label: string;
}

export const US_STATES: StateOption[] = [
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
];
