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
import type { PropertyData } from '../types/onboarding';

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
  // State (existing)
  householdId: string | null;
  homeBasics: HomeBasicsData | null;
  bills: BillEntry[];
  vendors: HouseholdVendor[];
  maintenanceTasks: MaintenanceTask[];
  taskSelections: TaskSelection[];
  selectedPlan: SubscriptionPlan | null;

  // State (new - ATTOM integration)
  step: 'address' | 'property' | 'confirm' | 'bank' | 'plan' | 'complete';
  propertyData: PropertyData | null;
  isLoadingAttom: boolean;
  attomError: string | null;

  // Actions (existing)
  setHouseholdId: (id: string) => void;
  setHomeBasics: (data: HomeBasicsData) => void;
  setBills: (bills: BillEntry[]) => void;
  setVendors: (vendors: HouseholdVendor[]) => void;
  setMaintenanceTasks: (tasks: MaintenanceTask[]) => void;
  setTaskSelections: (selections: TaskSelection[]) => void;
  setSelectedPlan: (plan: SubscriptionPlan) => void;
  reset: () => void;

  // Actions (new - ATTOM integration)
  setStep: (step: OnboardingContextValue['step']) => void;
  setPropertyData: (data: PropertyData | null) => void;
  setIsLoadingAttom: (loading: boolean) => void;
  setAttomError: (error: string | null) => void;
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
  // Existing state
  const [householdId, setHouseholdIdState] = useState<string | null>(null);
  const [homeBasics, setHomeBasics] = useState<HomeBasicsData | null>(null);
  const [bills, setBills] = useState<BillEntry[]>([]);
  const [vendors, setVendors] = useState<HouseholdVendor[]>([]);
  const [maintenanceTasks, setMaintenanceTasks] = useState<MaintenanceTask[]>([]);
  const [taskSelections, setTaskSelections] = useState<TaskSelection[]>([]);
  const [selectedPlan, setSelectedPlan] = useState<SubscriptionPlan | null>(null);

  // New state for ATTOM integration
  const [step, setStep] = useState<OnboardingContextValue['step']>('address');
  const [propertyData, setPropertyData] = useState<PropertyData | null>(null);
  const [isLoadingAttom, setIsLoadingAttom] = useState(false);
  const [attomError, setAttomError] = useState<string | null>(null);

  const setHouseholdId = useCallback((id: string) => {
    setHouseholdIdState(id);
  }, []);

  const reset = useCallback(() => {
    // Reset existing state
    setHouseholdIdState(null);
    setHomeBasics(null);
    setBills([]);
    setVendors([]);
    setMaintenanceTasks([]);
    setTaskSelections([]);
    setSelectedPlan(null);
    // Reset new state
    setStep('address');
    setPropertyData(null);
    setIsLoadingAttom(false);
    setAttomError(null);
  }, []);

  return (
    <OnboardingContext.Provider
      value={{
        // Existing state
        householdId,
        homeBasics,
        bills,
        vendors,
        maintenanceTasks,
        taskSelections,
        selectedPlan,
        // New state
        step,
        propertyData,
        isLoadingAttom,
        attomError,
        // Existing actions
        setHouseholdId,
        setHomeBasics,
        setBills,
        setVendors,
        setMaintenanceTasks,
        setTaskSelections,
        setSelectedPlan,
        reset,
        // New actions
        setStep,
        setPropertyData,
        setIsLoadingAttom,
        setAttomError,
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
