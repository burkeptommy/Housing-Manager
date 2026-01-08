export interface PropertyData {
  // From address
  addressLine1: string;
  city: string;
  state: string;
  postalCode: string;
  latitude?: number;
  longitude?: number;

  // From ATTOM or user input
  propertyType: string;
  yearBuilt?: number;
  squareFeet?: number;
  bedrooms?: number;
  bathrooms?: number;
  lotSize?: number;
  stories?: number;

  // Systems (from ATTOM)
  hvacType?: string;
  heatingFuel?: string;
  hasPool?: boolean;
  hasFireplace?: boolean;
  roofType?: string;
  roofAge?: number;
  foundationType?: string;

  // Utilities (from ATTOM regional data)
  electricProvider?: string;
  gasProvider?: string;
  waterProvider?: string;
  trashProvider?: string;
}

export interface OnboardingState {
  step: 'address' | 'property' | 'confirm' | 'bank' | 'plan' | 'complete';
  propertyData: PropertyData | null;
  householdId: string | null;
  isLoadingAttom: boolean;
  attomError: string | null;
}
