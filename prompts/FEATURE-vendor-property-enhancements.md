# Haven Mobile - Vendor Detail & Property Enhancements

## OVERVIEW

Enhance vendor detail screens with comprehensive information based on vendor type, and add missing functionality for property systems and utilities.

---

## PART A: VENDOR DETAIL ENHANCEMENTS

### Problem
Vendor detail (e.g., Eversource) only shows basic contact info and activity history. Need vendor-type-specific details like contracts, payments, service rates, etc.

### Location
```
apps/mobile/app/(tabs)/manager/vendors/[id].tsx
```

### Vendor Data Model Enhancement

```typescript
interface Vendor {
  // Basic (existing)
  id: string;
  name: string;
  type: VendorType;
  phone?: string;
  website?: string;
  isFavorite: boolean;
  rating?: number;
  
  // NEW: Contact Details
  contacts: Array<{
    id: string;
    name: string;
    title?: string;           // "Account Manager"
    phone?: string;
    email?: string;
    isPrimary: boolean;
  }>;
  
  // NEW: Account Information
  account?: {
    accountNumber?: string;   // Your account number with them
    serviceAddress?: string;  // Address they service
    customerSince?: Date;
    contractNumber?: string;
  };
  
  // NEW: Billing & Payment
  billing: {
    paymentFrequency?: 'monthly' | 'quarterly' | 'annual' | 'per_service' | 'on_demand';
    averageMonthlyBill?: number;
    lastPaymentAmount?: number;
    lastPaymentDate?: Date;
    nextPaymentDue?: Date;
    autopayEnabled?: boolean;
    paymentMethod?: 'haven' | 'direct' | 'check';
  };
  
  // NEW: Contracts
  contracts: Array<{
    id: string;
    name: string;             // "Service Agreement 2024"
    startDate: Date;
    endDate?: Date;
    value?: number;           // Total contract value
    documentUrl?: string;     // Link to PDF in vault
    autoRenews: boolean;
    renewalNoticeDays?: number; // 30 days notice required
    notes?: string;
  }>;
  
  // NEW: Service History
  serviceHistory: Array<{
    id: string;
    date: Date;
    type: 'service_call' | 'installation' | 'repair' | 'inspection' | 'delivery' | 'other';
    description: string;
    technician?: string;
    cost?: number;
    paid: boolean;
    rating?: number;
    notes?: string;
  }>;
  
  // NEW: Upcoming Services
  upcomingServices: Array<{
    id: string;
    scheduledDate: Date;
    type: string;
    description: string;
    estimatedCost?: number;
    confirmationNumber?: string;
  }>;
  
  // NEW: Type-Specific Data (see below)
  typeSpecificData?: VendorTypeSpecificData;
  
  // Notes
  notes?: string;
}

type VendorType = 
  | 'electric'
  | 'gas'
  | 'water'
  | 'internet'
  | 'cable'
  | 'phone'
  | 'oil_propane'
  | 'trash'
  | 'landscaping'
  | 'cleaning'
  | 'pool'
  | 'hvac'
  | 'plumbing'
  | 'electrical'
  | 'roofing'
  | 'pest_control'
  | 'security'
  | 'insurance'
  | 'mortgage'
  | 'other';
```

### Type-Specific Data

```typescript
// Electric Provider
interface ElectricVendorData {
  currentRate?: number;           // $0.14/kWh
  rateType?: 'fixed' | 'variable' | 'time_of_use';
  ratePlanName?: string;          // "Standard Residential"
  rateExpiresAt?: Date;           // When fixed rate expires
  avgMonthlyUsage?: number;       // kWh
  peakUsageMonth?: string;        // "August"
  greenEnergyPercent?: number;    // 100% renewable?
  budgetBilling?: boolean;
  budgetAmount?: number;
}

// Gas Provider
interface GasVendorData {
  currentRate?: number;           // $/therm
  avgMonthlyUsage?: number;       // therms
  budgetBilling?: boolean;
  budgetAmount?: number;
}

// Internet Provider  
interface InternetVendorData {
  planName?: string;              // "Gigabit Pro"
  downloadSpeed?: number;         // 1000 Mbps
  uploadSpeed?: number;           // 35 Mbps
  dataCapGB?: number;             // null = unlimited
  equipmentRental?: number;       // $15/mo for router
  contractEndsAt?: Date;
  wifiNetworkName?: string;
  wifiPassword?: string;          // Stored securely
}

// Oil/Propane Delivery
interface OilPropaneVendorData {
  currentPricePerGallon?: number;
  tankSize?: number;              // 275 gallons
  deliverySchedule?: 'automatic' | 'will_call';
  lastDeliveryGallons?: number;
  lastDeliveryDate?: Date;
  estimatedNextDelivery?: Date;
  paymentTerms?: string;          // "Net 30"
}

// Landscaping
interface LandscapingVendorData {
  serviceFrequency?: string;      // "Weekly during season"
  seasonStart?: string;           // "April"
  seasonEnd?: string;             // "November"
  servicesIncluded?: string[];    // ["Mowing", "Edging", "Leaf cleanup"]
  winterServices?: string[];      // ["Snow removal", "Salting"]
  snowRemovalRate?: number;       // Per visit or seasonal
}

// Cleaning
interface CleaningVendorData {
  serviceFrequency?: string;      // "Bi-weekly"
  regularDay?: string;            // "Thursday"
  regularTime?: string;           // "9:00 AM"
  teamSize?: number;              // 2 people
  servicesIncluded?: string[];
  deepCleanFrequency?: string;    // "Quarterly"
  suppliesProvided?: boolean;
}

// Pool Service
interface PoolVendorData {
  serviceFrequency?: string;
  seasonStart?: string;
  seasonEnd?: string;
  servicesIncluded?: string[];    // ["Chemical balance", "Skimming", "Filter clean"]
  poolOpeningCost?: number;
  poolClosingCost?: number;
  equipmentMaintenance?: string;
}

// HVAC
interface HVACVendorData {
  serviceContractType?: 'maintenance' | 'full_coverage';
  visitsPerYear?: number;
  partsIncluded?: boolean;
  laborIncluded?: boolean;
  priorityService?: boolean;
  systemsCovered?: string[];      // ["Central AC", "Furnace", "Heat pump"]
}

// Insurance
interface InsuranceVendorData {
  policyType?: 'homeowners' | 'auto' | 'umbrella' | 'life' | 'other';
  policyNumber?: string;
  coverageAmount?: number;
  deductible?: number;
  premium?: number;
  premiumFrequency?: 'monthly' | 'quarterly' | 'annual';
  renewalDate?: Date;
  agentName?: string;
  agentPhone?: string;
  agentEmail?: string;
}

// Mortgage
interface MortgageVendorData {
  loanNumber?: string;
  originalAmount?: number;
  currentBalance?: number;
  interestRate?: number;
  rateType?: 'fixed' | 'arm';
  monthlyPayment?: number;
  escrowAmount?: number;
  principalAmount?: number;
  interestAmount?: number;
  payoffDate?: Date;
  refinanceOpportunity?: boolean;
}
```

### UI Layout for Vendor Detail

```typescript
<ScreenContainer 
  title={vendor.name} 
  showBack
  rightAction={
    <TouchableOpacity onPress={toggleFavorite}>
      <Ionicons 
        name={vendor.isFavorite ? "star" : "star-outline"} 
        size={24} 
        color="#c4a574" 
      />
    </TouchableOpacity>
  }
>
  <ScrollView>
    {/* Header Card */}
    <Card style={styles.headerCard}>
      <View style={styles.vendorHeader}>
        <View style={styles.vendorIcon}>
          <Ionicons name={getVendorIcon(vendor.type)} size={32} color="#c4a574" />
        </View>
        <View style={styles.vendorInfo}>
          <Text style={styles.vendorName}>{vendor.name}</Text>
          <Text style={styles.vendorType}>{formatVendorType(vendor.type)}</Text>
        </View>
      </View>
      
      {/* Rating */}
      <TouchableOpacity style={styles.ratingRow} onPress={() => setShowRatingModal(true)}>
        <Text style={styles.ratingLabel}>Your Rating:</Text>
        <StarRating rating={vendor.rating} size={20} />
        <Ionicons name="chevron-forward" size={20} color="#627d98" />
      </TouchableOpacity>
      
      {/* Quick Actions */}
      <View style={styles.quickActions}>
        <ActionButton icon="call" label="Call" onPress={() => call(vendor.phone)} />
        <ActionButton icon="chatbubble" label="Message" onPress={openMessage} />
      </View>
      
      {/* Ask Alfred */}
      <TouchableOpacity style={styles.alfredButton} onPress={askAlfred}>
        <Ionicons name="calendar" size={20} color="#ffffff" />
        <Text style={styles.alfredButtonText}>Schedule Service</Text>
      </TouchableOpacity>
    </Card>

    {/* Type-Specific Card - PROMINENT */}
    {vendor.type === 'electric' && (
      <Card style={styles.rateCard}>
        <SectionHeader title="CURRENT RATE" />
        <View style={styles.rateDisplay}>
          <Text style={styles.rateValue}>
            ${vendor.typeSpecificData?.currentRate?.toFixed(3)}
          </Text>
          <Text style={styles.rateUnit}>per kWh</Text>
        </View>
        <Text style={styles.ratePlan}>{vendor.typeSpecificData?.ratePlanName}</Text>
        
        {/* Alfred Rate Check */}
        <TouchableOpacity style={styles.checkRatesButton} onPress={askAlfredToCheckRates}>
          <Ionicons name="sparkles" size={16} color="#c4a574" />
          <Text style={styles.checkRatesText}>Ask Alfred to check better rates</Text>
        </TouchableOpacity>
      </Card>
    )}

    {/* Account Information */}
    <Card>
      <SectionHeader title="ACCOUNT INFORMATION" action="Edit" />
      <InfoRow icon="card" label="Account #" value={vendor.account?.accountNumber} />
      <InfoRow icon="location" label="Service Address" value={vendor.account?.serviceAddress} />
      <InfoRow icon="calendar" label="Customer Since" value={formatDate(vendor.account?.customerSince)} />
    </Card>

    {/* Primary Contact */}
    <Card>
      <SectionHeader title="POINT OF CONTACT" action="Edit" />
      {vendor.contacts?.filter(c => c.isPrimary).map(contact => (
        <View key={contact.id}>
          <InfoRow icon="person" label="Name" value={contact.name} />
          <InfoRow icon="briefcase" label="Title" value={contact.title} />
          <InfoRow icon="call" label="Phone" value={contact.phone} />
          <InfoRow icon="mail" label="Email" value={contact.email} />
        </View>
      ))}
      {vendor.contacts?.length > 1 && (
        <TouchableOpacity style={styles.moreContactsLink}>
          <Text style={styles.linkText}>
            +{vendor.contacts.length - 1} more contacts
          </Text>
        </TouchableOpacity>
      )}
    </Card>

    {/* Billing & Payment */}
    <Card>
      <SectionHeader title="BILLING & PAYMENT" action="Edit" />
      <InfoRow 
        icon="repeat" 
        label="Frequency" 
        value={formatFrequency(vendor.billing?.paymentFrequency)} 
      />
      <InfoRow 
        icon="cash" 
        label="Avg Monthly" 
        value={formatCurrency(vendor.billing?.averageMonthlyBill)} 
      />
      <InfoRow 
        icon="checkmark-circle" 
        label="Last Payment" 
        value={`${formatCurrency(vendor.billing?.lastPaymentAmount)} on ${formatDate(vendor.billing?.lastPaymentDate)}`} 
      />
      {vendor.billing?.nextPaymentDue && (
        <InfoRow 
          icon="calendar" 
          label="Next Due" 
          value={formatDate(vendor.billing?.nextPaymentDue)}
          alert={isWithinDays(vendor.billing.nextPaymentDue, 7)}
        />
      )}
      <View style={styles.autopayRow}>
        <Text style={styles.autopayLabel}>Haven Autopay</Text>
        <Switch 
          value={vendor.billing?.autopayEnabled}
          onValueChange={toggleAutopay}
          trackColor={{ true: '#c4a574' }}
        />
      </View>
    </Card>

    {/* Contracts */}
    <Card>
      <SectionHeader title="CONTRACTS" action="+ Add" />
      {vendor.contracts?.length > 0 ? (
        vendor.contracts.map(contract => (
          <TouchableOpacity key={contract.id} style={styles.contractRow}>
            <Ionicons name="document-text" size={20} color="#627d98" />
            <View style={styles.contractInfo}>
              <Text style={styles.contractName}>{contract.name}</Text>
              <Text style={styles.contractDates}>
                {formatDate(contract.startDate)} - {contract.endDate ? formatDate(contract.endDate) : 'Ongoing'}
              </Text>
              {contract.autoRenews && (
                <Text style={styles.autoRenewBadge}>Auto-renews</Text>
              )}
            </View>
            <Ionicons name="chevron-forward" size={20} color="#627d98" />
          </TouchableOpacity>
        ))
      ) : (
        <EmptyPrompt text="No contracts on file" onPress={addContract} />
      )}
    </Card>

    {/* Recent Payments */}
    <Card>
      <SectionHeader title="RECENT PAYMENTS" action="See All" />
      {/* Show last 3 payments */}
      {vendor.serviceHistory
        ?.filter(s => s.cost && s.paid)
        .slice(0, 3)
        .map(payment => (
          <PaymentRow key={payment.id} payment={payment} />
        ))
      }
    </Card>

    {/* Service Visits */}
    <Card>
      <SectionHeader title="SERVICE VISITS" action="See All" />
      {vendor.serviceHistory
        ?.filter(s => s.type === 'service_call' || s.type === 'repair')
        .slice(0, 3)
        .map(visit => (
          <ServiceVisitRow key={visit.id} visit={visit} />
        ))
      }
      {(!vendor.serviceHistory || vendor.serviceHistory.length === 0) && (
        <EmptyPrompt text="No service visits recorded" />
      )}
    </Card>

    {/* Upcoming Services */}
    {vendor.upcomingServices?.length > 0 && (
      <Card>
        <SectionHeader title="UPCOMING" />
        {vendor.upcomingServices.map(service => (
          <UpcomingServiceRow key={service.id} service={service} />
        ))}
      </Card>
    )}

    {/* Contact Info */}
    <Card>
      <SectionHeader title="CONTACT INFORMATION" />
      <InfoRow icon="call" label="Phone" value={vendor.phone} onPress={() => call(vendor.phone)} />
      <InfoRow icon="globe" label="Website" value={vendor.website} onPress={() => openUrl(vendor.website)} />
    </Card>

    {/* Notes */}
    <Card>
      <SectionHeader title="NOTES" action="Edit" />
      <Text style={styles.notesText}>
        {vendor.notes || 'No notes added'}
      </Text>
    </Card>

    {/* Activity History (existing) */}
    <Card>
      <SectionHeader title="ACTIVITY HISTORY" action="+ Add" />
      {/* ... existing activity history ... */}
    </Card>
  </ScrollView>
</ScreenContainer>
```

### Vendor Type-Specific Sections

Create a component that renders the appropriate section based on vendor type:

```typescript
function VendorTypeSection({ vendor }: { vendor: Vendor }) {
  switch (vendor.type) {
    case 'electric':
      return <ElectricSection data={vendor.typeSpecificData as ElectricVendorData} />;
    case 'gas':
      return <GasSection data={vendor.typeSpecificData as GasVendorData} />;
    case 'internet':
      return <InternetSection data={vendor.typeSpecificData as InternetVendorData} />;
    case 'oil_propane':
      return <OilPropaneSection data={vendor.typeSpecificData as OilPropaneVendorData} />;
    case 'landscaping':
      return <LandscapingSection data={vendor.typeSpecificData as LandscapingVendorData} />;
    case 'cleaning':
      return <CleaningSection data={vendor.typeSpecificData as CleaningVendorData} />;
    case 'hvac':
      return <HVACSection data={vendor.typeSpecificData as HVACVendorData} />;
    case 'insurance':
      return <InsuranceSection data={vendor.typeSpecificData as InsuranceVendorData} />;
    case 'mortgage':
      return <MortgageSection data={vendor.typeSpecificData as MortgageVendorData} />;
    default:
      return null;
  }
}
```

---

## PART B: PROPERTY & ZONES - ADD SYSTEMS

### Problem
No way to add new systems on the Systems page.

### Location
```
apps/mobile/app/(tabs)/maintenance/index.tsx (Systems tab)
```

### Implementation

Add header with "Add System" button:

```typescript
{activeTab === 'systems' && (
  <View style={styles.systemsContainer}>
    {/* Header with Add button */}
    <View style={styles.systemsHeader}>
      <View>
        <Text style={styles.sectionTitle}>Home Systems</Text>
        <Text style={styles.sectionSubtitle}>
          Tap a system to view and manage maintenance tasks
        </Text>
      </View>
      <TouchableOpacity 
        style={styles.addSystemButton}
        onPress={() => setShowAddSystemModal(true)}
      >
        <Ionicons name="add" size={18} color="#c4a574" />
        <Text style={styles.addSystemText}>Add</Text>
      </TouchableOpacity>
    </View>

    {/* Systems list */}
    <ScrollView>
      {systems.map(system => (
        <SystemCard key={system.id} system={system} />
      ))}
      
      {systems.length === 0 && (
        <EmptyState
          icon="cog-outline"
          title="No Systems Yet"
          description="Track your home's major systems and their maintenance schedules"
          actionLabel="Add First System"
          onAction={() => setShowAddSystemModal(true)}
        />
      )}
    </ScrollView>

    {/* Add System Modal */}
    <AddSystemModal
      visible={showAddSystemModal}
      onClose={() => setShowAddSystemModal(false)}
      zones={zones}  // Systems must be associated with a zone
      onAdd={handleAddSystem}
    />
  </View>
)}
```

---

## PART C: PROPERTY & ZONES - ADD UTILITIES

### Problem
No way to add utilities on Property & Zones page.

### Location
```
apps/mobile/app/(tabs)/home/index.tsx
```

### Implementation

Add utility section with add button:

```typescript
{/* Utilities Section */}
<View style={styles.section}>
  <View style={styles.sectionHeader}>
    <View>
      <Text style={styles.sectionTitle}>Utilities</Text>
      <Text style={styles.sectionSubtitle}>Your service providers</Text>
    </View>
    <TouchableOpacity 
      style={styles.addButton}
      onPress={() => setShowAddUtilityModal(true)}
    >
      <Text style={styles.addButtonText}>+ Add</Text>
    </TouchableOpacity>
  </View>

  {utilities.length > 0 ? (
    <View style={styles.utilitiesGrid}>
      {utilities.map(utility => (
        <TouchableOpacity 
          key={utility.id} 
          style={styles.utilityCard}
          onPress={() => navigateToVendor(utility.vendorId)}
        >
          <Ionicons name={getUtilityIcon(utility.type)} size={24} color="#c4a574" />
          <Text style={styles.utilityName}>{utility.providerName}</Text>
          <Text style={styles.utilityType}>{formatUtilityType(utility.type)}</Text>
        </TouchableOpacity>
      ))}
    </View>
  ) : (
    <TouchableOpacity 
      style={styles.emptyUtilityCard}
      onPress={() => setShowAddUtilityModal(true)}
    >
      <Ionicons name="flash-outline" size={32} color="#c4a574" />
      <Text style={styles.emptyUtilityText}>Add your utility providers</Text>
      <Text style={styles.emptyUtilitySubtext}>Electric, gas, water, internet...</Text>
    </TouchableOpacity>
  )}
</View>

{/* Add Utility Modal */}
<AddUtilityModal
  visible={showAddUtilityModal}
  onClose={() => setShowAddUtilityModal(false)}
  onAdd={handleAddUtility}
/>
```

### Add Utility Modal

```typescript
const UTILITY_TYPES = [
  { id: 'electric', name: 'Electric', icon: 'flash-outline' },
  { id: 'gas', name: 'Gas', icon: 'flame-outline' },
  { id: 'water', name: 'Water', icon: 'water-outline' },
  { id: 'sewer', name: 'Sewer', icon: 'water-outline' },
  { id: 'trash', name: 'Trash/Recycling', icon: 'trash-outline' },
  { id: 'internet', name: 'Internet', icon: 'wifi-outline' },
  { id: 'cable', name: 'Cable/TV', icon: 'tv-outline' },
  { id: 'phone', name: 'Phone', icon: 'call-outline' },
  { id: 'oil', name: 'Heating Oil', icon: 'flame-outline' },
  { id: 'propane', name: 'Propane', icon: 'flame-outline' },
  { id: 'solar', name: 'Solar', icon: 'sunny-outline' },
];

// Modal with:
// 1. Utility type selection (grid)
// 2. Provider name input
// 3. Account number input (optional)
// 4. Phone number input (optional)
// 5. Option to link to existing vendor or create new
```

---

## PART D: ZONE DETAIL - SUGGESTED ITEMS

### Problem
Zone detail (Kitchen) doesn't suggest common appliances/systems.

### Location
```
apps/mobile/app/(tabs)/home/zone/[id].tsx
```

### Implementation

Add suggestions based on zone type:

```typescript
const ZONE_SUGGESTIONS: Record<string, { appliances: string[]; systems: string[] }> = {
  kitchen: {
    appliances: ['Refrigerator', 'Dishwasher', 'Oven/Range', 'Microwave', 'Garbage Disposal', 'Range Hood'],
    systems: ['Exhaust Fan', 'Under-sink Plumbing', 'Gas Line'],
  },
  bathroom: {
    appliances: ['Toilet', 'Shower/Tub', 'Vanity', 'Exhaust Fan'],
    systems: ['Plumbing', 'Water Heater'],
  },
  laundry: {
    appliances: ['Washer', 'Dryer', 'Utility Sink'],
    systems: ['Dryer Vent', 'Water Lines', 'Gas Line'],
  },
  garage: {
    appliances: ['Garage Door Opener', 'Chest Freezer', 'Workbench'],
    systems: ['Garage Door', 'Electrical Panel'],
  },
  basement: {
    appliances: ['Sump Pump', 'Dehumidifier'],
    systems: ['Water Heater', 'Furnace', 'Electrical Panel', 'Water Main'],
  },
  living_room: {
    appliances: ['TV', 'Fireplace', 'Ceiling Fan'],
    systems: ['HVAC Vents', 'Fireplace Flue'],
  },
  bedroom: {
    appliances: ['Ceiling Fan', 'TV'],
    systems: ['HVAC Vents'],
  },
  office: {
    appliances: ['Printer', 'Router/Modem'],
    systems: ['Ethernet Wiring'],
  },
  outdoor: {
    appliances: ['Grill', 'Fire Pit', 'Outdoor TV'],
    systems: ['Irrigation', 'Outdoor Lighting', 'Pool Equipment'],
  },
};

// In zone detail screen, show suggestions when empty:
{zone.items.length === 0 && (
  <Card style={styles.suggestionsCard}>
    <Text style={styles.suggestionsTitle}>
      Common items in a {zone.name.toLowerCase()}
    </Text>
    <Text style={styles.suggestionsSubtitle}>
      Tap to quickly add to your inventory
    </Text>
    
    <View style={styles.suggestionChips}>
      {ZONE_SUGGESTIONS[zone.type.toLowerCase()]?.appliances.map(item => (
        <TouchableOpacity
          key={item}
          style={styles.suggestionChip}
          onPress={() => quickAddItem(item, 'appliance')}
        >
          <Ionicons name="add-circle-outline" size={14} color="#c4a574" />
          <Text style={styles.suggestionChipText}>{item}</Text>
        </TouchableOpacity>
      ))}
    </View>
  </Card>
)}
```

---

## VERIFICATION CHECKLIST

### Vendor Detail
- [ ] Shows vendor-type-specific section (rates, plan details)
- [ ] Has account information section
- [ ] Has point of contact with name, title, direct contact
- [ ] Shows billing frequency and average
- [ ] Shows recent payments
- [ ] Shows contracts with expiration/renewal alerts
- [ ] Shows service visit history
- [ ] "Ask Alfred to check rates" button for utilities
- [ ] All sections are editable

### Systems Page
- [ ] Has "Add" button in header
- [ ] Add System modal with type selection
- [ ] Requires zone selection for new system
- [ ] Empty state prompts to add first system

### Property & Zones - Utilities
- [ ] Has "Add" link next to Utilities header
- [ ] Shows utility cards if utilities exist
- [ ] Empty state prompts to add utilities
- [ ] Links to vendor detail when tapped

### Zone Detail
- [ ] Has header with back button
- [ ] Shows suggested items when empty
- [ ] Suggestions are zone-type-specific
- [ ] Can tap suggestion to quick-add

---

## TEST

```bash
cd /Users/tomburke/Projects/Housing-Manager/apps/mobile
npx expo start --clear
```

1. Alfred → Vendors → Tap Eversource → Verify all new sections
2. Tasks → Systems tab → Verify "Add" button works
3. More → Property & Zones → Verify "Add" for utilities
4. Property & Zones → Tap Kitchen → Verify suggestions appear
