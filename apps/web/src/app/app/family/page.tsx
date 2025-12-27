'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useAuth } from '@/contexts/auth-context';
import { Card, Badge, Button } from '@/components/ui';
import {
  Users,
  User,
  Baby,
  Briefcase,
  Dog,
  Cat,
  Trophy,
  GraduationCap,
  Music,
  Palette,
  Dumbbell,
  MapPin,
  Phone,
  Mail,
  Calendar,
  DollarSign,
  ChevronRight,
  AlertCircle,
  Heart,
  Plus,
} from 'lucide-react';

// ============================================================================
// TYPES
// ============================================================================

interface FamilyMember {
  id: string;
  firstName: string;
  lastName: string | null;
  nickname: string | null;
  type: 'ADULT' | 'CHILD' | 'STAFF';
  relationship: string | null;
  email: string | null;
  phone: string | null;
  birthdate: string | null;
  school: string | null;
  schoolGrade: string | null;
  teacher: string | null;
  workSchedule: string | null;
  responsibilities: string | null;
  activitiesCount: number;
}

interface Pet {
  id: string;
  name: string;
  type: 'DOG' | 'CAT' | 'BIRD' | 'FISH' | 'REPTILE' | 'OTHER';
  breed: string | null;
  color: string | null;
  size: string | null;
  weight: number | null;
  birthday: string | null;
  gender: string | null;
  vetClinicName: string | null;
  vetClinicPhone: string | null;
  allergies: string[];
  medications: string[];
  specialNeeds: string | null;
}

interface Activity {
  id: string;
  name: string;
  type: string;
  organization: string | null;
  location: string | null;
  schedule: string | null;
  cost: number | null;
  costFrequency: string | null;
  coachName: string | null;
  contactPhone: string | null;
  memberName: string | null;
}

interface FamilyData {
  members: FamilyMember[];
  pets: Pet[];
  activities: Activity[];
  summary: {
    adultsCount: number;
    childrenCount: number;
    staffCount: number;
    petsCount: number;
    activitiesCount: number;
    monthlyActivitiesCost: number;
  };
}

// ============================================================================
// HELPERS
// ============================================================================

function formatCurrency(amount: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
  }).format(amount);
}

function getAge(birthdate: string | null) {
  if (!birthdate) return null;
  const birth = new Date(birthdate);
  const today = new Date();
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) {
    age--;
  }
  return age;
}

function getMemberIcon(type: string) {
  switch (type) {
    case 'ADULT':
      return <User className="w-5 h-5" />;
    case 'CHILD':
      return <Baby className="w-5 h-5" />;
    case 'STAFF':
      return <Briefcase className="w-5 h-5" />;
    default:
      return <User className="w-5 h-5" />;
  }
}

function getPetIcon(type: string) {
  switch (type.toUpperCase()) {
    case 'DOG':
      return <Dog className="w-5 h-5" />;
    case 'CAT':
      return <Cat className="w-5 h-5" />;
    default:
      return <Heart className="w-5 h-5" />;
  }
}

function getActivityIcon(type: string) {
  const t = type.toUpperCase();
  if (t.includes('SPORT')) return <Dumbbell className="w-5 h-5" />;
  if (t.includes('MUSIC')) return <Music className="w-5 h-5" />;
  if (t.includes('ART')) return <Palette className="w-5 h-5" />;
  if (t.includes('ACADEMIC')) return <GraduationCap className="w-5 h-5" />;
  return <Trophy className="w-5 h-5" />;
}

// ============================================================================
// COMPONENTS
// ============================================================================

function PageSkeleton() {
  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto animate-pulse">
      <div className="h-24 bg-gray-200 rounded-xl mb-6" />
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="h-32 bg-gray-200 rounded-xl" />
        ))}
      </div>
    </div>
  );
}

function SummaryHeader({ summary }: { summary: FamilyData['summary'] }) {
  return (
    <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-haven-700 via-haven-700 to-haven-800 p-6 text-white mb-6">
      <div className="absolute inset-0 opacity-10">
        <div className="absolute top-0 right-0 w-64 h-64 bg-white rounded-full -translate-y-1/2 translate-x-1/2" />
      </div>
      <div className="relative">
        <div className="flex items-center gap-3 mb-4">
          <div className="w-12 h-12 bg-white/20 rounded-xl flex items-center justify-center">
            <Users className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-2xl font-bold">Your Family</h1>
            <p className="text-haven-100">Everyone Haven helps manage</p>
          </div>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-white/10 rounded-xl px-4 py-3">
            <p className="text-xl font-bold">{summary.adultsCount + summary.childrenCount}</p>
            <p className="text-xs text-haven-100">Family Members</p>
          </div>
          {summary.staffCount > 0 && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <p className="text-xl font-bold">{summary.staffCount}</p>
              <p className="text-xs text-haven-100">Staff</p>
            </div>
          )}
          {summary.petsCount > 0 && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <p className="text-xl font-bold">{summary.petsCount}</p>
              <p className="text-xs text-haven-100">Pets</p>
            </div>
          )}
          {summary.activitiesCount > 0 && (
            <div className="bg-white/10 rounded-xl px-4 py-3">
              <p className="text-xl font-bold">{summary.activitiesCount}</p>
              <p className="text-xs text-haven-100">Activities</p>
            </div>
          )}
        </div>

        {summary.monthlyActivitiesCost > 0 && (
          <div className="mt-4 pt-4 border-t border-white/20">
            <p className="text-sm text-haven-100">
              Monthly Activities: <span className="font-semibold text-white">{formatCurrency(summary.monthlyActivitiesCost)}</span>
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

function MemberCard({ member }: { member: FamilyMember }) {
  const age = getAge(member.birthdate);
  const fullName = `${member.firstName} ${member.lastName || ''}`.trim();

  return (
    <Card hover>
      <div className="flex items-start gap-4">
        <div className={`w-12 h-12 rounded-xl flex items-center justify-center ${
          member.type === 'ADULT' ? 'bg-blue-100 text-blue-600' :
          member.type === 'CHILD' ? 'bg-pink-100 text-pink-600' :
          'bg-purple-100 text-purple-600'
        }`}>
          {getMemberIcon(member.type)}
        </div>
        <div className="flex-1">
          <div className="flex items-center gap-2">
            <h3 className="font-semibold text-gray-900">{fullName}</h3>
            {member.nickname && (
              <span className="text-sm text-gray-500">({member.nickname})</span>
            )}
          </div>
          <p className="text-sm text-gray-500">
            {member.relationship || member.type.charAt(0) + member.type.slice(1).toLowerCase()}
            {age !== null && ` - ${age} years old`}
          </p>

          {/* School info for children */}
          {member.school && (
            <div className="flex items-center gap-2 mt-2 text-sm text-gray-600">
              <GraduationCap className="w-4 h-4" />
              {member.school}
              {member.schoolGrade && ` - Grade ${member.schoolGrade}`}
            </div>
          )}

          {/* Contact info */}
          {(member.email || member.phone) && (
            <div className="flex items-center gap-4 mt-2 text-sm text-gray-500">
              {member.phone && (
                <span className="flex items-center gap-1">
                  <Phone className="w-3.5 h-3.5" />
                  {member.phone}
                </span>
              )}
              {member.email && (
                <span className="flex items-center gap-1">
                  <Mail className="w-3.5 h-3.5" />
                  {member.email}
                </span>
              )}
            </div>
          )}

          {/* Work schedule for staff */}
          {member.workSchedule && (
            <p className="text-sm text-gray-500 mt-2">
              Schedule: {member.workSchedule}
            </p>
          )}

          {/* Activities count */}
          {member.activitiesCount > 0 && (
            <Badge variant="secondary" className="mt-2">
              {member.activitiesCount} activit{member.activitiesCount > 1 ? 'ies' : 'y'}
            </Badge>
          )}
        </div>
      </div>
    </Card>
  );
}

function PetCard({ pet }: { pet: Pet }) {
  const age = getAge(pet.birthday);

  return (
    <Card hover>
      <div className="flex items-start gap-4">
        <div className="w-12 h-12 bg-orange-100 rounded-xl flex items-center justify-center text-orange-600">
          {getPetIcon(pet.type)}
        </div>
        <div className="flex-1">
          <h3 className="font-semibold text-gray-900">{pet.name}</h3>
          <p className="text-sm text-gray-500">
            {pet.breed || pet.type}
            {age !== null && ` - ${age} years old`}
          </p>

          {pet.vetClinicName && (
            <div className="flex items-center gap-2 mt-2 text-sm text-gray-600">
              <Heart className="w-4 h-4" />
              {pet.vetClinicName}
            </div>
          )}

          {pet.allergies.length > 0 && (
            <div className="mt-2">
              <p className="text-xs text-gray-500">Allergies:</p>
              <div className="flex flex-wrap gap-1 mt-1">
                {pet.allergies.map((a, i) => (
                  <Badge key={i} variant="warning" size="sm">{a}</Badge>
                ))}
              </div>
            </div>
          )}

          {pet.medications.length > 0 && (
            <div className="mt-2">
              <p className="text-xs text-gray-500">Medications:</p>
              <div className="flex flex-wrap gap-1 mt-1">
                {pet.medications.map((m, i) => (
                  <Badge key={i} variant="secondary" size="sm">{m}</Badge>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </Card>
  );
}

function ActivityCard({ activity }: { activity: Activity }) {
  return (
    <Card hover>
      <div className="flex items-start gap-4">
        <div className="w-10 h-10 bg-green-100 rounded-lg flex items-center justify-center text-green-600">
          {getActivityIcon(activity.type)}
        </div>
        <div className="flex-1">
          <div className="flex items-center justify-between">
            <div>
              <h3 className="font-medium text-gray-900">{activity.name}</h3>
              {activity.memberName && (
                <p className="text-sm text-gray-500">{activity.memberName}</p>
              )}
            </div>
            {activity.cost && (
              <div className="text-right">
                <p className="font-medium text-gray-900">{formatCurrency(activity.cost)}</p>
                <p className="text-xs text-gray-500">
                  /{activity.costFrequency?.toLowerCase() || 'mo'}
                </p>
              </div>
            )}
          </div>

          {activity.organization && (
            <p className="text-sm text-gray-600 mt-1">{activity.organization}</p>
          )}

          {activity.schedule && (
            <div className="flex items-center gap-2 mt-2 text-sm text-gray-500">
              <Calendar className="w-4 h-4" />
              {activity.schedule}
            </div>
          )}

          {activity.location && (
            <div className="flex items-center gap-2 mt-1 text-sm text-gray-500">
              <MapPin className="w-4 h-4" />
              {activity.location}
            </div>
          )}
        </div>
      </div>
    </Card>
  );
}

// ============================================================================
// MAIN PAGE
// ============================================================================

export default function FamilyPage() {
  const { getIdToken, householdId } = useAuth();
  const [data, setData] = useState<FamilyData | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (householdId) {
      fetchFamily();
    }
  }, [householdId]);

  const fetchFamily = async () => {
    try {
      const token = await getIdToken();
      if (!token || !householdId) return;

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/dashboard/household/${householdId}/family`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load family data');
      }

      const result = await response.json();
      setData(result);
    } catch (err) {
      console.error('Family error:', err);
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  };

  if (loading) return <PageSkeleton />;

  if (error) {
    return (
      <div className="p-6 text-center">
        <AlertCircle className="w-12 h-12 text-red-500 mx-auto mb-4" />
        <p className="text-red-600 mb-4">Error loading family: {error}</p>
        <Button onClick={fetchFamily}>Try Again</Button>
      </div>
    );
  }

  if (!data || (data.members.length === 0 && data.pets.length === 0)) {
    return (
      <div className="pb-32 lg:pb-8 max-w-4xl mx-auto">
        <div className="text-center py-12">
          <Users className="w-12 h-12 text-gray-300 mx-auto mb-4" />
          <p className="text-gray-500 mb-2">No family data set up yet</p>
          <p className="text-sm text-gray-400">
            Your Home Manager will add family members during onboarding.
          </p>
        </div>
      </div>
    );
  }

  const adults = data.members.filter(m => m.type === 'ADULT');
  const children = data.members.filter(m => m.type === 'CHILD');
  const staff = data.members.filter(m => m.type === 'STAFF');

  return (
    <div className="pb-32 lg:pb-8 max-w-4xl mx-auto">
      <SummaryHeader summary={data.summary} />

      {/* Adults */}
      {adults.length > 0 && (
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Adults</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {adults.map((member) => (
              <MemberCard key={member.id} member={member} />
            ))}
          </div>
        </div>
      )}

      {/* Children */}
      {children.length > 0 && (
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Children</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {children.map((member) => (
              <MemberCard key={member.id} member={member} />
            ))}
          </div>
        </div>
      )}

      {/* Staff */}
      {staff.length > 0 && (
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Household Staff</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {staff.map((member) => (
              <MemberCard key={member.id} member={member} />
            ))}
          </div>
        </div>
      )}

      {/* Pets */}
      {data.pets.length > 0 && (
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">Pets</h2>
            <Link href="/app/family/pets" className="text-sm text-haven-champagne-600 hover:underline">
              View all
            </Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {data.pets.map((pet) => (
              <PetCard key={pet.id} pet={pet} />
            ))}
          </div>
        </div>
      )}

      {/* Activities */}
      {data.activities.length > 0 && (
        <div className="mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold text-gray-900">
              Activities ({data.activities.length})
            </h2>
            {data.summary.monthlyActivitiesCost > 0 && (
              <span className="text-sm text-gray-500">
                {formatCurrency(data.summary.monthlyActivitiesCost)}/mo
              </span>
            )}
          </div>
          <div className="space-y-3">
            {data.activities.map((activity) => (
              <ActivityCard key={activity.id} activity={activity} />
            ))}
          </div>
        </div>
      )}

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-3">
        <Link href="/app/family/calendar">
          <Card hover className="text-center py-4">
            <Calendar className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Family Calendar</p>
          </Card>
        </Link>
        <Link href="/app/family/pets">
          <Card hover className="text-center py-4">
            <Dog className="w-6 h-6 mx-auto mb-2 text-haven-champagne-600" />
            <p className="text-sm font-medium text-gray-700">Pet Care</p>
          </Card>
        </Link>
      </div>
    </div>
  );
}
