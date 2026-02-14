'use client';

import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  ClipboardCheck,
  ArrowRight,
  ArrowLeft,
  Building2,
  Receipt,
  Settings,
  Users,
  Pencil,
  Check,
  MapPin,
  Car,
  PawPrint,
  Briefcase,
} from 'lucide-react';
import { useOnboarding } from '@/context/OnboardingContext';
import { BILL_CATEGORIES, SYSTEM_CATEGORIES, APPLIANCE_CATEGORIES } from '@/types/onboarding';
import { formatCurrency } from '@/lib/format';

export default function ReviewPage() {
  const router = useRouter();
  const { data, completeStep, calculateMonthlyTotal } = useOnboarding();

  const monthlyTotal = calculateMonthlyTotal();

  const handleContinue = () => {
    completeStep('review');
    router.push('/onboarding/activation');
  };

  const renderSection = (
    title: string,
    icon: React.ReactNode,
    editHref: string,
    content: React.ReactNode,
    isEmpty: boolean
  ) => (
    <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
      <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 bg-haven-100 rounded-xl flex items-center justify-center">
            {icon}
          </div>
          <h3 className="font-semibold text-haven-900">{title}</h3>
        </div>
        <Link
          href={editHref}
          className="text-sm text-haven-600 hover:text-haven-700 font-medium flex items-center gap-1"
        >
          <Pencil className="w-4 h-4" />
          Edit
        </Link>
      </div>
      <div className="p-6">
        {isEmpty ? (
          <p className="text-gray-400 text-sm italic">No information added</p>
        ) : (
          content
        )}
      </div>
    </div>
  );

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <ClipboardCheck className="w-7 h-7 text-haven-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-900 mb-2">Review your information</h1>
        <p className="text-gray-600">
          Take a moment to review everything before we get you set up.
        </p>
      </div>

      {/* Sections */}
      <div className="space-y-6">
        {/* Property Section */}
        {renderSection(
          'Property',
          <Building2 className="w-5 h-5 text-haven-600" />,
          '/onboarding/wizard/property',
          data.property && (
            <div className="space-y-3">
              <div className="flex items-start gap-3">
                <MapPin className="w-5 h-5 text-gray-400 mt-0.5" />
                <div>
                  <p className="font-medium text-haven-900">
                    {data.property.propertyName || data.property.address.formatted}
                  </p>
                  {data.property.propertyName && (
                    <p className="text-sm text-gray-500">{data.property.address.formatted}</p>
                  )}
                </div>
              </div>
              <div className="flex flex-wrap gap-2 text-sm text-gray-600">
                {data.property.propertyType && (
                  <span className="bg-gray-100 px-2 py-1 rounded-lg capitalize">
                    {data.property.propertyType.replace(/_/g, ' ')}
                  </span>
                )}
                {data.property.bedrooms && (
                  <span className="bg-gray-100 px-2 py-1 rounded-lg">
                    {data.property.bedrooms} bed
                  </span>
                )}
                {data.property.bathrooms && (
                  <span className="bg-gray-100 px-2 py-1 rounded-lg">
                    {data.property.bathrooms} bath
                  </span>
                )}
                {data.property.squareFeet && (
                  <span className="bg-gray-100 px-2 py-1 rounded-lg">
                    {data.property.squareFeet.toLocaleString()} sq ft
                  </span>
                )}
                {data.property.yearBuilt && (
                  <span className="bg-gray-100 px-2 py-1 rounded-lg">
                    Built {data.property.yearBuilt}
                  </span>
                )}
              </div>
            </div>
          ),
          !data.property
        )}

        {/* Bills Section */}
        {renderSection(
          'Bills & Accounts',
          <Receipt className="w-5 h-5 text-haven-600" />,
          '/onboarding/wizard/bills',
          data.bills.length > 0 && (
            <div className="space-y-4">
              {/* Monthly Total */}
              <div className="bg-haven-900 text-white rounded-xl p-4">
                <div className="flex items-center justify-between">
                  <span className="text-white/70 text-sm">Estimated Monthly Total</span>
                  <span className="text-xl font-bold">{formatCurrency(monthlyTotal)}</span>
                </div>
              </div>

              {/* Bills List */}
              <div className="space-y-2">
                {data.bills.map((bill) => {
                  const catInfo = BILL_CATEGORIES[bill.category];
                  return (
                    <div
                      key={bill.id}
                      className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0"
                    >
                      <div className="flex items-center gap-2">
                        <span className="text-gray-600">{catInfo?.label || bill.category}</span>
                        <span className="text-gray-400">—</span>
                        <span className="text-haven-900 font-medium">{bill.provider}</span>
                      </div>
                      <span className="text-haven-900 font-medium">
                        {formatCurrency(bill.amount)}/{bill.frequency === 'monthly' ? 'mo' : bill.frequency}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          ),
          data.bills.length === 0
        )}

        {/* Systems Section */}
        {renderSection(
          'Home Systems & Appliances',
          <Settings className="w-5 h-5 text-haven-600" />,
          '/onboarding/wizard/systems',
          (data.systems.length > 0 || data.appliances.length > 0) && (
            <div className="space-y-4">
              {/* Systems */}
              {data.systems.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-gray-400 uppercase mb-2">Systems</p>
                  <div className="flex flex-wrap gap-2">
                    {data.systems.map((system) => {
                      const catInfo = SYSTEM_CATEGORIES[system.category];
                      return (
                        <div
                          key={system.id}
                          className="flex items-center gap-2 bg-gray-100 px-3 py-2 rounded-lg"
                        >
                          <Check className="w-4 h-4 text-green-500" />
                          <span className="text-sm text-haven-900">{catInfo?.label}</span>
                          {system.brand && (
                            <span className="text-xs text-gray-500">({system.brand})</span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}

              {/* Appliances */}
              {data.appliances.length > 0 && (
                <div>
                  <p className="text-xs font-semibold text-gray-400 uppercase mb-2">Appliances</p>
                  <div className="flex flex-wrap gap-2">
                    {data.appliances.map((appliance) => {
                      const catInfo = APPLIANCE_CATEGORIES[appliance.category];
                      return (
                        <div
                          key={appliance.id}
                          className="flex items-center gap-2 bg-gray-100 px-3 py-2 rounded-lg"
                        >
                          <Check className="w-4 h-4 text-green-500" />
                          <span className="text-sm text-haven-900">{catInfo?.label}</span>
                          {appliance.brand && (
                            <span className="text-xs text-gray-500">({appliance.brand})</span>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>
              )}
            </div>
          ),
          data.systems.length === 0 && data.appliances.length === 0
        )}

        {/* Family Section */}
        {renderSection(
          'Family & Household',
          <Users className="w-5 h-5 text-haven-600" />,
          '/onboarding/wizard/family',
          (data.familyMembers.length > 0 ||
            data.vehicles.length > 0 ||
            data.pets.length > 0 ||
            data.staff.length > 0) && (
            <div className="space-y-4">
              {/* Family Members */}
              {data.familyMembers.length > 0 && (
                <div className="flex items-start gap-3">
                  <Users className="w-5 h-5 text-gray-400 mt-0.5" />
                  <div>
                    <p className="text-sm text-gray-500 mb-1">{data.familyMembers.length} family members</p>
                    <p className="text-haven-900">
                      {data.familyMembers.map((m) => `${m.firstName} ${m.lastName}`).join(', ')}
                    </p>
                  </div>
                </div>
              )}

              {/* Vehicles */}
              {data.vehicles.length > 0 && (
                <div className="flex items-start gap-3">
                  <Car className="w-5 h-5 text-gray-400 mt-0.5" />
                  <div>
                    <p className="text-sm text-gray-500 mb-1">{data.vehicles.length} vehicles</p>
                    <p className="text-haven-900">
                      {data.vehicles.map((v) => `${v.year} ${v.make} ${v.model}`).join(', ')}
                    </p>
                  </div>
                </div>
              )}

              {/* Pets */}
              {data.pets.length > 0 && (
                <div className="flex items-start gap-3">
                  <PawPrint className="w-5 h-5 text-gray-400 mt-0.5" />
                  <div>
                    <p className="text-sm text-gray-500 mb-1">{data.pets.length} pets</p>
                    <p className="text-haven-900">
                      {data.pets
                        .map((p) => `${p.name} (${p.species}${p.breed ? `, ${p.breed}` : ''})`)
                        .join(', ')}
                    </p>
                  </div>
                </div>
              )}

              {/* Staff */}
              {data.staff.length > 0 && (
                <div className="flex items-start gap-3">
                  <Briefcase className="w-5 h-5 text-gray-400 mt-0.5" />
                  <div>
                    <p className="text-sm text-gray-500 mb-1">{data.staff.length} household staff</p>
                    <p className="text-haven-900">
                      {data.staff
                        .map(
                          (s) =>
                            `${s.firstName} ${s.lastName} (${s.role
                              .replace(/_/g, ' ')
                              .replace(/\b\w/g, (c) => c.toUpperCase())})`
                        )
                        .join(', ')}
                    </p>
                  </div>
                </div>
              )}
            </div>
          ),
          data.familyMembers.length === 0 &&
            data.vehicles.length === 0 &&
            data.pets.length === 0 &&
            data.staff.length === 0
        )}
      </div>

      {/* Completion Summary */}
      <div className="mt-8 bg-haven-50 border border-haven-200 rounded-2xl p-6">
        <h3 className="font-semibold text-haven-900 mb-3">Ready to get started!</h3>
        <p className="text-sm text-gray-600 mb-4">
          You&apos;ve provided great information about your home. In the next step, you&apos;ll
          schedule an activation call with your dedicated Home Manager to finalize everything.
        </p>
        <div className="flex flex-wrap gap-2">
          {data.steps.property && (
            <span className="inline-flex items-center gap-1 bg-green-100 text-green-700 text-xs font-medium px-2 py-1 rounded-full">
              <Check className="w-3 h-3" /> Property
            </span>
          )}
          {data.steps.bills && (
            <span className="inline-flex items-center gap-1 bg-green-100 text-green-700 text-xs font-medium px-2 py-1 rounded-full">
              <Check className="w-3 h-3" /> Bills
            </span>
          )}
          {data.steps.systems && (
            <span className="inline-flex items-center gap-1 bg-green-100 text-green-700 text-xs font-medium px-2 py-1 rounded-full">
              <Check className="w-3 h-3" /> Systems
            </span>
          )}
          {data.steps.family && (
            <span className="inline-flex items-center gap-1 bg-green-100 text-green-700 text-xs font-medium px-2 py-1 rounded-full">
              <Check className="w-3 h-3" /> Family
            </span>
          )}
        </div>
      </div>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/wizard/family"
          className="text-gray-600 hover:text-haven-900 py-3 px-4 font-medium flex items-center gap-2 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-900 hover:bg-haven-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue to Activation
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
