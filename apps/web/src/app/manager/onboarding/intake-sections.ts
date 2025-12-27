// ===========================================================================
// INTAKE SECTIONS CONFIGURATION
// ===========================================================================
// This file defines all the questions asked during the onboarding call.
// Questions are grouped into sections and support various input types
// including repeater fields for capturing multiple items.
// ===========================================================================

export interface IntakeQuestion {
  id: string;
  question: string;
  type: 'text' | 'number' | 'currency' | 'phone' | 'email' | 'date' | 'select' | 'yesno' | 'textarea' | 'repeater';
  options?: string[];
  placeholder?: string;
  required?: boolean;
  helpText?: string;
  conditionalOn?: { field: string; value: any };
  fields?: IntakeQuestion[]; // For repeater type
}

export interface IntakeSection {
  id: string;
  title: string;
  icon: string;
  description: string;
  questions: IntakeQuestion[];
  contextFromEnrichment?: (enrichment: any) => string | null;
}

export const intakeSections: IntakeSection[] = [
  {
    id: 'quickStart',
    title: 'Quick Start',
    icon: '🎯',
    description: 'Confirm pain points and set expectations',
    questions: [
      {
        id: 'confirmedChallenge',
        question: 'Confirm their biggest challenge',
        type: 'select',
        options: ['Bills & Payments', 'Home Maintenance', 'Vendor Coordination', 'Family Logistics', 'All of the above'],
      },
      {
        id: 'urgentIssues',
        question: 'Any urgent issues to address first?',
        type: 'textarea',
        placeholder: 'Leaking pipe, overdue bill, etc.',
      },
      {
        id: 'expectations',
        question: 'What would success look like in 30 days?',
        type: 'textarea',
      },
    ],
  },
  {
    id: 'family',
    title: 'Family & Household',
    icon: '👨‍👩‍👧‍👦',
    description: 'Adults, children, pets, staff',
    questions: [
      {
        id: 'adults',
        question: 'Adults in household',
        type: 'repeater',
        fields: [
          { id: 'firstName', question: 'First Name', type: 'text', required: true },
          { id: 'lastName', question: 'Last Name', type: 'text' },
          { id: 'role', question: 'Role', type: 'select', options: ['Head of Household', 'Spouse/Partner', 'Parent', 'Other'] },
          { id: 'email', question: 'Email', type: 'email' },
          { id: 'phone', question: 'Phone', type: 'phone' },
          { id: 'employer', question: 'Employer', type: 'text' },
        ],
      },
      {
        id: 'hasKids',
        question: 'Any children in the household?',
        type: 'yesno',
      },
      {
        id: 'children',
        question: 'Children',
        type: 'repeater',
        conditionalOn: { field: 'hasKids', value: true },
        fields: [
          { id: 'firstName', question: 'First Name', type: 'text', required: true },
          { id: 'age', question: 'Age', type: 'number' },
          { id: 'school', question: 'School', type: 'text' },
          { id: 'grade', question: 'Grade', type: 'text' },
          { id: 'allergies', question: 'Allergies', type: 'text', placeholder: 'Separate with commas' },
        ],
      },
      {
        id: 'hasPets',
        question: 'Any pets?',
        type: 'yesno',
      },
      {
        id: 'pets',
        question: 'Pets',
        type: 'repeater',
        conditionalOn: { field: 'hasPets', value: true },
        fields: [
          { id: 'name', question: 'Name', type: 'text', required: true },
          { id: 'type', question: 'Type/Breed', type: 'text', placeholder: 'Golden Retriever, Tabby Cat, etc.' },
          { id: 'vetName', question: 'Vet Name', type: 'text' },
          { id: 'vetPhone', question: 'Vet Phone', type: 'phone' },
        ],
      },
      {
        id: 'hasStaff',
        question: 'Any household staff (nanny, housekeeper, etc.)?',
        type: 'yesno',
      },
      {
        id: 'staff',
        question: 'Household Staff',
        type: 'repeater',
        conditionalOn: { field: 'hasStaff', value: true },
        fields: [
          { id: 'name', question: 'Name', type: 'text', required: true },
          { id: 'role', question: 'Role', type: 'select', options: ['Nanny', 'Au Pair', 'Housekeeper', 'Gardener', 'Other'] },
          { id: 'schedule', question: 'Schedule', type: 'text', placeholder: 'M-F 8am-5pm' },
          { id: 'phone', question: 'Phone', type: 'phone' },
        ],
      },
    ],
  },
  {
    id: 'vehicles',
    title: 'Vehicles',
    icon: '🚗',
    description: 'Cars, registration, maintenance',
    questions: [
      {
        id: 'hasVehicles',
        question: 'Any vehicles?',
        type: 'yesno',
      },
      {
        id: 'vehicles',
        question: 'Vehicles',
        type: 'repeater',
        conditionalOn: { field: 'hasVehicles', value: true },
        fields: [
          { id: 'year', question: 'Year', type: 'number' },
          { id: 'make', question: 'Make', type: 'text', placeholder: 'Toyota, Honda, etc.' },
          { id: 'model', question: 'Model', type: 'text' },
          { id: 'color', question: 'Color', type: 'text' },
          { id: 'licensePlate', question: 'License Plate', type: 'text' },
          { id: 'primaryDriver', question: 'Primary Driver', type: 'text' },
          { id: 'registrationDue', question: 'Registration Due', type: 'date' },
          { id: 'oilChangeVendor', question: 'Where do you get oil changes?', type: 'text' },
        ],
      },
    ],
  },
  {
    id: 'systems',
    title: 'Home Systems',
    icon: '⚙️',
    description: 'HVAC, plumbing, electrical',
    contextFromEnrichment: (e) => {
      if (!e) return null;
      const notes = [];
      if (e.heatingFuel?.toLowerCase().includes('oil')) {
        notes.push('Oil heat detected - ask about delivery schedule');
      }
      if (e.fireplaces > 0) {
        notes.push(`${e.fireplaces} fireplace(s) - ask about chimney sweeps`);
      }
      return notes.length > 0 ? notes.join(' • ') : null;
    },
    questions: [
      {
        id: 'hvacBrand',
        question: 'HVAC Brand/Model',
        type: 'text',
        helpText: 'Check for sticker on unit',
      },
      {
        id: 'hvacAge',
        question: 'HVAC Age (years)',
        type: 'number',
      },
      {
        id: 'hvacVendor',
        question: 'HVAC Service Company',
        type: 'text',
        helpText: 'Who services the HVAC?',
      },
      {
        id: 'heatingFuel',
        question: 'Heating Fuel',
        type: 'select',
        options: ['Natural Gas', 'Oil', 'Propane', 'Electric', 'Heat Pump', 'Geothermal'],
      },
      {
        id: 'oilDelivery',
        question: 'Oil Delivery Company',
        type: 'text',
        conditionalOn: { field: 'heatingFuel', value: 'Oil' },
      },
      {
        id: 'oilAutoFill',
        question: 'Auto-fill or call when needed?',
        type: 'select',
        options: ['Auto-fill', 'Call when needed'],
        conditionalOn: { field: 'heatingFuel', value: 'Oil' },
      },
      {
        id: 'waterHeaterType',
        question: 'Water Heater Type',
        type: 'select',
        options: ['Tank (Gas)', 'Tank (Electric)', 'Tankless (Gas)', 'Tankless (Electric)'],
      },
      {
        id: 'waterHeaterAge',
        question: 'Water Heater Age (years)',
        type: 'number',
      },
      {
        id: 'hasFireplace',
        question: 'Fireplace(s)?',
        type: 'yesno',
      },
      {
        id: 'fireplaceType',
        question: 'Fireplace Type',
        type: 'select',
        options: ['Wood burning', 'Gas', 'Electric'],
        conditionalOn: { field: 'hasFireplace', value: true },
      },
      {
        id: 'chimneySweep',
        question: 'Chimney Sweep Company',
        type: 'text',
        conditionalOn: { field: 'hasFireplace', value: true },
      },
      {
        id: 'hasGenerator',
        question: 'Generator?',
        type: 'yesno',
      },
      {
        id: 'generatorBrand',
        question: 'Generator Brand',
        type: 'text',
        conditionalOn: { field: 'hasGenerator', value: true },
      },
      {
        id: 'hasSecuritySystem',
        question: 'Security System?',
        type: 'yesno',
      },
      {
        id: 'securityProvider',
        question: 'Security Provider',
        type: 'text',
        conditionalOn: { field: 'hasSecuritySystem', value: true },
      },
      {
        id: 'securityCost',
        question: 'Monthly Cost',
        type: 'currency',
        conditionalOn: { field: 'hasSecuritySystem', value: true },
      },
    ],
  },
  {
    id: 'exterior',
    title: 'Exterior & Grounds',
    icon: '🏡',
    description: 'Lawn, pool, roof, gutters',
    contextFromEnrichment: (e) => {
      if (!e) return null;
      const notes = [];
      if (e.pool) notes.push('Pool detected');
      if (e.hasSeptic) notes.push('Septic system');
      if (e.hasWell) notes.push('Well water');
      return notes.length > 0 ? notes.join(' • ') : null;
    },
    questions: [
      {
        id: 'hasLawnService',
        question: 'Lawn/Landscape Service?',
        type: 'yesno',
      },
      {
        id: 'lawnVendor',
        question: 'Lawn Service Company',
        type: 'text',
        conditionalOn: { field: 'hasLawnService', value: true },
      },
      {
        id: 'lawnCost',
        question: 'Monthly Cost',
        type: 'currency',
        conditionalOn: { field: 'hasLawnService', value: true },
      },
      {
        id: 'lawnSchedule',
        question: 'Service Schedule',
        type: 'text',
        placeholder: 'Weekly, bi-weekly, etc.',
        conditionalOn: { field: 'hasLawnService', value: true },
      },
      {
        id: 'hasPool',
        question: 'Pool?',
        type: 'yesno',
      },
      {
        id: 'poolType',
        question: 'Pool Type',
        type: 'select',
        options: ['In-ground', 'Above-ground', 'Hot tub only'],
        conditionalOn: { field: 'hasPool', value: true },
      },
      {
        id: 'poolVendor',
        question: 'Pool Service Company',
        type: 'text',
        conditionalOn: { field: 'hasPool', value: true },
      },
      {
        id: 'poolCost',
        question: 'Monthly Cost',
        type: 'currency',
        conditionalOn: { field: 'hasPool', value: true },
      },
      {
        id: 'roofAge',
        question: 'Roof Age (years)',
        type: 'number',
      },
      {
        id: 'roofType',
        question: 'Roof Type',
        type: 'select',
        options: ['Asphalt shingle', 'Metal', 'Tile', 'Slate', 'Flat/TPO'],
      },
      {
        id: 'gutterVendor',
        question: 'Gutter Cleaning Company',
        type: 'text',
      },
      {
        id: 'hasIrrigation',
        question: 'Irrigation System?',
        type: 'yesno',
      },
      {
        id: 'irrigationVendor',
        question: 'Irrigation Service Company',
        type: 'text',
        conditionalOn: { field: 'hasIrrigation', value: true },
      },
      {
        id: 'hasSeptic',
        question: 'Septic System?',
        type: 'yesno',
      },
      {
        id: 'septicVendor',
        question: 'Septic Pumping Company',
        type: 'text',
        conditionalOn: { field: 'hasSeptic', value: true },
      },
      {
        id: 'hasWell',
        question: 'Well Water?',
        type: 'yesno',
      },
      {
        id: 'wellVendor',
        question: 'Well Service Company',
        type: 'text',
        conditionalOn: { field: 'hasWell', value: true },
      },
    ],
  },
  {
    id: 'bills',
    title: 'Bills & Accounts',
    icon: '💳',
    description: 'All recurring payments Haven will manage',
    questions: [
      // Mortgage/Rent
      {
        id: 'hasMortgage',
        question: 'Mortgage or rent?',
        type: 'select',
        options: ['Mortgage', 'Rent', 'Own outright'],
      },
      {
        id: 'mortgageLender',
        question: 'Lender Name',
        type: 'text',
        conditionalOn: { field: 'hasMortgage', value: 'Mortgage' },
      },
      {
        id: 'mortgageAccount',
        question: 'Account/Loan Number',
        type: 'text',
        conditionalOn: { field: 'hasMortgage', value: 'Mortgage' },
      },
      {
        id: 'mortgagePayment',
        question: 'Monthly Payment',
        type: 'currency',
        conditionalOn: { field: 'hasMortgage', value: 'Mortgage' },
      },
      {
        id: 'mortgageDueDay',
        question: 'Due Date (day of month)',
        type: 'number',
        conditionalOn: { field: 'hasMortgage', value: 'Mortgage' },
      },
      // Utilities
      {
        id: 'electricProvider',
        question: 'Electric Provider',
        type: 'text',
      },
      {
        id: 'electricAccount',
        question: 'Account Number',
        type: 'text',
      },
      {
        id: 'electricAvgBill',
        question: 'Average Monthly Bill',
        type: 'currency',
      },
      {
        id: 'hasGas',
        question: 'Natural Gas Service?',
        type: 'yesno',
      },
      {
        id: 'gasProvider',
        question: 'Gas Provider',
        type: 'text',
        conditionalOn: { field: 'hasGas', value: true },
      },
      {
        id: 'gasAccount',
        question: 'Account Number',
        type: 'text',
        conditionalOn: { field: 'hasGas', value: true },
      },
      {
        id: 'waterProvider',
        question: 'Water/Sewer Provider',
        type: 'text',
      },
      {
        id: 'waterAccount',
        question: 'Account Number',
        type: 'text',
      },
      // Internet & Phone
      {
        id: 'internetProvider',
        question: 'Internet Provider',
        type: 'text',
      },
      {
        id: 'internetAccount',
        question: 'Account Number',
        type: 'text',
      },
      {
        id: 'internetCost',
        question: 'Monthly Cost',
        type: 'currency',
      },
      {
        id: 'cellProvider',
        question: 'Cell Phone Provider',
        type: 'text',
      },
      {
        id: 'cellAccount',
        question: 'Account Number',
        type: 'text',
      },
      {
        id: 'cellCost',
        question: 'Monthly Cost',
        type: 'currency',
      },
      // HOA
      {
        id: 'hasHoa',
        question: 'HOA?',
        type: 'yesno',
      },
      {
        id: 'hoaName',
        question: 'HOA Name',
        type: 'text',
        conditionalOn: { field: 'hasHoa', value: true },
      },
      {
        id: 'hoaAmount',
        question: 'HOA Amount',
        type: 'currency',
        conditionalOn: { field: 'hasHoa', value: true },
      },
      {
        id: 'hoaFrequency',
        question: 'Frequency',
        type: 'select',
        options: ['Monthly', 'Quarterly', 'Annually'],
        conditionalOn: { field: 'hasHoa', value: true },
      },
    ],
  },
  {
    id: 'insurance',
    title: 'Insurance',
    icon: '🛡️',
    description: 'Home, auto, umbrella policies',
    questions: [
      {
        id: 'homeInsuranceProvider',
        question: 'Home Insurance Provider',
        type: 'text',
      },
      {
        id: 'homeInsurancePolicy',
        question: 'Policy Number',
        type: 'text',
      },
      {
        id: 'homeInsurancePremium',
        question: 'Annual Premium',
        type: 'currency',
      },
      {
        id: 'homeInsuranceRenewal',
        question: 'Renewal Date',
        type: 'date',
      },
      {
        id: 'autoInsuranceProvider',
        question: 'Auto Insurance Provider',
        type: 'text',
      },
      {
        id: 'autoInsurancePolicy',
        question: 'Policy Number',
        type: 'text',
      },
      {
        id: 'autoInsurancePremium',
        question: 'Premium Amount',
        type: 'currency',
      },
      {
        id: 'autoInsuranceFrequency',
        question: 'Payment Frequency',
        type: 'select',
        options: ['Monthly', 'Semi-annually', 'Annually'],
      },
      {
        id: 'hasUmbrella',
        question: 'Umbrella Policy?',
        type: 'yesno',
      },
      {
        id: 'umbrellaProvider',
        question: 'Umbrella Provider',
        type: 'text',
        conditionalOn: { field: 'hasUmbrella', value: true },
      },
    ],
  },
  {
    id: 'subscriptions',
    title: 'Subscriptions & Services',
    icon: '📺',
    description: 'Streaming, software, recurring services',
    questions: [
      {
        id: 'subscriptions',
        question: 'Active Subscriptions',
        type: 'repeater',
        helpText: 'Netflix, Spotify, gym, etc.',
        fields: [
          { id: 'name', question: 'Service Name', type: 'text', required: true },
          { id: 'cost', question: 'Monthly Cost', type: 'currency' },
          { id: 'billedTo', question: 'Billed To', type: 'text', placeholder: 'Card ending in...' },
        ],
      },
    ],
  },
  {
    id: 'education',
    title: 'Education & Activities',
    icon: '🎓',
    description: 'School tuition, sports, lessons',
    questions: [
      {
        id: 'schoolTuitions',
        question: 'School Tuition Payments',
        type: 'repeater',
        fields: [
          { id: 'school', question: 'School Name', type: 'text', required: true },
          { id: 'child', question: 'For Which Child', type: 'text' },
          { id: 'amount', question: 'Payment Amount', type: 'currency' },
          { id: 'frequency', question: 'Frequency', type: 'select', options: ['Monthly', 'Quarterly', 'Semester', 'Annually'] },
        ],
      },
      {
        id: 'activities',
        question: 'Kids Activities & Lessons',
        type: 'repeater',
        fields: [
          { id: 'activity', question: 'Activity', type: 'text', required: true, placeholder: 'Soccer, Piano, etc.' },
          { id: 'child', question: 'For Which Child', type: 'text' },
          { id: 'organization', question: 'Organization', type: 'text' },
          { id: 'cost', question: 'Cost', type: 'currency' },
          { id: 'frequency', question: 'Frequency', type: 'select', options: ['Weekly', 'Monthly', 'Per Session', 'Seasonal'] },
        ],
      },
    ],
  },
  {
    id: 'other',
    title: 'Other Bills',
    icon: '📋',
    description: 'Any other recurring payments',
    questions: [
      {
        id: 'otherBills',
        question: 'Other Recurring Bills',
        type: 'repeater',
        fields: [
          { id: 'name', question: 'Bill Name', type: 'text', required: true },
          { id: 'payee', question: 'Payee', type: 'text' },
          { id: 'account', question: 'Account Number', type: 'text' },
          { id: 'amount', question: 'Amount', type: 'currency' },
          { id: 'frequency', question: 'Frequency', type: 'select', options: ['Weekly', 'Monthly', 'Quarterly', 'Annually'] },
        ],
      },
    ],
  },
];

// ===========================================================================
// HELPER FUNCTIONS
// ===========================================================================

export function calculateSectionProgress(
  sectionId: string,
  formData: Record<string, any>
): number {
  const section = intakeSections.find((s) => s.id === sectionId);
  if (!section) return 0;

  const sectionData = formData[sectionId] || {};
  let totalFields = 0;
  let filledFields = 0;

  for (const question of section.questions) {
    // Skip conditional questions if condition not met
    if (question.conditionalOn) {
      const conditionValue = sectionData[question.conditionalOn.field];
      if (conditionValue !== question.conditionalOn.value) continue;
    }

    if (question.type === 'repeater') {
      // For repeaters, count as filled if at least one item exists
      const items = sectionData[question.id] || [];
      totalFields += 1;
      if (items.length > 0) filledFields += 1;
    } else if (question.required) {
      totalFields += 1;
      if (sectionData[question.id] !== undefined && sectionData[question.id] !== '') {
        filledFields += 1;
      }
    }
  }

  if (totalFields === 0) return 100;
  return Math.round((filledFields / totalFields) * 100);
}

export function calculateMonthlyFunding(formData: Record<string, any>): number {
  let total = 0;

  // Bills section
  const bills = formData.bills || {};
  if (bills.mortgagePayment) total += parseFloat(bills.mortgagePayment) || 0;
  if (bills.electricAvgBill) total += parseFloat(bills.electricAvgBill) || 0;
  if (bills.internetCost) total += parseFloat(bills.internetCost) || 0;
  if (bills.cellCost) total += parseFloat(bills.cellCost) || 0;

  // HOA - convert to monthly if needed
  if (bills.hoaAmount) {
    const hoaAmount = parseFloat(bills.hoaAmount) || 0;
    switch (bills.hoaFrequency) {
      case 'Quarterly':
        total += hoaAmount / 3;
        break;
      case 'Annually':
        total += hoaAmount / 12;
        break;
      default:
        total += hoaAmount;
    }
  }

  // Exterior - lawn, pool
  const exterior = formData.exterior || {};
  if (exterior.lawnCost) total += parseFloat(exterior.lawnCost) || 0;
  if (exterior.poolCost) total += parseFloat(exterior.poolCost) || 0;

  // Systems - security
  const systems = formData.systems || {};
  if (systems.securityCost) total += parseFloat(systems.securityCost) || 0;

  // Insurance (annualized to monthly)
  const insurance = formData.insurance || {};
  if (insurance.homeInsurancePremium) {
    total += (parseFloat(insurance.homeInsurancePremium) || 0) / 12;
  }
  if (insurance.autoInsurancePremium) {
    const premium = parseFloat(insurance.autoInsurancePremium) || 0;
    switch (insurance.autoInsuranceFrequency) {
      case 'Semi-annually':
        total += premium / 6;
        break;
      case 'Annually':
        total += premium / 12;
        break;
      default:
        total += premium;
    }
  }

  // Subscriptions
  const subs = formData.subscriptions?.subscriptions || [];
  for (const sub of subs) {
    if (sub.cost) total += parseFloat(sub.cost) || 0;
  }

  // Education
  const edu = formData.education || {};
  for (const tuition of edu.schoolTuitions || []) {
    if (tuition.amount) {
      const amount = parseFloat(tuition.amount) || 0;
      switch (tuition.frequency) {
        case 'Quarterly':
          total += amount / 3;
          break;
        case 'Semester':
          total += amount / 6;
          break;
        case 'Annually':
          total += amount / 12;
          break;
        default:
          total += amount;
      }
    }
  }
  for (const activity of edu.activities || []) {
    if (activity.cost) {
      const cost = parseFloat(activity.cost) || 0;
      switch (activity.frequency) {
        case 'Weekly':
          total += cost * 4.33;
          break;
        case 'Seasonal':
          total += cost / 3;
          break;
        default:
          total += cost;
      }
    }
  }

  // Other bills
  for (const bill of formData.other?.otherBills || []) {
    if (bill.amount) {
      const amount = parseFloat(bill.amount) || 0;
      switch (bill.frequency) {
        case 'Weekly':
          total += amount * 4.33;
          break;
        case 'Quarterly':
          total += amount / 3;
          break;
        case 'Annually':
          total += amount / 12;
          break;
        default:
          total += amount;
      }
    }
  }

  // Add 10% buffer
  total *= 1.1;

  return Math.round(total * 100) / 100;
}
