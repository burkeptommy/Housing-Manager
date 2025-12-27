'use client';

import React, { createContext, useContext, useReducer, useEffect, ReactNode } from 'react';
import {
  OnboardingData,
  ServiceTier,
  OnboardingPath,
  OnboardingStatus,
  PropertyDetails,
  PropertyEnrichmentData,
  Bill,
  HomeSystem,
  Appliance,
  FamilyMember,
  Vehicle,
  Pet,
  HouseholdStaff,
} from '@/types/onboarding';

// ============================================
// INITIAL STATE
// ============================================

const initialOnboardingData: OnboardingData = {
  tier: 'haven',
  path: 'self_serve',
  status: 'started',
  startedAt: new Date().toISOString(),
  steps: {
    property: false,
    bills: false,
    systems: false,
    family: false,
    review: false,
  },
  property: null,
  propertyEnrichment: null,
  bills: [],
  systems: [],
  appliances: [],
  familyMembers: [],
  vehicles: [],
  pets: [],
  staff: [],
};

// ============================================
// ACTION TYPES
// ============================================

type OnboardingAction =
  | { type: 'SET_TIER'; payload: ServiceTier }
  | { type: 'SET_PATH'; payload: OnboardingPath }
  | { type: 'SET_STATUS'; payload: OnboardingStatus }
  | { type: 'SET_PROPERTY'; payload: PropertyDetails }
  | { type: 'SET_PROPERTY_ENRICHMENT'; payload: PropertyEnrichmentData | null }
  | { type: 'ADD_BILL'; payload: Bill }
  | { type: 'UPDATE_BILL'; payload: Bill }
  | { type: 'REMOVE_BILL'; payload: string }
  | { type: 'SET_BILLS'; payload: Bill[] }
  | { type: 'ADD_SYSTEM'; payload: HomeSystem }
  | { type: 'UPDATE_SYSTEM'; payload: HomeSystem }
  | { type: 'REMOVE_SYSTEM'; payload: string }
  | { type: 'SET_SYSTEMS'; payload: HomeSystem[] }
  | { type: 'ADD_APPLIANCE'; payload: Appliance }
  | { type: 'UPDATE_APPLIANCE'; payload: Appliance }
  | { type: 'REMOVE_APPLIANCE'; payload: string }
  | { type: 'SET_APPLIANCES'; payload: Appliance[] }
  | { type: 'ADD_FAMILY_MEMBER'; payload: FamilyMember }
  | { type: 'UPDATE_FAMILY_MEMBER'; payload: FamilyMember }
  | { type: 'REMOVE_FAMILY_MEMBER'; payload: string }
  | { type: 'SET_FAMILY_MEMBERS'; payload: FamilyMember[] }
  | { type: 'ADD_VEHICLE'; payload: Vehicle }
  | { type: 'UPDATE_VEHICLE'; payload: Vehicle }
  | { type: 'REMOVE_VEHICLE'; payload: string }
  | { type: 'SET_VEHICLES'; payload: Vehicle[] }
  | { type: 'ADD_PET'; payload: Pet }
  | { type: 'UPDATE_PET'; payload: Pet }
  | { type: 'REMOVE_PET'; payload: string }
  | { type: 'SET_PETS'; payload: Pet[] }
  | { type: 'ADD_STAFF'; payload: HouseholdStaff }
  | { type: 'UPDATE_STAFF'; payload: HouseholdStaff }
  | { type: 'REMOVE_STAFF'; payload: string }
  | { type: 'SET_STAFF'; payload: HouseholdStaff[] }
  | { type: 'COMPLETE_STEP'; payload: keyof OnboardingData['steps'] }
  | { type: 'SET_SCHEDULED_CALL'; payload: string }
  | { type: 'SET_SCHEDULED_VISIT'; payload: string }
  | { type: 'SET_ACTIVATION_CALL'; payload: string }
  | { type: 'RESET' }
  | { type: 'LOAD_STATE'; payload: OnboardingData };

// ============================================
// REDUCER
// ============================================

function onboardingReducer(state: OnboardingData, action: OnboardingAction): OnboardingData {
  switch (action.type) {
    case 'SET_TIER':
      return { ...state, tier: action.payload };

    case 'SET_PATH':
      return { ...state, path: action.payload, status: 'path_selected' };

    case 'SET_STATUS':
      return { ...state, status: action.payload };

    case 'SET_PROPERTY':
      return { ...state, property: action.payload };

    case 'SET_PROPERTY_ENRICHMENT':
      return { ...state, propertyEnrichment: action.payload };

    case 'ADD_BILL':
      return { ...state, bills: [...state.bills, action.payload] };

    case 'UPDATE_BILL':
      return {
        ...state,
        bills: state.bills.map((b) => (b.id === action.payload.id ? action.payload : b)),
      };

    case 'REMOVE_BILL':
      return { ...state, bills: state.bills.filter((b) => b.id !== action.payload) };

    case 'SET_BILLS':
      return { ...state, bills: action.payload };

    case 'ADD_SYSTEM':
      return { ...state, systems: [...state.systems, action.payload] };

    case 'UPDATE_SYSTEM':
      return {
        ...state,
        systems: state.systems.map((s) => (s.id === action.payload.id ? action.payload : s)),
      };

    case 'REMOVE_SYSTEM':
      return { ...state, systems: state.systems.filter((s) => s.id !== action.payload) };

    case 'SET_SYSTEMS':
      return { ...state, systems: action.payload };

    case 'ADD_APPLIANCE':
      return { ...state, appliances: [...state.appliances, action.payload] };

    case 'UPDATE_APPLIANCE':
      return {
        ...state,
        appliances: state.appliances.map((a) => (a.id === action.payload.id ? action.payload : a)),
      };

    case 'REMOVE_APPLIANCE':
      return { ...state, appliances: state.appliances.filter((a) => a.id !== action.payload) };

    case 'SET_APPLIANCES':
      return { ...state, appliances: action.payload };

    case 'ADD_FAMILY_MEMBER':
      return { ...state, familyMembers: [...state.familyMembers, action.payload] };

    case 'UPDATE_FAMILY_MEMBER':
      return {
        ...state,
        familyMembers: state.familyMembers.map((m) =>
          m.id === action.payload.id ? action.payload : m
        ),
      };

    case 'REMOVE_FAMILY_MEMBER':
      return { ...state, familyMembers: state.familyMembers.filter((m) => m.id !== action.payload) };

    case 'SET_FAMILY_MEMBERS':
      return { ...state, familyMembers: action.payload };

    case 'ADD_VEHICLE':
      return { ...state, vehicles: [...state.vehicles, action.payload] };

    case 'UPDATE_VEHICLE':
      return {
        ...state,
        vehicles: state.vehicles.map((v) => (v.id === action.payload.id ? action.payload : v)),
      };

    case 'REMOVE_VEHICLE':
      return { ...state, vehicles: state.vehicles.filter((v) => v.id !== action.payload) };

    case 'SET_VEHICLES':
      return { ...state, vehicles: action.payload };

    case 'ADD_PET':
      return { ...state, pets: [...state.pets, action.payload] };

    case 'UPDATE_PET':
      return {
        ...state,
        pets: state.pets.map((p) => (p.id === action.payload.id ? action.payload : p)),
      };

    case 'REMOVE_PET':
      return { ...state, pets: state.pets.filter((p) => p.id !== action.payload) };

    case 'SET_PETS':
      return { ...state, pets: action.payload };

    case 'ADD_STAFF':
      return { ...state, staff: [...state.staff, action.payload] };

    case 'UPDATE_STAFF':
      return {
        ...state,
        staff: state.staff.map((s) => (s.id === action.payload.id ? action.payload : s)),
      };

    case 'REMOVE_STAFF':
      return { ...state, staff: state.staff.filter((s) => s.id !== action.payload) };

    case 'SET_STAFF':
      return { ...state, staff: action.payload };

    case 'COMPLETE_STEP':
      return {
        ...state,
        steps: { ...state.steps, [action.payload]: true },
      };

    case 'SET_SCHEDULED_CALL':
      return { ...state, scheduledCallAt: action.payload };

    case 'SET_SCHEDULED_VISIT':
      return { ...state, scheduledVisitAt: action.payload };

    case 'SET_ACTIVATION_CALL':
      return { ...state, activationCallAt: action.payload };

    case 'RESET':
      return { ...initialOnboardingData, startedAt: new Date().toISOString() };

    case 'LOAD_STATE':
      return action.payload;

    default:
      return state;
  }
}

// ============================================
// CONTEXT
// ============================================

interface OnboardingContextType {
  data: OnboardingData;
  dispatch: React.Dispatch<OnboardingAction>;

  // Helper functions
  setTier: (tier: ServiceTier) => void;
  setPath: (path: OnboardingPath) => void;
  setProperty: (property: PropertyDetails) => void;
  setPropertyEnrichment: (enrichment: PropertyEnrichmentData | null) => void;
  addBill: (bill: Bill) => void;
  updateBill: (bill: Bill) => void;
  removeBill: (id: string) => void;
  addSystem: (system: HomeSystem) => void;
  updateSystem: (system: HomeSystem) => void;
  removeSystem: (id: string) => void;
  addAppliance: (appliance: Appliance) => void;
  updateAppliance: (appliance: Appliance) => void;
  removeAppliance: (id: string) => void;
  addFamilyMember: (member: FamilyMember) => void;
  updateFamilyMember: (member: FamilyMember) => void;
  removeFamilyMember: (id: string) => void;
  addVehicle: (vehicle: Vehicle) => void;
  updateVehicle: (vehicle: Vehicle) => void;
  removeVehicle: (id: string) => void;
  addPet: (pet: Pet) => void;
  updatePet: (pet: Pet) => void;
  removePet: (id: string) => void;
  addStaff: (staff: HouseholdStaff) => void;
  updateStaff: (staff: HouseholdStaff) => void;
  removeStaff: (id: string) => void;
  completeStep: (step: keyof OnboardingData['steps']) => void;
  getCompletedSteps: () => string[];
  getCurrentStep: () => string;
  getNextStep: () => string | null;
  calculateMonthlyTotal: () => number;
  reset: () => void;
  clearOnboardingData: () => void;
}

const OnboardingContext = createContext<OnboardingContextType | undefined>(undefined);

// ============================================
// PROVIDER
// ============================================

const STORAGE_KEY = 'haven_onboarding_data';

export function OnboardingProvider({ children }: { children: ReactNode }) {
  const [data, dispatch] = useReducer(onboardingReducer, initialOnboardingData);

  // Load from localStorage on mount
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        try {
          const parsed = JSON.parse(saved);
          dispatch({ type: 'LOAD_STATE', payload: parsed });
        } catch (e) {
          console.error('Failed to load onboarding state:', e);
        }
      }
    }
  }, []);

  // Save to localStorage on change
  useEffect(() => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    }
  }, [data]);

  // Helper functions
  const setTier = (tier: ServiceTier) => dispatch({ type: 'SET_TIER', payload: tier });
  const setPath = (path: OnboardingPath) => dispatch({ type: 'SET_PATH', payload: path });
  const setProperty = (property: PropertyDetails) =>
    dispatch({ type: 'SET_PROPERTY', payload: property });
  const setPropertyEnrichment = (enrichment: PropertyEnrichmentData | null) =>
    dispatch({ type: 'SET_PROPERTY_ENRICHMENT', payload: enrichment });

  const addBill = (bill: Bill) => dispatch({ type: 'ADD_BILL', payload: bill });
  const updateBill = (bill: Bill) => dispatch({ type: 'UPDATE_BILL', payload: bill });
  const removeBill = (id: string) => dispatch({ type: 'REMOVE_BILL', payload: id });

  const addSystem = (system: HomeSystem) => dispatch({ type: 'ADD_SYSTEM', payload: system });
  const updateSystem = (system: HomeSystem) => dispatch({ type: 'UPDATE_SYSTEM', payload: system });
  const removeSystem = (id: string) => dispatch({ type: 'REMOVE_SYSTEM', payload: id });

  const addAppliance = (appliance: Appliance) =>
    dispatch({ type: 'ADD_APPLIANCE', payload: appliance });
  const updateAppliance = (appliance: Appliance) =>
    dispatch({ type: 'UPDATE_APPLIANCE', payload: appliance });
  const removeAppliance = (id: string) => dispatch({ type: 'REMOVE_APPLIANCE', payload: id });

  const addFamilyMember = (member: FamilyMember) =>
    dispatch({ type: 'ADD_FAMILY_MEMBER', payload: member });
  const updateFamilyMember = (member: FamilyMember) =>
    dispatch({ type: 'UPDATE_FAMILY_MEMBER', payload: member });
  const removeFamilyMember = (id: string) =>
    dispatch({ type: 'REMOVE_FAMILY_MEMBER', payload: id });

  const addVehicle = (vehicle: Vehicle) => dispatch({ type: 'ADD_VEHICLE', payload: vehicle });
  const updateVehicle = (vehicle: Vehicle) => dispatch({ type: 'UPDATE_VEHICLE', payload: vehicle });
  const removeVehicle = (id: string) => dispatch({ type: 'REMOVE_VEHICLE', payload: id });

  const addPet = (pet: Pet) => dispatch({ type: 'ADD_PET', payload: pet });
  const updatePet = (pet: Pet) => dispatch({ type: 'UPDATE_PET', payload: pet });
  const removePet = (id: string) => dispatch({ type: 'REMOVE_PET', payload: id });

  const addStaff = (staff: HouseholdStaff) => dispatch({ type: 'ADD_STAFF', payload: staff });
  const updateStaff = (staff: HouseholdStaff) => dispatch({ type: 'UPDATE_STAFF', payload: staff });
  const removeStaff = (id: string) => dispatch({ type: 'REMOVE_STAFF', payload: id });

  const completeStep = (step: keyof OnboardingData['steps']) =>
    dispatch({ type: 'COMPLETE_STEP', payload: step });

  const getCompletedSteps = () => {
    return Object.entries(data.steps)
      .filter(([, completed]) => completed)
      .map(([step]) => step);
  };

  const stepOrder = ['property', 'bills', 'systems', 'family', 'review'];

  const getCurrentStep = () => {
    for (const step of stepOrder) {
      if (!data.steps[step as keyof OnboardingData['steps']]) {
        return step;
      }
    }
    return 'review';
  };

  const getNextStep = () => {
    const current = getCurrentStep();
    const currentIndex = stepOrder.indexOf(current);
    if (currentIndex < stepOrder.length - 1) {
      return stepOrder[currentIndex + 1];
    }
    return null;
  };

  const calculateMonthlyTotal = () => {
    return data.bills.reduce((total, bill) => {
      switch (bill.frequency) {
        case 'monthly':
          return total + bill.amount;
        case 'quarterly':
          return total + bill.amount / 3;
        case 'semi_annual':
          return total + bill.amount / 6;
        case 'annual':
          return total + bill.amount / 12;
        case 'one_time':
          return total; // Don't include one-time in monthly
        default:
          return total + bill.amount;
      }
    }, 0);
  };

  const reset = () => dispatch({ type: 'RESET' });

  const clearOnboardingData = () => {
    // Clear from localStorage
    if (typeof window !== 'undefined') {
      localStorage.removeItem(STORAGE_KEY);
    }
    // Reset state
    dispatch({ type: 'RESET' });
  };

  return (
    <OnboardingContext.Provider
      value={{
        data,
        dispatch,
        setTier,
        setPath,
        setProperty,
        setPropertyEnrichment,
        addBill,
        updateBill,
        removeBill,
        addSystem,
        updateSystem,
        removeSystem,
        addAppliance,
        updateAppliance,
        removeAppliance,
        addFamilyMember,
        updateFamilyMember,
        removeFamilyMember,
        addVehicle,
        updateVehicle,
        removeVehicle,
        addPet,
        updatePet,
        removePet,
        addStaff,
        updateStaff,
        removeStaff,
        completeStep,
        getCompletedSteps,
        getCurrentStep,
        getNextStep,
        calculateMonthlyTotal,
        reset,
        clearOnboardingData,
      }}
    >
      {children}
    </OnboardingContext.Provider>
  );
}

// ============================================
// HOOK
// ============================================

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  if (context === undefined) {
    throw new Error('useOnboarding must be used within an OnboardingProvider');
  }
  return context;
}
