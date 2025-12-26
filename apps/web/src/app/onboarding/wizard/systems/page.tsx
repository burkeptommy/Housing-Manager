'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Settings,
  ArrowRight,
  ArrowLeft,
  Plus,
  X,
  ChevronDown,
  ChevronUp,
  Pencil,
  Trash2,
  Home,
  Thermometer,
  Snowflake,
  Droplet,
  Droplets,
  Zap,
  ArrowUpFromLine,
  BatteryCharging,
  Waves,
  Container,
  CircleDot,
  ShieldCheck,
  Cpu,
  Sun,
  PlugZap,
  Flame,
  Wind,
  Disc,
  Trash,
  Wine,
  Microwave,
} from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { FormInput, FormSelect } from '@/components/onboarding/forms';
import { useOnboarding } from '@/context/OnboardingContext';
import {
  HomeSystem,
  Appliance,
  SystemCategory,
  ApplianceCategory,
  SYSTEM_CATEGORIES,
  APPLIANCE_CATEGORIES,
} from '@/types/onboarding';
import { generateId } from '@/lib/id';
import { cn } from '@/lib/utils';

const FUEL_TYPE_OPTIONS = [
  { value: 'electric', label: 'Electric' },
  { value: 'gas', label: 'Natural Gas' },
  { value: 'oil', label: 'Oil' },
  { value: 'propane', label: 'Propane' },
  { value: 'solar', label: 'Solar' },
];

// Icon map for systems
const SYSTEM_ICON_MAP: Record<string, React.ComponentType<{ className?: string }>> = {
  Thermometer,
  Snowflake,
  Droplet,
  Droplets,
  Zap,
  ArrowUpFromLine,
  BatteryCharging,
  Waves,
  Container,
  CircleDot,
  ShieldCheck,
  Cpu,
  Sun,
  PlugZap,
};

// Icon map for appliances
const APPLIANCE_ICON_MAP: Record<string, React.ComponentType<{ className?: string }>> = {
  Refrigerator: Container,
  Disc,
  Waves,
  Wind,
  Flame,
  Microwave,
  Trash,
  Wine,
  Snowflake,
};

type ItemType = 'system' | 'appliance';

export default function SystemsPage() {
  const router = useRouter();
  const { data, addSystem, updateSystem, removeSystem, addAppliance, updateAppliance, removeAppliance, completeStep } =
    useOnboarding();

  // Modal state
  const [isAdding, setIsAdding] = useState(false);
  const [itemType, setItemType] = useState<ItemType>('system');
  const [editingSystem, setEditingSystem] = useState<HomeSystem | null>(null);
  const [editingAppliance, setEditingAppliance] = useState<Appliance | null>(null);
  const [expandedSections, setExpandedSections] = useState<string[]>(['systems', 'appliances']);

  // Form state
  const [selectedSystemCategory, setSelectedSystemCategory] = useState<SystemCategory | null>(null);
  const [selectedApplianceCategory, setSelectedApplianceCategory] = useState<ApplianceCategory | null>(null);
  const [brand, setBrand] = useState('');
  const [model, setModel] = useState('');
  const [serialNumber, setSerialNumber] = useState('');
  const [installDate, setInstallDate] = useState('');
  const [age, setAge] = useState('');
  const [lastServiceDate, setLastServiceDate] = useState('');
  const [serviceVendor, setServiceVendor] = useState('');
  const [serviceVendorPhone, setServiceVendorPhone] = useState('');
  const [warrantyExpiration, setWarrantyExpiration] = useState('');
  const [fuelType, setFuelType] = useState<HomeSystem['fuelType']>();
  const [notes, setNotes] = useState('');

  const toggleSection = (section: string) => {
    setExpandedSections((prev) =>
      prev.includes(section) ? prev.filter((s) => s !== section) : [...prev, section]
    );
  };

  const resetForm = () => {
    setSelectedSystemCategory(null);
    setSelectedApplianceCategory(null);
    setBrand('');
    setModel('');
    setSerialNumber('');
    setInstallDate('');
    setAge('');
    setLastServiceDate('');
    setServiceVendor('');
    setServiceVendorPhone('');
    setWarrantyExpiration('');
    setFuelType(undefined);
    setNotes('');
  };

  const openAddSystemModal = (category?: SystemCategory) => {
    resetForm();
    setItemType('system');
    if (category) setSelectedSystemCategory(category);
    setEditingSystem(null);
    setEditingAppliance(null);
    setIsAdding(true);
  };

  const openAddApplianceModal = (category?: ApplianceCategory) => {
    resetForm();
    setItemType('appliance');
    if (category) setSelectedApplianceCategory(category);
    setEditingSystem(null);
    setEditingAppliance(null);
    setIsAdding(true);
  };

  const openEditSystemModal = (system: HomeSystem) => {
    setEditingSystem(system);
    setItemType('system');
    setSelectedSystemCategory(system.category);
    setBrand(system.brand || '');
    setModel(system.model || '');
    setSerialNumber(system.serialNumber || '');
    setInstallDate(system.installDate || '');
    setAge(system.age?.toString() || '');
    setLastServiceDate(system.lastServiceDate || '');
    setServiceVendor(system.serviceVendor || '');
    setServiceVendorPhone(system.serviceVendorPhone || '');
    setWarrantyExpiration(system.warrantyExpiration || '');
    setFuelType(system.fuelType);
    setNotes(system.notes || '');
    setIsAdding(true);
  };

  const openEditApplianceModal = (appliance: Appliance) => {
    setEditingAppliance(appliance);
    setItemType('appliance');
    setSelectedApplianceCategory(appliance.category);
    setBrand(appliance.brand || '');
    setModel(appliance.model || '');
    setSerialNumber(appliance.serialNumber || '');
    setInstallDate(appliance.purchaseDate || '');
    setWarrantyExpiration(appliance.warrantyExpiration || '');
    setNotes(appliance.notes || '');
    setIsAdding(true);
  };

  const handleSaveSystem = () => {
    if (!selectedSystemCategory) return;

    const system: HomeSystem = {
      id: editingSystem?.id || generateId(),
      category: selectedSystemCategory,
      brand: brand || undefined,
      model: model || undefined,
      serialNumber: serialNumber || undefined,
      installDate: installDate || undefined,
      age: age ? parseInt(age) : undefined,
      lastServiceDate: lastServiceDate || undefined,
      serviceVendor: serviceVendor || undefined,
      serviceVendorPhone: serviceVendorPhone || undefined,
      warrantyExpiration: warrantyExpiration || undefined,
      fuelType,
      notes: notes || undefined,
    };

    if (editingSystem) {
      updateSystem(system);
    } else {
      addSystem(system);
    }

    setIsAdding(false);
    setEditingSystem(null);
    resetForm();
  };

  const handleSaveAppliance = () => {
    if (!selectedApplianceCategory) return;

    const appliance: Appliance = {
      id: editingAppliance?.id || generateId(),
      category: selectedApplianceCategory,
      brand: brand || undefined,
      model: model || undefined,
      serialNumber: serialNumber || undefined,
      purchaseDate: installDate || undefined,
      warrantyExpiration: warrantyExpiration || undefined,
      notes: notes || undefined,
    };

    if (editingAppliance) {
      updateAppliance(appliance);
    } else {
      addAppliance(appliance);
    }

    setIsAdding(false);
    setEditingAppliance(null);
    resetForm();
  };

  const handleDeleteSystem = (id: string) => {
    if (confirm('Are you sure you want to remove this system?')) {
      removeSystem(id);
    }
  };

  const handleDeleteAppliance = (id: string) => {
    if (confirm('Are you sure you want to remove this appliance?')) {
      removeAppliance(id);
    }
  };

  const handleContinue = () => {
    completeStep('systems');
    router.push('/onboarding/wizard/family');
  };

  const getSystemIcon = (iconName: string) => {
    const Icon = SYSTEM_ICON_MAP[iconName];
    return Icon ? <Icon className="w-5 h-5" /> : <Settings className="w-5 h-5" />;
  };

  const getApplianceIcon = (iconName: string) => {
    const Icon = APPLIANCE_ICON_MAP[iconName];
    return Icon ? <Icon className="w-5 h-5" /> : <Settings className="w-5 h-5" />;
  };

  const showFuelTypeField = selectedSystemCategory && ['hvac_heating', 'hvac_cooling', 'water_heater', 'generator'].includes(selectedSystemCategory);

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Settings className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">Home systems & appliances</h1>
        <p className="text-gray-600">
          Tell us about your home systems and major appliances so we can track maintenance.
        </p>
      </div>

      {/* Schedule Home Visit CTA */}
      <div className="bg-haven-champagne-50 border border-haven-champagne-200 rounded-2xl p-6 mb-6">
        <div className="flex items-start gap-4">
          <div className="w-12 h-12 bg-haven-champagne-100 rounded-xl flex items-center justify-center flex-shrink-0">
            <Home className="w-6 h-6 text-haven-champagne-600" />
          </div>
          <div className="flex-1">
            <h3 className="font-semibold text-haven-navy-900">Want us to document everything?</h3>
            <p className="text-sm text-gray-600 mt-1">
              Schedule a free home visit and our handyman will photograph and catalog all your systems.
            </p>
            <Link
              href="/onboarding/schedule?type=visit"
              className="inline-flex items-center gap-1 text-sm font-medium text-haven-champagne-700 hover:text-haven-champagne-800 mt-3"
            >
              Schedule home visit →
            </Link>
          </div>
        </div>
      </div>

      {/* Home Systems Section */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden mb-4">
        <button
          onClick={() => toggleSection('systems')}
          className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <h3 className="font-semibold text-haven-navy-900">Home Systems</h3>
            {data.systems.length > 0 && (
              <span className="bg-haven-champagne-100 text-haven-champagne-700 text-xs font-medium px-2 py-0.5 rounded-full">
                {data.systems.length}
              </span>
            )}
          </div>
          {expandedSections.includes('systems') ? (
            <ChevronUp className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-gray-400" />
          )}
        </button>

        {expandedSections.includes('systems') && (
          <div className="px-6 pb-6 space-y-3">
            {/* Existing systems */}
            {data.systems.map((system) => {
              const catInfo = SYSTEM_CATEGORIES[system.category];
              return (
                <div
                  key={system.id}
                  className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl group"
                >
                  <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center text-gray-600">
                    {getSystemIcon(catInfo.icon)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-haven-navy-900">{catInfo.label}</p>
                    <p className="text-sm text-gray-500">
                      {system.brand && system.model ? `${system.brand} ${system.model}` : catInfo.description}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => openEditSystemModal(system)}
                      className="p-2 text-gray-400 hover:text-haven-navy-900 hover:bg-white rounded-lg"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDeleteSystem(system.id)}
                      className="p-2 text-gray-400 hover:text-red-500 hover:bg-white rounded-lg"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}

            {/* Quick-add buttons */}
            <div className="flex flex-wrap gap-2 pt-2">
              {Object.entries(SYSTEM_CATEGORIES).map(([key, cat]) => {
                const hasEntry = data.systems.some((s) => s.category === key);
                return (
                  <button
                    key={key}
                    onClick={() => openAddSystemModal(key as SystemCategory)}
                    className={cn(
                      'inline-flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                      hasEntry
                        ? 'bg-green-50 text-green-700 hover:bg-green-100'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    )}
                  >
                    <Plus className="w-3 h-3" />
                    {cat.label}
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* Major Appliances Section */}
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden mb-6">
        <button
          onClick={() => toggleSection('appliances')}
          className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            <h3 className="font-semibold text-haven-navy-900">Major Appliances</h3>
            {data.appliances.length > 0 && (
              <span className="bg-haven-champagne-100 text-haven-champagne-700 text-xs font-medium px-2 py-0.5 rounded-full">
                {data.appliances.length}
              </span>
            )}
          </div>
          {expandedSections.includes('appliances') ? (
            <ChevronUp className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-gray-400" />
          )}
        </button>

        {expandedSections.includes('appliances') && (
          <div className="px-6 pb-6 space-y-3">
            {/* Existing appliances */}
            {data.appliances.map((appliance) => {
              const catInfo = APPLIANCE_CATEGORIES[appliance.category];
              return (
                <div
                  key={appliance.id}
                  className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl group"
                >
                  <div className="w-10 h-10 bg-white rounded-lg flex items-center justify-center text-gray-600">
                    {getApplianceIcon(catInfo.icon)}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-haven-navy-900">{catInfo.label}</p>
                    <p className="text-sm text-gray-500">
                      {appliance.brand && appliance.model ? `${appliance.brand} ${appliance.model}` : 'No details added'}
                    </p>
                  </div>
                  <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => openEditApplianceModal(appliance)}
                      className="p-2 text-gray-400 hover:text-haven-navy-900 hover:bg-white rounded-lg"
                    >
                      <Pencil className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDeleteAppliance(appliance.id)}
                      className="p-2 text-gray-400 hover:text-red-500 hover:bg-white rounded-lg"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}

            {/* Quick-add buttons */}
            <div className="flex flex-wrap gap-2 pt-2">
              {Object.entries(APPLIANCE_CATEGORIES).map(([key, cat]) => {
                const hasEntry = data.appliances.some((a) => a.category === key);
                return (
                  <button
                    key={key}
                    onClick={() => openAddApplianceModal(key as ApplianceCategory)}
                    className={cn(
                      'inline-flex items-center gap-2 px-3 py-2 rounded-lg text-sm font-medium transition-colors',
                      hasEntry
                        ? 'bg-green-50 text-green-700 hover:bg-green-100'
                        : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                    )}
                  >
                    <Plus className="w-3 h-3" />
                    {cat.label}
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/wizard/bills"
          className="text-gray-600 hover:text-haven-navy-900 py-3 px-4 font-medium flex items-center gap-2 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          Back
        </Link>
        <button
          onClick={handleContinue}
          className="bg-haven-navy-900 hover:bg-haven-navy-800 text-white py-3 px-6 rounded-xl font-medium flex items-center gap-2 transition-colors"
        >
          Continue
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>

      {/* Add/Edit Modal */}
      {isAdding && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-haven-navy-900">
                {editingSystem || editingAppliance ? 'Edit' : 'Add'} {itemType === 'system' ? 'System' : 'Appliance'}
              </h2>
              <button
                onClick={() => {
                  setIsAdding(false);
                  setEditingSystem(null);
                  setEditingAppliance(null);
                  resetForm();
                }}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="p-6 space-y-6">
              {/* Category Selection for Systems */}
              {itemType === 'system' && !selectedSystemCategory && (
                <div className="space-y-3">
                  <label className="block text-sm font-medium text-gray-700">
                    What type of system is this?
                  </label>
                  <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto">
                    {Object.entries(SYSTEM_CATEGORIES).map(([key, cat]) => (
                      <button
                        key={key}
                        onClick={() => setSelectedSystemCategory(key as SystemCategory)}
                        className="flex items-center gap-2 p-3 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 text-left transition-colors"
                      >
                        <span className="text-gray-500">{getSystemIcon(cat.icon)}</span>
                        <div>
                          <span className="text-sm font-medium text-haven-navy-900 block">{cat.label}</span>
                          <span className="text-xs text-gray-500">{cat.description}</span>
                        </div>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Category Selection for Appliances */}
              {itemType === 'appliance' && !selectedApplianceCategory && (
                <div className="space-y-3">
                  <label className="block text-sm font-medium text-gray-700">
                    What type of appliance is this?
                  </label>
                  <div className="grid grid-cols-2 gap-2 max-h-64 overflow-y-auto">
                    {Object.entries(APPLIANCE_CATEGORIES).map(([key, cat]) => (
                      <button
                        key={key}
                        onClick={() => setSelectedApplianceCategory(key as ApplianceCategory)}
                        className="flex items-center gap-2 p-3 rounded-xl border border-gray-200 hover:border-haven-champagne-500 hover:bg-haven-champagne-50 text-left transition-colors"
                      >
                        <span className="text-gray-500">{getApplianceIcon(cat.icon)}</span>
                        <span className="text-sm font-medium text-haven-navy-900">{cat.label}</span>
                      </button>
                    ))}
                  </div>
                </div>
              )}

              {/* Form Fields */}
              {((itemType === 'system' && selectedSystemCategory) || (itemType === 'appliance' && selectedApplianceCategory)) && (
                <>
                  {/* Selected Category Indicator */}
                  <div className="flex items-center gap-3 p-3 bg-haven-champagne-50 rounded-xl">
                    <div className="w-10 h-10 bg-haven-champagne-100 rounded-lg flex items-center justify-center text-haven-champagne-600">
                      {itemType === 'system' && selectedSystemCategory
                        ? getSystemIcon(SYSTEM_CATEGORIES[selectedSystemCategory].icon)
                        : selectedApplianceCategory && getApplianceIcon(APPLIANCE_CATEGORIES[selectedApplianceCategory].icon)}
                    </div>
                    <div className="flex-1">
                      <p className="font-medium text-haven-navy-900">
                        {itemType === 'system' && selectedSystemCategory
                          ? SYSTEM_CATEGORIES[selectedSystemCategory].label
                          : selectedApplianceCategory && APPLIANCE_CATEGORIES[selectedApplianceCategory].label}
                      </p>
                    </div>
                    {!editingSystem && !editingAppliance && (
                      <button
                        onClick={() => {
                          setSelectedSystemCategory(null);
                          setSelectedApplianceCategory(null);
                        }}
                        className="text-sm text-haven-champagne-600 hover:text-haven-champagne-700"
                      >
                        Change
                      </button>
                    )}
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Brand"
                      placeholder="e.g., Carrier, Lennox"
                      value={brand}
                      onChange={(e) => setBrand(e.target.value)}
                    />
                    <FormInput
                      label="Model"
                      placeholder="e.g., XC25"
                      value={model}
                      onChange={(e) => setModel(e.target.value)}
                    />
                  </div>

                  <FormInput
                    label="Serial Number (optional)"
                    placeholder="e.g., 1234567890"
                    value={serialNumber}
                    onChange={(e) => setSerialNumber(e.target.value)}
                  />

                  {showFuelTypeField && (
                    <FormSelect
                      label="Fuel Type"
                      options={FUEL_TYPE_OPTIONS}
                      value={fuelType || ''}
                      onChange={(e) => setFuelType(e.target.value as HomeSystem['fuelType'])}
                      placeholder="Select fuel type..."
                    />
                  )}

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label={itemType === 'system' ? 'Install Date' : 'Purchase Date'}
                      type="date"
                      value={installDate}
                      onChange={(e) => setInstallDate(e.target.value)}
                    />
                    {itemType === 'system' && (
                      <FormInput
                        label="Age (years)"
                        type="number"
                        placeholder="e.g., 5"
                        value={age}
                        onChange={(e) => setAge(e.target.value)}
                        min={0}
                        max={100}
                      />
                    )}
                  </div>

                  {itemType === 'system' && (
                    <>
                      <div className="grid grid-cols-2 gap-4">
                        <FormInput
                          label="Last Service Date"
                          type="date"
                          value={lastServiceDate}
                          onChange={(e) => setLastServiceDate(e.target.value)}
                        />
                        <FormInput
                          label="Warranty Expiration"
                          type="date"
                          value={warrantyExpiration}
                          onChange={(e) => setWarrantyExpiration(e.target.value)}
                        />
                      </div>

                      <div className="grid grid-cols-2 gap-4">
                        <FormInput
                          label="Service Vendor"
                          placeholder="e.g., HVAC Pros"
                          value={serviceVendor}
                          onChange={(e) => setServiceVendor(e.target.value)}
                        />
                        <FormInput
                          label="Vendor Phone"
                          type="tel"
                          placeholder="(555) 123-4567"
                          value={serviceVendorPhone}
                          onChange={(e) => setServiceVendorPhone(e.target.value)}
                        />
                      </div>
                    </>
                  )}

                  {itemType === 'appliance' && (
                    <FormInput
                      label="Warranty Expiration"
                      type="date"
                      value={warrantyExpiration}
                      onChange={(e) => setWarrantyExpiration(e.target.value)}
                    />
                  )}

                  <FormInput
                    label="Notes (optional)"
                    placeholder="Any additional details..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                  />
                </>
              )}
            </div>

            {/* Modal Footer */}
            {((itemType === 'system' && selectedSystemCategory) || (itemType === 'appliance' && selectedApplianceCategory)) && (
              <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
                <button
                  onClick={() => {
                    setIsAdding(false);
                    setEditingSystem(null);
                    setEditingAppliance(null);
                    resetForm();
                  }}
                  className="flex-1 py-3 px-4 border border-gray-200 rounded-xl font-medium text-gray-700 hover:bg-gray-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={itemType === 'system' ? handleSaveSystem : handleSaveAppliance}
                  className="flex-1 py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition-colors"
                >
                  {editingSystem || editingAppliance ? 'Save Changes' : `Add ${itemType === 'system' ? 'System' : 'Appliance'}`}
                </button>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
