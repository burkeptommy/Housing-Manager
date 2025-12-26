'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import {
  Users,
  ArrowRight,
  ArrowLeft,
  Plus,
  X,
  ChevronDown,
  ChevronUp,
  Pencil,
  Trash2,
  User,
  Car,
  PawPrint,
  Briefcase,
} from 'lucide-react';
import { SkipToHumanBanner } from '@/components/onboarding/SkipToHumanBanner';
import { FormInput, FormSelect } from '@/components/onboarding/forms';
import { useOnboarding } from '@/context/OnboardingContext';
import { FamilyMember, Vehicle, Pet, HouseholdStaff } from '@/types/onboarding';
import { generateId } from '@/lib/id';
import { cn } from '@/lib/utils';

const MEMBER_TYPE_OPTIONS = [
  { value: 'adult', label: 'Adult' },
  { value: 'child', label: 'Child' },
  { value: 'other', label: 'Other' },
];

const RELATIONSHIP_OPTIONS = [
  { value: 'spouse', label: 'Spouse' },
  { value: 'partner', label: 'Partner' },
  { value: 'child', label: 'Child' },
  { value: 'parent', label: 'Parent' },
  { value: 'sibling', label: 'Sibling' },
  { value: 'other', label: 'Other' },
];

const SPECIES_OPTIONS = [
  { value: 'dog', label: 'Dog' },
  { value: 'cat', label: 'Cat' },
  { value: 'bird', label: 'Bird' },
  { value: 'fish', label: 'Fish' },
  { value: 'other', label: 'Other' },
];

const STAFF_ROLE_OPTIONS = [
  { value: 'nanny', label: 'Nanny' },
  { value: 'housekeeper', label: 'Housekeeper' },
  { value: 'au_pair', label: 'Au Pair' },
  { value: 'caregiver', label: 'Caregiver' },
  { value: 'personal_assistant', label: 'Personal Assistant' },
  { value: 'other', label: 'Other' },
];

const OWNERSHIP_OPTIONS = [
  { value: 'own', label: 'Own' },
  { value: 'lease', label: 'Lease' },
  { value: 'finance', label: 'Finance' },
];

type ModalType = 'member' | 'vehicle' | 'pet' | 'staff' | null;

export default function FamilyPage() {
  const router = useRouter();
  const {
    data,
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
  } = useOnboarding();

  // UI state
  const [expandedSections, setExpandedSections] = useState<string[]>(['members', 'vehicles', 'pets', 'staff']);
  const [modalType, setModalType] = useState<ModalType>(null);
  const [editingMember, setEditingMember] = useState<FamilyMember | null>(null);
  const [editingVehicle, setEditingVehicle] = useState<Vehicle | null>(null);
  const [editingPet, setEditingPet] = useState<Pet | null>(null);
  const [editingStaff, setEditingStaff] = useState<HouseholdStaff | null>(null);

  // Member form state
  const [memberType, setMemberType] = useState<FamilyMember['type']>('adult');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [relationship, setRelationship] = useState('');
  const [occupation, setOccupation] = useState('');
  const [school, setSchool] = useState('');
  const [grade, setGrade] = useState('');

  // Vehicle form state
  const [year, setYear] = useState('');
  const [make, setMake] = useState('');
  const [model, setModel] = useState('');
  const [color, setColor] = useState('');
  const [licensePlate, setLicensePlate] = useState('');
  const [leaseOrOwn, setLeaseOrOwn] = useState<Vehicle['leaseOrOwn']>('own');

  // Pet form state
  const [petName, setPetName] = useState('');
  const [species, setSpecies] = useState<Pet['species']>('dog');
  const [breed, setBreed] = useState('');
  const [petAge, setPetAge] = useState('');
  const [vetName, setVetName] = useState('');
  const [vetPhone, setVetPhone] = useState('');

  // Staff form state
  const [staffRole, setStaffRole] = useState<HouseholdStaff['role']>('nanny');
  const [staffFirstName, setStaffFirstName] = useState('');
  const [staffLastName, setStaffLastName] = useState('');
  const [staffPhone, setStaffPhone] = useState('');
  const [staffEmail, setStaffEmail] = useState('');
  const [schedule, setSchedule] = useState('');

  const toggleSection = (section: string) => {
    setExpandedSections((prev) =>
      prev.includes(section) ? prev.filter((s) => s !== section) : [...prev, section]
    );
  };

  const resetAllForms = () => {
    // Member
    setMemberType('adult');
    setFirstName('');
    setLastName('');
    setEmail('');
    setPhone('');
    setRelationship('');
    setOccupation('');
    setSchool('');
    setGrade('');
    // Vehicle
    setYear('');
    setMake('');
    setModel('');
    setColor('');
    setLicensePlate('');
    setLeaseOrOwn('own');
    // Pet
    setPetName('');
    setSpecies('dog');
    setBreed('');
    setPetAge('');
    setVetName('');
    setVetPhone('');
    // Staff
    setStaffRole('nanny');
    setStaffFirstName('');
    setStaffLastName('');
    setStaffPhone('');
    setStaffEmail('');
    setSchedule('');
  };

  const closeModal = () => {
    setModalType(null);
    setEditingMember(null);
    setEditingVehicle(null);
    setEditingPet(null);
    setEditingStaff(null);
    resetAllForms();
  };

  // Member handlers
  const openAddMemberModal = () => {
    resetAllForms();
    setModalType('member');
  };

  const openEditMemberModal = (member: FamilyMember) => {
    setEditingMember(member);
    setMemberType(member.type);
    setFirstName(member.firstName);
    setLastName(member.lastName);
    setEmail(member.email || '');
    setPhone(member.phone || '');
    setRelationship(member.relationship || '');
    setOccupation(member.occupation || '');
    setSchool(member.school || '');
    setGrade(member.grade || '');
    setModalType('member');
  };

  const handleSaveMember = () => {
    if (!firstName.trim() || !lastName.trim()) return;

    const member: FamilyMember = {
      id: editingMember?.id || generateId(),
      type: memberType,
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email || undefined,
      phone: phone || undefined,
      relationship: relationship || undefined,
      occupation: occupation || undefined,
      school: school || undefined,
      grade: grade || undefined,
    };

    if (editingMember) {
      updateFamilyMember(member);
    } else {
      addFamilyMember(member);
    }

    closeModal();
  };

  // Vehicle handlers
  const openAddVehicleModal = () => {
    resetAllForms();
    setModalType('vehicle');
  };

  const openEditVehicleModal = (vehicle: Vehicle) => {
    setEditingVehicle(vehicle);
    setYear(vehicle.year.toString());
    setMake(vehicle.make);
    setModel(vehicle.model);
    setColor(vehicle.color || '');
    setLicensePlate(vehicle.licensePlate || '');
    setLeaseOrOwn(vehicle.leaseOrOwn || 'own');
    setModalType('vehicle');
  };

  const handleSaveVehicle = () => {
    if (!year || !make.trim() || !model.trim()) return;

    const vehicle: Vehicle = {
      id: editingVehicle?.id || generateId(),
      year: parseInt(year),
      make: make.trim(),
      model: model.trim(),
      color: color || undefined,
      licensePlate: licensePlate || undefined,
      leaseOrOwn,
    };

    if (editingVehicle) {
      updateVehicle(vehicle);
    } else {
      addVehicle(vehicle);
    }

    closeModal();
  };

  // Pet handlers
  const openAddPetModal = () => {
    resetAllForms();
    setModalType('pet');
  };

  const openEditPetModal = (pet: Pet) => {
    setEditingPet(pet);
    setPetName(pet.name);
    setSpecies(pet.species);
    setBreed(pet.breed || '');
    setPetAge(pet.age?.toString() || '');
    setVetName(pet.vetName || '');
    setVetPhone(pet.vetPhone || '');
    setModalType('pet');
  };

  const handleSavePet = () => {
    if (!petName.trim()) return;

    const pet: Pet = {
      id: editingPet?.id || generateId(),
      name: petName.trim(),
      species,
      breed: breed || undefined,
      age: petAge ? parseInt(petAge) : undefined,
      vetName: vetName || undefined,
      vetPhone: vetPhone || undefined,
    };

    if (editingPet) {
      updatePet(pet);
    } else {
      addPet(pet);
    }

    closeModal();
  };

  // Staff handlers
  const openAddStaffModal = () => {
    resetAllForms();
    setModalType('staff');
  };

  const openEditStaffModal = (staff: HouseholdStaff) => {
    setEditingStaff(staff);
    setStaffRole(staff.role);
    setStaffFirstName(staff.firstName);
    setStaffLastName(staff.lastName);
    setStaffPhone(staff.phone || '');
    setStaffEmail(staff.email || '');
    setSchedule(staff.schedule || '');
    setModalType('staff');
  };

  const handleSaveStaff = () => {
    if (!staffFirstName.trim() || !staffLastName.trim()) return;

    const staff: HouseholdStaff = {
      id: editingStaff?.id || generateId(),
      role: staffRole,
      firstName: staffFirstName.trim(),
      lastName: staffLastName.trim(),
      phone: staffPhone || undefined,
      email: staffEmail || undefined,
      schedule: schedule || undefined,
    };

    if (editingStaff) {
      updateStaff(staff);
    } else {
      addStaff(staff);
    }

    closeModal();
  };

  const handleContinue = () => {
    completeStep('family');
    router.push('/onboarding/wizard/review');
  };

  const renderSection = (
    id: string,
    title: string,
    icon: React.ReactNode,
    items: { id: string; name: string; subtitle: string }[],
    onAdd: () => void,
    onEdit: (id: string) => void,
    onDelete: (id: string) => void
  ) => {
    const isExpanded = expandedSections.includes(id);

    return (
      <div className="bg-white rounded-2xl border border-gray-200 overflow-hidden">
        <button
          onClick={() => toggleSection(id)}
          className="w-full px-6 py-4 flex items-center justify-between hover:bg-gray-50 transition-colors"
        >
          <div className="flex items-center gap-3">
            {icon}
            <h3 className="font-semibold text-haven-navy-900">{title}</h3>
            {items.length > 0 && (
              <span className="bg-haven-champagne-100 text-haven-champagne-700 text-xs font-medium px-2 py-0.5 rounded-full">
                {items.length}
              </span>
            )}
          </div>
          {isExpanded ? (
            <ChevronUp className="w-5 h-5 text-gray-400" />
          ) : (
            <ChevronDown className="w-5 h-5 text-gray-400" />
          )}
        </button>

        {isExpanded && (
          <div className="px-6 pb-6 space-y-3">
            {items.map((item) => (
              <div key={item.id} className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl group">
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-haven-navy-900">{item.name}</p>
                  <p className="text-sm text-gray-500">{item.subtitle}</p>
                </div>
                <div className="flex items-center gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button
                    onClick={() => onEdit(item.id)}
                    className="p-2 text-gray-400 hover:text-haven-navy-900 hover:bg-white rounded-lg"
                  >
                    <Pencil className="w-4 h-4" />
                  </button>
                  <button
                    onClick={() => onDelete(item.id)}
                    className="p-2 text-gray-400 hover:text-red-500 hover:bg-white rounded-lg"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}

            <button
              onClick={onAdd}
              className="w-full py-3 px-4 border-2 border-dashed border-gray-200 rounded-xl text-gray-500 hover:border-haven-champagne-500 hover:text-haven-champagne-600 transition-colors flex items-center justify-center gap-2"
            >
              <Plus className="w-4 h-4" />
              Add {title.toLowerCase().replace(/s$/, '')}
            </button>
          </div>
        )}
      </div>
    );
  };

  const memberItems = data.familyMembers.map((m) => ({
    id: m.id,
    name: `${m.firstName} ${m.lastName}`,
    subtitle: m.type === 'child' ? `${m.school || 'Child'}${m.grade ? ` - Grade ${m.grade}` : ''}` : m.occupation || m.relationship || 'Adult',
  }));

  const vehicleItems = data.vehicles.map((v) => ({
    id: v.id,
    name: `${v.year} ${v.make} ${v.model}`,
    subtitle: v.color || v.leaseOrOwn || '',
  }));

  const petItems = data.pets.map((p) => ({
    id: p.id,
    name: p.name,
    subtitle: `${p.species}${p.breed ? ` - ${p.breed}` : ''}`,
  }));

  const staffItems = data.staff.map((s) => ({
    id: s.id,
    name: `${s.firstName} ${s.lastName}`,
    subtitle: s.role.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()),
  }));

  return (
    <div className="max-w-2xl mx-auto px-4 py-8">
      <SkipToHumanBanner />

      {/* Header */}
      <div className="text-center mb-8">
        <div className="w-14 h-14 bg-haven-champagne-100 rounded-2xl flex items-center justify-center mx-auto mb-4">
          <Users className="w-7 h-7 text-haven-champagne-600" />
        </div>
        <h1 className="text-2xl font-bold text-haven-navy-900 mb-2">Family & household</h1>
        <p className="text-gray-600">
          Tell us about your family, vehicles, pets, and household staff.
        </p>
      </div>

      {/* Sections */}
      <div className="space-y-4">
        {renderSection(
          'members',
          'Family Members',
          <User className="w-5 h-5 text-haven-champagne-600" />,
          memberItems,
          openAddMemberModal,
          (id) => {
            const member = data.familyMembers.find((m) => m.id === id);
            if (member) openEditMemberModal(member);
          },
          (id) => {
            if (confirm('Remove this family member?')) removeFamilyMember(id);
          }
        )}

        {renderSection(
          'vehicles',
          'Vehicles',
          <Car className="w-5 h-5 text-haven-champagne-600" />,
          vehicleItems,
          openAddVehicleModal,
          (id) => {
            const vehicle = data.vehicles.find((v) => v.id === id);
            if (vehicle) openEditVehicleModal(vehicle);
          },
          (id) => {
            if (confirm('Remove this vehicle?')) removeVehicle(id);
          }
        )}

        {renderSection(
          'pets',
          'Pets',
          <PawPrint className="w-5 h-5 text-haven-champagne-600" />,
          petItems,
          openAddPetModal,
          (id) => {
            const pet = data.pets.find((p) => p.id === id);
            if (pet) openEditPetModal(pet);
          },
          (id) => {
            if (confirm('Remove this pet?')) removePet(id);
          }
        )}

        {renderSection(
          'staff',
          'Household Staff',
          <Briefcase className="w-5 h-5 text-haven-champagne-600" />,
          staffItems,
          openAddStaffModal,
          (id) => {
            const staff = data.staff.find((s) => s.id === id);
            if (staff) openEditStaffModal(staff);
          },
          (id) => {
            if (confirm('Remove this staff member?')) removeStaff(id);
          }
        )}
      </div>

      {/* Navigation */}
      <div className="flex justify-between mt-8">
        <Link
          href="/onboarding/wizard/systems"
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

      {/* Modal */}
      {modalType && (
        <div className="fixed inset-0 bg-black/50 flex items-end sm:items-center justify-center z-50 p-4">
          <div className="bg-white rounded-t-2xl sm:rounded-2xl w-full max-w-lg max-h-[90vh] overflow-y-auto">
            {/* Modal Header */}
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-lg font-semibold text-haven-navy-900">
                {editingMember || editingVehicle || editingPet || editingStaff ? 'Edit' : 'Add'}{' '}
                {modalType === 'member' && 'Family Member'}
                {modalType === 'vehicle' && 'Vehicle'}
                {modalType === 'pet' && 'Pet'}
                {modalType === 'staff' && 'Staff Member'}
              </h2>
              <button onClick={closeModal} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Content */}
            <div className="p-6 space-y-6">
              {/* Family Member Form */}
              {modalType === 'member' && (
                <>
                  <FormSelect
                    label="Type"
                    options={MEMBER_TYPE_OPTIONS}
                    value={memberType}
                    onChange={(e) => setMemberType(e.target.value as FamilyMember['type'])}
                  />

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="First Name"
                      placeholder="John"
                      value={firstName}
                      onChange={(e) => setFirstName(e.target.value)}
                      required
                    />
                    <FormInput
                      label="Last Name"
                      placeholder="Smith"
                      value={lastName}
                      onChange={(e) => setLastName(e.target.value)}
                      required
                    />
                  </div>

                  <FormSelect
                    label="Relationship"
                    options={RELATIONSHIP_OPTIONS}
                    value={relationship}
                    onChange={(e) => setRelationship(e.target.value)}
                    placeholder="Select relationship..."
                  />

                  {memberType === 'adult' && (
                    <>
                      <FormInput
                        label="Email"
                        type="email"
                        placeholder="john@example.com"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                      />
                      <FormInput
                        label="Phone"
                        type="tel"
                        placeholder="(555) 123-4567"
                        value={phone}
                        onChange={(e) => setPhone(e.target.value)}
                      />
                      <FormInput
                        label="Occupation"
                        placeholder="Software Engineer"
                        value={occupation}
                        onChange={(e) => setOccupation(e.target.value)}
                      />
                    </>
                  )}

                  {memberType === 'child' && (
                    <div className="grid grid-cols-2 gap-4">
                      <FormInput
                        label="School"
                        placeholder="Greenwich High School"
                        value={school}
                        onChange={(e) => setSchool(e.target.value)}
                      />
                      <FormInput
                        label="Grade"
                        placeholder="10th"
                        value={grade}
                        onChange={(e) => setGrade(e.target.value)}
                      />
                    </div>
                  )}
                </>
              )}

              {/* Vehicle Form */}
              {modalType === 'vehicle' && (
                <>
                  <div className="grid grid-cols-3 gap-4">
                    <FormInput
                      label="Year"
                      type="number"
                      placeholder="2023"
                      value={year}
                      onChange={(e) => setYear(e.target.value)}
                      required
                    />
                    <FormInput
                      label="Make"
                      placeholder="Tesla"
                      value={make}
                      onChange={(e) => setMake(e.target.value)}
                      required
                    />
                    <FormInput
                      label="Model"
                      placeholder="Model Y"
                      value={model}
                      onChange={(e) => setModel(e.target.value)}
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Color"
                      placeholder="White"
                      value={color}
                      onChange={(e) => setColor(e.target.value)}
                    />
                    <FormInput
                      label="License Plate"
                      placeholder="ABC-1234"
                      value={licensePlate}
                      onChange={(e) => setLicensePlate(e.target.value)}
                    />
                  </div>

                  <FormSelect
                    label="Ownership"
                    options={OWNERSHIP_OPTIONS}
                    value={leaseOrOwn}
                    onChange={(e) => setLeaseOrOwn(e.target.value as Vehicle['leaseOrOwn'])}
                  />
                </>
              )}

              {/* Pet Form */}
              {modalType === 'pet' && (
                <>
                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Name"
                      placeholder="Max"
                      value={petName}
                      onChange={(e) => setPetName(e.target.value)}
                      required
                    />
                    <FormSelect
                      label="Species"
                      options={SPECIES_OPTIONS}
                      value={species}
                      onChange={(e) => setSpecies(e.target.value as Pet['species'])}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Breed"
                      placeholder="Golden Retriever"
                      value={breed}
                      onChange={(e) => setBreed(e.target.value)}
                    />
                    <FormInput
                      label="Age (years)"
                      type="number"
                      placeholder="3"
                      value={petAge}
                      onChange={(e) => setPetAge(e.target.value)}
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Vet Name"
                      placeholder="Dr. Smith"
                      value={vetName}
                      onChange={(e) => setVetName(e.target.value)}
                    />
                    <FormInput
                      label="Vet Phone"
                      type="tel"
                      placeholder="(555) 123-4567"
                      value={vetPhone}
                      onChange={(e) => setVetPhone(e.target.value)}
                    />
                  </div>
                </>
              )}

              {/* Staff Form */}
              {modalType === 'staff' && (
                <>
                  <FormSelect
                    label="Role"
                    options={STAFF_ROLE_OPTIONS}
                    value={staffRole}
                    onChange={(e) => setStaffRole(e.target.value as HouseholdStaff['role'])}
                  />

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="First Name"
                      placeholder="Maria"
                      value={staffFirstName}
                      onChange={(e) => setStaffFirstName(e.target.value)}
                      required
                    />
                    <FormInput
                      label="Last Name"
                      placeholder="Garcia"
                      value={staffLastName}
                      onChange={(e) => setStaffLastName(e.target.value)}
                      required
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <FormInput
                      label="Phone"
                      type="tel"
                      placeholder="(555) 123-4567"
                      value={staffPhone}
                      onChange={(e) => setStaffPhone(e.target.value)}
                    />
                    <FormInput
                      label="Email"
                      type="email"
                      placeholder="maria@example.com"
                      value={staffEmail}
                      onChange={(e) => setStaffEmail(e.target.value)}
                    />
                  </div>

                  <FormInput
                    label="Schedule"
                    placeholder="Mon-Fri 9am-5pm"
                    value={schedule}
                    onChange={(e) => setSchedule(e.target.value)}
                  />
                </>
              )}
            </div>

            {/* Modal Footer */}
            <div className="sticky bottom-0 bg-white border-t border-gray-200 px-6 py-4 flex gap-3">
              <button
                onClick={closeModal}
                className="flex-1 py-3 px-4 border border-gray-200 rounded-xl font-medium text-gray-700 hover:bg-gray-50 transition-colors"
              >
                Cancel
              </button>
              <button
                onClick={() => {
                  if (modalType === 'member') handleSaveMember();
                  else if (modalType === 'vehicle') handleSaveVehicle();
                  else if (modalType === 'pet') handleSavePet();
                  else if (modalType === 'staff') handleSaveStaff();
                }}
                className="flex-1 py-3 px-4 bg-haven-navy-900 text-white rounded-xl font-medium hover:bg-haven-navy-800 transition-colors"
              >
                {editingMember || editingVehicle || editingPet || editingStaff ? 'Save Changes' : 'Add'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
