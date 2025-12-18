'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import type { PropertyFeatures } from '@haven/core';
import { propertyTypeOptions, usStates } from '@/lib/validations/onboarding';

const homeBasicsSchema = z.object({
  name: z.string().min(1, 'Home name is required').max(100),
  propertyType: z.enum([
    'SINGLE_FAMILY',
    'TOWNHOUSE',
    'CONDO',
    'APARTMENT',
    'MULTI_FAMILY',
    'MOBILE_HOME',
    'OTHER',
  ]),
  addressLine1: z.string().min(1, 'Address is required').max(200),
  addressLine2: z.string().max(200).optional(),
  city: z.string().min(1, 'City is required').max(100),
  state: z.string().min(2, 'State is required').max(2),
  postalCode: z.string().min(5, 'Valid ZIP code required').max(10),
  yearBuilt: z.coerce.number().min(1800).max(new Date().getFullYear()).optional(),
  squareFeet: z.coerce.number().min(100).max(100000).optional(),
  bedrooms: z.coerce.number().min(0).max(20).optional(),
  bathrooms: z.coerce.number().min(0).max(20).optional(),
  // Property features
  hasCentralAc: z.boolean().default(false),
  hasGasHeat: z.boolean().default(false),
  hasOilHeat: z.boolean().default(false),
  hasFireplace: z.boolean().default(false),
  hasSeptic: z.boolean().default(false),
  hasWellWater: z.boolean().default(false),
  hasPool: z.boolean().default(false),
  hasGenerator: z.boolean().default(false),
  hasLawn: z.boolean().default(false),
  hasDriveway: z.boolean().default(false),
});

export type HomeBasicsData = z.infer<typeof homeBasicsSchema>;

interface StepHomeBasicsProps {
  onSubmit: (data: HomeBasicsData) => void;
  defaultValues?: Partial<HomeBasicsData> | null;
  isSubmitting?: boolean;
}

const featureOptions: { name: keyof PropertyFeatures; label: string; description: string }[] = [
  { name: 'hasCentralAc', label: 'Central A/C', description: 'Central air conditioning system' },
  { name: 'hasGasHeat', label: 'Gas Heat', description: 'Natural gas heating' },
  { name: 'hasOilHeat', label: 'Oil Heat', description: 'Oil-fired heating system' },
  { name: 'hasFireplace', label: 'Fireplace/Chimney', description: 'Wood or gas fireplace' },
  { name: 'hasSeptic', label: 'Septic System', description: 'Private septic tank' },
  { name: 'hasWellWater', label: 'Well Water', description: 'Private well water supply' },
  { name: 'hasPool', label: 'Swimming Pool', description: 'In-ground or above-ground pool' },
  { name: 'hasGenerator', label: 'Generator', description: 'Backup power generator' },
  { name: 'hasLawn', label: 'Lawn/Yard', description: 'Needs regular mowing' },
  { name: 'hasDriveway', label: 'Driveway', description: 'May need snow removal' },
];

export function StepHomeBasics({ onSubmit, defaultValues, isSubmitting }: StepHomeBasicsProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(homeBasicsSchema),
    defaultValues: {
      name: '',
      propertyType: 'SINGLE_FAMILY',
      addressLine1: '',
      addressLine2: '',
      city: '',
      state: '',
      postalCode: '',
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
      ...defaultValues,
    },
  });

  return (
    <form onSubmit={handleSubmit((data) => onSubmit(data as HomeBasicsData))} className="space-y-6">
      <div>
        <h2 className="text-lg font-semibold text-slate-900 dark:text-white mb-1">
          Tell us about your home
        </h2>
        <p className="text-sm text-slate-600 dark:text-slate-400">
          We&apos;ll use this to personalize your maintenance schedule and recommendations
        </p>
      </div>

      {/* Basic Info */}
      <div className="space-y-4">
        <div>
          <label htmlFor="name" className="label block mb-1.5">
            Home name
          </label>
          <input
            {...register('name')}
            id="name"
            type="text"
            className="input"
            placeholder="e.g., Main Residence, Beach House"
          />
          {errors.name && <p className="text-sm text-red-500 mt-1">{errors.name.message}</p>}
        </div>

        <div>
          <label htmlFor="propertyType" className="label block mb-1.5">
            Property type
          </label>
          <select {...register('propertyType')} id="propertyType" className="input">
            {propertyTypeOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>
          {errors.propertyType && (
            <p className="text-sm text-red-500 mt-1">{errors.propertyType.message}</p>
          )}
        </div>
      </div>

      {/* Address */}
      <div className="space-y-4">
        <h3 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2">
          Address
        </h3>

        <div>
          <label htmlFor="addressLine1" className="label block mb-1.5">
            Street address
          </label>
          <input
            {...register('addressLine1')}
            id="addressLine1"
            type="text"
            className="input"
            placeholder="123 Main Street"
          />
          {errors.addressLine1 && (
            <p className="text-sm text-red-500 mt-1">{errors.addressLine1.message}</p>
          )}
        </div>

        <div>
          <label htmlFor="addressLine2" className="label block mb-1.5">
            Apt, suite, etc. (optional)
          </label>
          <input
            {...register('addressLine2')}
            id="addressLine2"
            type="text"
            className="input"
            placeholder="Apt 4B"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="city" className="label block mb-1.5">
              City
            </label>
            <input {...register('city')} id="city" type="text" className="input" placeholder="City" />
            {errors.city && <p className="text-sm text-red-500 mt-1">{errors.city.message}</p>}
          </div>
          <div>
            <label htmlFor="state" className="label block mb-1.5">
              State
            </label>
            <select {...register('state')} id="state" className="input">
              <option value="">Select state</option>
              {usStates.map((s) => (
                <option key={s.value} value={s.value}>
                  {s.label}
                </option>
              ))}
            </select>
            {errors.state && <p className="text-sm text-red-500 mt-1">{errors.state.message}</p>}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label htmlFor="postalCode" className="label block mb-1.5">
              ZIP code
            </label>
            <input
              {...register('postalCode')}
              id="postalCode"
              type="text"
              className="input"
              placeholder="12345"
            />
            {errors.postalCode && (
              <p className="text-sm text-red-500 mt-1">{errors.postalCode.message}</p>
            )}
          </div>
          <div>
            <label htmlFor="yearBuilt" className="label block mb-1.5">
              Year built (optional)
            </label>
            <input
              {...register('yearBuilt')}
              id="yearBuilt"
              type="number"
              className="input"
              placeholder="1990"
            />
            {errors.yearBuilt && (
              <p className="text-sm text-red-500 mt-1">{errors.yearBuilt.message}</p>
            )}
          </div>
        </div>
      </div>

      {/* Property Details */}
      <div className="space-y-4">
        <h3 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2">
          Property Details
        </h3>

        <div className="grid grid-cols-3 gap-4">
          <div>
            <label htmlFor="squareFeet" className="label block mb-1.5">
              Square feet
            </label>
            <input
              {...register('squareFeet')}
              id="squareFeet"
              type="number"
              className="input"
              placeholder="2000"
            />
          </div>
          <div>
            <label htmlFor="bedrooms" className="label block mb-1.5">
              Bedrooms
            </label>
            <input
              {...register('bedrooms')}
              id="bedrooms"
              type="number"
              className="input"
              placeholder="3"
            />
          </div>
          <div>
            <label htmlFor="bathrooms" className="label block mb-1.5">
              Bathrooms
            </label>
            <input
              {...register('bathrooms')}
              id="bathrooms"
              type="number"
              step="0.5"
              className="input"
              placeholder="2"
            />
          </div>
        </div>
      </div>

      {/* Property Features */}
      <div className="space-y-4">
        <h3 className="text-sm font-medium text-slate-700 dark:text-slate-300 border-b border-slate-200 dark:border-slate-700 pb-2">
          Property Features
        </h3>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          Select all that apply - this helps us create a personalized maintenance plan
        </p>

        <div className="grid grid-cols-2 gap-3">
          {featureOptions.map((feature) => (
            <label
              key={feature.name}
              className="flex items-start gap-3 p-3 rounded-lg border border-slate-200 dark:border-slate-700 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors"
            >
              <input
                type="checkbox"
                {...register(feature.name)}
                className="w-4 h-4 mt-0.5 text-emerald-600 rounded border-slate-300 dark:border-slate-600"
              />
              <div>
                <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                  {feature.label}
                </span>
                <p className="text-xs text-slate-500 dark:text-slate-400">{feature.description}</p>
              </div>
            </label>
          ))}
        </div>
      </div>

      <div className="pt-4">
        <button type="submit" disabled={isSubmitting} className="btn btn-primary w-full">
          {isSubmitting ? (
            <>
              <svg className="animate-spin -ml-1 mr-2 h-4 w-4" fill="none" viewBox="0 0 24 24">
                <circle
                  className="opacity-25"
                  cx="12"
                  cy="12"
                  r="10"
                  stroke="currentColor"
                  strokeWidth="4"
                />
                <path
                  className="opacity-75"
                  fill="currentColor"
                  d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                />
              </svg>
              Saving...
            </>
          ) : (
            'Continue'
          )}
        </button>
      </div>
    </form>
  );
}
