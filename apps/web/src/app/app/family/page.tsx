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
}

type FamilyMember = AdultMember | ChildMember | PetMember | StaffMember;

// ============================================================================
// MOCK DATA (Fallback for demo mode)
// ============================================================================

const MOCK_ADULTS: AdultMember[] = [
  {
    id: 'a1',
    type: 'adult',
    name: 'Bob Miller',
    initials: 'BM',
    role: 'Dad / Admin',
    isAdmin: true,
    email: 'bob@miller.family',
    phone: '(512) 555-0101',
    location: { status: 'work', label: 'At Work', returnTime: '6:30 PM', eventName: 'Miller Consulting' },
    work: {
      company: 'Miller Consulting',
      title: 'Managing Partner',
      address: '100 Congress Ave, Suite 400, Austin, TX',
    },
    clubs: [
      { name: 'Austin Country Club', type: 'Golf', membershipId: 'ACC-4521', monthlyDues: 750 },
      { name: 'Capital City Club', type: 'Social', membershipId: 'CCC-1122', monthlyDues: 250 },
    ],
    wellness: { gym: 'Equinox - Downtown', membershipId: 'EQ-88721' },
    civic: ['Rotary Club', 'Austin Chamber of Commerce'],
  },
  {
    id: 'a2',
    type: 'adult',
    name: 'Alice Miller',
    initials: 'AM',
    role: 'Mom',
    isAdmin: false,
    email: 'alice@miller.family',
    phone: '(512) 555-0102',
    location: { status: 'activity', label: 'At Yoga', returnTime: '11:30 AM', eventName: 'CorePower Yoga' },
    work: {
      company: 'Self-Employed',
      title: 'Interior Designer',
      address: 'Home Office',
    },
    clubs: [
      { name: 'Junior League of Austin', type: 'Civic', membershipId: 'JLA-2234', monthlyDues: 100 },
    ],
    wellness: { gym: 'CorePower Yoga - Westlake', membershipId: 'CP-44521' },
    civic: ['Junior League of Austin', 'Garden Club'],
  },
];

const MOCK_CHILDREN: ChildMember[] = [
  {
    id: 'c1',
    type: 'child',
    name: 'Emma Miller',
    initials: 'EM',
    age: 12,
    grade: '7th Grade',
    location: { status: 'school', label: 'At School', returnTime: '3:30 PM', eventName: 'Westlake Middle School' },
    school: {
      name: 'Westlake Middle School',
      tuitionMonthly: 2200,
      tuitionDue: new Date(Date.now() + 5 * 24 * 60 * 60 * 1000),
      address: '4100 Westbank Dr, Austin, TX',
    },
    activities: [
      { name: 'Travel Soccer', organization: 'Lonestar SC', coachName: 'Coach Martinez', monthlyFee: 350, schedule: 'Tue/Thu 5-7pm, Sat 9am' },
      { name: 'Piano Lessons', organization: 'Austin Music Academy', monthlyFee: 200, schedule: 'Wed 4pm' },
    ],
    careProvider: { name: 'Maria Santos', id: 's1' },
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(512) 555-PEDS',
      allergies: ['Peanuts', 'Tree nuts'],
      medications: ['EpiPen (emergency)'],
    },
    sizes: { shirt: 'Youth M', pants: '12', shoe: '6' },
  },
  {
    id: 'c2',
    type: 'child',
    name: 'Jake Miller',
    initials: 'JM',
    age: 8,
    grade: '3rd Grade',
    location: { status: 'school', label: 'At School', returnTime: '3:00 PM', eventName: 'Eanes Elementary' },
    school: {
      name: 'Eanes Elementary',
      tuitionMonthly: 0, // Public school
      address: '4101 Bee Cave Rd, Austin, TX',
    },
    activities: [
      { name: 'Little League', organization: 'West Austin Little League', coachName: 'Coach Johnson', monthlyFee: 75, schedule: 'Mon/Wed 5pm' },
      { name: 'Art Class', organization: 'Creative Kids Studio', monthlyFee: 150, schedule: 'Sat 10am' },
    ],
    careProvider: { name: 'Maria Santos', id: 's1' },
    health: {
      pediatrician: 'Dr. Sarah Chen',
      pediatricianPhone: '(512) 555-PEDS',
      allergies: [],
    },
    sizes: { shirt: 'Youth S', pants: '8', shoe: '3' },
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
    vaccinesDue: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
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
    name: 'Maria Santos',
    initials: 'MS',
    role: 'Nanny',
    agency: 'Austin Elite Nannies',
    email: 'maria.s@austinnannies.com',
    phone: '(512) 555-0199',
    location: { status: 'home', label: 'At Home', eventName: 'With kids' },
    weeklyStipend: 1200,
    schedule: [
      { day: 'Monday', hours: '7am - 6pm' },
      { day: 'Tuesday', hours: '7am - 6pm' },
      { day: 'Wednesday', hours: '7am - 6pm' },
      { day: 'Thursday', hours: '7am - 6pm' },
      { day: 'Friday', hours: '7am - 3pm' },
    ],
    permissions: ["Kids' Schedules", 'Emergency Contacts', 'Medical Info'],
    startDate: new Date(2023, 5, 15),
  },
];

// ============================================================================
// MAPPING FUNCTIONS
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
  // MemberProfile has emergencyPhone and workPhone, use workPhone for adults
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
    age: 0, // Would need to calculate from profile.birthday
    grade: '',
    location: { status: 'unknown', label: 'Unknown' },
    school: {
      name: 'Not set',
      tuitionMonthly: 0,
      address: '',
    },
    activities: [],
    health: {
      pediatrician: 'Not set',
      pediatricianPhone: '',
      allergies: apiMember.profile?.dietaryRestrictions || [],
    },
    sizes: apiMember.profile?.shirtSize
      ? {
          shirt: apiMember.profile.shirtSize,
          pants: '',
          shoe: '',
        }
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
    case 'DOG':
      return 'dog';
    case 'CAT':
      return 'cat';
    default:
      return 'other';
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
  // Get next vaccination date from vet records if available
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
    monthlyExpenses: 0, // Not available in API
  };
}

// ============================================================================
// LOCATION STATUS CONFIG
// ============================================================================

const locationConfig: Record<LocationStatus, { color: string; bgColor: string; icon: typeof Home }> = {
  home: { color: 'text-green-700', bgColor: 'bg-green-100', icon: Home },
  away: { color: 'text-slate-700', bgColor: 'bg-slate-100', icon: Car },
  school: { color: 'text-blue-700', bgColor: 'bg-blue-100', icon: GraduationCap },
  work: { color: 'text-purple-700', bgColor: 'bg-purple-100', icon: Briefcase },
  activity: { color: 'text-amber-700', bgColor: 'bg-amber-100', icon: Trophy },
  unknown: { color: 'text-slate-500', bgColor: 'bg-slate-50', icon: MapPin },
};

// ============================================================================
// ADD MEMBER FORM TYPES
// ============================================================================

type AddMemberType = 'adult' | 'child' | 'pet' | 'staff';

interface AddMemberFormData {
  type: AddMemberType;
  name: string;
  email?: string;
  phone?: string;
  // Pet specific
  petType?: PetType;
  breed?: string;
}

// ============================================================================
// MAIN COMPONENT
// ============================================================================

export default function FamilyPage() {
  const { currentHousehold } = useAuth();

  // Data State - initialized with mocks
  const [adults, setAdults] = useState<AdultMember[]>(MOCK_ADULTS);
  const [children, setChildren] = useState<ChildMember[]>(MOCK_CHILDREN);
  const [pets, setPets] = useState<PetMember[]>(MOCK_PETS);
  const [staff, setStaff] = useState<StaffMember[]>(MOCK_STAFF);
  const [isLoading, setIsLoading] = useState(true);

  // UI State
  const [showFinancials, setShowFinancials] = useState(true);
  const [expandedCards, setExpandedCards] = useState<Set<string>>(new Set());
  const [showAddMemberModal, setShowAddMemberModal] = useState(false);
  const [showEditModal, setShowEditModal] = useState<FamilyMember | null>(null);
  const [addMemberStep, setAddMemberStep] = useState<'select' | 'form'>('select');
  const [addMemberType, setAddMemberType] = useState<AddMemberType | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // ============================================================================
  // DATA FETCHING
  // ============================================================================

  const loadFamilyData = useCallback(async () => {
    if (!currentHousehold?.id) {
      setIsLoading(false);
      return;
    }

    try {
      const api = getApiClient();

      // Fetch members and pets in parallel
      const [membersResult, petsResult] = await Promise.allSettled([
        api.getFamilyMembers(),
        api.getFamilyPets(),
      ]);

      // Process members
      if (membersResult.status === 'fulfilled' && membersResult.value.length > 0) {
        const apiMembers = membersResult.value;
        const newAdults: AdultMember[] = [];
        const newChildren: ChildMember[] = [];
        const newStaff: StaffMember[] = [];

        apiMembers.forEach((member) => {
          const roleUpper = member.role.toUpperCase();
          // Categorize by role
          if (roleUpper === 'CHILD') {
            newChildren.push(mapToChild(member));
          } else if (roleUpper === 'STAFF') {
            newStaff.push(mapToStaff(member));
          } else {
            // OWNER, MANAGER, MEMBER are all adults
            newAdults.push(mapToAdult(member));
          }
        });

        // Only update if we got data
        if (newAdults.length > 0) setAdults(newAdults);
        if (newChildren.length > 0) setChildren(newChildren);
        if (newStaff.length > 0) setStaff(newStaff);
      }
      // If empty or error, keep MOCK data (already the default)

      // Process pets
      if (petsResult.status === 'fulfilled' && petsResult.value.length > 0) {
        const mappedPets = petsResult.value.map(mapToPet);
        setPets(mappedPets);
      }
      // If empty or error, keep MOCK_PETS
    } catch (error) {
      console.error('Failed to load family data:', error);
      // Keep mock data as fallback
    } finally {
      setIsLoading(false);
    }
  }, [currentHousehold?.id]);

  useEffect(() => {
    loadFamilyData();
  }, [loadFamilyData]);

  // ============================================================================
  // ADD MEMBER HANDLER
  // ============================================================================

  const handleAddMember = async (formData: AddMemberFormData) => {
    if (!currentHousehold?.id) return;

    setIsSubmitting(true);
    try {
      const api = getApiClient();

      if (formData.type === 'pet') {
        // Create pet via API
        const petRequest: CreatePetRequest = {
          name: formData.name,
          type: formData.petType || 'DOG',
          breed: formData.breed,
        };

        const newPet = await api.createPet(petRequest);
        const mappedPet = mapToPet(newPet);
        setPets((prev) => [...prev, mappedPet]);
      } else {
        // For adults/staff, we would call inviteMember API
        // For now, do optimistic update with local data
        const id = `temp-${Date.now()}`;
        const name = formData.name;

        if (formData.type === 'adult') {
          const newAdult: AdultMember = {
            id,
            type: 'adult',
            name,
            initials: getInitials(name),
            role: 'Family Member',
            isAdmin: false,
            email: formData.email || '',
            phone: formData.phone || '',
            location: { status: 'unknown', label: 'Invited' },
            clubs: [],
          };
          setAdults((prev) => [...prev, newAdult]);
        } else if (formData.type === 'child') {
          const newChild: ChildMember = {
            id,
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
              allergies: [],
            },
          };
          setChildren((prev) => [...prev, newChild]);
        } else if (formData.type === 'staff') {
          const newStaffMember: StaffMember = {
            id,
            type: 'staff',
            name,
            initials: getInitials(name),
            role: 'Staff',
            email: formData.email || '',
            phone: formData.phone || '',
            location: { status: 'unknown', label: 'Invited' },
            weeklyStipend: 0,
            schedule: [],
            permissions: [],
            startDate: new Date(),
          };
          setStaff((prev) => [...prev, newStaffMember]);
        }
      }

      // Reset modal state
      setShowAddMemberModal(false);
      setAddMemberStep('select');
      setAddMemberType(null);
    } catch (error) {
      console.error('Failed to add member:', error);
      // Could show error toast here
    } finally {
      setIsSubmitting(false);
    }
  };

  // ============================================================================
  // COMPUTED VALUES
  // ============================================================================

  // All members for logistics dashboard
  const allMembers = useMemo(() => {
    return [...adults, ...children, ...pets, ...staff];
  }, [adults, children, pets, staff]);

  // Financial calculations
  const monthlyLifestyleCosts = useMemo(() => {
    let total = 0;

    // Adult club dues
    adults.forEach((adult) => {
      adult.clubs.forEach((club) => {
        total += club.monthlyDues;
      });
    });

    // School tuition
    children.forEach((child) => {
      total += child.school.tuitionMonthly;
      child.activities.forEach((activity) => {
        total += activity.monthlyFee;
      });
    });

    // Pet expenses
    pets.forEach((pet) => {
      total += pet.monthlyExpenses;
    });

    // Staff stipends
    staff.forEach((s) => {
      total += s.weeklyStipend * 4.33; // Monthly average
    });

    return total;
  }, [adults, children, pets, staff]);

  // ============================================================================
  // HANDLERS
  // ============================================================================

  const toggleCard = (id: string) => {
    setExpandedCards((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
      } else {
        next.add(id);
      }
      return next;
    });
  };

  // ============================================================================
  // FORMAT HELPERS
  // ============================================================================

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatDate = (date: Date) => {
    return date.toLocaleDateString('en-US', {
      month: 'short',
      day: 'numeric',
    });
  };

  const getDaysUntil = (date: Date) => {
    const days = Math.ceil((date.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    return days;
  };

  // Render location status pill
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900">Family</h1>
          <p className="text-slate-600 mt-1">Household members, logistics, and lifestyle management</p>
        </div>
        <button
          onClick={() => setShowAddMemberModal(true)}
          className="flex items-center gap-2 px-4 py-2 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
        >
          <UserPlus className="w-5 h-5" />
          Add Member
        </button>
      </div>

      {/* Today's Logistics Dashboard */}
      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <MapPin className="w-5 h-5 text-emerald-600" />
            <h2 className="font-semibold text-slate-900">Today's Logistics</h2>
          </div>
          <span className="text-sm text-slate-500">
            {new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'short', day: 'numeric' })}
          </span>
        </div>

        <p className="text-sm text-slate-500 mb-4">Where is everyone right now?</p>

        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-4">
          {allMembers.map((member) => {
            const config = locationConfig[member.location.status];
            const Icon = config.icon;
            return (
              <div
                key={member.id}
                className="flex flex-col items-center p-4 bg-slate-50 rounded-xl hover:bg-slate-100 transition-colors"
              >
                {/* Avatar */}
                <div className="relative mb-2">
                  <div
                    className={`w-14 h-14 rounded-full flex items-center justify-center ${
                      member.type === 'pet'
                        ? 'bg-amber-100'
                        : member.type === 'staff'
                          ? 'bg-purple-100'
                          : member.type === 'child'
                            ? 'bg-blue-100'
                            : 'bg-emerald-100'
                    }`}
                  >
                    {member.type === 'pet' ? (
                      (member as PetMember).species === 'cat' ? (
                        <Cat className="w-7 h-7 text-amber-600" />
                      ) : (
                        <Dog className="w-7 h-7 text-amber-600" />
                      )
                    ) : (
                      <span
                        className={`text-lg font-semibold ${
                          member.type === 'staff'
                            ? 'text-purple-600'
                            : member.type === 'child'
                              ? 'text-blue-600'
                              : 'text-emerald-600'
                        }`}
                      >
                        {member.initials}
                      </span>
                    )}
                  </div>
                  {/* Status dot */}
                  <span
                    className={`absolute -bottom-0.5 -right-0.5 w-4 h-4 rounded-full border-2 border-white ${
                      member.location.status === 'home'
                        ? 'bg-green-500'
                        : member.location.status === 'unknown'
                          ? 'bg-slate-400'
                          : 'bg-blue-500'
                    }`}
                  />
                </div>

                {/* Name */}
                <p className="font-medium text-slate-900 text-sm text-center">{member.name.split(' ')[0]}</p>

                {/* Status */}
                <div className={`flex items-center gap-1 mt-1 ${config.color}`}>
                  <Icon className="w-3 h-3" />
                  <span className="text-xs">{member.location.label}</span>
                </div>

                {/* Return time */}
                {member.location.returnTime && (
                  <p className="text-xs text-slate-400 mt-0.5">Back {member.location.returnTime}</p>
                )}

                {/* Check-in button for non-home members */}
                {member.location.status !== 'home' && member.type !== 'pet' && (
                  <button className="mt-2 text-xs text-emerald-600 hover:text-emerald-700 font-medium">
                    Check In
                  </button>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Financial Roll-up (Admin only) */}
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

          <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Club Memberships</p>
              <p className="font-semibold">
                {formatCurrency(adults.reduce((sum, a) => sum + a.clubs.reduce((s, c) => s + c.monthlyDues, 0), 0))}
              </p>
            </div>
            <div className="bg-white/10 rounded-lg p-3">
              <p className="text-slate-400 text-xs">Education & Activities</p>
              <p className="font-semibold">
                {formatCurrency(
                  children.reduce(
                    (sum, c) => sum + c.school.tuitionMonthly + c.activities.reduce((s, a) => s + a.monthlyFee, 0),
                    0
                  )
                )}
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
              {/* Header */}
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
                  <button
                    onClick={() => setShowEditModal(adult)}
                    className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                  >
                    <Pencil className="w-4 h-4" />
                  </button>
                </div>
              </div>

              {/* Quick Contact */}
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

              {/* Expandable Details */}
              <button
                onClick={() => toggleCard(adult.id)}
                className="w-full px-4 py-3 flex items-center justify-between text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
              >
                <span>Lifestyle Details</span>
                {expandedCards.has(adult.id) ? (
                  <ChevronDown className="w-4 h-4" />
                ) : (
                  <ChevronRight className="w-4 h-4" />
                )}
              </button>

              {expandedCards.has(adult.id) && (
                <div className="px-4 pb-4 space-y-4">
                  {/* Work */}
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

                  {/* Clubs */}
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
                                <p className="text-xs text-slate-400">
                                  {club.type} • {club.membershipId}
                                </p>
                              </div>
                            </div>
                            {showFinancials && (
                              <span className="text-sm font-medium text-slate-600">
                                {formatCurrency(club.monthlyDues)}/mo
                              </span>
                            )}
                          </div>
                        ))}
                      </div>
                    </div>
                  )}

                  {/* Wellness */}
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

                  {/* Civic */}
                  {adult.civic && adult.civic.length > 0 && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">
                        Civic Organizations
                      </p>
                      <div className="flex flex-wrap gap-2">
                        {adult.civic.map((org, idx) => (
                          <span key={idx} className="px-3 py-1 bg-blue-50 text-blue-700 text-sm rounded-full">
                            {org}
                          </span>
                        ))}
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
            return (
              <div key={child.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                {/* Header */}
                <div className="p-4 border-b border-slate-100">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 bg-blue-100 rounded-full flex items-center justify-center">
                        <span className="text-lg font-semibold text-blue-600">{child.initials}</span>
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900">{child.name}</h3>
                        <p className="text-sm text-slate-500">
                          {child.age} years old • {child.grade}
                        </p>
                        <div className="mt-1">{renderLocationPill(child.location)}</div>
                      </div>
                    </div>
                    <button
                      onClick={() => setShowEditModal(child)}
                      className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Alerts */}
                {child.health.allergies.length > 0 && (
                  <div className="px-4 py-2 bg-red-50 border-b border-red-100 flex items-center gap-2">
                    <AlertTriangle className="w-4 h-4 text-red-600" />
                    <span className="text-sm text-red-700 font-medium">
                      Allergies: {child.health.allergies.join(', ')}
                    </span>
                  </div>
                )}

                {/* School Info */}
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
                        <p className="text-sm font-medium text-slate-900">
                          {formatCurrency(child.school.tuitionMonthly)}/mo
                        </p>
                        {tuitionDue !== null && tuitionDue <= 7 && (
                          <span className="text-xs text-red-600 font-medium">Due in {tuitionDue} days</span>
                        )}
                      </div>
                    )}
                  </div>
                </div>

                {/* Expandable Details */}
                <button
                  onClick={() => toggleCard(child.id)}
                  className="w-full px-4 py-3 flex items-center justify-between text-sm font-medium text-slate-600 hover:bg-slate-50 transition-colors"
                >
                  <span>Activities & Support Team</span>
                  {expandedCards.has(child.id) ? (
                    <ChevronDown className="w-4 h-4" />
                  ) : (
                    <ChevronRight className="w-4 h-4" />
                  )}
                </button>

                {expandedCards.has(child.id) && (
                  <div className="px-4 pb-4 space-y-4">
                    {/* Activities */}
                    {child.activities.length > 0 && (
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Activities</p>
                        <div className="space-y-2">
                          {child.activities.map((activity, idx) => (
                            <div key={idx} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                              <div className="flex items-center gap-3">
                                {activity.name.toLowerCase().includes('soccer') ||
                                activity.name.toLowerCase().includes('league') ? (
                                  <Trophy className="w-5 h-5 text-amber-500" />
                                ) : activity.name.toLowerCase().includes('piano') ||
                                  activity.name.toLowerCase().includes('music') ? (
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
                                    <Timer className="w-3 h-3 inline mr-1" />
                                    {activity.schedule}
                                  </p>
                                </div>
                              </div>
                              {showFinancials && (
                                <span className="text-sm font-medium text-slate-600">
                                  {formatCurrency(activity.monthlyFee)}/mo
                                </span>
                              )}
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Care Provider */}
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

                    {/* Health Info */}
                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Health</p>
                      <div className="space-y-2">
                        <div className="flex items-center gap-3 p-3 bg-slate-50 rounded-lg">
                          <Syringe className="w-5 h-5 text-green-600" />
                          <div>
                            <p className="font-medium text-slate-900">{child.health.pediatrician}</p>
                            <p className="text-xs text-slate-400">{child.health.pediatricianPhone}</p>
                          </div>
                        </div>
                        {child.health.medications && child.health.medications.length > 0 && (
                          <div className="p-3 bg-amber-50 rounded-lg">
                            <p className="text-sm text-amber-700 font-medium">
                              Medications: {child.health.medications.join(', ')}
                            </p>
                          </div>
                        )}
                      </div>
                    </div>

                    {/* Sizes */}
                    {child.sizes && (
                      <div>
                        <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">Sizes</p>
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
                {/* Header */}
                <div className="p-4">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 bg-amber-100 rounded-full flex items-center justify-center">
                        {pet.species === 'cat' ? (
                          <Cat className="w-7 h-7 text-amber-600" />
                        ) : (
                          <Dog className="w-7 h-7 text-amber-600" />
                        )}
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900">{pet.name}</h3>
                        <p className="text-sm text-slate-500">
                          {pet.breed} • {pet.age} years old
                        </p>
                        <div className="mt-1">{renderLocationPill(pet.location)}</div>
                      </div>
                    </div>
                    <button
                      onClick={() => setShowEditModal(pet)}
                      className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Vaccine Alert */}
                {vaccinesDays !== null && vaccinesDays <= 30 && (
                  <div
                    className={`px-4 py-2 flex items-center gap-2 ${
                      vaccinesDays <= 7 ? 'bg-red-50 border-b border-red-100' : 'bg-amber-50 border-b border-amber-100'
                    }`}
                  >
                    <AlertCircle className={`w-4 h-4 ${vaccinesDays <= 7 ? 'text-red-600' : 'text-amber-600'}`} />
                    <span className={`text-sm font-medium ${vaccinesDays <= 7 ? 'text-red-700' : 'text-amber-700'}`}>
                      Vaccines due {pet.vaccinesDue && formatDate(pet.vaccinesDue)}
                    </span>
                  </div>
                )}

                {/* Details */}
                <div className="p-4 space-y-3 bg-slate-50">
                  <div className="flex items-center gap-3">
                    <Syringe className="w-4 h-4 text-slate-400" />
                    <div>
                      <p className="text-sm font-medium text-slate-900">{pet.vet.name}</p>
                      <p className="text-xs text-slate-500">
                        {pet.vet.clinic} • {pet.vet.phone}
                      </p>
                    </div>
                  </div>
                  <div className="flex items-center gap-3">
                    <Utensils className="w-4 h-4 text-slate-400" />
                    <div>
                      <p className="text-sm font-medium text-slate-900">{pet.food.brand}</p>
                      <p className="text-xs text-slate-500">
                        {pet.food.type} • {pet.food.monthlyAmount}/mo
                      </p>
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

      {/* Staff Section */}
      {staff.length > 0 && (
        <div>
          <div className="flex items-center gap-2 mb-4">
            <BadgeCheck className="w-5 h-5 text-slate-400" />
            <h2 className="font-semibold text-slate-900">Household Staff</h2>
            <span className="text-sm text-slate-500">({staff.length})</span>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
            {staff.map((s) => (
              <div key={s.id} className="bg-white rounded-xl shadow-sm border border-slate-200 overflow-hidden">
                {/* Header */}
                <div className="p-4 border-b border-slate-100">
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-4">
                      <div className="w-14 h-14 bg-purple-100 rounded-full flex items-center justify-center">
                        <span className="text-lg font-semibold text-purple-600">{s.initials}</span>
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="font-semibold text-slate-900">{s.name}</h3>
                          <span className="px-2 py-0.5 bg-purple-100 text-purple-700 text-xs font-medium rounded-full">
                            {s.role}
                          </span>
                        </div>
                        {s.agency && <p className="text-sm text-slate-500">via {s.agency}</p>}
                        <div className="mt-1">{renderLocationPill(s.location)}</div>
                      </div>
                    </div>
                    <button
                      onClick={() => setShowEditModal(s)}
                      className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {/* Quick Contact */}
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

                {/* Schedule */}
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

                {/* Permissions & Compensation */}
                <div className="px-4 pb-4 space-y-3">
                  {s.permissions.length > 0 && (
                    <div>
                      <p className="text-xs font-medium text-slate-500 uppercase tracking-wide mb-2">App Permissions</p>
                      <div className="flex flex-wrap gap-2">
                        {s.permissions.map((perm, idx) => (
                          <span
                            key={idx}
                            className="flex items-center gap-1 px-2 py-1 bg-slate-100 text-slate-600 text-xs rounded-full"
                          >
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
            ))}
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
                            className={`flex flex-col items-center p-4 border-2 border-slate-200 rounded-xl hover:border-${option.color}-500 hover:bg-${option.color}-50 transition-colors text-center`}
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
                  <button
                    onClick={() => setShowEditModal(null)}
                    className="p-2 hover:bg-slate-100 rounded-lg transition-colors"
                  >
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
                  onClick={() => setShowEditModal(null)}
                  className="flex-1 py-2.5 bg-emerald-600 text-white font-medium rounded-lg hover:bg-emerald-700 transition-colors"
                >
                  Save Changes
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Mobile FAB */}
      <div className="fixed bottom-6 right-6 sm:hidden">
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
