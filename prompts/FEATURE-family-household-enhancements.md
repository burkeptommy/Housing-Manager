# Haven Mobile - Family & Household Detail Enhancements

## OVERVIEW

Enhance the Family & Household detail screens with comprehensive editable fields for family members, children, vehicles, pets, and staff.

---

## ENHANCEMENT 1: Family Member Detail - Adults

### Current State
- Shows avatar, name, role (Spouse), age
- Phone, Email, Birthday
- Call/Email buttons
- Remove button

### Required Fields to Add

**Personal Information (Editable)**
```typescript
interface AdultMember {
  // Basic (existing)
  firstName: string;
  lastName: string;
  phone: string;
  email: string;
  birthday: Date;
  role: 'head_of_household' | 'spouse' | 'partner' | 'other_adult';
  photo?: string;
  
  // NEW: Work Information
  work: {
    employer?: string;           // "Goldman Sachs"
    jobTitle?: string;           // "Managing Director"
    workPhone?: string;          // "212-555-1234"
    workEmail?: string;          // "tom@gs.com"
    workAddress?: string;        // "200 West St, NYC"
    workSchedule?: string;       // "Mon-Fri 8am-6pm"
  };
  
  // NEW: Memberships & Clubs
  memberships: Array<{
    id: string;
    name: string;               // "Greenwich Country Club"
    type: 'gym' | 'country_club' | 'social_club' | 'professional' | 'other';
    memberNumber?: string;      // "12345"
    expiresAt?: Date;
    monthlyFee?: number;
    notes?: string;
  }>;
  
  // NEW: Emergency Contact
  emergencyContact: {
    name?: string;
    relationship?: string;
    phone?: string;
  };
  
  // NEW: Medical (optional, sensitive)
  medical?: {
    bloodType?: string;
    allergies?: string[];
    primaryCareDoctor?: string;
    doctorPhone?: string;
    insuranceProvider?: string;
    insuranceMemberId?: string;
  };
  
  // NEW: Preferences
  preferences?: {
    dietaryRestrictions?: string[];
    shirtSize?: string;
    shoeSize?: string;
    notes?: string;
  };
}
```

### UI Layout for Adult Detail

```typescript
<ScreenContainer title={`${member.firstName} ${member.lastName}`} showBack>
  <ScrollView>
    {/* Avatar Section (existing) */}
    <View style={styles.avatarSection}>
      {/* ... existing avatar, badges ... */}
    </View>

    {/* Quick Actions (existing) */}
    <View style={styles.quickActions}>
      <ActionButton icon="call" label="Call" />
      <ActionButton icon="mail" label="Email" />
    </View>

    {/* Contact Information (existing, make editable) */}
    <Card>
      <SectionHeader title="CONTACT INFORMATION" action="Edit" onAction={editContact} />
      <InfoRow icon="call" label="Phone" value={member.phone} />
      <InfoRow icon="mail" label="Email" value={member.email} />
      <InfoRow icon="calendar" label="Birthday" value={formatDate(member.birthday)} />
    </Card>

    {/* NEW: Work Information */}
    <Card>
      <SectionHeader title="WORK" action="Edit" onAction={editWork} />
      {member.work?.employer ? (
        <>
          <InfoRow icon="business" label="Employer" value={member.work.employer} />
          <InfoRow icon="briefcase" label="Title" value={member.work.jobTitle} />
          <InfoRow icon="call" label="Work Phone" value={member.work.workPhone} />
          <InfoRow icon="mail" label="Work Email" value={member.work.workEmail} />
          <InfoRow icon="location" label="Office" value={member.work.workAddress} />
        </>
      ) : (
        <EmptyPrompt 
          text="Add work information" 
          onPress={editWork} 
        />
      )}
    </Card>

    {/* NEW: Memberships */}
    <Card>
      <SectionHeader title="MEMBERSHIPS" action="+ Add" onAction={addMembership} />
      {member.memberships?.length > 0 ? (
        member.memberships.map(m => (
          <MembershipRow key={m.id} membership={m} onPress={() => editMembership(m)} />
        ))
      ) : (
        <EmptyPrompt 
          text="Add gym, country club, or other memberships" 
          onPress={addMembership} 
        />
      )}
    </Card>

    {/* NEW: Emergency Contact */}
    <Card>
      <SectionHeader title="EMERGENCY CONTACT" action="Edit" onAction={editEmergency} />
      {member.emergencyContact?.name ? (
        <>
          <InfoRow icon="person" label="Name" value={member.emergencyContact.name} />
          <InfoRow icon="people" label="Relationship" value={member.emergencyContact.relationship} />
          <InfoRow icon="call" label="Phone" value={member.emergencyContact.phone} />
        </>
      ) : (
        <EmptyPrompt text="Add emergency contact" onPress={editEmergency} />
      )}
    </Card>

    {/* NEW: Medical Info (collapsible, sensitive) */}
    <Card>
      <SectionHeader title="MEDICAL INFORMATION" action="Edit" onAction={editMedical} />
      {/* Show if data exists, otherwise prompt */}
    </Card>

    {/* Remove Member */}
    <TouchableOpacity style={styles.dangerButton}>
      <Ionicons name="trash-outline" size={20} color="#dc2626" />
      <Text style={styles.dangerButtonText}>Remove Family Member</Text>
    </TouchableOpacity>
  </ScrollView>
</ScreenContainer>
```

---

## ENHANCEMENT 2: Child Detail

### Required Fields

```typescript
interface ChildMember {
  // Basic
  firstName: string;
  lastName: string;
  nickname?: string;
  birthday: Date;
  photo?: string;
  
  // NEW: School Information
  school: {
    name?: string;              // "Greenwich Country Day"
    grade?: string;             // "7th Grade"
    teacher?: string;           // "Mrs. Johnson"
    schoolPhone?: string;
    schoolAddress?: string;
    busNumber?: string;
    pickupTime?: string;        // "3:15 PM"
    dropoffTime?: string;       // "7:45 AM"
    monthlyTuition?: number;    // 4500
  };
  
  // NEW: Activities & Sports
  activities: Array<{
    id: string;
    name: string;               // "Soccer"
    organization?: string;      // "Greenwich Youth Soccer"
    coach?: string;
    coachPhone?: string;
    schedule?: string;          // "Tues/Thurs 4-5:30pm"
    location?: string;
    seasonStart?: Date;
    seasonEnd?: Date;
    monthlyFee?: number;
  }>;
  
  // NEW: Camps & Programs
  camps: Array<{
    id: string;
    name: string;               // "Camp Laurelwood"
    type: 'summer' | 'day' | 'sports' | 'academic' | 'other';
    startDate?: Date;
    endDate?: Date;
    cost?: number;
    notes?: string;
  }>;
  
  // Medical & Allergies
  medical: {
    allergies?: string[];       // ["Peanuts", "Tree nuts"]
    medications?: string[];
    pediatrician?: string;
    pediatricianPhone?: string;
    insuranceMemberId?: string;
    specialNeeds?: string;
  };
  
  // Preferences
  preferences?: {
    favoriteFood?: string;
    dietaryRestrictions?: string[];
    clothingSize?: string;
    shoeSize?: string;
    interests?: string[];
    notes?: string;
  };
  
  // Friends & Contacts
  friends?: Array<{
    name: string;
    parentName?: string;
    parentPhone?: string;
  }>;
}
```

### UI Sections for Child

```typescript
{/* School */}
<Card>
  <SectionHeader title="SCHOOL" action="Edit" />
  <InfoRow icon="school" label="School" value={child.school?.name} />
  <InfoRow icon="ribbon" label="Grade" value={child.school?.grade} />
  <InfoRow icon="person" label="Teacher" value={child.school?.teacher} />
  <InfoRow icon="bus" label="Bus #" value={child.school?.busNumber} />
  <InfoRow icon="time" label="Pickup" value={child.school?.pickupTime} />
</Card>

{/* Activities */}
<Card>
  <SectionHeader title="ACTIVITIES & SPORTS" action="+ Add" />
  {child.activities?.map(activity => (
    <ActivityRow key={activity.id} activity={activity} />
  ))}
</Card>

{/* Medical & Allergies - Prominent if allergies exist */}
{child.medical?.allergies?.length > 0 && (
  <Card style={styles.alertCard}>
    <View style={styles.allergyHeader}>
      <Ionicons name="warning" size={20} color="#dc2626" />
      <Text style={styles.allergyTitle}>ALLERGIES</Text>
    </View>
    {child.medical.allergies.map(allergy => (
      <Text key={allergy} style={styles.allergyItem}>• {allergy}</Text>
    ))}
  </Card>
)}
```

---

## ENHANCEMENT 3: Vehicle Detail

### Required Fields

```typescript
interface Vehicle {
  // Basic
  year: number;
  make: string;
  model: string;
  color: string;
  vin?: string;
  photo?: string;
  
  // NEW: Registration
  registration: {
    licensePlate?: string;      // "CT ABC-1234"
    state?: string;             // "Connecticut"
    expiresAt?: Date;           // Registration expiration
    registrationNumber?: string;
  };
  
  // NEW: Insurance
  insurance: {
    provider?: string;          // "State Farm"
    policyNumber?: string;
    expiresAt?: Date;
    agentName?: string;
    agentPhone?: string;
    monthlyPremium?: number;
  };
  
  // NEW: Maintenance Schedule
  maintenance: {
    // Oil
    oilChangeInterval: number;  // 5000 (miles)
    lastOilChange?: Date;
    lastOilChangeMileage?: number;
    nextOilChangeDue?: Date;
    oilType?: string;           // "5W-30 Synthetic"
    
    // Tires
    tireType?: string;          // "Michelin Pilot Sport"
    tireSize?: string;          // "255/40R19"
    lastTireRotation?: Date;
    tireRotationInterval: number; // 7500 (miles)
    lastTireReplacement?: Date;
    tireReplacementMileage?: number;
    
    // Other
    lastInspection?: Date;
    inspectionDue?: Date;
    lastBrakeService?: Date;
    lastTransmissionService?: Date;
  };
  
  // NEW: Current Status
  status: {
    currentMileage?: number;
    fuelType?: 'gas' | 'diesel' | 'electric' | 'hybrid';
    averageMPG?: number;
  };
  
  // NEW: Financing (optional)
  financing?: {
    lender?: string;
    monthlyPayment?: number;
    payoffDate?: Date;
    remainingBalance?: number;
  };
  
  // NEW: Service History
  serviceHistory: Array<{
    id: string;
    date: Date;
    type: 'oil_change' | 'tire_rotation' | 'inspection' | 'repair' | 'other';
    description: string;
    mileage: number;
    cost: number;
    vendor?: string;
    notes?: string;
  }>;
}
```

### UI Sections for Vehicle

```typescript
<ScreenContainer title={`${vehicle.year} ${vehicle.make} ${vehicle.model}`} showBack>
  {/* Hero with car image */}
  <View style={styles.vehicleHero}>
    <View style={styles.vehicleImagePlaceholder}>
      <Ionicons name="car" size={64} color="#c4a574" />
    </View>
    <Text style={styles.vehicleName}>
      {vehicle.year} {vehicle.make} {vehicle.model}
    </Text>
    <Text style={styles.vehicleColor}>{vehicle.color}</Text>
  </View>

  {/* Registration */}
  <Card>
    <SectionHeader title="REGISTRATION" action="Edit" />
    <InfoRow icon="card" label="License Plate" value={vehicle.registration?.licensePlate} />
    <InfoRow icon="flag" label="State" value={vehicle.registration?.state} />
    <InfoRow icon="calendar" label="Expires" value={formatDate(vehicle.registration?.expiresAt)} 
      alert={isExpiringSoon(vehicle.registration?.expiresAt)} />
  </Card>

  {/* Insurance */}
  <Card>
    <SectionHeader title="INSURANCE" action="Edit" />
    <InfoRow icon="shield" label="Provider" value={vehicle.insurance?.provider} />
    <InfoRow icon="document" label="Policy #" value={vehicle.insurance?.policyNumber} />
    <InfoRow icon="calendar" label="Expires" value={formatDate(vehicle.insurance?.expiresAt)} />
    <InfoRow icon="cash" label="Monthly" value={formatCurrency(vehicle.insurance?.monthlyPremium)} />
  </Card>

  {/* Maintenance Due - Prominent alerts */}
  <Card style={styles.maintenanceCard}>
    <SectionHeader title="MAINTENANCE DUE" />
    <MaintenanceAlert 
      type="oil"
      lastService={vehicle.maintenance?.lastOilChange}
      nextDue={vehicle.maintenance?.nextOilChangeDue}
      interval={`Every ${vehicle.maintenance?.oilChangeInterval?.toLocaleString()} miles`}
    />
    <MaintenanceAlert 
      type="tires"
      lastService={vehicle.maintenance?.lastTireRotation}
      interval={`Every ${vehicle.maintenance?.tireRotationInterval?.toLocaleString()} miles`}
    />
    <MaintenanceAlert 
      type="inspection"
      lastService={vehicle.maintenance?.lastInspection}
      nextDue={vehicle.maintenance?.inspectionDue}
    />
  </Card>

  {/* Service History */}
  <Card>
    <SectionHeader title="SERVICE HISTORY" action="+ Add" />
    {vehicle.serviceHistory?.slice(0, 5).map(service => (
      <ServiceHistoryRow key={service.id} service={service} />
    ))}
    {vehicle.serviceHistory?.length > 5 && (
      <TouchableOpacity style={styles.seeAllButton}>
        <Text style={styles.seeAllText}>See all {vehicle.serviceHistory.length} records</Text>
      </TouchableOpacity>
    )}
  </Card>

  {/* Financing (if applicable) */}
  {vehicle.financing?.lender && (
    <Card>
      <SectionHeader title="FINANCING" action="Edit" />
      <InfoRow icon="business" label="Lender" value={vehicle.financing.lender} />
      <InfoRow icon="cash" label="Monthly" value={formatCurrency(vehicle.financing.monthlyPayment)} />
      <InfoRow icon="calendar" label="Payoff Date" value={formatDate(vehicle.financing.payoffDate)} />
    </Card>
  )}
</ScreenContainer>
```

---

## ENHANCEMENT 4: Pet Detail

### Required Fields

```typescript
interface Pet {
  name: string;
  type: 'dog' | 'cat' | 'bird' | 'fish' | 'reptile' | 'other';
  breed?: string;
  birthday?: Date;
  adoptionDate?: Date;
  photo?: string;
  
  // Vet & Medical
  vet: {
    clinicName?: string;        // "Westlake Animal Hospital"
    vetName?: string;           // "Dr. Williams"
    phone?: string;
    address?: string;
    lastVisit?: Date;
    nextVisit?: Date;
  };
  
  vaccinations: Array<{
    name: string;               // "Rabies"
    date: Date;
    expiresAt?: Date;
    notes?: string;
  }>;
  
  medications?: Array<{
    name: string;
    dosage: string;
    frequency: string;
    prescribedBy?: string;
  }>;
  
  // Care
  care: {
    foodBrand?: string;         // "Blue Buffalo"
    foodType?: string;          // "Adult Large Breed"
    feedingSchedule?: string;   // "2x daily, 1 cup each"
    monthlyFoodCost?: number;
    groomer?: string;
    groomerPhone?: string;
    groomingFrequency?: string; // "Every 6 weeks"
    walker?: string;
    walkerPhone?: string;
    boardingFacility?: string;
  };
  
  // IDs & Registration
  registration?: {
    microchipId?: string;
    licenseNumber?: string;
    licenseExpires?: Date;
  };
  
  // Insurance
  insurance?: {
    provider?: string;
    policyNumber?: string;
    monthlyPremium?: number;
  };
}
```

---

## ENHANCEMENT 5: Staff Detail

### Required Fields

```typescript
interface Staff {
  firstName: string;
  lastName: string;
  role: 'nanny' | 'housekeeper' | 'gardener' | 'driver' | 'chef' | 'other';
  photo?: string;
  
  // Contact
  phone: string;
  email?: string;
  address?: string;
  emergencyContact?: {
    name: string;
    phone: string;
    relationship: string;
  };
  
  // Employment
  employment: {
    startDate: Date;
    agency?: string;            // "Greenwich Elite Nannies"
    agencyContact?: string;
    agencyPhone?: string;
    schedule?: string;          // "Mon-Thu 7am-6pm, Fri 7am-3pm"
    responsibilities?: string[];
  };
  
  // NEW: Compensation
  compensation: {
    payFrequency: 'weekly' | 'biweekly' | 'monthly';
    payAmount: number;          // 1500 per week
    payMethod?: 'check' | 'direct_deposit' | 'cash' | 'payroll_service';
    lastPayDate?: Date;
    
    // Benefits you provide
    benefits?: {
      healthInsurance?: boolean;
      healthInsuranceCost?: number;  // What you pay
      dentalInsurance?: boolean;
      paidTimeOff?: number;          // Days per year
      sickDays?: number;
      holidayPay?: boolean;
    };
    
    // Reimbursements
    reimbursements?: {
      mileage?: boolean;
      mileageRate?: number;          // 0.67 per mile
      gas?: boolean;
      gasMonthlyLimit?: number;
      meals?: boolean;
      mealsMonthlyLimit?: number;
      phone?: boolean;
      phoneMonthly?: number;
      other?: string;
    };
  };
  
  // NEW: Documents
  documents?: {
    w9OnFile?: boolean;
    i9OnFile?: boolean;
    backgroundCheckDate?: Date;
    backgroundCheckProvider?: string;
    driversLicense?: string;
    driversLicenseExpires?: Date;
    cprCertified?: boolean;
    cprExpires?: Date;
    firstAidCertified?: boolean;
  };
  
  // Notes
  notes?: string;
}
```

### UI Sections for Staff

```typescript
{/* Compensation */}
<Card>
  <SectionHeader title="COMPENSATION" action="Edit" />
  <InfoRow 
    icon="cash" 
    label="Pay" 
    value={`$${staff.compensation.payAmount.toLocaleString()} ${staff.compensation.payFrequency}`} 
  />
  <InfoRow icon="card" label="Method" value={staff.compensation.payMethod} />
  <InfoRow icon="calendar" label="Last Paid" value={formatDate(staff.compensation.lastPayDate)} />
</Card>

{/* Benefits */}
<Card>
  <SectionHeader title="BENEFITS YOU PROVIDE" action="Edit" />
  {staff.compensation.benefits?.healthInsurance && (
    <InfoRow 
      icon="medkit" 
      label="Health Insurance" 
      value={`$${staff.compensation.benefits.healthInsuranceCost}/mo`} 
    />
  )}
  <InfoRow 
    icon="calendar" 
    label="PTO" 
    value={`${staff.compensation.benefits?.paidTimeOff || 0} days/year`} 
  />
</Card>

{/* Reimbursements */}
<Card>
  <SectionHeader title="REIMBURSEMENTS" action="Edit" />
  {staff.compensation.reimbursements?.gas && (
    <InfoRow 
      icon="car" 
      label="Gas" 
      value={`Up to $${staff.compensation.reimbursements.gasMonthlyLimit}/mo`} 
    />
  )}
  {staff.compensation.reimbursements?.meals && (
    <InfoRow 
      icon="restaurant" 
      label="Meals" 
      value={`Up to $${staff.compensation.reimbursements.mealsMonthlyLimit}/mo`} 
    />
  )}
</Card>

{/* Documents & Certifications */}
<Card>
  <SectionHeader title="DOCUMENTS" action="Edit" />
  <ChecklistRow label="W-9 on file" checked={staff.documents?.w9OnFile} />
  <ChecklistRow label="I-9 on file" checked={staff.documents?.i9OnFile} />
  <ChecklistRow label="Background check" checked={!!staff.documents?.backgroundCheckDate} />
  <ChecklistRow label="CPR certified" checked={staff.documents?.cprCertified} />
</Card>
```

---

## EDIT MODALS

Create reusable edit modal components:

```typescript
// apps/mobile/src/components/forms/EditInfoModal.tsx
interface EditInfoModalProps {
  visible: boolean;
  title: string;
  fields: Array<{
    key: string;
    label: string;
    value: string;
    type: 'text' | 'phone' | 'email' | 'date' | 'currency' | 'multiline';
    placeholder?: string;
    required?: boolean;
  }>;
  onSave: (values: Record<string, string>) => void;
  onClose: () => void;
}
```

---

## VERIFICATION CHECKLIST

### Adult Members
- [ ] Has header with back button
- [ ] Contact info is editable
- [ ] Can add/edit work information
- [ ] Can add/edit memberships
- [ ] Can add/edit emergency contact

### Children
- [ ] Has header with back button
- [ ] School info section with grade, teacher, bus
- [ ] Activities section with add button
- [ ] Allergies prominently displayed if present

### Vehicles
- [ ] Has header with back button
- [ ] Registration with plate, expiration alert
- [ ] Insurance details
- [ ] Maintenance schedule with due alerts
- [ ] Service history with add button

### Pets
- [ ] Has header with back button
- [ ] Vet info with next appointment
- [ ] Vaccination records
- [ ] Care instructions (food, grooming)

### Staff
- [ ] Has header with back button
- [ ] Schedule and responsibilities
- [ ] Compensation details (pay, frequency)
- [ ] Benefits you provide
- [ ] Reimbursement policy
- [ ] Documents checklist

### All Screens
- [ ] Every field is editable via Edit buttons
- [ ] Changes persist (API or local storage)
- [ ] Loading states while saving
- [ ] Success feedback after saving

---

## TEST

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

Test each family entity type and verify all fields are present and editable.
