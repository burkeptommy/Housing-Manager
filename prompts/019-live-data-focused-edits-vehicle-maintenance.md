# Prompt 019: Live Data, Focused Edits, Vehicle Maintenance Intelligence

## Overview

This prompt addresses critical issues for beta launch:

1. **Remove all mock/hardcoded data** - Everything must use real API data
2. **Ensure all updates persist** - Every edit must update the production database
3. **Focused edit modals** - Actions like "Add Service History" should open focused modals, not full edit pages
4. **Vehicle maintenance intelligence** - Alfred researches make/model for maintenance intervals and recalls
5. **Pet focused edits** - Vaccination, medication, and ID actions should be focused modals
6. **Alfred-gathered data flows to home profile** - Any info Alfred learns goes into the home database

---

## Part 1: Remove Mock Data

### Wallet Screen - CRITICAL

The wallet screen (`apps/mobile/app/(tabs)/wallet/index.tsx`) uses entirely mock data:

```typescript
// REMOVE THESE - They are hardcoded mock data
const mockTransactions: Transaction[] = [...]
const mockBankAccount: ClientBankAccount = {...}
const mockStatements: MonthlyInvoiceListItem[] = [...]
```

**Fix:**

```typescript
// Replace with API calls

const fetchWalletData = useCallback(async () => {
  if (!householdInfo?.id) {
    setIsLoading(false);
    return;
  }

  try {
    const token = await getIdToken(true);
    if (!token) {
      setIsLoading(false);
      return;
    }

    // Fetch transactions
    const transactionsRes = await fetch(
      `${API_BASE_URL}/settlement/transactions?householdId=${householdInfo.id}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    if (transactionsRes.ok) {
      const data = await transactionsRes.json();
      setTransactions(data);
    }

    // Fetch bank accounts
    const bankRes = await fetch(
      `${API_BASE_URL}/settlement/bank-accounts?householdId=${householdInfo.id}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    if (bankRes.ok) {
      const accounts = await bankRes.json();
      setBankAccount(accounts[0] || null); // Primary account
    }

    // Fetch statements/invoices
    const statementsRes = await fetch(
      `${API_BASE_URL}/settlement/invoices?householdId=${householdInfo.id}`,
      { headers: { Authorization: `Bearer ${token}` } }
    );
    if (statementsRes.ok) {
      const data = await statementsRes.json();
      setStatements(data);
    }
  } catch (err) {
    console.error('Wallet fetch error:', err);
  } finally {
    setIsLoading(false);
  }
}, [householdInfo?.id]);
```

### Audit All Screens for Mock Data

Search and replace any remaining mock data across:
- `apps/mobile/app/(tabs)/billing.tsx`
- `apps/mobile/app/(tabs)/activity.tsx`
- Any screen that shows transactions, bills, or statements

---

## Part 2: Ensure All Updates Persist to Database

Every form, modal, and edit action MUST:
1. Call the appropriate PATCH/POST API endpoint
2. Wait for success response
3. Refresh the data from the server
4. Show error feedback if it fails

### Pattern for All Edit Actions

```typescript
const handleSave = async (data: UpdateData) => {
  setIsSaving(true);
  try {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/resource/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(data),
      }
    );

    if (!response.ok) {
      const error = await response.json().catch(() => ({}));
      throw new Error(error.message || 'Failed to save');
    }

    // Refresh data from server to ensure we have latest
    await fetchData();
    
    // Close modal and show success
    setModalVisible(false);
    Alert.alert('Saved', 'Your changes have been saved.');
  } catch (err) {
    Alert.alert('Error', err instanceof Error ? err.message : 'Failed to save. Please try again.');
  } finally {
    setIsSaving(false);
  }
};
```

### Verify These Screens Update the Database

- [ ] Family member edits
- [ ] Pet edits
- [ ] Vehicle edits
- [ ] Home system edits
- [ ] Maintenance task completion
- [ ] Zone/asset edits
- [ ] Profile edits
- [ ] Vendor edits/additions
- [ ] Bill edits

---

## Part 3: Vehicle - Focused Edit Modals

### Problem

Current: "Add Service History" navigates to full edit page
```typescript
onAction={() => router.push(`/(tabs)/family/vehicle/edit/${id}` as any)}
```

Expected: Should open a focused modal for adding a service record

### Fix: Create AddServiceHistoryModal

Create: `apps/mobile/src/components/forms/AddServiceHistoryModal.tsx`

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as DocumentPicker from 'expo-document-picker';
import { Button } from '../ui/Button';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';

interface AddServiceHistoryModalProps {
  visible: boolean;
  onClose: () => void;
  vehicleId: string;
  householdId: string;
  onSuccess: () => void;
}

const SERVICE_TYPES = [
  { id: 'oil_change', label: 'Oil Change', icon: 'water-outline' },
  { id: 'tire_rotation', label: 'Tire Rotation', icon: 'ellipse-outline' },
  { id: 'tire_replacement', label: 'Tire Replacement', icon: 'ellipse' },
  { id: 'inspection', label: 'Inspection', icon: 'clipboard-outline' },
  { id: 'brake_service', label: 'Brake Service', icon: 'disc-outline' },
  { id: 'transmission', label: 'Transmission', icon: 'cog-outline' },
  { id: 'battery', label: 'Battery', icon: 'battery-charging-outline' },
  { id: 'repair', label: 'Repair', icon: 'build-outline' },
  { id: 'other', label: 'Other', icon: 'construct-outline' },
];

export function AddServiceHistoryModal({
  visible,
  onClose,
  vehicleId,
  householdId,
  onSuccess,
}: AddServiceHistoryModalProps) {
  const [serviceType, setServiceType] = useState('oil_change');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [mileage, setMileage] = useState('');
  const [cost, setCost] = useState('');
  const [vendor, setVendor] = useState('');
  const [description, setDescription] = useState('');
  const [notes, setNotes] = useState('');
  const [documents, setDocuments] = useState<{ uri: string; name: string }[]>([]);
  const [isSaving, setIsSaving] = useState(false);

  const handlePickDocument = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: ['application/pdf', 'image/*'],
        copyToCacheDirectory: true,
      });

      if (result.canceled) return;

      setDocuments(prev => [...prev, {
        uri: result.assets[0].uri,
        name: result.assets[0].name,
      }]);
    } catch (err) {
      Alert.alert('Error', 'Failed to pick document');
    }
  };

  const handleSave = async () => {
    if (!date) {
      Alert.alert('Required', 'Service date is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Authentication expired');

      // First, create the service record
      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdId}/vehicle/${vehicleId}/service`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            type: serviceType,
            date,
            mileage: mileage ? parseInt(mileage, 10) : null,
            cost: cost ? parseFloat(cost) : null,
            vendor: vendor || null,
            description: description || SERVICE_TYPES.find(t => t.id === serviceType)?.label,
            notes: notes || null,
          }),
        }
      );

      if (!response.ok) throw new Error('Failed to save service record');

      const serviceRecord = await response.json();

      // Upload documents if any
      for (const doc of documents) {
        const formData = new FormData();
        formData.append('file', {
          uri: doc.uri,
          name: doc.name,
          type: doc.name.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
        } as any);
        formData.append('category', 'SERVICE_RECORD');
        formData.append('vehicleId', vehicleId);
        formData.append('serviceRecordId', serviceRecord.id);

        await fetch(`${API_BASE_URL}/vault/upload`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
          },
          body: formData,
        });
      }

      onSuccess();
      onClose();
      
      // Reset form
      setServiceType('oil_change');
      setDate(new Date().toISOString().split('T')[0]);
      setMileage('');
      setCost('');
      setVendor('');
      setDescription('');
      setNotes('');
      setDocuments([]);
    } catch (err) {
      Alert.alert('Error', 'Failed to save service record');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboard}
        >
          {/* Header */}
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Service Record</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content}>
            {/* Service Type */}
            <Text style={styles.label}>Service Type</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.typeScroll}>
              {SERVICE_TYPES.map(type => (
                <TouchableOpacity
                  key={type.id}
                  style={[styles.typeChip, serviceType === type.id && styles.typeChipActive]}
                  onPress={() => setServiceType(type.id)}
                >
                  <Ionicons
                    name={type.icon as any}
                    size={16}
                    color={serviceType === type.id ? colors.white : colors.text.secondary}
                  />
                  <Text style={[styles.typeChipText, serviceType === type.id && styles.typeChipTextActive]}>
                    {type.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            {/* Date */}
            <Text style={styles.label}>Service Date</Text>
            <TextInput
              style={styles.input}
              value={date}
              onChangeText={setDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Mileage */}
            <Text style={styles.label}>Mileage (optional)</Text>
            <TextInput
              style={styles.input}
              value={mileage}
              onChangeText={setMileage}
              placeholder="e.g., 45000"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="numeric"
            />

            {/* Cost */}
            <Text style={styles.label}>Cost (optional)</Text>
            <TextInput
              style={styles.input}
              value={cost}
              onChangeText={setCost}
              placeholder="e.g., 75.00"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="decimal-pad"
            />

            {/* Vendor */}
            <Text style={styles.label}>Service Provider (optional)</Text>
            <TextInput
              style={styles.input}
              value={vendor}
              onChangeText={setVendor}
              placeholder="e.g., Joe's Auto Shop"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Description */}
            <Text style={styles.label}>Description (optional)</Text>
            <TextInput
              style={styles.input}
              value={description}
              onChangeText={setDescription}
              placeholder="Details about the service..."
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Notes */}
            <Text style={styles.label}>Notes (optional)</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Any additional notes..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={3}
            />

            {/* Documents */}
            <Text style={styles.label}>Receipts & Documents</Text>
            <TouchableOpacity style={styles.uploadButton} onPress={handlePickDocument}>
              <Ionicons name="cloud-upload-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.uploadButtonText}>Upload Receipt or Invoice</Text>
            </TouchableOpacity>
            {documents.map((doc, index) => (
              <View key={index} style={styles.documentRow}>
                <Ionicons name="document-outline" size={18} color={colors.text.secondary} />
                <Text style={styles.documentName} numberOfLines={1}>{doc.name}</Text>
                <TouchableOpacity onPress={() => setDocuments(prev => prev.filter((_, i) => i !== index))}>
                  <Ionicons name="close-circle" size={20} color={colors.text.tertiary} />
                </TouchableOpacity>
              </View>
            ))}
          </ScrollView>

          {/* Footer */}
          <View style={styles.footer}>
            <Button
              title="Cancel"
              variant="outline"
              onPress={onClose}
              style={styles.cancelButton}
            />
            <Button
              title={isSaving ? 'Saving...' : 'Save Record'}
              onPress={handleSave}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

const styles = StyleSheet.create({
  // ... styles
});
```

### Update Vehicle Detail Screen

In `apps/mobile/app/(tabs)/family/vehicle/[id].tsx`:

```typescript
// Add import
import { AddServiceHistoryModal } from '../../../../src/components/forms/AddServiceHistoryModal';

// Add state
const [showAddServiceModal, setShowAddServiceModal] = useState(false);

// Update the Service History section action
<SectionHeader
  title="SERVICE HISTORY"
  action="+ Add"
  onAction={() => setShowAddServiceModal(true)}  // Changed from router.push
/>

// Add modal at bottom
<AddServiceHistoryModal
  visible={showAddServiceModal}
  onClose={() => setShowAddServiceModal(false)}
  vehicleId={id}
  householdId={householdInfo?.id || ''}
  onSuccess={fetchVehicle}
/>
```

---

## Part 4: Vehicle Maintenance Intelligence with Alfred

### Problem

Vehicle maintenance due section doesn't use:
- Current mileage to calculate when service is due
- Make/model specific maintenance intervals from manufacturer
- Recall information for that make/model/year

### Solution: VehicleMaintenanceResearchService

Create: `apps/api/src/vehicles/vehicle-maintenance-research.service.ts`

```typescript
import { Injectable } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';

interface VehicleMaintenanceSchedule {
  maintenanceItems: MaintenanceItem[];
  recalls: RecallInfo[];
  tips: string[];
}

interface MaintenanceItem {
  type: string;
  description: string;
  intervalMiles: number;
  intervalMonths?: number;
  estimatedCost: { low: number; high: number };
  diyDifficulty: 'EASY' | 'MODERATE' | 'PROFESSIONAL_REQUIRED';
  priority: 'CRITICAL' | 'IMPORTANT' | 'RECOMMENDED';
  warningSignsToWatch: string[];
}

interface RecallInfo {
  campaignNumber: string;
  component: string;
  summary: string;
  consequence: string;
  remedy: string;
  dateIssued: string;
}

@Injectable()
export class VehicleMaintenanceResearchService {
  private anthropic = new Anthropic();

  async researchVehicleMaintenance(
    year: number,
    make: string,
    model: string,
    currentMileage?: number,
  ): Promise<VehicleMaintenanceSchedule> {
    const systemPrompt = `You are an expert automotive technician with deep knowledge of vehicle maintenance schedules, manufacturer recommendations, and common issues for all vehicle makes and models.

For the given vehicle, provide:
1. Complete manufacturer-recommended maintenance schedule with mileage intervals
2. Estimated costs (low and high range)
3. Whether it's DIY-friendly or needs a professional
4. Warning signs to watch for
5. Any known recalls in the last 5 years
6. Tips specific to this vehicle

Always base recommendations on manufacturer guidelines, not generic advice.`;

    const userPrompt = `Research the complete maintenance schedule for a ${year} ${make} ${model}.
${currentMileage ? `Current mileage: ${currentMileage.toLocaleString()} miles` : ''}

Provide a comprehensive maintenance schedule in JSON format:
{
  "maintenanceItems": [
    {
      "type": "Oil Change",
      "description": "Full synthetic oil change with filter",
      "intervalMiles": 7500,
      "intervalMonths": 6,
      "estimatedCost": { "low": 50, "high": 90 },
      "diyDifficulty": "EASY",
      "priority": "CRITICAL",
      "warningSignsToWatch": ["Oil light on dashboard", "Engine knocking", "Dark or gritty oil"]
    }
  ],
  "recalls": [
    {
      "campaignNumber": "21V-123",
      "component": "Airbag",
      "summary": "...",
      "consequence": "...",
      "remedy": "...",
      "dateIssued": "2021-03-15"
    }
  ],
  "tips": [
    "This model is known for...",
    "Consider checking..."
  ]
}

Include ALL standard maintenance items: oil, filters (oil, air, cabin, fuel), tires (rotation, alignment, replacement), brakes, transmission fluid, coolant, spark plugs, battery, timing belt/chain, suspension, etc.

For recalls, only include actual recalls issued by NHTSA in the last 5 years. If you're not certain of specific recall details, omit the recalls array.`;

    const response = await this.anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 4000,
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
    });

    const content = response.content[0];
    if (content.type !== 'text') {
      throw new Error('Unexpected response type');
    }

    // Parse JSON from response
    const jsonMatch = content.text.match(/\{[\s\S]*\}/);
    if (!jsonMatch) {
      throw new Error('Failed to parse maintenance schedule');
    }

    return JSON.parse(jsonMatch[0]);
  }

  calculateNextServiceDue(
    maintenanceItem: MaintenanceItem,
    currentMileage: number,
    lastServiceMileage?: number,
    lastServiceDate?: Date,
  ): { dueMileage: number; dueDate?: Date; status: 'ok' | 'due_soon' | 'overdue' } {
    // Calculate next due mileage
    const baseMileage = lastServiceMileage || 0;
    const nextDueMileage = baseMileage + maintenanceItem.intervalMiles;

    // Calculate next due date if we have interval months
    let nextDueDate: Date | undefined;
    if (maintenanceItem.intervalMonths && lastServiceDate) {
      nextDueDate = new Date(lastServiceDate);
      nextDueDate.setMonth(nextDueDate.getMonth() + maintenanceItem.intervalMonths);
    }

    // Determine status
    const milesUntilDue = nextDueMileage - currentMileage;
    const daysUntilDue = nextDueDate 
      ? Math.ceil((nextDueDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24))
      : null;

    let status: 'ok' | 'due_soon' | 'overdue' = 'ok';
    
    if (milesUntilDue < 0 || (daysUntilDue !== null && daysUntilDue < 0)) {
      status = 'overdue';
    } else if (milesUntilDue < 1000 || (daysUntilDue !== null && daysUntilDue < 30)) {
      status = 'due_soon';
    }

    return {
      dueMileage: nextDueMileage,
      dueDate: nextDueDate,
      status,
    };
  }
}
```

### Create Vehicle Maintenance Endpoint

Create: `apps/api/src/vehicles/vehicle-maintenance.controller.ts`

```typescript
@Controller('vehicles')
export class VehicleMaintenanceController {
  constructor(
    private readonly researchService: VehicleMaintenanceResearchService,
    private readonly prisma: PrismaService,
  ) {}

  @Post(':id/research-maintenance')
  async researchMaintenance(
    @Param('id') vehicleId: string,
    @CurrentUser() user: User,
  ) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: { household: true },
    });

    if (!vehicle) throw new NotFoundException('Vehicle not found');

    // Research maintenance schedule
    const schedule = await this.researchService.researchVehicleMaintenance(
      vehicle.year,
      vehicle.make,
      vehicle.model,
      vehicle.currentMileage || undefined,
    );

    // Save research to vehicle
    await this.prisma.vehicle.update({
      where: { id: vehicleId },
      data: {
        maintenanceResearch: schedule as any,
        maintenanceResearchedAt: new Date(),
      },
    });

    return schedule;
  }

  @Get(':id/maintenance-due')
  async getMaintenanceDue(
    @Param('id') vehicleId: string,
    @CurrentUser() user: User,
  ) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: { serviceHistory: true },
    });

    if (!vehicle) throw new NotFoundException('Vehicle not found');

    const research = vehicle.maintenanceResearch as VehicleMaintenanceSchedule | null;
    if (!research) {
      return { needsResearch: true, items: [] };
    }

    const currentMileage = vehicle.currentMileage || 0;

    // Calculate status for each maintenance item
    const items = research.maintenanceItems.map(item => {
      // Find last service of this type
      const lastService = vehicle.serviceHistory
        ?.filter(s => s.type === item.type.toLowerCase().replace(' ', '_'))
        .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())[0];

      const status = this.researchService.calculateNextServiceDue(
        item,
        currentMileage,
        lastService?.mileage || undefined,
        lastService?.date ? new Date(lastService.date) : undefined,
      );

      return {
        ...item,
        lastServiceDate: lastService?.date,
        lastServiceMileage: lastService?.mileage,
        ...status,
      };
    });

    // Sort by priority and status
    items.sort((a, b) => {
      const statusOrder = { overdue: 0, due_soon: 1, ok: 2 };
      const priorityOrder = { CRITICAL: 0, IMPORTANT: 1, RECOMMENDED: 2 };
      
      if (statusOrder[a.status] !== statusOrder[b.status]) {
        return statusOrder[a.status] - statusOrder[b.status];
      }
      return priorityOrder[a.priority] - priorityOrder[b.priority];
    });

    return {
      needsResearch: false,
      currentMileage,
      items,
      recalls: research.recalls || [],
      tips: research.tips || [],
    };
  }
}
```

### Update Vehicle Detail Screen - Maintenance Section

```typescript
// In vehicle/[id].tsx

const [maintenanceDue, setMaintenanceDue] = useState<MaintenanceDueResponse | null>(null);
const [isResearching, setIsResearching] = useState(false);

const fetchMaintenanceDue = useCallback(async () => {
  if (!id || !householdInfo?.id) return;

  try {
    const token = await getIdToken(true);
    const response = await fetch(
      `${API_BASE_URL}/vehicles/${id}/maintenance-due`,
      { headers: { Authorization: `Bearer ${token}` } }
    );

    if (response.ok) {
      const data = await response.json();
      setMaintenanceDue(data);
    }
  } catch (err) {
    console.error('Fetch maintenance due error:', err);
  }
}, [id, householdInfo?.id]);

const handleResearchMaintenance = async () => {
  setIsResearching(true);
  try {
    const token = await getIdToken(true);
    await fetch(
      `${API_BASE_URL}/vehicles/${id}/research-maintenance`,
      {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      }
    );
    await fetchMaintenanceDue();
    Alert.alert('Success', 'Maintenance schedule has been researched for your vehicle.');
  } catch (err) {
    Alert.alert('Error', 'Failed to research maintenance schedule');
  } finally {
    setIsResearching(false);
  }
};

// In the Maintenance Due section:
<Card style={styles.section}>
  <SectionHeader
    title="MAINTENANCE DUE"
    action={maintenanceDue?.needsResearch ? 'Research' : 'Refresh'}
    onAction={handleResearchMaintenance}
  />
  
  {isResearching ? (
    <View style={styles.loadingContainer}>
      <ActivityIndicator size="small" color={colors.haven.champagne[500]} />
      <Text style={styles.loadingText}>Researching maintenance schedule...</Text>
    </View>
  ) : maintenanceDue?.needsResearch ? (
    <TouchableOpacity style={styles.researchPrompt} onPress={handleResearchMaintenance}>
      <Ionicons name="sparkles" size={24} color={colors.haven.champagne[500]} />
      <View style={styles.researchContent}>
        <Text style={styles.researchTitle}>Get Personalized Maintenance Schedule</Text>
        <Text style={styles.researchSubtitle}>
          Alfred will research manufacturer recommendations for your {vehicle?.year} {vehicle?.make} {vehicle?.model}
        </Text>
      </View>
    </TouchableOpacity>
  ) : maintenanceDue?.items.length > 0 ? (
    <>
      {/* Current Mileage Input */}
      <View style={styles.mileageRow}>
        <Text style={styles.mileageLabel}>Current Mileage</Text>
        <TouchableOpacity
          style={styles.mileageValue}
          onPress={() => setShowMileageModal(true)}
        >
          <Text style={styles.mileageText}>
            {vehicle?.status?.currentMileage?.toLocaleString() || 'Not set'}
          </Text>
          <Ionicons name="pencil" size={16} color={colors.haven.champagne[500]} />
        </TouchableOpacity>
      </View>

      {/* Maintenance Items */}
      {maintenanceDue.items.map((item, index) => (
        <MaintenanceItemRow
          key={index}
          item={item}
          onPress={() => {/* Show detail modal */}}
        />
      ))}

      {/* Recalls Section */}
      {maintenanceDue.recalls?.length > 0 && (
        <>
          <View style={styles.recallsHeader}>
            <Ionicons name="warning" size={20} color={colors.status.error} />
            <Text style={styles.recallsTitle}>
              {maintenanceDue.recalls.length} Recall{maintenanceDue.recalls.length > 1 ? 's' : ''}
            </Text>
          </View>
          {maintenanceDue.recalls.map((recall, index) => (
            <View key={index} style={styles.recallRow}>
              <Text style={styles.recallComponent}>{recall.component}</Text>
              <Text style={styles.recallSummary}>{recall.summary}</Text>
              <Text style={styles.recallRemedy}>{recall.remedy}</Text>
            </View>
          ))}
        </>
      )}
    </>
  ) : (
    <Text style={styles.noMaintenanceText}>No maintenance items tracked yet.</Text>
  )}
</Card>
```

---

## Part 5: Pet - Focused Edit Modals

### Problem

"Add Vaccination Records", "Add Medication", "Add IDs & Registration" all navigate to full edit page instead of focused modals.

### Create Focused Modals

Create these modal components:

1. `AddVaccinationModal.tsx`
2. `AddMedicationModal.tsx`
3. `AddPetIdModal.tsx`

Example - `apps/mobile/src/components/forms/AddVaccinationModal.tsx`:

```typescript
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  Modal,
  TouchableOpacity,
  TextInput,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
  Alert,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { Ionicons } from '@expo/vector-icons';
import * as DocumentPicker from 'expo-document-picker';
import { Button } from '../ui/Button';
import { colors, typography, spacing, borderRadius } from '../../lib/theme';
import { API_BASE_URL } from '../../lib/api';
import { getIdToken } from '../../lib/firebase';

interface AddVaccinationModalProps {
  visible: boolean;
  onClose: () => void;
  petId: string;
  householdId: string;
  onSuccess: () => void;
}

const COMMON_VACCINES = {
  dog: ['Rabies', 'DHPP (Distemper)', 'Bordetella', 'Lyme', 'Leptospirosis', 'Canine Influenza'],
  cat: ['Rabies', 'FVRCP', 'FeLV', 'FIV'],
  default: ['Rabies'],
};

export function AddVaccinationModal({
  visible,
  onClose,
  petId,
  householdId,
  petType = 'dog',
  onSuccess,
}: AddVaccinationModalProps & { petType?: string }) {
  const [vaccineName, setVaccineName] = useState('');
  const [customName, setCustomName] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [expiresAt, setExpiresAt] = useState('');
  const [veterinarian, setVeterinarian] = useState('');
  const [notes, setNotes] = useState('');
  const [documentUri, setDocumentUri] = useState<string | null>(null);
  const [documentName, setDocumentName] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const vaccines = COMMON_VACCINES[petType as keyof typeof COMMON_VACCINES] || COMMON_VACCINES.default;

  const handlePickDocument = async () => {
    try {
      const result = await DocumentPicker.getDocumentAsync({
        type: ['application/pdf', 'image/*'],
        copyToCacheDirectory: true,
      });

      if (result.canceled) return;

      setDocumentUri(result.assets[0].uri);
      setDocumentName(result.assets[0].name);
    } catch (err) {
      Alert.alert('Error', 'Failed to pick document');
    }
  };

  const handleSave = async () => {
    const name = vaccineName === 'other' ? customName : vaccineName;
    if (!name) {
      Alert.alert('Required', 'Vaccination name is required');
      return;
    }
    if (!date) {
      Alert.alert('Required', 'Vaccination date is required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Authentication expired');

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdId}/pet/${petId}/vaccination`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name,
            date,
            expiresAt: expiresAt || null,
            veterinarian: veterinarian || null,
            notes: notes || null,
          }),
        }
      );

      if (!response.ok) throw new Error('Failed to save');

      const vaccination = await response.json();

      // Upload document if provided
      if (documentUri) {
        const formData = new FormData();
        formData.append('file', {
          uri: documentUri,
          name: documentName || 'vaccination_record.pdf',
          type: documentName?.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
        } as any);
        formData.append('category', 'VACCINATION_RECORD');
        formData.append('petId', petId);
        formData.append('vaccinationId', vaccination.id);

        await fetch(`${API_BASE_URL}/vault/upload`, {
          method: 'POST',
          headers: { Authorization: `Bearer ${token}` },
          body: formData,
        });
      }

      onSuccess();
      onClose();
      
      // Reset form
      setVaccineName('');
      setCustomName('');
      setDate(new Date().toISOString().split('T')[0]);
      setExpiresAt('');
      setVeterinarian('');
      setNotes('');
      setDocumentUri(null);
      setDocumentName(null);
    } catch (err) {
      Alert.alert('Error', 'Failed to save vaccination record');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <SafeAreaView style={styles.container} edges={['top']}>
        <KeyboardAvoidingView
          behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
          style={styles.keyboard}
        >
          <View style={styles.header}>
            <TouchableOpacity onPress={onClose} style={styles.closeButton}>
              <Ionicons name="close" size={24} color={colors.text.primary} />
            </TouchableOpacity>
            <Text style={styles.title}>Add Vaccination</Text>
            <View style={styles.placeholder} />
          </View>

          <ScrollView style={styles.content}>
            {/* Vaccine Selection */}
            <Text style={styles.label}>Vaccination</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.vaccineScroll}>
              {vaccines.map(vaccine => (
                <TouchableOpacity
                  key={vaccine}
                  style={[styles.vaccineChip, vaccineName === vaccine && styles.vaccineChipActive]}
                  onPress={() => setVaccineName(vaccine)}
                >
                  <Text style={[styles.vaccineChipText, vaccineName === vaccine && styles.vaccineChipTextActive]}>
                    {vaccine}
                  </Text>
                </TouchableOpacity>
              ))}
              <TouchableOpacity
                style={[styles.vaccineChip, vaccineName === 'other' && styles.vaccineChipActive]}
                onPress={() => setVaccineName('other')}
              >
                <Text style={[styles.vaccineChipText, vaccineName === 'other' && styles.vaccineChipTextActive]}>
                  Other
                </Text>
              </TouchableOpacity>
            </ScrollView>

            {vaccineName === 'other' && (
              <TextInput
                style={styles.input}
                value={customName}
                onChangeText={setCustomName}
                placeholder="Enter vaccination name"
                placeholderTextColor={colors.text.tertiary}
              />
            )}

            {/* Date */}
            <Text style={styles.label}>Date Given</Text>
            <TextInput
              style={styles.input}
              value={date}
              onChangeText={setDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Expires */}
            <Text style={styles.label}>Expires (optional)</Text>
            <TextInput
              style={styles.input}
              value={expiresAt}
              onChangeText={setExpiresAt}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Veterinarian */}
            <Text style={styles.label}>Veterinarian (optional)</Text>
            <TextInput
              style={styles.input}
              value={veterinarian}
              onChangeText={setVeterinarian}
              placeholder="Dr. Smith"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Document Upload */}
            <Text style={styles.label}>Vaccination Record Document</Text>
            <TouchableOpacity style={styles.uploadButton} onPress={handlePickDocument}>
              <Ionicons name="cloud-upload-outline" size={20} color={colors.haven.champagne[500]} />
              <Text style={styles.uploadButtonText}>
                {documentName || 'Upload Document'}
              </Text>
            </TouchableOpacity>

            {/* Notes */}
            <Text style={styles.label}>Notes (optional)</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              value={notes}
              onChangeText={setNotes}
              placeholder="Any additional notes..."
              placeholderTextColor={colors.text.tertiary}
              multiline
              numberOfLines={3}
            />
          </ScrollView>

          <View style={styles.footer}>
            <Button title="Cancel" variant="outline" onPress={onClose} style={styles.cancelButton} />
            <Button
              title={isSaving ? 'Saving...' : 'Save'}
              onPress={handleSave}
              disabled={isSaving}
              style={styles.saveButton}
            />
          </View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    </Modal>
  );
}

// Similar styles as AddServiceHistoryModal
```

### Update Pet Detail Screen

In `apps/mobile/app/(tabs)/family/pet/[id].tsx`:

```typescript
// Add imports
import { AddVaccinationModal } from '../../../../src/components/forms/AddVaccinationModal';
import { AddMedicationModal } from '../../../../src/components/forms/AddMedicationModal';
import { AddPetIdModal } from '../../../../src/components/forms/AddPetIdModal';

// Add states
const [showVaccinationModal, setShowVaccinationModal] = useState(false);
const [showMedicationModal, setShowMedicationModal] = useState(false);
const [showIdModal, setShowIdModal] = useState(false);

// Update sections to use modals:

{/* Vaccinations */}
<Card style={styles.section}>
  <SectionHeader
    title="VACCINATIONS"
    action="+ Add"
    onAction={() => setShowVaccinationModal(true)}  // Changed from router.push
  />
  {/* ... vaccination list ... */}
</Card>

{/* Medications */}
<Card style={styles.section}>
  <SectionHeader
    title="MEDICATIONS"
    action="+ Add"
    onAction={() => setShowMedicationModal(true)}  // Changed from router.push
  />
  {/* ... medication list ... */}
</Card>

{/* IDs & Registration */}
<Card style={styles.section}>
  <SectionHeader
    title="IDS & REGISTRATION"
    action="Edit"
    onAction={() => setShowIdModal(true)}  // Changed from router.push
  />
  {/* ... IDs content ... */}
</Card>

// Add modals at bottom
<AddVaccinationModal
  visible={showVaccinationModal}
  onClose={() => setShowVaccinationModal(false)}
  petId={id}
  householdId={householdInfo?.id || ''}
  petType={pet?.type}
  onSuccess={fetchPet}
/>
<AddMedicationModal
  visible={showMedicationModal}
  onClose={() => setShowMedicationModal(false)}
  petId={id}
  householdId={householdInfo?.id || ''}
  onSuccess={fetchPet}
/>
<AddPetIdModal
  visible={showIdModal}
  onClose={() => setShowIdModal(false)}
  petId={id}
  householdId={householdInfo?.id || ''}
  initialData={{
    microchipId: pet?.registration?.microchipId,
    licenseNumber: pet?.registration?.licenseNumber,
    licenseExpires: pet?.registration?.licenseExpires,
  }}
  onSuccess={fetchPet}
/>
```

---

## Part 6: Alfred-Gathered Data Flows to Home Profile

When Alfred processes emails or conversations and learns information, it should update the home profile automatically.

### Update AlfredService

In `apps/api/src/alfred/alfred.service.ts`, after Alfred extracts information:

```typescript
// After detecting a new system from an email:
if (detectedSystem) {
  await this.homeSystemService.createOrUpdate({
    householdId,
    type: detectedSystem.type,
    name: detectedSystem.name,
    brand: detectedSystem.brand,
    model: detectedSystem.model,
    serialNumber: detectedSystem.serialNumber,
    installedDate: detectedSystem.installedDate,
    source: 'alfred_email',
    sourceEmailId: emailCase.id,
  });
}

// After detecting a new vendor from an email:
if (detectedVendor) {
  await this.vendorService.createOrUpdate({
    householdId,
    displayName: detectedVendor.name,
    category: detectedVendor.category,
    phone: detectedVendor.phone,
    email: detectedVendor.email,
    source: 'alfred_email',
    sourceEmailId: emailCase.id,
  });
}

// After detecting bill/payment info:
if (detectedBill) {
  await this.billService.createOrUpdate({
    householdId,
    name: detectedBill.name,
    category: detectedBill.category,
    amount: detectedBill.amount,
    dueDate: detectedBill.dueDate,
    vendor: detectedBill.vendor,
    source: 'alfred_email',
    sourceEmailId: emailCase.id,
  });
}

// After detecting utility provider:
if (detectedUtility) {
  await this.propertyService.updateUtility(householdId, {
    type: detectedUtility.type, // electric, gas, water, etc.
    provider: detectedUtility.provider,
    accountNumber: detectedUtility.accountNumber,
    source: 'alfred_email',
  });
}
```

---

## Part 7: API Endpoints for New Features

### Vehicle Service History API

```typescript
// POST /family/household/:householdId/vehicle/:vehicleId/service
// GET /family/household/:householdId/vehicle/:vehicleId/service
// DELETE /family/household/:householdId/vehicle/:vehicleId/service/:serviceId
```

### Pet Vaccination API

```typescript
// POST /family/household/:householdId/pet/:petId/vaccination
// GET /family/household/:householdId/pet/:petId/vaccination
// DELETE /family/household/:householdId/pet/:petId/vaccination/:vaccinationId
```

### Pet Medication API

```typescript
// POST /family/household/:householdId/pet/:petId/medication
// GET /family/household/:householdId/pet/:petId/medication
// DELETE /family/household/:householdId/pet/:petId/medication/:medicationId
```

---

## Implementation Checklist

### Day 1: Mock Data & Persistence
- [ ] Remove all mock data from wallet screen
- [ ] Connect wallet to real API endpoints
- [ ] Audit all screens for mock data
- [ ] Verify all edit actions call PATCH/POST APIs
- [ ] Test data persistence round-trip

### Day 2: Vehicle Focused Edits & Maintenance
- [ ] Create AddServiceHistoryModal component
- [ ] Create vehicle service history API endpoints
- [ ] Update vehicle detail screen to use modal
- [ ] Create VehicleMaintenanceResearchService
- [ ] Create vehicle maintenance API endpoints
- [ ] Update vehicle detail maintenance section
- [ ] Add mileage input and tracking

### Day 3: Pet Focused Edits
- [ ] Create AddVaccinationModal component
- [ ] Create AddMedicationModal component
- [ ] Create AddPetIdModal component
- [ ] Create pet vaccination/medication API endpoints
- [ ] Update pet detail screen to use modals

### Day 4: Alfred Integration & Testing
- [ ] Update Alfred service to write to home profile
- [ ] Test Alfred email processing updates home data
- [ ] End-to-end testing of all flows
- [ ] Fix any remaining issues

---

## Success Criteria

- [ ] Zero mock data anywhere in the app
- [ ] All edits persist to production database
- [ ] "Add Service History" opens focused upload modal
- [ ] Vehicle maintenance shows mileage-based intervals
- [ ] Vehicle maintenance shows recalls (if any)
- [ ] Pet vaccinations/medications have focused add modals
- [ ] Alfred-learned data appears in home profile
- [ ] All data refreshes properly after updates
