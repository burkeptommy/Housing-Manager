import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';
import type {
  PropertyType,
  VendorCategory,
  BillingFrequency,
  PaymentResponsibility,
  MaintenanceTask,
  HouseholdVendor,
  SubscriptionPlan,
  PropertyFeatures,
} from '@haven/core';

// ============================================================================
// TYPES
// ============================================================================

export interface HomeBasicsData {
  name: string;
  propertyType: PropertyType;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  postalCode: string;
  yearBuilt?: number;
  squareFeet?: number;
  bedrooms?: number;
  bathrooms?: number;
  features: PropertyFeatures;
}

export interface BillEntry {
  category: VendorCategory;
  vendorName: string;
  accountNumber: string;
  typicalAmount: number | null;
  billingFrequency: BillingFrequency;
  nextDueDate: string;
  paymentResponsibility: PaymentResponsibility;
}

export interface TaskSelection {
  taskId: string;
  keep: boolean;
  vendorId?: string;
  dueDate?: string;
}

// ============================================================================
// CONTEXT
// ============================================================================

interface OnboardingContextValue {
  // State
  householdId: string | null;
  homeBasics: HomeBasicsData | null;
  bills: BillEntry[];
  vendors: HouseholdVendor[];
  maintenanceTasks: MaintenanceTask[];
  taskSelections: TaskSelection[];
  selectedPlan: SubscriptionPlan | null;

  // Actions
  setHouseholdId: (id: string) => void;
  setHomeBasics: (data: HomeBasicsData) => void;
  setBills: (bills: BillEntry[]) => void;
  setVendors: (vendors: HouseholdVendor[]) => void;
  setMaintenanceTasks: (tasks: MaintenanceTask[]) => void;
  setTaskSelections: (selections: TaskSelection[]) => void;
  setSelectedPlan: (plan: SubscriptionPlan) => void;
  reset: () => void;
}

const OnboardingContext = createContext<OnboardingContextValue | null>(null);

// ============================================================================
// PROVIDER
// ============================================================================

const DEFAULT_FEATURES: PropertyFeatures = {
  hasCentralAc: false,
  hasGasHeat: false,
  hasOilHeat: false,
  hasFireplace: false,
  hasSeptic: false,
  hasWellWater: false,
  hasPool: false,
  hasGenerator: false,
  hasLawn: false,
  hasDriveway: false,
};

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [householdId, setHouseholdId] = useState<string | null>(null);
  const [homeBasics, setHomeBasics] = useState<HomeBasicsData | null>(null);
  const [bills, setBills] = useState<BillEntry[]>([]);
  const [vendors, setVendors] = useState<HouseholdVendor[]>([]);
  const [maintenanceTasks, setMaintenanceTasks] = useState<MaintenanceTask[]>([]);
  const [taskSelections, setTaskSelections] = useState<TaskSelection[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);

  const reset = useCallback(() => {
    setHouseholdId(null);
    setHomeBasics(null);
    setBills([]);
    setVendors([]);
    setMaintenanceTasks([]);
    setTaskSelections([]);
    setSelectedPlan(null);
  }, []);

  return (
    <OnboardingContext.Provider
      value={{
        householdId,
        homeBasics,
        bills,
        vendors,
        maintenanceTasks,
        taskSelections,
        selectedPlan,
        setHouseholdId,
        setHomeBasics,
        setBills,
        setVendors,
        setMaintenanceTasks,
        setTaskSelections,
        setSelectedPlan,
        reset,
      }}
    >
      {children}
    </OnboardingContext.Provider>
  );
}

// ============================================================================
// HOOK
// ============================================================================

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (!context) {
    throw new Error('useOnboarding must be used within an OnboardingProvider');
  }
  return context;
}
