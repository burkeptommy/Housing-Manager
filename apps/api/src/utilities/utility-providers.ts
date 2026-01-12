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
export function getElectricityProvider(
  zipCode: string,
  state: string,
): string | null {
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
export function inferSewerType(
  lotSizeAcres: number | null,
  city: string,
  zipCode: string,
): { type: string; confidence: number } {
  // Urban areas almost always have municipal sewer
  const urbanZips = [
    '06510',
    '06511',
    '06604',
    '06605',
    '06606',
    '06607',
    '06901',
    '06902',
  ];
  if (urbanZips.includes(zipCode)) {
    return { type: 'municipal', confidence: 0.95 };
  }

  // Lot size is the best indicator
  if (lotSizeAcres !== null) {
    if (lotSizeAcres >= 1.0) {
      return { type: 'septic', confidence: 0.85 };
    } else if (lotSizeAcres <= 0.25) {
      return { type: 'municipal', confidence: 0.8 };
    } else {
      return { type: 'unknown', confidence: 0.5 };
    }
  }

  return { type: 'unknown', confidence: 0.3 };
}

// Infer well vs municipal water (correlates strongly with sewer type)
export function inferWaterSource(
  lotSizeAcres: number | null,
  city: string,
  sewerType: string,
): { type: string; confidence: number } {
  // If we know sewer type, water source usually matches
  if (sewerType === 'septic') {
    return { type: 'well', confidence: 0.8 };
  } else if (sewerType === 'municipal') {
    return { type: 'municipal', confidence: 0.85 };
  }

  // Fallback to lot size
  if (lotSizeAcres !== null && lotSizeAcres >= 1.0) {
    return { type: 'well', confidence: 0.7 };
  }

  return { type: 'unknown', confidence: 0.3 };
}

// Get all utility providers for a location
export function getUtilityProviders(
  zipCode: string,
  city: string,
  state: string,
) {
  return {
    electricity: getElectricityProvider(zipCode, state),
    gas: getGasProvider(zipCode, state),
  };
}
