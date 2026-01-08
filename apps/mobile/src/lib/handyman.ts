import { Ionicons } from '@expo/vector-icons';

// =============================================================================
// ON-DEMAND HANDYMAN BOOKING SYSTEM
// =============================================================================
// Pre-defined handyman services for the $50/visit handyman program.
// Most common tasks are included in the base price, with add-ons available.

export interface HandymanService {
  id: string;
  name: string;
  description: string;
  estimatedTime: string;
  included: boolean; // Included in $50 base price
  additionalCost?: number;
  icon: keyof typeof Ionicons.glyphMap;
  category: HandymanCategory;
}

export type HandymanCategory =
  | 'hvac'
  | 'plumbing'
  | 'electrical'
  | 'carpentry'
  | 'exterior'
  | 'general';

export interface HandymanBooking {
  id: string;
  services: string[]; // Service IDs
  scheduledDate: string;
  scheduledTime: string;
  status: HandymanBookingStatus;
  totalCost: number;
  notes?: string;
  createdAt: string;
}

export type HandymanBookingStatus =
  | 'pending'
  | 'confirmed'
  | 'in_progress'
  | 'completed'
  | 'cancelled';

export interface TimeSlot {
  id: string;
  label: string;
  timeRange: string;
  available: boolean;
}

// =============================================================================
// CONSTANTS
// =============================================================================

export const HANDYMAN_BASE_PRICE = 50;

export const HANDYMAN_CATEGORY_INFO: Record<HandymanCategory, {
  label: string;
  icon: keyof typeof Ionicons.glyphMap;
}> = {
  hvac: { label: 'HVAC', icon: 'thermometer-outline' },
  plumbing: { label: 'Plumbing', icon: 'water-outline' },
  electrical: { label: 'Electrical', icon: 'flash-outline' },
  carpentry: { label: 'Carpentry', icon: 'hammer-outline' },
  exterior: { label: 'Exterior', icon: 'home-outline' },
  general: { label: 'General', icon: 'construct-outline' },
};

export const TIME_SLOTS: TimeSlot[] = [
  { id: 'morning-early', label: 'Early Morning', timeRange: '8:00 AM - 10:00 AM', available: true },
  { id: 'morning-late', label: 'Late Morning', timeRange: '10:00 AM - 12:00 PM', available: true },
  { id: 'afternoon-early', label: 'Early Afternoon', timeRange: '12:00 PM - 2:00 PM', available: true },
  { id: 'afternoon-late', label: 'Late Afternoon', timeRange: '2:00 PM - 4:00 PM', available: true },
  { id: 'evening', label: 'Evening', timeRange: '4:00 PM - 6:00 PM', available: true },
];

// =============================================================================
// HANDYMAN SERVICES
// =============================================================================

export const HANDYMAN_SERVICES: HandymanService[] = [
  // ========== HVAC ==========
  {
    id: 'filter-change',
    name: 'Change HVAC Filters',
    description: 'Replace all air filters (filters provided)',
    estimatedTime: '30 min',
    included: true,
    icon: 'filter-outline',
    category: 'hvac',
  },
  {
    id: 'pilot-light',
    name: 'Relight Furnace Pilot',
    description: 'Safely relight pilot light on furnace or water heater',
    estimatedTime: '15 min',
    included: true,
    icon: 'flame-outline',
    category: 'hvac',
  },
  {
    id: 'thermostat-install',
    name: 'Install Thermostat',
    description: 'Replace or install new thermostat (device not included)',
    estimatedTime: '45 min',
    included: true,
    icon: 'thermometer-outline',
    category: 'hvac',
  },

  // ========== SAFETY ==========
  {
    id: 'smoke-detector',
    name: 'Test/Replace Smoke Detector Batteries',
    description: 'Test all units and replace batteries as needed',
    estimatedTime: '30 min',
    included: true,
    icon: 'alert-circle-outline',
    category: 'electrical',
  },
  {
    id: 'co-detector',
    name: 'Install CO Detector',
    description: 'Install carbon monoxide detector (device not included)',
    estimatedTime: '20 min',
    included: true,
    icon: 'shield-checkmark-outline',
    category: 'electrical',
  },

  // ========== PLUMBING ==========
  {
    id: 'faucet-repair',
    name: 'Minor Faucet Repair',
    description: 'Fix dripping faucet, replace washers',
    estimatedTime: '30 min',
    included: true,
    icon: 'water-outline',
    category: 'plumbing',
  },
  {
    id: 'caulking',
    name: 'Re-caulk Bathroom/Kitchen',
    description: 'Replace old caulk around tub, shower, or sink',
    estimatedTime: '1 hour',
    included: true,
    icon: 'water',
    category: 'plumbing',
  },
  {
    id: 'toilet-repair',
    name: 'Toilet Minor Repair',
    description: 'Fix running toilet, replace flapper or fill valve',
    estimatedTime: '30 min',
    included: true,
    icon: 'water-outline',
    category: 'plumbing',
  },
  {
    id: 'showerhead',
    name: 'Replace Showerhead',
    description: 'Install new showerhead (fixture not included)',
    estimatedTime: '15 min',
    included: true,
    icon: 'rainy-outline',
    category: 'plumbing',
  },

  // ========== ELECTRICAL ==========
  {
    id: 'outlet-cover',
    name: 'Replace Outlet/Switch Covers',
    description: 'Replace broken or outdated covers',
    estimatedTime: '15 min',
    included: true,
    icon: 'flash-outline',
    category: 'electrical',
  },
  {
    id: 'light-fixture',
    name: 'Replace Light Fixture',
    description: 'Install new light fixture (fixture not included)',
    estimatedTime: '45 min',
    included: true,
    icon: 'bulb-outline',
    category: 'electrical',
  },
  {
    id: 'ceiling-fan',
    name: 'Install Ceiling Fan',
    description: 'Replace existing fixture with ceiling fan',
    estimatedTime: '1-2 hours',
    included: false,
    additionalCost: 35,
    icon: 'sync-outline',
    category: 'electrical',
  },

  // ========== CARPENTRY ==========
  {
    id: 'drywall-patch',
    name: 'Small Drywall Repair',
    description: 'Patch small holes (up to 4 inches)',
    estimatedTime: '45 min',
    included: true,
    icon: 'construct-outline',
    category: 'carpentry',
  },
  {
    id: 'door-adjustment',
    name: 'Door Adjustment',
    description: 'Fix sticking doors, adjust hinges',
    estimatedTime: '30 min',
    included: true,
    icon: 'exit-outline',
    category: 'carpentry',
  },
  {
    id: 'cabinet-repair',
    name: 'Cabinet Door/Drawer Repair',
    description: 'Fix loose hinges, drawer slides, or handles',
    estimatedTime: '30 min',
    included: true,
    icon: 'cube-outline',
    category: 'carpentry',
  },
  {
    id: 'shelf-install',
    name: 'Mount Shelf or TV',
    description: 'Securely mount shelf, TV, or heavy items',
    estimatedTime: '30-45 min',
    included: true,
    icon: 'tv-outline',
    category: 'carpentry',
  },
  {
    id: 'furniture-assembly',
    name: 'Furniture Assembly',
    description: 'Assemble flat-pack furniture',
    estimatedTime: '1-2 hours',
    included: false,
    additionalCost: 25,
    icon: 'bed-outline',
    category: 'carpentry',
  },

  // ========== EXTERIOR ==========
  {
    id: 'weather-strip',
    name: 'Replace Weather Stripping',
    description: 'Replace worn door/window weather stripping',
    estimatedTime: '45 min',
    included: true,
    icon: 'sunny-outline',
    category: 'exterior',
  },
  {
    id: 'gutter-clean',
    name: 'Clean Gutters',
    description: 'Clean debris from gutters and downspouts',
    estimatedTime: '1-2 hours',
    included: false,
    additionalCost: 50,
    icon: 'rainy-outline',
    category: 'exterior',
  },
  {
    id: 'pressure-wash',
    name: 'Pressure Wash Patio/Deck',
    description: 'Power wash outdoor surfaces',
    estimatedTime: '1-2 hours',
    included: false,
    additionalCost: 75,
    icon: 'water-outline',
    category: 'exterior',
  },
  {
    id: 'screen-repair',
    name: 'Window/Door Screen Repair',
    description: 'Repair or replace torn screens',
    estimatedTime: '30 min',
    included: true,
    icon: 'grid-outline',
    category: 'exterior',
  },

  // ========== GENERAL ==========
  {
    id: 'picture-hanging',
    name: 'Hang Pictures/Mirrors',
    description: 'Securely hang art, mirrors, or decor',
    estimatedTime: '30 min',
    included: true,
    icon: 'image-outline',
    category: 'general',
  },
  {
    id: 'doorbell-install',
    name: 'Install Doorbell',
    description: 'Install wired or wireless doorbell (device not included)',
    estimatedTime: '30 min',
    included: true,
    icon: 'notifications-outline',
    category: 'general',
  },
  {
    id: 'dryer-vent',
    name: 'Clean Dryer Vent',
    description: 'Clean lint from dryer vent hose and exhaust',
    estimatedTime: '45 min',
    included: true,
    icon: 'flame-outline',
    category: 'general',
  },
];

// =============================================================================
// HELPER FUNCTIONS
// =============================================================================

/**
 * Get services by category
 */
export function getServicesByCategory(category: HandymanCategory): HandymanService[] {
  return HANDYMAN_SERVICES.filter(s => s.category === category);
}

/**
 * Get included services (no additional cost)
 */
export function getIncludedServices(): HandymanService[] {
  return HANDYMAN_SERVICES.filter(s => s.included);
}

/**
 * Get add-on services (additional cost)
 */
export function getAddOnServices(): HandymanService[] {
  return HANDYMAN_SERVICES.filter(s => !s.included);
}

/**
 * Get a service by ID
 */
export function getServiceById(id: string): HandymanService | undefined {
  return HANDYMAN_SERVICES.find(s => s.id === id);
}

/**
 * Calculate total cost for selected services
 */
export function calculateTotalCost(serviceIds: string[]): number {
  if (serviceIds.length === 0) return 0;

  let total = HANDYMAN_BASE_PRICE;

  serviceIds.forEach(id => {
    const service = getServiceById(id);
    if (service?.additionalCost) {
      total += service.additionalCost;
    }
  });

  return total;
}

/**
 * Calculate estimated total time for selected services
 */
export function calculateEstimatedTime(serviceIds: string[]): string {
  if (serviceIds.length === 0) return '0 min';

  let totalMinutes = 0;

  serviceIds.forEach(id => {
    const service = getServiceById(id);
    if (service) {
      // Parse estimated time
      const time = service.estimatedTime;
      if (time.includes('hour')) {
        const match = time.match(/(\d+)/);
        if (match) {
          // If range like "1-2 hours", use the higher number
          const nums = time.match(/\d+/g);
          const hours = nums ? parseInt(nums[nums.length - 1]) : 1;
          totalMinutes += hours * 60;
        }
      } else if (time.includes('min')) {
        const match = time.match(/(\d+)/);
        if (match) {
          totalMinutes += parseInt(match[1]);
        }
      }
    }
  });

  if (totalMinutes >= 60) {
    const hours = Math.floor(totalMinutes / 60);
    const mins = totalMinutes % 60;
    return mins > 0 ? `${hours} hr ${mins} min` : `${hours} hr`;
  }

  return `${totalMinutes} min`;
}

/**
 * Get available dates for booking (next 14 days, excluding Sundays)
 */
export function getAvailableDates(): Date[] {
  const dates: Date[] = [];
  const today = new Date();

  for (let i = 1; i <= 14; i++) {
    const date = new Date(today);
    date.setDate(today.getDate() + i);

    // Exclude Sundays (0 = Sunday)
    if (date.getDay() !== 0) {
      dates.push(date);
    }
  }

  return dates;
}

/**
 * Format date for display
 */
export function formatBookingDate(date: Date): string {
  const today = new Date();
  const tomorrow = new Date(today);
  tomorrow.setDate(today.getDate() + 1);

  if (date.toDateString() === tomorrow.toDateString()) {
    return 'Tomorrow';
  }

  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  return `${days[date.getDay()]}, ${months[date.getMonth()]} ${date.getDate()}`;
}
