'use client';

import { useState, useMemo, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/auth-context';
import { getApiClient } from '@/lib/api';
import type { FamilyMember as ApiFamilyMember, Pet, CreatePetRequest, PetType } from '@haven/core';
import {
  MapPin,
  Home,
  Car,
  Building2,
  GraduationCap,
  Trophy,
  Heart,
  Phone,
  Mail,
  MessageCircle,
  ChevronDown,
  ChevronRight,
  Plus,
  Pencil,
  AlertTriangle,
  Check,
  X,
  DollarSign,
  User,
  Users,
  Baby,
  Dog,
  Briefcase,
  Dumbbell,
  Shield,
  Star,
  AlertCircle,
  Eye,
  EyeOff,
  Syringe,
  Utensils,
  Shirt,
  Footprints,
  Music,
  Palette,
  Timer,
  Crown,
  BadgeCheck,
  UserPlus,
  Loader2,
  Cat,
  Calendar,
  CreditCard,
  Bell,
  FileText,
  Printer,
  Download,
  RefreshCw,
  ArrowRight,
  CheckCircle2,
  ShoppingBag,
  Stethoscope,
  ClipboardList,
  Navigation,
  UserCheck,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

type LocationStatus = 'home' | 'away' | 'school' | 'work' | 'activity' | 'unknown';

interface LocationInfo {
  status: LocationStatus;
  label: string;
  returnTime?: string;
  eventName?: string;
}

interface Club {
  name: string;
  type: string;
  membershipId?: string;
  monthlyDues: number;
}

interface AdultMember {
  id: string;
  type: 'adult';
  name: string;
  avatar?: string;
  initials: string;
  role: string;
  isAdmin: boolean;
  email: string;
  phone: string;
  location: LocationInfo;
  work?: {
    company: string;
    title: string;
    address: string;
  };
  clubs: Club[];
  wellness?: {
    gym: string;
    membershipId: string;
  };
  civic?: string[];
}

interface Activity {
  name: string;
  organization: string;
  coachName?: string;
  monthlyFee: number;
  schedule: string;
  contact?: string;
}

interface ChildMember {
  id: string;
  type: 'child';
  name: string;
  avatar?: string;
  initials: string;
  age: number;
  grade: string;
  location: LocationInfo;
  school: {
    name: string;
    tuitionMonthly: number;
    tuitionDue?: Date;
    address: string;
  };
  activities: Activity[];
  careProvider?: {
    name: string;
    id: string;
  };
  health: {
    pediatrician: string;
    pediatricianPhone: string;
    allergies: string[];
    medications?: string[];
  };
  sizes?: {
    shirt: string;
    pants: string;
    shoe: string;
    lastUpdated?: Date;
  };
}

interface PetMember {
  id: string;
  type: 'pet';
  name: string;
  avatar?: string;
  initials: string;
  species: 'dog' | 'cat' | 'other';
  breed: string;
  age: number;
  location: LocationInfo;
  vet: {
    name: string;
    phone: string;
    clinic: string;
  };
  vaccinesDue?: Date;
  microchipId?: string;
  food: {
    brand: string;
    type: string;
    monthlyAmount: string;
  };
  monthlyExpenses: number;
}

interface StaffMember {
  id: string;
  type: 'staff';
  name: string;
  avatar?: string;
  initials: string;
  role: string;
  agency?: string;
  email: string;
  phone: string;
  location: LocationInfo;
  weeklyStipend: number;
  schedule: { day: string; hours: string }[];
  permissions: string[];
  startDate: Date;
  contractEndDate?: Date;
}

interface VehicleMember {
  id: string;
  type: 'vehicle';
  name: string; // Display name like "Bob's Tesla"
  make: string;
  model: string;
  year: number;
  color: string;
  licensePlate: string;
  vin?: string;
  primaryDriverId?: string;
  primaryDriverName?: string;
  photoUrl?: string;

  // Tracking
  currentMileage: number;
  mileageUpdatedAt?: Date;
  annualMiles?: number;

  // Registration & Insurance
  registrationExpiry?: Date;
  registrationState?: string;
  insuranceProvider?: string;
  insurancePolicyNum?: string;
  insuranceExpiry?: Date;
  insuranceMonthly?: number;

  // Loan Info
  hasLoan: boolean;
  lender?: string;
  monthlyPayment?: number;
  loanBalance?: number;
  loanMaturityDate?: Date;

  // Service Info
  lastOilChange?: Date;
  oilChangeMileage?: number;
  nextServiceDue?: Date;
  nextServiceMileage?: number;
  preferredServiceShop?: string;
  serviceHistory?: VehicleServiceRecord[];
}

interface VehicleServiceRecord {
  id: string;
  serviceType: string;
  date: Date;
  mileage: number;
  cost: number;
  shop: string;
  notes?: string;
}

type FamilyMember = AdultMember | ChildMember | PetMember | StaffMember;

// Smart Alert Types
interface SmartAlert {
  id: string;
  type: 'tuition' | 'vaccine' | 'size' | 'contract' | 'activity' | 'shopping' | 'appointment';
  priority: 'urgent' | 'soon' | 'info';
  title: string;
  description: string;
  dueDate?: Date;
  action?: {
    label: string;
    handler: () => void;
  };
  memberId?: string;
  memberName?: string;
}

// Pickup/Logistics Types
interface PickupEvent {
  id: string;
  childName: string;
  childId: string;
  location: string;
  time: string;
  activity: string;
  driver?: string;
  driverId?: string;
  status: 'unassigned' | 'assigned' | 'confirmed' | 'completed';
}

// Bill Account Types
interface BillAccount {
  id: string;
  name: string;
  category: 'education' | 'activities' | 'childcare' | 'pet' | 'membership';
  amount: number;
  frequency: 'weekly' | 'monthly' | 'quarterly' | 'annually';
  dueDay?: number;
  recipient: string;
  autopay: boolean;
  linkedMemberId?: string;
}

// ============================================================================
// MOCK DATA
// ============================================================================

const MANAGER_NAME = 'Sarah';

// Calculate dates relative to now
const today = new Date();
const getDate = (daysOffset: number) => {
  const date = new Date(today);
  date.setDate(date.getDate() + daysOffset);
  return date;
};

const MOCK_ADULTS: AdultMember[] = [
  {
    id: 'a1',
    type: 'adult',
    name: 'Bob Morrison',
    initials: 'BM',
    role: 'Head of Household',
    isAdmin: true,
    email: 'bob@example.com',
    phone: '(203) 555-0101',
    location: { status: 'work', label: 'At Work', returnTime: '6:30 PM', eventName: 'TechCorp Greenwich' },
    work: {
      company: 'Morrison Capital Partners',
      title: 'Managing Partner',
      address: '100 Field Point Rd, Greenwich, CT',
    },
    clubs: [
      { name: 'Greenwich Country Club', type: 'Golf', membershipId: 'GCC-4521', monthlyDues: 1500 },
      { name: 'Belle Haven Club', type: 'Social', membershipId: 'BHC-1122', monthlyDues: 850 },
    ],
    wellness: { gym: 'Equinox - Greenwich', membershipId: 'EQ-88721' },
    civic: ['Rotary Club of Greenwich', 'Greenwich Chamber of Commerce'],
  },
  {
    id: 'a2',
    type: 'adult',
    name: 'Alice Morrison',
    initials: 'AM',
    role: 'Spouse',
    isAdmin: true,
    email: 'alice@example.com',
    phone: '(203) 555-0102',
    location: { status: 'activity', label: 'At Yoga', returnTime: '11:30 AM', eventName: 'CorePower Yoga' },
    work: {
      company: 'Greenwich Hospital',
      title: 'Pediatric Nurse Practitioner',
      address: '5 Perryridge Rd, Greenwich, CT',
    },
    clubs: [
      { name: 'Junior League of Greenwich', type: 'Civic', membershipId: 'JLG-2234', monthlyDues: 200 },
    ],
    wellness: { gym: 'CorePower Yoga - Greenwich', membershipId: 'CP-44521' },
    civic: ['Junior League of Greenwich', 'Garden Club of Greenwich'],
  },
];

const MOCK_VEHICLES: VehicleMember[] = [
  {
    id: 'v1',
    type: 'vehicle',
    name: "Bob's Tesla",
    make: 'Tesla',
    model: 'Model Y',
    year: 2023,
    color: 'Midnight Silver',
    licensePlate: 'GRN 1234',
    vin: '5YJYGDEE9MF123456',
    primaryDriverId: 'a1',
    primaryDriverName: 'Bob Morrison',
    currentMileage: 24500,
    mileageUpdatedAt: getDate(-7),
    annualMiles: 12000,
    registrationExpiry: getDate(45), // 45 days from now
    registrationState: 'TX',
    insuranceProvider: 'State Farm',
    insurancePolicyNum: 'SF-8847291',
    insuranceExpiry: getDate(180),
    insuranceMonthly: 145,
    hasLoan: true,
    lender: 'Tesla Finance',
    monthlyPayment: 750,
    loanBalance: 38500,
    loanMaturityDate: new Date(2028, 5, 15),
    lastOilChange: undefined, // Electric - no oil changes!
    nextServiceDue: getDate(60),
    nextServiceMileage: 30000,
    preferredServiceShop: 'Tesla Service Center - Greenwich',
    serviceHistory: [
      { id: 's1', serviceType: 'Tire Rotation', date: getDate(-90), mileage: 22000, cost: 75, shop: 'Tesla Service Center' },
      { id: 's2', serviceType: 'Cabin Air Filter', date: getDate(-180), mileage: 18000, cost: 95, shop: 'Tesla Service Center' },
    ],
  },
  {
    id: 'v2',
    type: 'vehicle',
    name: 'Family Highlander',
    make: 'Toyota',
    model: 'Highlander',
    year: 2022,
    color: 'Pearl White',
    licensePlate: 'XYZ 5678',
    vin: '5TDGZRBH8NS123456',
    primaryDriverId: 'a2',
    primaryDriverName: 'Alice Morrison',
    currentMileage: 35200,
    mileageUpdatedAt: getDate(-3),
    annualMiles: 15000,
    registrationExpiry: getDate(120),
    registrationState: 'TX',
    insuranceProvider: 'State Farm',
    insurancePolicyNum: 'SF-8847292',
    insuranceExpiry: getDate(180),
    insuranceMonthly: 125,
    hasLoan: true,
    lender: 'Toyota Financial',
    monthlyPayment: 650,
    loanBalance: 28000,
    loanMaturityDate: new Date(2027, 8, 1),
    lastOilChange: getDate(-45),
    oilChangeMileage: 32500,
    nextServiceDue: getDate(45),
    nextServiceMileage: 37500,
    preferredServiceShop: 'Greenwich Toyota',
    serviceHistory: [
      { id: 's3', serviceType: 'Oil Change', date: getDate(-45), mileage: 32500, cost: 85, shop: 'Greenwich Toyota' },
      { id: 's4', serviceType: 'Tire Rotation', date: getDate(-45), mileage: 32500, cost: 0, shop: 'Greenwich Toyota', notes: 'Included with oil change' },
      { id: 's5', serviceType: 'Brake Inspection', date: getDate(-90), mileage: 30000, cost: 0, shop: 'Greenwich Toyota' },
    ],
  },
];

const MOCK_CHILDREN: ChildMember[] = [
  {
    id: 'c1',
    type: 'child',
    name: 'Emma Morrison',
    initials: 'EM',
    age: 12,
    grade: '7th Grade',
    location: { status: 'school', label: 'At School', returnTime: '3:30 PM', eventName: 'Greenwich Country Day' },
    school: {
      name: 'Greenwich Country Day School',
      tuitionMonthly: 4500,
      tuitionDue: getDate(5),
      address: '401 Old Church Rd, Greenwich, CT',
    },
    activities: [
      { name: 'Travel Soccer', organization: 'FC Greenwich', coachName: 'Coach Martinez', monthlyFee: 450, schedule: 'Tue/Thu 5-7pm, Sat 9am', contact: '(203) 555-KICK' },
      { name: 'Piano Lessons', organization: 'Greenwich Music Academy', monthlyFee: 250, schedule: 'Wed 4pm', contact: '(203) 555-KEYS' },
    ],
    careProvider: { name: 'Maria Garcia', id: 's1' },
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(203) 555-PEDS',
      allergies: ['Peanuts', 'Tree nuts'],
      medications: ['EpiPen (emergency)'],
    },
    sizes: { shirt: 'Youth M', pants: '12', shoe: '6', lastUpdated: getDate(-180) },
  },
  {
    id: 'c2',
    type: 'child',
    name: 'Jack Morrison',
    initials: 'JM',
    age: 8,
    grade: '3rd Grade',
    location: { status: 'school', label: 'At School', returnTime: '3:00 PM', eventName: 'North Street School' },
    school: {
      name: 'North Street School',
      tuitionMonthly: 0,
      address: '381 North St, Greenwich, CT',
    },
    activities: [
      { name: 'Little League', organization: 'Greenwich Little League', coachName: 'Coach Johnson', monthlyFee: 100, schedule: 'Mon/Wed 5pm', contact: '(203) 555-BALL' },
      { name: 'Art Class', organization: 'Bruce Museum Art Studio', monthlyFee: 175, schedule: 'Sat 10am', contact: '(203) 555-ARTS' },
    ],
    careProvider: { name: 'Maria Garcia', id: 's1' },
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(203) 555-PEDS',
      allergies: [],
    },
    sizes: { shirt: 'Youth S', pants: '8', shoe: '3', lastUpdated: getDate(-45) },
  },
];

const MOCK_PETS: PetMember[] = [
  {
    id: 'p1',
    type: 'pet',
    name: 'Max',
    initials: 'M',
    species: 'dog',
    breed: 'Golden Retriever',
    age: 4,
    location: { status: 'home', label: 'At Home' },
    vet: {
      name: 'Dr. Williams',
      phone: '(512) 555-VETS',
      clinic: 'Westlake Animal Hospital',
    },
    vaccinesDue: getDate(30),
    microchipId: '985141001234567',
    food: {
      brand: 'Blue Buffalo',
      type: 'Life Protection Adult Chicken',
      monthlyAmount: '30 lbs',
    },
    monthlyExpenses: 150,
  },
];

const MOCK_STAFF: StaffMember[] = [
  {
    id: 's1',
    type: 'staff',
    name: 'Maria Garcia',
    initials: 'MG',
    role: 'Nanny',
    agency: 'Greenwich Elite Nannies',
    email: 'maria.g@greenwichnannies.com',
    phone: '(203) 555-0199',
    location: { status: 'home', label: 'At Home', eventName: 'With kids' },
    weeklyStipend: 1500,
    schedule: [
      { day: 'Monday', hours: '7am - 6pm' },
      { day: 'Tuesday', hours: '7am - 6pm' },
      { day: 'Wednesday', hours: '7am - 6pm' },
      { day: 'Thursday', hours: '7am - 6pm' },
      { day: 'Friday', hours: '7am - 3pm' },
    ],
    permissions: ["Kids' Schedules", 'Emergency Contacts', 'Medical Info'],
    startDate: new Date(2023, 5, 15),
    contractEndDate: getDate(7),
  },
];

// Mock today's pickups
const MOCK_PICKUPS: PickupEvent[] = [
  {
    id: 'pk1',
    childName: 'Emma',
    childId: 'c1',
    location: 'Greenwich Country Day School',
    time: '3:30 PM',
    activity: 'School',
    driver: 'Maria Garcia',
    driverId: 's1',
    status: 'confirmed',
  },
  {
    id: 'pk2',
    childName: 'Jack',
    childId: 'c2',
    location: 'North Street School',
    time: '3:00 PM',
    activity: 'School',
    driver: 'Maria Garcia',
    driverId: 's1',
    status: 'confirmed',
  },
  {
    id: 'pk3',
    childName: 'Emma',
    childId: 'c1',
    location: 'Greenwich Polo Club Fields',
    time: '7:00 PM',
    activity: 'Soccer Practice',
    status: 'unassigned',
  },
  {
    id: 'pk4',
    childName: 'Jack',
    childId: 'c2',
    location: 'Cos Cob Park',
    time: '7:00 PM',
    activity: 'Little League',
    driver: 'Bob Morrison',
    driverId: 'a1',
    status: 'assigned',
  },
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getInitials(name: string): string {
  return name
    .split(' ')
    .map((n) => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2);
}

function mapRoleToDisplay(role: string): string {
  switch (role.toUpperCase()) {
    case 'OWNER':
    case 'ADMIN':
      return 'Admin';
    case 'MANAGER':
      return 'Manager';
    case 'MEMBER':
      return 'Family Member';
    case 'CHILD':
      return 'Child';
    case 'STAFF':
      return 'Staff';
    default:
      return role;
  }
}

function mapToAdult(apiMember: ApiFamilyMember): AdultMember {
  const name = apiMember.displayName || apiMember.user?.displayName || 'Unknown';
  const email = apiMember.user?.email || '';
  const phone = apiMember.profile?.workPhone || apiMember.profile?.emergencyPhone || '';
  const isAdmin = apiMember.role.toUpperCase() === 'OWNER' || apiMember.role.toUpperCase() === 'ADMIN';

  return {
    id: apiMember.id,
    type: 'adult',
    name,
    initials: getInitials(name),
    role: mapRoleToDisplay(apiMember.role),
    isAdmin,
    email,
    phone,
    location: { status: 'unknown', label: 'Unknown' },
    clubs: [],
    wellness: undefined,
    civic: [],
  };
}

function mapToChild(apiMember: ApiFamilyMember): ChildMember {
  const name = apiMember.displayName || 'Unknown';
  return {
    id: apiMember.id,
    type: 'child',
    name,
    initials: getInitials(name),
    age: 0,
    grade: '',
    location: { status: 'unknown', label: 'Unknown' },
    school: { name: 'Not set', tuitionMonthly: 0, address: '' },
    activities: [],
    health: {
      pediatrician: 'Not set',
      pediatricianPhone: '',
      allergies: apiMember.profile?.dietaryRestrictions || [],
    },
    sizes: apiMember.profile?.shirtSize
      ? { shirt: apiMember.profile.shirtSize, pants: '', shoe: '' }
      : undefined,
  };
}

function mapToStaff(apiMember: ApiFamilyMember): StaffMember {
  const name = apiMember.displayName || 'Unknown';
  return {
    id: apiMember.id,
    type: 'staff',
    name,
    initials: getInitials(name),
    role: apiMember.role || 'Staff',
    email: apiMember.user?.email || '',
    phone: apiMember.profile?.emergencyPhone || apiMember.profile?.workPhone || '',
    location: { status: 'unknown', label: 'Unknown' },
    weeklyStipend: 0,
    schedule: [],
    permissions: apiMember.permissions || [],
    startDate: new Date(),
  };
}

function mapPetTypeToSpecies(type: PetType): 'dog' | 'cat' | 'other' {
  switch (type) {
    case 'DOG': return 'dog';
    case 'CAT': return 'cat';
    default: return 'other';
  }
}

function calculateAgeFromBirthday(birthday?: string | null): number {
  if (!birthday) return 0;
  const birthDate = new Date(birthday);
  const today = new Date();
  let age = today.getFullYear() - birthDate.getFullYear();
  const monthDiff = today.getMonth() - birthDate.getMonth();
  if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
    age--;
  }
  return Math.max(0, age);
}

function mapToPet(apiPet: Pet): PetMember {
  const nextVaccineDate = apiPet.vetRecords
    ?.filter((r) => r.nextVaccinationDate)
    .sort((a, b) => new Date(a.nextVaccinationDate!).getTime() - new Date(b.nextVaccinationDate!).getTime())[0]
    ?.nextVaccinationDate;

  return {
    id: apiPet.id,
    type: 'pet',
    name: apiPet.name,
    initials: (apiPet.name?.charAt(0) ?? 'P').toUpperCase(),
    species: mapPetTypeToSpecies(apiPet.type),
    breed: apiPet.breed || 'Unknown',
    age: calculateAgeFromBirthday(apiPet.birthday),
    location: { status: 'home', label: 'At Home' },
    vet: {
      name: apiPet.primaryVetName || 'Not set',
      phone: apiPet.vetClinicPhone || '',
      clinic: apiPet.vetClinicName || '',
    },
    vaccinesDue: nextVaccineDate ? new Date(nextVaccineDate) : undefined,
    microchipId: apiPet.microchipId || undefined,
    food: {
      brand: apiPet.foodBrand || 'Not set',
      type: apiPet.foodType || '',
      monthlyAmount: apiPet.feedingSchedule || '',
    },
    monthlyExpenses: 0,
  };
}

// Location status config
const locationConfig: Record<LocationStatus, { color: string; bgColor: string; icon: typeof Home }> = {
  home: { color: 'text-green-700', bgColor: 'bg-green-100', icon: Home },
  away: { color: 'text-slate-700', bgColor: 'bg-slate-100', icon: Car },
  school: { color: 'text-blue-700', bgColor: 'bg-blue-100', icon: GraduationCap },
  work: { color: 'text-purple-700', bgColor: 'bg-purple-100', icon: Briefcase },
  activity: { color: 'text-amber-700', bgColor: 'bg-amber-100', icon: Trophy },
  unknown: { color: 'text-slate-500', bgColor: 'bg-slate-50', icon: MapPin },
};

type AddMemberType = 'adult' | 'child' | 'pet' | 'staff';

interface AddMemberFormData {
  type: AddMemberType;
  name: string;
  email?: string;
  phone?: string;
  petType?: PetType;
  breed?: string;
}

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function FamilyPage() {
  const { currentHousehold } = useAuth();

  // Data State
  const [adults, setAdults] = useState<AdultMember[]>(MOCK_ADULTS);
  const [children, setChildren] = useState<ChildMember[]>(MOCK_CHILDREN);
  const [pets, setPets] = useState<PetMember[]>(MOCK_PETS);
  const [staff, setStaff] = useState<StaffMember[]>(MOCK_STAFF);
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [vehicles, _setVehicles] = useState<VehicleMember[]>(MOCK_VEHICLES);
  const [pickups, setPickups] = useState<PickupEvent[]>(MOCK_PICKUPS);
  const [isLoading, setIsLoading] = useState(true);

  // UI State
  const [showFinancials, setShowFinancials] = useState(true);
  const [expandedCards, setExpandedCards] = useState<Set<string>>(new Set());
  const [showAddMemberModal, setShowAddMemberModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState<FamilyMember | null>(null);
  const [showEmergencyCard, setShowEmergencyCard] = useState(false);
  const [showSyncModal, setShowSyncModal] = useState<'calendar' | 'billing' | null>(null);
  const [addMemberStep, setAddMemberStep] = useState<'select' | 'form'>('select');
  const [addMemberType, setAddMemberType] = useState<AddMemberType | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showToast, setShowToast] = useState<string | null>(null);

  // Toast helper
  const toast = useCallback((message: string) => {
    setShowToast(message);
    setTimeout(() => setShowToast(null), 3000);
  }, []);

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  const loadFamilyData = useCallback(async () => {
    if (!currentHousehold?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const api = getApiClient();
      const [membersResult, petsResult] = await Promise.allSettled([
        api.getFamilyMembers(),
        api.getFamilyPets(),
      ]);

      if (membersResult.status === 'fulfilled' && membersResult.value.length > 0) {
        const apiMembers = membersResult.value;
        const newAdults: AdultMember[] = [];
        const newChildren: ChildMember[] = [];
        const newStaff: StaffMember[] = [];

        apiMembers.forEach((member) => {
          const roleUpper = member.role.toUpperCase();
          if (roleUpper === 'CHILD') {
            newChildren.push(mapToChild(member));
          } else if (roleUpper === 'STAFF') {
            newStaff.push(mapToStaff(member));
          } else {
            newAdults.push(mapToAdult(member));
          }
        });

        // MERGE with mock data instead of replacing completely
        // This ensures demo data (like Alice) always shows
        if (newAdults.length > 0) {
          const apiAdultIds = new Set(newAdults.map(a => a.id));
          const mockAdultsToKeep = MOCK_ADULTS.filter(a => !apiAdultIds.has(a.id));
          setAdults([...newAdults, ...mockAdultsToKeep]);
        } else {
          // If no API adults, use all mock adults
          setAdults(MOCK_ADULTS);
        }

        if (newChildren.length > 0) {
          const apiChildIds = new Set(newChildren.map(c => c.id));
          const mockChildrenToKeep = MOCK_CHILDREN.filter(c => !apiChildIds.has(c.id));
          setChildren([...newChildren, ...mockChildrenToKeep]);
        } else {
          setChildren(MOCK_CHILDREN);
        }

        if (newStaff.length > 0) {
          const apiStaffIds = new Set(newStaff.map(s => s.id));
          const mockStaffToKeep = MOCK_STAFF.filter(s => !apiStaffIds.has(s.id));
          setStaff([...newStaff, ...mockStaffToKeep]);
        } else {
          setStaff(MOCK_STAFF);
        }
      }

      if (petsResult.status === 'fulfilled' && petsResult.value.length > 0) {
        const mappedPets = petsResult.value.map(mapToPet);
        setPets(mappedPets);
      }
    } catch (error) {
      console.error('Failed to load family data:', error);
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold?.id]);

  useEffect(() => {
    loadFamilyData();
  }, [loadFamilyData]);

  // ============================================================================
  // COMPUTED VALUES - SMART ALERTS
  // ============================================================================

  const smartAlerts = useMemo(() => {
    const alerts: SmartAlert[] = [];
    const now = new Date();

    // Tuition due alerts
    children.forEach((child) => {
      if (child.school.tuitionDue && child.school.tuitionMonthly > 0) {
        const daysUntil = Math.ceil((child.school.tuitionDue.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        if (daysUntil <= 7 && daysUntil >= 0) {
          alerts.push({
            id: `tuition-${child.id}`,
            type: 'tuition',
            priority: daysUntil <= 2 ? 'urgent' : 'soon',
            title: `${child.name}'s tuition due in ${daysUntil} days`,
            description: `${child.school.name} - $${child.school.tuitionMonthly.toLocaleString()}`,
            dueDate: child.school.tuitionDue,
            memberId: child.id,
            memberName: child.name,
            action: { label: 'Pay Now', handler: () => toast(`Payment initiated for ${child.school.name}`) },
          });
        }
      }
    });

    // Pet vaccine alerts
    pets.forEach((pet) => {
      if (pet.vaccinesDue) {
        const daysUntil = Math.ceil((pet.vaccinesDue.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        if (daysUntil <= 30 && daysUntil >= 0) {
          alerts.push({
            id: `vaccine-${pet.id}`,
            type: 'vaccine',
            priority: daysUntil <= 7 ? 'urgent' : 'soon',
            title: `${pet.name}'s vaccines due ${daysUntil <= 0 ? 'today' : `in ${daysUntil} days`}`,
            description: `Schedule appointment with ${pet.vet.clinic}`,
            dueDate: pet.vaccinesDue,
            memberId: pet.id,
            memberName: pet.name,
            action: { label: 'Ask Sarah to Schedule', handler: () => toast(`${MANAGER_NAME} will schedule ${pet.name}'s vet appointment`) },
          });
        }
      }
    });

    // Size update alerts (6 months since last update)
    children.forEach((child) => {
      if (child.sizes?.lastUpdated) {
        const daysSinceUpdate = Math.floor((now.getTime() - child.sizes.lastUpdated.getTime()) / (1000 * 60 * 60 * 24));
        if (daysSinceUpdate >= 180) {
          alerts.push({
            id: `size-${child.id}`,
            type: 'size',
            priority: 'info',
            title: `${child.name}'s sizes may be outdated`,
            description: `Last updated ${Math.floor(daysSinceUpdate / 30)} months ago`,
            memberId: child.id,
            memberName: child.name,
            action: { label: 'Update Sizes', handler: () => setShowEditModal(child) },
          });
        }
      }
    });

    // Staff contract expiring
    staff.forEach((s) => {
      if (s.contractEndDate) {
        const daysUntil = Math.ceil((s.contractEndDate.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        if (daysUntil <= 14 && daysUntil >= 0) {
          alerts.push({
            id: `contract-${s.id}`,
            type: 'contract',
            priority: daysUntil <= 7 ? 'urgent' : 'soon',
            title: `${s.name}'s contract expires in ${daysUntil} days`,
            description: `${s.role} via ${s.agency || 'Direct hire'}`,
            dueDate: s.contractEndDate,
            memberId: s.id,
            memberName: s.name,
            action: { label: 'Renew Contract', handler: () => toast(`${MANAGER_NAME} will handle contract renewal`) },
          });
        }
      }
    });

    // Vehicle registration expiring
    vehicles.forEach((v) => {
      if (v.registrationExpiry) {
        const daysUntil = Math.ceil((v.registrationExpiry.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        if (daysUntil <= 60 && daysUntil >= 0) {
          alerts.push({
            id: `reg-${v.id}`,
            type: 'activity',
            priority: daysUntil <= 14 ? 'urgent' : 'soon',
            title: `${v.name} registration expires in ${daysUntil} days`,
            description: `${v.year} ${v.make} ${v.model} - ${v.licensePlate}`,
            dueDate: v.registrationExpiry,
            memberId: v.id,
            memberName: v.name,
            action: { label: 'Ask Sarah to Renew', handler: () => toast(`${MANAGER_NAME} will handle registration renewal`) },
          });
        }
      }
    });

    // Vehicle service due
    vehicles.forEach((v) => {
      if (v.nextServiceDue) {
        const daysUntil = Math.ceil((v.nextServiceDue.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        if (daysUntil <= 30 && daysUntil >= 0) {
          alerts.push({
            id: `service-${v.id}`,
            type: 'appointment',
            priority: daysUntil <= 7 ? 'urgent' : 'soon',
            title: `${v.name} service due ${daysUntil <= 0 ? 'now' : `in ${daysUntil} days`}`,
            description: v.nextServiceMileage ? `At ${v.nextServiceMileage.toLocaleString()} miles` : 'Schedule maintenance',
            dueDate: v.nextServiceDue,
            memberId: v.id,
            memberName: v.name,
            action: { label: 'Schedule Service', handler: () => toast(`${MANAGER_NAME} will schedule ${v.name} service`) },
          });
        }
      }
    });

    return alerts.sort((a, b) => {
      const priorityOrder = { urgent: 0, soon: 1, info: 2 };
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });
  }, [children, pets, staff, vehicles, toast]);

  // Computed bill accounts from family data
  const autoBillAccounts = useMemo(() => {
    const accounts: BillAccount[] = [];

    // School tuition
    children.forEach((child) => {
      if (child.school.tuitionMonthly > 0) {
        accounts.push({
          id: `school-${child.id}`,
          name: child.school.name,
          category: 'education',
          amount: child.school.tuitionMonthly,
          frequency: 'monthly',
          dueDay: 5,
          recipient: child.name,
          autopay: false,
          linkedMemberId: child.id,
        });
      }
    });

    // Activities
    children.forEach((child) => {
      child.activities.forEach((activity, idx) => {
        accounts.push({
          id: `activity-${child.id}-${idx}`,
          name: activity.name,
          category: 'activities',
          amount: activity.monthlyFee,
          frequency: 'monthly',
          recipient: child.name,
          autopay: false,
          linkedMemberId: child.id,
        });
      });
    });

    // Staff stipends
    staff.forEach((s) => {
      if (s.weeklyStipend > 0) {
        accounts.push({
          id: `staff-${s.id}`,
          name: `${s.name} (${s.role})`,
          category: 'childcare',
          amount: s.weeklyStipend,
          frequency: 'weekly',
          recipient: s.name,
          autopay: true,
          linkedMemberId: s.id,
        });
      }
    });

    // Pet expenses
    pets.forEach((pet) => {
      if (pet.monthlyExpenses > 0) {
        accounts.push({
          id: `pet-${pet.id}`,
          name: `${pet.name} Care`,
          category: 'pet',
          amount: pet.monthlyExpenses,
          frequency: 'monthly',
          recipient: pet.name,
          autopay: false,
          linkedMemberId: pet.id,
        });
      }
    });

    // Adult memberships
    adults.forEach((adult) => {
      adult.clubs.forEach((club, idx) => {
        accounts.push({
          id: `club-${adult.id}-${idx}`,
          name: club.name,
          category: 'membership',
          amount: club.monthlyDues,
          frequency: 'monthly',
          recipient: adult.name,
          autopay: true,
          linkedMemberId: adult.id,
        });
      });
    });

    return accounts;
  }, [children, staff, pets, adults]);

  // Computed calendar events from family data
  const autoCalendarEvents = useMemo(() => {
    const events: { title: string; schedule: string; member: string; type: string }[] = [];

    children.forEach((child) => {
      child.activities.forEach((activity) => {
        events.push({
          title: `${child.name.split(' ')[0]}'s ${activity.name}`,
          schedule: activity.schedule,
          member: child.name,
          type: 'recurring',
        });
      });
    });

    staff.forEach((s) => {
      events.push({
        title: `${s.name} (${s.role})`,
        schedule: s.schedule.map(d => `${d.day.slice(0, 3)}: ${d.hours}`).join(', '),
        member: s.name,
        type: 'availability',
      });
    });

    pets.forEach((pet) => {
      if (pet.vaccinesDue) {
        events.push({
          title: `${pet.name} - Vaccines Due`,
          schedule: pet.vaccinesDue.toLocaleDateString(),
          member: pet.name,
          type: 'reminder',
        });
      }
    });

    return events;
  }, [children, staff, pets]);

  const monthlyLifestyleCosts = useMemo(() => {
    let total = 0;
    adults.forEach((adult) => {
      adult.clubs.forEach((club) => { total += club.monthlyDues; });
    });
    children.forEach((child) => {
      total += child.school.tuitionMonthly;
      child.activities.forEach((activity) => { total += activity.monthlyFee; });
    });
    pets.forEach((pet) => { total += pet.monthlyExpenses; });
    staff.forEach((s) => { total += s.weeklyStipend * 4.33; });
    vehicles.forEach((v) => {
      total += v.monthlyPayment || 0;
      total += v.insuranceMonthly || 0;
    });
    return total;
  }, [adults, children, pets, staff, vehicles]);

  const vehicleMonthlyCosts = useMemo(() => {
    let payments = 0;
    let insurance = 0;
    vehicles.forEach((v) => {
      payments += v.monthlyPayment || 0;
      insurance += v.insuranceMonthly || 0;
    });
    return { payments, insurance, total: payments + insurance };
  }, [vehicles]);

  // ============================================================================
  // HANDLERS
  // ============================================================================

  const handleAddMember = async (formData: AddMemberFormData) => {
    if (!currentHousehold?.id) return;
    setIsSubmitting(true);
    try {
      const api = getApiClient();
      if (formData.type === 'pet') {
        const petRequest: CreatePetRequest = {
          name: formData.name,
          type: formData.petType || 'DOG',
          breed: formData.breed,
        };
        const newPet = await api.createPet(petRequest);
        const mappedPet = mapToPet(newPet);
        setPets((prev) => [...prev, mappedPet]);
      } else {
        const id = `temp-${Date.now()}`;
        const name = formData.name;
        if (formData.type === 'adult') {
          const newAdult: AdultMember = {
            id, type: 'adult', name, initials: getInitials(name), role: 'Family Member', isAdmin: false,
            email: formData.email || '', phone: formData.phone || '', location: { status: 'unknown', label: 'Invited' }, clubs: [],
          };
          setAdults((prev) => [...prev, newAdult]);
        } else if (formData.type === 'child') {
          const newChild: ChildMember = {
            id, type: 'child', name, initials: getInitials(name), age: 0, grade: '',
            location: { status: 'unknown', label: 'Unknown' }, school: { name: 'Not set', tuitionMonthly: 0, address: '' },
            activities: [], health: { pediatrician: 'Not set', pediatricianPhone: '', allergies: [] },
          };
          setChildren((prev) => [...prev, newChild]);
        } else if (formData.type === 'staff') {
          const newStaffMember: StaffMember = {
            id, type: 'staff', name, initials: getInitials(name), role: 'Staff',
            email: formData.email || '', phone: formData.phone || '', location: { status: 'unknown', label: 'Invited' },
            weeklyStipend: 0, schedule: [], permissions: [], startDate: new Date(),
          };
          setStaff((prev) => [...prev, newStaffMember]);
        }
      }
      setShowAddMemberModal(false);
      setAddMemberStep('select');
      setAddMemberType(null);
      toast(`${formData.name} added successfully`);
    } catch (error) {
      console.error('Failed to add member:', error);
      toast('Failed to add member');
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleAssignDriver = useCallback((pickupId: string, driverName: string, driverId: string) => {
    setPickups(prev => prev.map(p =>
      p.id === pickupId ? { ...p, driver: driverName, driverId, status: 'assigned' as const } : p
    ));
    toast(`${driverName} assigned for pickup`);
  }, [toast]);

  const handleSyncToCalendar = useCallback(() => {
    toast(`${autoCalendarEvents.length} events synced to calendar`);
    setShowSyncModal(null);
  }, [autoCalendarEvents.length, toast]);

  const handleSyncToBilling = useCallback(() => {
    toast(`${autoBillAccounts.length} bill accounts created`);
    setShowSyncModal(null);
  }, [autoBillAccounts.length, toast]);

  const toggleCard = (id: string) => {
    setExpandedCards((prev) => {
      const next = new Set(prev);
      if (next.has(id)) { next.delete(id); } else { next.add(id); }
      return next;
    });
  };

  // Format helpers
  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', minimumFractionDigits: 0, maximumFractionDigits: 0 }).format(amount);
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getDaysUntil = (date: Date) => {
    return Math.ceil((date.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
  };

  const renderLocationPill = (location: LocationInfo) => {
    const config = locationConfig[location.status];
    const Icon = config.icon;
    return (
      <div className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full ${config.bgColor}`}>
        <Icon className={`w-4 h-4 ${config.color}`} />
        <span className={`text-sm font-medium ${config.color}`}>{location.label}</span>
        {location.returnTime && (
          <span className={`text-xs ${config.color} opacity-75`}>• Back {location.returnTime}</span>
        )}
      </div>
    );
  };

  // ============================================================================
  // LOADING STATE
  // ============================================================================

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="flex flex-col items-center gap-3">
          <Loader2 className="w-8 h-8 animate-spin text-emerald-600" />
          <p className="text-slate-500">Loading family data...</p>
        </div>
      </div>
    );
  }

  // ============================================================================
  // RENDER
  // ============================================================================

  return (
    <div className="space-y-6 pb-20">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Family</h1>
          <p className="text-slate-600 mt-1">Household members, logistics, and lifestyle management</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setShowEmergencyCard(true)}
            className="flex items-center gap-2 px-4 py-2 bg-red-50 text-red-700 font-medium rounded-lg hover:bg-red-100 transition-colors border border-red-200"
          >
            <Shield className="w-4 h-4" />
            <span className="hidden sm:inline">Emergency Card</span>
          </button>
          <button
            onClick={() => setShowAddMemberModal(true)}
            className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
          >
            <UserPlus className="w-5 h-5" />
            Add Member
          </button>
        </div>
      </div>

      {/* Smart Alerts for Manager */}
      {smartAlerts.length > 0 && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Bell className="w-5 h-5 text-amber-500" />
              <h2 className="font-semibold text-slate-900">Smart Alerts</h2>
              <span className="px-2 py-0.5 bg-amber-100 text-amber-700 text-xs font-medium rounded-full">
                {smartAlerts.length}
              </span>
            </div>
            <button className="text-sm text-slate-500 hover:text-slate-700">View All</button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
            {smartAlerts.slice(0, 6).map((alert) => {
              const priorityStyles = {
                urgent: 'bg-red-50 border-red-200',
                soon: 'bg-amber-50 border-amber-200',
                info: 'bg-blue-50 border-blue-200',
              };
              const iconStyles = {
                urgent: 'text-red-500',
                soon: 'text-amber-500',
                info: 'text-blue-500',
              };
              const getAlertIcon = () => {
                switch (alert.type) {
                  case 'tuition': return DollarSign;
                  case 'vaccine': return Syringe;
                  case 'size': return Shirt;
                  case 'contract': return FileText;
                  case 'shopping': return ShoppingBag;
                  default: return AlertCircle;
                }
              };
              const Icon = getAlertIcon();

              return (
                <div
                  key={alert.id}
                  className={`flex items-start gap-3 p-4 rounded-xl border ${priorityStyles[alert.priority]}`}
                >
                  <div className={`w-10 h-10 rounded-lg flex items-center justify-center ${
                    alert.priority === 'urgent' ? 'bg-red-100' :
                    alert.priority === 'soon' ? 'bg-amber-100' : 'bg-blue-100'
                  }`}>
                    <Icon className={`w-5 h-5 ${iconStyles[alert.priority]}`} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-slate-900 text-sm">{alert.title}</p>
                    <p className="text-xs text-slate-500 mt-0.5">{alert.description}</p>
                    {alert.action && (
                      <button
                        onClick={alert.action.handler}
                        className={`mt-2 text-xs font-medium ${
                          alert.priority === 'urgent' ? 'text-red-600 hover:text-red-700' :
                          alert.priority === 'soon' ? 'text-amber-600 hover:text-amber-700' :
                          'text-blue-600 hover:text-blue-700'
                        }`}
                      >
                        {alert.action.label} →
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Today's Logistics - Enhanced */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
        <div className="p-4 border-b border-slate-200 bg-gradient-to-r from-slate-50 to-white">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center">
                <Navigation className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <h2 className="font-semibold text-slate-900">Today's Logistics</h2>
                <p className="text-sm text-slate-500">
                  {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
                </p>
              </div>
            </div>
            <div className="flex items-center gap-2">
              <button
                onClick={() => toast('Messaging Maria...')}
                className="flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
              >
                <MessageCircle className="w-4 h-4" />
                Message Maria
              </button>
            </div>
          </div>
        </div>

        {/* Pickup Timeline */}
        <div className="p-4">
          <h3 className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-3">Pickups & Drop-offs</h3>
          <div className="space-y-3">
            {pickups.sort((a, b) => a.time.localeCompare(b.time)).map((pickup) => {
              const isUnassigned = pickup.status === 'unassigned';
              return (
                <div
                  key={pickup.id}
                  className={`flex items-center gap-4 p-3 rounded-xl ${
                    isUnassigned ? 'bg-red-50 border border-red-200' : 'bg-slate-50'
                  }`}
                >
                  <div className={`text-center min-w-[60px] ${isUnassigned ? 'text-red-600' : 'text-slate-600'}`}>
                    <p className="text-lg font-bold">{pickup.time.split(' ')[0]}</p>
                    <p className="text-xs">{pickup.time.split(' ')[1]}</p>
                  </div>

                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium text-slate-900">{pickup.childName}</span>
                      <ArrowRight className="w-3 h-3 text-slate-400" />
                      <span className="text-sm text-slate-600 truncate">{pickup.activity}</span>
                    </div>
                    <p className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                      <MapPin className="w-3 h-3" />
                      {pickup.location}
                    </p>
                  </div>

                  {isUnassigned ? (
                    <div className="flex items-center gap-2">
                      <AlertTriangle className="w-4 h-4 text-red-500" />
                      <select
                        onChange={(e) => {
                          const [name, id] = e.target.value.split('|');
                          if (name && id) handleAssignDriver(pickup.id, name, id);
                        }}
                        className="text-sm px-3 py-1.5 border border-red-300 rounded-lg bg-white text-red-700 focus:ring-2 focus:ring-red-500"
                        defaultValue=""
                      >
                        <option value="" disabled>Assign Driver</option>
                        {adults.map(a => <option key={a.id} value={`${a.name}|${a.id}`}>{a.name}</option>)}
                        {staff.map(s => <option key={s.id} value={`${s.name}|${s.id}`}>{s.name}</option>)}
                      </select>
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 bg-emerald-100 rounded-full flex items-center justify-center">
                        <UserCheck className="w-4 h-4 text-emerald-600" />
                      </div>
                      <div className="text-right">
                        <p className="text-sm font-medium text-slate-900">{pickup.driver}</p>
                        <p className={`text-xs ${
                          pickup.status === 'confirmed' ? 'text-green-600' : 'text-amber-600'
                        }`}>
                          {pickup.status === 'confirmed' ? 'Confirmed' : 'Pending'}
                        </p>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Quick Actions for Logistics */}
        <div className="px-4 pb-4 flex gap-2 flex-wrap">
          <button
            onClick={() => toast('Arranging backup driver...')}
            className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Arrange Backup
          </button>
          <button
            onClick={() => toast('Opening carpool chat...')}
            className="flex items-center gap-2 px-3 py-2 text-sm font-medium text-slate-600 bg-slate-100 hover:bg-slate-200 rounded-lg transition-colors"
          >
            <Users className="w-4 h-4" />
            Carpool Options
          </button>
        </div>
      </div>

      {/* Quick Sync Actions */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Sync to Calendar */}
        <button
          onClick={() => setShowSyncModal('calendar')}
          className="flex items-center gap-4 p-4 bg-white rounded-xl shadow-sm border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50/50 transition-colors text-left"
        >
          <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center">
            <Calendar className="w-6 h-6 text-blue-600" />
          </div>
          <div className="flex-1">
            <p className="font-medium text-slate-900">Sync to Calendar</p>
            <p className="text-sm text-slate-500">{autoCalendarEvents.length} events from family data</p>
          </div>
          <ArrowRight className="w-5 h-5 text-slate-400" />
        </button>

        {/* Sync to Billing */}
        <button
          onClick={() => setShowSyncModal('billing')}
          className="flex items-center gap-4 p-4 bg-white rounded-xl shadow-sm border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50/50 transition-colors text-left"
        >
          <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center">
            <CreditCard className="w-6 h-6 text-emerald-600" />
          </div>
          <div className="flex-1">
            <p className="font-medium text-slate-900">Create Bill Accounts</p>
            <p className="text-sm text-slate-500">{autoBillAccounts.length} recurring bills detected</p>
          </div>
          <ArrowRight className="w-5 h-5 text-slate-400" />
        </button>
      </div>

      {/* Financial Roll-up */}
      {showFinancials && (
        <div className="bg-gradient-to-r from-slate-900 to-slate-800 rounded-xl p-6 text-white">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-white/10 rounded-lg flex items-center justify-center">
                <DollarSign className="w-5 h-5" />
              </div>
              <div>
                <p className="text-slate-300 text-sm">Monthly Lifestyle Fixed Costs</p>
                <p className="text-2xl font-bold">{formatCurrency(monthlyLifestyleCosts)}</p>
              </div>
            </div>
            <button
              onClick={() => setShowFinancials(false)}
              className="p-2 hover:bg-white/10 rounded-lg transition-colors"
            >
              <EyeOff className="w-5 h-5 text-slate-400" />
            </button>
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-5 gap-4">
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Club Memberships</p>
              <p className="font-semibold">
                {formatCurrency(adults.reduce((sum, a) => sum + a.clubs.reduce((s, c) => s + c.monthlyDues, 0), 0))}
              </p>
            </div>
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Education & Activities</p>
              <p className="font-semibold">
                {formatCurrency(children.reduce((sum, c) => sum + c.school.tuitionMonthly + c.activities.reduce((s, a) => s + a.monthlyFee, 0), 0))}
              </p>
            </div>
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Childcare</p>
              <p className="font-semibold">{formatCurrency(staff.reduce((sum, s) => sum + s.weeklyStipend * 4.33, 0))}</p>
            </div>
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Pet Care</p>
              <p className="font-semibold">{formatCurrency(pets.reduce((sum, p) => sum + p.monthlyExpenses, 0))}</p>
            </div>
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Auto (Loans + Insurance)</p>
              <p className="font-semibold">{formatCurrency(vehicleMonthlyCosts.total)}</p>
            </div>
          </div>
        </div>
      )}

      {!showFinancials && (
        <button
          onClick={() => setShowFinancials(true)}
          className="w-full py-3 bg-slate-100 text-slate-600 font-medium rounded-xl hover:bg-slate-200 transition-colors flex items-center justify-center gap-2"
        >
          <Eye className="w-5 h-5" />
          Show Financial Summary
        </button>
      )}

      {/* Adults Section */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <Users className="w-5 h-5 text-slate-400" />
          <h2 className="font-semibold text-slate-900">Adults</h2>
          <span className="text-sm text-slate-500">({adults.length})</span>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {adults.map((adult) => (
            <div key={adult.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
              <div className="p-4 border-b border-slate-100">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-4">
                    <div className="w-14 h-14 bg-emerald-100 rounded-full flex items-center justify-center">
                      <span className="text-lg font-semibold text-emerald-600">{adult.initials}</span>
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h3 className="font-semibold text-slate-900">{adult.name}</h3>
                        {adult.isAdmin && (
                          <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 text-xs font-medium rounded-full flex items-center gap-1">
                            <Crown className="w-3 h-3" />
                            Admin
                          </span>
                        )}
                      </div>
                      <p className="text-sm text-slate-500">{adult.role}</p>
                      <div className="mt-1">{renderLocationPill(adult.location)}</div>
                    </div>
                  </div>
                  <button onClick={() => setShowEditModal(adult)} className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                    <Pencil className="w-4 h-4" />
                  </button>
                </div>
              </div>

              <div className="px-4 py-3 bg-slate-50 flex items-center gap-4">
                <button className="flex items-center gap-1.5 text-sm text-slate-600 hover:text-emerald-600 transition-colors">
                  <Phone className="w-4 h-4" />
                  {adult.phone || 'No phone'}
                </button>
                <button className="flex items-center gap-1.5 text-sm text-slate-600 hover:text-emerald-600 transition-colors">
                  <Mail className="w-4 h-4" />
                  {adult.email || 'No email'}
                </button>
              </div>

              <button
                onClick={() => toggleCard(adult.id)}
                className="w-full px-4 py-3 flex items-center justify-between text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
              >
                <span>Lifestyle Details</span>
                {expandedCards.has(adult.id) ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
              </button>

              {expandedCards.has(adult.id) && (
                <div className="px-4 pb-4 space-y-4">
                  {adult.work && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Work</p>
                      <div className="flex items-start gap-3 p-3 bg-slate-50 rounded-lg">
                        <Building2 className="w-5 h-5 text-slate-400 flex-shrink-0 mt-0.5" />
                        <div>
                          <p className="font-medium text-slate-900">{adult.work.company}</p>
                          <p className="text-sm text-slate-500">{adult.work.title}</p>
                          <p className="text-xs text-slate-400 mt-1">{adult.work.address}</p>
                        </div>
                      </div>
                    </div>
                  )}

                  {adult.clubs.length > 0 && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Memberships</p>
                      <div className="space-y-2">
                        {adult.clubs.map((club, idx) => (
                          <div key={idx} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center gap-3">
                              <Star className="w-5 h-5 text-amber-500" />
                              <div>
                                <p className="font-medium text-slate-900">{club.name}</p>
                                <p className="text-xs text-slate-400">{club.type} • {club.membershipId}</p>
                              </div>
                            </div>
                            {showFinancials && <span className="text-sm font-medium text-slate-600">{formatCurrency(club.monthlyDues)}/mo</span>}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {adult.wellness && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Wellness</p>
                      <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                        <Dumbbell className="w-5 h-5 text-purple-500" />
                        <div>
                          <p className="font-medium text-slate-900">{adult.wellness.gym}</p>
                          <p className="text-xs text-slate-400">ID: {adult.wellness.membershipId}</p>
                        </div>
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Children Section */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <Baby className="w-5 h-5 text-slate-400" />
          <h2 className="font-semibold text-slate-900">Children</h2>
          <span className="text-sm text-slate-500">({children.length})</span>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
          {children.map((child) => {
            const tuitionDue = child.school.tuitionDue ? getDaysUntil(child.school.tuitionDue) : null;
            const sizeOutdated = child.sizes?.lastUpdated && getDaysUntil(child.sizes.lastUpdated) <= -180;
            return (
              <div key={child.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                <div className="p-4 border-b border-slate-100">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 bg-blue-100 rounded-full flex items-center justify-center">
                        <span className="text-lg font-semibold text-blue-600">{child.initials}</span>
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900">{child.name}</h3>
                        <p className="text-sm text-slate-500">{child.age} years old • {child.grade}</p>
                        <div className="mt-1">{renderLocationPill(child.location)}</div>
                      </div>
                    </div>
                    <button onClick={() => setShowEditModal(child)} className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                      <Pencil className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {child.health.allergies.length > 0 && (
                  <div className="px-4 py-2 bg-red-50 border-b border-red-100 flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 text-red-600" />
                    <span className="text-sm text-red-700 font-medium">Allergies: {child.health.allergies.join(', ')}</span>
                  </div>
                )}

                <div className="p-4 border-b border-slate-100">
                  <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Education</p>
                  <div className="flex items-center justify-between p-3 bg-blue-50 rounded-lg">
                    <div className="flex items-center gap-3">
                      <GraduationCap className="w-5 h-5 text-blue-600" />
                      <div>
                        <p className="font-medium text-slate-900">{child.school.name}</p>
                        <p className="text-xs text-slate-500">{child.school.address}</p>
                      </div>
                    </div>
                    {child.school.tuitionMonthly > 0 && showFinancials && (
                      <div className="text-right">
                        <p className="text-sm font-medium text-slate-900">{formatCurrency(child.school.tuitionMonthly)}/mo</p>
                        {tuitionDue !== null && tuitionDue <= 7 && (
                          <span className="text-xs text-red-600 font-medium">Due in {tuitionDue} days</span>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                <button
                  onClick={() => toggleCard(child.id)}
                  className="w-full px-4 py-3 flex items-center justify-between text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
                >
                  <span>Activities & Support Team</span>
                  {expandedCards.has(child.id) ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                </button>

                {expandedCards.has(child.id) && (
                  <div className="px-4 pb-4 space-y-4">
                    {child.activities.length > 0 && (
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Activities</p>
                        <div className="space-y-2">
                          {child.activities.map((activity, idx) => (
                            <div key={idx} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                              <div className="flex items-center gap-3">
                                {activity.name.toLowerCase().includes('soccer') || activity.name.toLowerCase().includes('league') ? (
                                  <Trophy className="w-5 h-5 text-amber-500" />
                                ) : activity.name.toLowerCase().includes('piano') || activity.name.toLowerCase().includes('music') ? (
                                  <Music className="w-5 h-5 text-purple-500" />
                                ) : activity.name.toLowerCase().includes('art') ? (
                                  <Palette className="w-5 h-5 text-pink-500" />
                                ) : (
                                  <Star className="w-5 h-5 text-blue-500" />
                                )}
                                <div>
                                  <p className="font-medium text-slate-900">{activity.name}</p>
                                  <p className="text-xs text-slate-500">{activity.organization}</p>
                                  {activity.coachName && <p className="text-xs text-slate-400">{activity.coachName}</p>}
                                  <p className="text-xs text-slate-400 mt-0.5">
                                    <Timer className="w-3 h-3 inline mr-1" />{activity.schedule}
                                  </p>
                                </div>
                              </div>
                              {showFinancials && <span className="text-sm font-medium text-slate-600">{formatCurrency(activity.monthlyFee)}/mo</span>}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {child.careProvider && (
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Care Provider</p>
                        <div className="flex items-center gap-3 p-3 bg-purple-50 rounded-lg">
                          <Heart className="w-5 h-5 text-purple-600" />
                          <div>
                            <p className="font-medium text-slate-900">{child.careProvider.name}</p>
                            <p className="text-xs text-purple-600">View Schedule →</p>
                          </div>
                        </div>
                      </div>
                    )}

                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Health</p>
                      <div className="space-y-2">
                        <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                          <Stethoscope className="w-5 h-5 text-green-600" />
                          <div>
                            <p className="font-medium text-slate-900">{child.health.pediatrician}</p>
                            <p className="text-xs text-slate-400">{child.health.pediatricianPhone}</p>
                          </div>
                        </div>
                        {child.health.medications && child.health.medications.length > 0 && (
                          <div className="p-3 bg-amber-50 rounded-lg">
                            <p className="text-sm text-amber-700 font-medium">Medications: {child.health.medications.join(', ')}</p>
                          </div>
                        )}
                      </div>
                    </div>

                    {child.sizes && (
                      <div>
                        <div className="flex items-center justify-between mb-2">
                          <p className="text-xs font-medium text-slate-500 uppercase tracking-wide">Sizes</p>
                          {sizeOutdated && (
                            <span className="text-xs text-amber-600 flex items-center gap-1">
                              <AlertCircle className="w-3 h-3" />
                              May need update
                            </span>
                          )}
                        </div>
                        <div className="grid grid-cols-3 gap-2">
                          <div className="p-2 bg-slate-50 rounded-lg text-center">
                            <Shirt className="w-4 h-4 mx-auto text-slate-400 mb-1" />
                            <p className="text-xs text-slate-500">Shirt</p>
                            <p className="font-medium text-slate-900">{child.sizes.shirt}</p>
                          </div>
                          <div className="p-2 bg-slate-50 rounded-lg text-center">
                            <span className="text-slate-400 text-sm">👖</span>
                            <p className="text-xs text-slate-500">Pants</p>
                            <p className="font-medium text-slate-900">{child.sizes.pants}</p>
                          </div>
                          <div className="p-2 bg-slate-50 rounded-lg text-center">
                            <Footprints className="w-4 h-4 mx-auto text-slate-400 mb-1" />
                            <p className="text-xs text-slate-500">Shoe</p>
                            <p className="font-medium text-slate-900">{child.sizes.shoe}</p>
                          </div>
                        </div>
                        {sizeOutdated && (
                          <button
                            onClick={() => toast(`${MANAGER_NAME} will ask about ${child.name}'s current sizes`)}
                            className="w-full mt-2 py-2 text-sm text-amber-700 bg-amber-50 rounded-lg hover:bg-amber-100 transition-colors"
                          >
                            Ask Sarah to order new clothes?
                          </button>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Pets Section */}
      <div>
        <div className="flex items-center gap-2 mb-4">
          <Dog className="w-5 h-5 text-slate-400" />
          <h2 className="font-semibold text-slate-900">Pets</h2>
          <span className="text-sm text-slate-500">({pets.length})</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {pets.map((pet) => {
            const vaccinesDays = pet.vaccinesDue ? getDaysUntil(pet.vaccinesDue) : null;
            return (
              <div key={pet.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                <div className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 bg-amber-100 rounded-full flex items-center justify-center">
                        {pet.species === 'cat' ? <Cat className="w-7 h-7 text-amber-600" /> : <Dog className="w-7 h-7 text-amber-600" />}
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900">{pet.name}</h3>
                        <p className="text-sm text-slate-500">{pet.breed} • {pet.age} years old</p>
                        <div className="mt-1">{renderLocationPill(pet.location)}</div>
                      </div>
                    </div>
                    <button onClick={() => setShowEditModal(pet)} className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                      <Pencil className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {vaccinesDays !== null && vaccinesDays <= 30 && (
                  <div className={`px-4 py-2 flex items-center justify-between ${
                    vaccinesDays <= 7 ? 'bg-red-50 border-b border-red-100' : 'bg-amber-50 border-b border-amber-100'
                  }`}>
                    <div className="flex items-center gap-2">
                      <AlertCircle className={`w-4 h-4 ${vaccinesDays <= 7 ? 'text-red-600' : 'text-amber-600'}`} />
                      <span className={`text-sm font-medium ${vaccinesDays <= 7 ? 'text-red-700' : 'text-amber-700'}`}>
                        Vaccines due {pet.vaccinesDue && formatDate(pet.vaccinesDue)}
                      </span>
                    </div>
                    <button
                      onClick={() => toast(`${MANAGER_NAME} will schedule ${pet.name}'s vet visit`)}
                      className={`text-xs font-medium ${vaccinesDays <= 7 ? 'text-red-600' : 'text-amber-600'}`}
                    >
                      Schedule →
                    </button>
                  </div>
                )}

                <div className="p-4 space-y-3 bg-slate-50">
                  <div className="flex items-center gap-3">
                    <Syringe className="w-4 h-4 text-slate-400" />
                    <div>
                      <p className="text-sm font-medium text-slate-900">{pet.vet.name}</p>
                      <p className="text-xs text-slate-500">{pet.vet.clinic} • {pet.vet.phone}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Utensils className="w-4 h-4 text-slate-400" />
                    <div>
                      <p className="text-sm font-medium text-slate-900">{pet.food.brand}</p>
                      <p className="text-xs text-slate-500">{pet.food.type} • {pet.food.monthlyAmount}/mo</p>
                    </div>
                  </div>
                  {pet.microchipId && (
                    <div className="flex items-center gap-3">
                      <Shield className="w-4 h-4 text-slate-400" />
                      <p className="text-sm text-slate-600">Microchip: {pet.microchipId}</p>
                    </div>
                  )}
                  {showFinancials && pet.monthlyExpenses > 0 && (
                    <div className="pt-2 border-t border-slate-200">
                      <p className="text-xs text-slate-500">Monthly Expenses</p>
                      <p className="font-semibold text-slate-900">{formatCurrency(pet.monthlyExpenses)}</p>
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Vehicles Section */}
      {vehicles.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-4">
            <Car className="w-5 h-5 text-slate-400" />
            <h2 className="font-semibold text-slate-900">Vehicles</h2>
            <span className="text-sm text-slate-500">({vehicles.length})</span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {vehicles.map((vehicle) => {
              const regDays = vehicle.registrationExpiry ? getDaysUntil(vehicle.registrationExpiry) : null;
              const serviceDays = vehicle.nextServiceDue ? getDaysUntil(vehicle.nextServiceDue) : null;
              const isElectric = vehicle.make === 'Tesla' || vehicle.model.toLowerCase().includes('electric');

              return (
                <div key={vehicle.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                  {/* Vehicle Header */}
                  <div className="p-4 border-b border-slate-100">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-4">
                        <div className={`w-14 h-14 rounded-full flex items-center justify-center ${
                          isElectric ? 'bg-green-100' : 'bg-blue-100'
                        }`}>
                          <Car className={`w-7 h-7 ${isElectric ? 'text-green-600' : 'text-blue-600'}`} />
                        </div>
                        <div>
                          <h3 className="font-semibold text-slate-900">{vehicle.name}</h3>
                          <p className="text-sm text-slate-500">{vehicle.year} {vehicle.make} {vehicle.model}</p>
                          <div className="flex items-center gap-2 mt-1">
                            <span className="text-xs text-slate-400">{vehicle.color}</span>
                            <span className="text-xs text-slate-400">•</span>
                            <span className="text-xs font-mono text-slate-500">{vehicle.licensePlate}</span>
                          </div>
                        </div>
                      </div>
                      <button
                        onClick={() => toggleCard(vehicle.id)}
                        className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                      >
                        {expandedCards.has(vehicle.id) ? <ChevronDown className="w-4 h-4" /> : <ChevronRight className="w-4 h-4" />}
                      </button>
                    </div>
                  </div>

                  {/* Alerts Row */}
                  {((regDays !== null && regDays <= 60) || (serviceDays !== null && serviceDays <= 30)) && (
                    <div className="px-4 py-2 bg-amber-50 border-b border-amber-100 flex flex-wrap gap-3">
                      {regDays !== null && regDays <= 60 && (
                        <div className="flex items-center gap-2">
                          <AlertCircle className={`w-4 h-4 ${regDays <= 14 ? 'text-red-600' : 'text-amber-600'}`} />
                          <span className={`text-xs font-medium ${regDays <= 14 ? 'text-red-700' : 'text-amber-700'}`}>
                            Registration expires in {regDays} days
                          </span>
                        </div>
                      )}
                      {serviceDays !== null && serviceDays <= 30 && (
                        <div className="flex items-center gap-2">
                          <AlertCircle className={`w-4 h-4 ${serviceDays <= 7 ? 'text-red-600' : 'text-amber-600'}`} />
                          <span className={`text-xs font-medium ${serviceDays <= 7 ? 'text-red-700' : 'text-amber-700'}`}>
                            Service due in {serviceDays} days
                          </span>
                        </div>
                      )}
                    </div>
                  )}

                  {/* Quick Stats */}
                  <div className="px-4 py-3 bg-slate-50 grid grid-cols-3 gap-3 text-center border-b border-slate-100">
                    <div>
                      <p className="text-xs text-slate-500">Mileage</p>
                      <p className="font-semibold text-slate-900">{vehicle.currentMileage.toLocaleString()}</p>
                    </div>
                    <div>
                      <p className="text-xs text-slate-500">Primary Driver</p>
                      <p className="font-medium text-slate-700 text-sm">{vehicle.primaryDriverName?.split(' ')[0] || 'Unassigned'}</p>
                    </div>
                    {showFinancials && (
                      <div>
                        <p className="text-xs text-slate-500">Monthly Cost</p>
                        <p className="font-semibold text-slate-900">
                          {formatCurrency((vehicle.monthlyPayment || 0) + (vehicle.insuranceMonthly || 0))}
                        </p>
                      </div>
                    )}
                  </div>

                  {/* Expanded Details */}
                  {expandedCards.has(vehicle.id) && (
                    <div className="p-4 space-y-4">
                      {/* Registration & Insurance */}
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Registration & Insurance</p>
                        <div className="grid grid-cols-2 gap-3">
                          <div className="p-3 bg-slate-50 rounded-lg">
                            <p className="text-xs text-slate-500">Registration</p>
                            <p className="font-medium text-slate-900">
                              {vehicle.registrationExpiry ? formatDate(vehicle.registrationExpiry) : 'Not set'}
                            </p>
                            <p className="text-xs text-slate-400">{vehicle.registrationState}</p>
                          </div>
                          <div className="p-3 bg-slate-50 rounded-lg">
                            <p className="text-xs text-slate-500">Insurance</p>
                            <p className="font-medium text-slate-900">{vehicle.insuranceProvider || 'Not set'}</p>
                            {vehicle.insuranceMonthly && showFinancials && (
                              <p className="text-xs text-slate-400">{formatCurrency(vehicle.insuranceMonthly)}/mo</p>
                            )}
                          </div>
                        </div>
                      </div>

                      {/* Loan Info */}
                      {vehicle.hasLoan && showFinancials && (
                        <div>
                          <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Loan Details</p>
                          <div className="p-3 bg-slate-50 rounded-lg">
                            <div className="flex items-center justify-between mb-2">
                              <span className="text-sm text-slate-600">{vehicle.lender}</span>
                              <span className="font-semibold text-slate-900">{formatCurrency(vehicle.monthlyPayment || 0)}/mo</span>
                            </div>
                            <div className="flex items-center justify-between text-xs text-slate-500">
                              <span>Balance: {formatCurrency(vehicle.loanBalance || 0)}</span>
                              {vehicle.loanMaturityDate && (
                                <span>Payoff: {vehicle.loanMaturityDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}</span>
                              )}
                            </div>
                          </div>
                        </div>
                      )}

                      {/* Service Info */}
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Service</p>
                        <div className="p-3 bg-slate-50 rounded-lg space-y-2">
                          {!isElectric && vehicle.lastOilChange && (
                            <div className="flex items-center justify-between text-sm">
                              <span className="text-slate-600">Last Oil Change</span>
                              <span className="text-slate-900">
                                {formatDate(vehicle.lastOilChange)} ({vehicle.oilChangeMileage?.toLocaleString()} mi)
                              </span>
                            </div>
                          )}
                          {vehicle.nextServiceDue && (
                            <div className="flex items-center justify-between text-sm">
                              <span className="text-slate-600">Next Service</span>
                              <span className={`font-medium ${serviceDays !== null && serviceDays <= 14 ? 'text-amber-600' : 'text-slate-900'}`}>
                                {formatDate(vehicle.nextServiceDue)}
                                {vehicle.nextServiceMileage && ` (${vehicle.nextServiceMileage.toLocaleString()} mi)`}
                              </span>
                            </div>
                          )}
                          {vehicle.preferredServiceShop && (
                            <div className="flex items-center justify-between text-sm pt-2 border-t border-slate-200">
                              <span className="text-slate-500">Preferred Shop</span>
                              <span className="text-slate-700">{vehicle.preferredServiceShop}</span>
                            </div>
                          )}
                        </div>
                      </div>

                      {/* Recent Service History */}
                      {vehicle.serviceHistory && vehicle.serviceHistory.length > 0 && (
                        <div>
                          <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Recent Service History</p>
                          <div className="space-y-2">
                            {vehicle.serviceHistory.slice(0, 3).map((service) => (
                              <div key={service.id} className="flex items-center justify-between p-2 bg-slate-50 rounded-lg text-sm">
                                <div>
                                  <p className="font-medium text-slate-900">{service.serviceType}</p>
                                  <p className="text-xs text-slate-500">
                                    {formatDate(service.date)} • {service.mileage.toLocaleString()} mi
                                  </p>
                                </div>
                                {showFinancials && service.cost > 0 && (
                                  <span className="text-slate-600">{formatCurrency(service.cost)}</span>
                                )}
                              </div>
                            ))}
                          </div>
                        </div>
                      )}

                      {/* Quick Actions */}
                      <div className="flex gap-2 pt-2">
                        <button
                          onClick={() => toast(`${MANAGER_NAME} will schedule service for ${vehicle.name}`)}
                          className="flex-1 flex items-center justify-center gap-2 py-2 text-sm font-medium text-emerald-700 bg-emerald-50 rounded-lg hover:bg-emerald-100 transition-colors"
                        >
                          <ClipboardList className="w-4 h-4" />
                          Schedule Service
                        </button>
                        <button
                          onClick={() => toast('Opening vehicle details...')}
                          className="flex-1 flex items-center justify-center gap-2 py-2 text-sm font-medium text-slate-600 bg-slate-100 rounded-lg hover:bg-slate-200 transition-colors"
                        >
                          <FileText className="w-4 h-4" />
                          View Details
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Staff Section */}
      {staff.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-4">
            <BadgeCheck className="w-5 h-5 text-slate-400" />
            <h2 className="font-semibold text-slate-900">Household Staff</h2>
            <span className="text-sm text-slate-500">({staff.length})</span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {staff.map((s) => {
              const contractDays = s.contractEndDate ? getDaysUntil(s.contractEndDate) : null;
              return (
                <div key={s.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                  <div className="p-4 border-b border-slate-100">
                    <div className="flex items-start justify-between">
                      <div className="flex items-center gap-4">
                        <div className="w-14 h-14 bg-purple-100 rounded-full flex items-center justify-center">
                          <span className="text-lg font-semibold text-purple-600">{s.initials}</span>
                        </div>
                        <div>
                          <div className="flex items-center gap-2">
                            <h3 className="font-semibold text-slate-900">{s.name}</h3>
                            <span className="px-2 py-0.5 bg-purple-100 text-purple-700 text-xs font-medium rounded-full">{s.role}</span>
                          </div>
                          {s.agency && <p className="text-sm text-slate-500">via {s.agency}</p>}
                          <div className="mt-1">{renderLocationPill(s.location)}</div>
                        </div>
                      </div>
                      <button onClick={() => setShowEditModal(s)} className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors">
                        <Pencil className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  {contractDays !== null && contractDays <= 14 && (
                    <div className={`px-4 py-2 flex items-center justify-between ${
                      contractDays <= 7 ? 'bg-red-50 border-b border-red-100' : 'bg-amber-50 border-b border-amber-100'
                    }`}>
                      <div className="flex items-center gap-2">
                        <AlertCircle className={`w-4 h-4 ${contractDays <= 7 ? 'text-red-600' : 'text-amber-600'}`} />
                        <span className={`text-sm font-medium ${contractDays <= 7 ? 'text-red-700' : 'text-amber-700'}`}>
                          Contract expires in {contractDays} days
                        </span>
                      </div>
                      <button
                        onClick={() => toast(`${MANAGER_NAME} will handle contract renewal`)}
                        className={`text-xs font-medium ${contractDays <= 7 ? 'text-red-600' : 'text-amber-600'}`}
                      >
                        Renew →
                      </button>
                    </div>
                  )}

                  <div className="px-4 py-3 bg-slate-50 flex items-center gap-4 border-b border-slate-100">
                    <button className="flex items-center gap-1.5 text-sm text-slate-600 hover:text-emerald-600 transition-colors">
                      <Phone className="w-4 h-4" />
                      {s.phone || 'No phone'}
                    </button>
                    <button className="flex items-center gap-1.5 text-sm text-slate-600 hover:text-emerald-600 transition-colors">
                      <MessageCircle className="w-4 h-4" />
                      Message
                    </button>
                  </div>

                  {s.schedule.length > 0 && (
                    <div className="p-4">
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Weekly Schedule</p>
                      <div className="grid grid-cols-5 gap-1">
                        {s.schedule.map((day, idx) => (
                          <div key={idx} className="text-center p-2 bg-purple-50 rounded-lg">
                            <p className="text-xs font-medium text-purple-700">{day.day.slice(0, 3)}</p>
                            <p className="text-xs text-slate-600 mt-0.5">{day.hours.split(' - ')[0]}</p>
                            <p className="text-xs text-slate-600">{day.hours.split(' - ')[1]}</p>
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  <div className="px-4 pb-4 space-y-3">
                    {s.permissions.length > 0 && (
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">App Permissions</p>
                        <div className="flex flex-wrap gap-2">
                          {s.permissions.map((perm, idx) => (
                            <span key={idx} className="flex items-center gap-1 px-2 py-1 bg-slate-100 text-slate-600 text-xs rounded-full">
                              <Check className="w-3 h-3 text-green-600" />
                              {perm}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    {showFinancials && s.weeklyStipend > 0 && (
                      <div className="pt-3 border-t border-slate-200">
                        <div className="flex items-center justify-between">
                          <p className="text-sm text-slate-500">Weekly Stipend</p>
                          <p className="font-semibold text-slate-900">{formatCurrency(s.weeklyStipend)}</p>
                        </div>
                        <p className="text-xs text-slate-400 mt-0.5">
                          Since {s.startDate.toLocaleDateString('en-US', { month: 'short', year: 'numeric' })}
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Emergency Card Modal */}
      {showEmergencyCard && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowEmergencyCard(false)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-slate-200 bg-red-50">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-red-100 rounded-lg flex items-center justify-center">
                      <Shield className="w-5 h-5 text-red-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-900">Emergency Info Card</h3>
                      <p className="text-sm text-slate-500">Print for babysitters</p>
                    </div>
                  </div>
                  <button onClick={() => setShowEmergencyCard(false)} className="p-2 hover:bg-red-100 rounded-lg transition-colors">
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-6">
                {/* Emergency Contacts */}
                <div>
                  <h4 className="font-medium text-slate-900 mb-3 flex items-center gap-2">
                    <Phone className="w-4 h-4 text-red-500" />
                    Emergency Contacts
                  </h4>
                  <div className="space-y-2 bg-slate-50 p-4 rounded-lg">
                    {adults.map(a => (
                      <div key={a.id} className="flex justify-between">
                        <span className="font-medium">{a.name}</span>
                        <span className="text-slate-600">{a.phone}</span>
                      </div>
                    ))}
                    <div className="pt-2 mt-2 border-t border-slate-200">
                      <div className="flex justify-between">
                        <span className="font-medium">Poison Control</span>
                        <span className="text-slate-600">1-800-222-1222</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Kids Info */}
                {children.map(child => (
                  <div key={child.id}>
                    <h4 className="font-medium text-slate-900 mb-3">{child.name}</h4>
                    <div className="space-y-2 bg-slate-50 p-4 rounded-lg text-sm">
                      {child.health.allergies.length > 0 && (
                        <div className="p-2 bg-red-100 rounded-lg">
                          <p className="font-medium text-red-700">ALLERGIES: {child.health.allergies.join(', ')}</p>
                        </div>
                      )}
                      {child.health.medications && child.health.medications.length > 0 && (
                        <div className="p-2 bg-amber-100 rounded-lg">
                          <p className="font-medium text-amber-700">Medications: {child.health.medications.join(', ')}</p>
                        </div>
                      )}
                      <div className="flex justify-between">
                        <span>Pediatrician</span>
                        <span className="font-medium">{child.health.pediatrician}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Doctor Phone</span>
                        <span className="font-medium">{child.health.pediatricianPhone}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>School</span>
                        <span className="font-medium">{child.school.name}</span>
                      </div>
                    </div>
                  </div>
                ))}

                {/* Pet Info */}
                {pets.length > 0 && (
                  <div>
                    <h4 className="font-medium text-slate-900 mb-3 flex items-center gap-2">
                      <Dog className="w-4 h-4 text-amber-500" />
                      Pet Info
                    </h4>
                    <div className="space-y-2 bg-slate-50 p-4 rounded-lg text-sm">
                      {pets.map(pet => (
                        <div key={pet.id}>
                          <p className="font-medium">{pet.name} ({pet.breed})</p>
                          <p className="text-slate-500">Vet: {pet.vet.clinic} - {pet.vet.phone}</p>
                        </div>
                      ))}
                    </div>
                  </div>
                )}

                {/* Home Info */}
                <div>
                  <h4 className="font-medium text-slate-900 mb-3 flex items-center gap-2">
                    <Home className="w-4 h-4 text-slate-500" />
                    Home Info
                  </h4>
                  <div className="space-y-2 bg-slate-50 p-4 rounded-lg text-sm">
                    <div className="flex justify-between">
                      <span>WiFi Password</span>
                      <span className="font-medium font-mono">MillerFamily2024</span>
                    </div>
                    <div className="flex justify-between">
                      <span>Alarm Code</span>
                      <span className="font-medium font-mono">****</span>
                    </div>
                  </div>
                </div>
              </div>

              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => toast('Printing emergency card...')}
                  className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-slate-100 text-slate-700 font-medium rounded-lg hover:bg-slate-200 transition-colors"
                >
                  <Printer className="w-4 h-4" />
                  Print
                </button>
                <button
                  onClick={() => toast('Downloading PDF...')}
                  className="flex-1 flex items-center justify-center gap-2 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  <Download className="w-4 h-4" />
                  Download PDF
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Sync to Calendar Modal */}
      {showSyncModal === 'calendar' && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowSyncModal(null)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                      <Calendar className="w-5 h-5 text-blue-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-900">Sync to Calendar</h3>
                      <p className="text-sm text-slate-500">{autoCalendarEvents.length} events from family data</p>
                    </div>
                  </div>
                  <button onClick={() => setShowSyncModal(null)} className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4 max-h-[400px] overflow-y-auto">
                {autoCalendarEvents.map((event, idx) => (
                  <div key={idx} className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                    <CheckCircle2 className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-slate-900 text-sm">{event.title}</p>
                      <p className="text-xs text-slate-500">{event.schedule}</p>
                    </div>
                    <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${
                      event.type === 'recurring' ? 'bg-blue-100 text-blue-700' :
                      event.type === 'availability' ? 'bg-purple-100 text-purple-700' :
                      'bg-amber-100 text-amber-700'
                    }`}>
                      {event.type}
                    </span>
                  </div>
                ))}
              </div>

              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => setShowSyncModal(null)}
                  className="flex-1 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={handleSyncToCalendar}
                  className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors flex items-center justify-center gap-2"
                >
                  <RefreshCw className="w-4 h-4" />
                  Sync All Events
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Sync to Billing Modal */}
      {showSyncModal === 'billing' && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowSyncModal(null)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 bg-emerald-100 rounded-lg flex items-center justify-center">
                      <CreditCard className="w-5 h-5 text-emerald-600" />
                    </div>
                    <div>
                      <h3 className="text-lg font-semibold text-slate-900">Create Bill Accounts</h3>
                      <p className="text-sm text-slate-500">{autoBillAccounts.length} recurring bills detected</p>
                    </div>
                  </div>
                  <button onClick={() => setShowSyncModal(null)} className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4 max-h-[400px] overflow-y-auto">
                {autoBillAccounts.map((account) => (
                  <div key={account.id} className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                    <CheckCircle2 className="w-5 h-5 text-emerald-500 flex-shrink-0" />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-slate-900 text-sm">{account.name}</p>
                      <p className="text-xs text-slate-500">For {account.recipient}</p>
                    </div>
                    <div className="text-right">
                      <p className="font-medium text-slate-900">{formatCurrency(account.amount)}</p>
                      <p className="text-xs text-slate-500">/{account.frequency}</p>
                    </div>
                  </div>
                ))}
              </div>

              <div className="p-6 border-t border-slate-200">
                <div className="flex items-center justify-between mb-4 p-3 bg-emerald-50 rounded-lg">
                  <span className="text-sm font-medium text-emerald-700">Total Monthly</span>
                  <span className="text-lg font-bold text-emerald-700">
                    {formatCurrency(autoBillAccounts.reduce((sum, a) => {
                      if (a.frequency === 'weekly') return sum + a.amount * 4.33;
                      if (a.frequency === 'monthly') return sum + a.amount;
                      if (a.frequency === 'quarterly') return sum + a.amount / 3;
                      if (a.frequency === 'annually') return sum + a.amount / 12;
                      return sum;
                    }, 0))}
                  </span>
                </div>
                <div className="flex gap-3">
                  <button
                    onClick={() => setShowSyncModal(null)}
                    className="flex-1 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
                  >
                    Cancel
                  </button>
                  <button
                    onClick={handleSyncToBilling}
                    className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors flex items-center justify-center gap-2"
                  >
                    <CreditCard className="w-4 h-4" />
                    Create Accounts
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Add Member Modal */}
      {showAddMemberModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => {
              setShowAddMemberModal(false);
              setAddMemberStep('select');
              setAddMemberType(null);
            }} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-md">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">
                    {addMemberStep === 'select' ? 'Add Family Member' : `Add ${addMemberType}`}
                  </h3>
                  <button
                    onClick={() => {
                      setShowAddMemberModal(false);
                      setAddMemberStep('select');
                      setAddMemberType(null);
                    }}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6">
                {addMemberStep === 'select' ? (
                  <>
                    <p className="text-sm text-slate-500 mb-4">What type of member would you like to add?</p>
                    <div className="grid grid-cols-2 gap-3">
                      {[
                        { type: 'adult' as AddMemberType, icon: User, label: 'Adult', description: 'Invite via email', color: 'emerald' },
                        { type: 'child' as AddMemberType, icon: Baby, label: 'Child', description: 'Create profile', color: 'blue' },
                        { type: 'pet' as AddMemberType, icon: Dog, label: 'Pet', description: 'Add pet profile', color: 'amber' },
                        { type: 'staff' as AddMemberType, icon: BadgeCheck, label: 'Staff', description: 'Nanny, Au Pair, etc.', color: 'purple' },
                      ].map((option) => {
                        const Icon = option.icon;
                        return (
                          <button
                            key={option.type}
                            onClick={() => {
                              setAddMemberType(option.type);
                              setAddMemberStep('form');
                            }}
                            className="flex flex-col items-center p-4 border-2 border-slate-200 rounded-xl hover:border-emerald-500 hover:bg-emerald-50/50 transition-colors text-center"
                          >
                            <div className={`w-12 h-12 bg-${option.color}-100 rounded-full flex items-center justify-center mb-2`}>
                              <Icon className={`w-6 h-6 text-${option.color}-600`} />
                            </div>
                            <p className="font-medium text-slate-900">{option.label}</p>
                            <p className="text-xs text-slate-500">{option.description}</p>
                          </button>
                        );
                      })}
                    </div>
                  </>
                ) : (
                  <AddMemberForm
                    type={addMemberType!}
                    onSubmit={handleAddMember}
                    onCancel={() => {
                      setAddMemberStep('select');
                      setAddMemberType(null);
                    }}
                    isSubmitting={isSubmitting}
                  />
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Edit Member Modal */}
      {showEditModal && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-black/50" onClick={() => setShowEditModal(null)} />
            <div className="relative bg-white rounded-xl shadow-xl w-full max-w-lg">
              <div className="p-6 border-b border-slate-200">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold text-slate-900">Edit {showEditModal.name}</h3>
                  <button onClick={() => setShowEditModal(null)} className="p-2 hover:bg-slate-100 rounded-lg transition-colors">
                    <X className="w-5 h-5 text-slate-400" />
                  </button>
                </div>
              </div>

              <div className="p-6 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">Name</label>
                  <input
                    type="text"
                    defaultValue={showEditModal.name}
                    className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                  />
                </div>

                {showEditModal.type === 'child' && (
                  <>
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">Age</label>
                        <input
                          type="number"
                          defaultValue={(showEditModal as ChildMember).age}
                          className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium text-slate-700 mb-2">Grade</label>
                        <input
                          type="text"
                          defaultValue={(showEditModal as ChildMember).grade}
                          className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Sizes (for shopping)</label>
                      <div className="grid grid-cols-3 gap-3">
                        <div>
                          <label className="block text-xs text-slate-500 mb-1">Shirt</label>
                          <input
                            type="text"
                            defaultValue={(showEditModal as ChildMember).sizes?.shirt}
                            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-sm"
                          />
                        </div>
                        <div>
                          <label className="block text-xs text-slate-500 mb-1">Pants</label>
                          <input
                            type="text"
                            defaultValue={(showEditModal as ChildMember).sizes?.pants}
                            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-sm"
                          />
                        </div>
                        <div>
                          <label className="block text-xs text-slate-500 mb-1">Shoe</label>
                          <input
                            type="text"
                            defaultValue={(showEditModal as ChildMember).sizes?.shoe}
                            className="w-full px-3 py-2 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent text-sm"
                          />
                        </div>
                      </div>
                    </div>
                  </>
                )}

                {showEditModal.type === 'pet' && (
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Breed</label>
                      <input
                        type="text"
                        defaultValue={(showEditModal as PetMember).breed}
                        className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-2">Age</label>
                      <input
                        type="number"
                        defaultValue={(showEditModal as PetMember).age}
                        className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                      />
                    </div>
                  </div>
                )}
              </div>

              <div className="p-6 border-t border-slate-200 flex gap-3">
                <button
                  onClick={() => setShowEditModal(null)}
                  className="flex-1 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => {
                    setShowEditModal(null);
                    toast('Changes saved');
                  }}
                  className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {showToast && (
        <div className="fixed bottom-20 left-1/2 -translate-x-1/2 z-50 px-4 py-2 bg-slate-900 text-white rounded-lg shadow-lg text-sm animate-fade-in">
          {showToast}
        </div>
      )}

      {/* Mobile FAB */}
      <div className="fixed bottom-24 right-4 sm:hidden flex flex-col gap-2">
        <button
          onClick={() => setShowEmergencyCard(true)}
          className="w-12 h-12 bg-red-500 text-white rounded-full shadow-lg flex items-center justify-center hover:bg-red-600 transition-colors"
        >
          <Shield className="w-5 h-5" />
        </button>
        <button
          onClick={() => setShowAddMemberModal(true)}
          className="w-14 h-14 bg-emerald-600 text-white rounded-full shadow-lg flex items-center justify-center hover:bg-emerald-700 transition-colors"
        >
          <Plus className="w-6 h-6" />
        </button>
      </div>
    </div>
  );
}

// ============================================================================
// ADD MEMBER FORM COMPONENT
// ============================================================================

interface AddMemberFormProps {
  type: AddMemberType;
  onSubmit: (data: AddMemberFormData) => void;
  onCancel: () => void;
  isSubmitting: boolean;
}

function AddMemberForm({ type, onSubmit, onCancel, isSubmitting }: AddMemberFormProps) {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [petType, setPetType] = useState<PetType>('DOG');
  const [breed, setBreed] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      type,
      name,
      email: email || undefined,
      phone: phone || undefined,
      petType: type === 'pet' ? petType : undefined,
      breed: type === 'pet' ? breed : undefined,
    });
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-slate-700 mb-2">Name *</label>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
          placeholder={type === 'pet' ? "Pet's name" : 'Full name'}
        />
      </div>

      {type === 'pet' ? (
        <>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Type</label>
            <select
              value={petType}
              onChange={(e) => setPetType(e.target.value as PetType)}
              className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
            >
              <option value="DOG">Dog</option>
              <option value="CAT">Cat</option>
              <option value="BIRD">Bird</option>
              <option value="FISH">Fish</option>
              <option value="REPTILE">Reptile</option>
              <option value="SMALL_ANIMAL">Small Animal</option>
              <option value="OTHER">Other</option>
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Breed</label>
            <input
              type="text"
              value={breed}
              onChange={(e) => setBreed(e.target.value)}
              className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              placeholder="e.g., Golden Retriever"
            />
          </div>
        </>
      ) : (
        <>
          {(type === 'adult' || type === 'staff') && (
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">Email</label>
              <input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
                placeholder="email@example.com"
              />
              {type === 'adult' && (
                <p className="text-xs text-slate-500 mt-1">An invitation will be sent to this email</p>
              )}
            </div>
          )}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">Phone</label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full px-4 py-2.5 border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent"
              placeholder="(555) 555-5555"
            />
          </div>
        </>
      )}

      <div className="flex gap-3 pt-2">
        <button
          type="button"
          onClick={onCancel}
          className="flex-1 py-2.5 border border-slate-200 text-slate-700 font-medium rounded-lg hover:bg-slate-50 transition-colors"
        >
          Back
        </button>
        <button
          type="submit"
          disabled={!name || isSubmitting}
          className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {isSubmitting && <Loader2 className="w-4 h-4 animate-spin" />}
          {type === 'pet' ? 'Add Pet' : 'Add Member'}
        </button>
      </div>
    </form>
  );
}
