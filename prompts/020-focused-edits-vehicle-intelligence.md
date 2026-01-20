# Prompt 020: Focused Edits, Vehicle Maintenance Intelligence, Live Data Persistence

## Overview

This prompt addresses critical issues for beta launch:

1. **Vehicle: Focused service history modal** - "Add Service History" should open a focused modal, not navigate to full edit page
2. **Vehicle: AI-powered maintenance intelligence** - Alfred researches make/model for intervals, recalls, and mileage-based due dates
3. **Pet: Focused edit modals** - Vaccination, medication, and ID actions should be focused modals
4. **Ensure all updates persist** - Every edit must update the production database and refresh UI
5. **Alfred-gathered data flows to home profile** - Any info Alfred learns goes into the home database

---

## Part 1: Vehicle - Add Service History Modal

### Current Problem

In `apps/mobile/app/(tabs)/family/vehicle/[id].tsx`:
```typescript
// Line ~620 - This navigates to full edit page instead of focused modal
onAction={() => router.push(`/(tabs)/family/vehicle/edit/${id}` as any)}
```

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
  { id: 'brake_service', label: 'Brake Service', icon: 'disc-outline' },
  { id: 'inspection', label: 'Inspection', icon: 'clipboard-outline' },
  { id: 'transmission', label: 'Transmission', icon: 'cog-outline' },
  { id: 'battery', label: 'Battery', icon: 'battery-charging-outline' },
  { id: 'air_filter', label: 'Air Filter', icon: 'funnel-outline' },
  { id: 'coolant', label: 'Coolant Flush', icon: 'thermometer-outline' },
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

      // Create the service record
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
          headers: { Authorization: `Bearer ${token}` },
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
      
      Alert.alert('Success', 'Service record added');
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

          <ScrollView style={styles.content} showsVerticalScrollIndicator={false}>
            {/* Service Type */}
            <Text style={styles.label}>Service Type</Text>
            <ScrollView 
              horizontal 
              showsHorizontalScrollIndicator={false} 
              style={styles.typeScroll}
              contentContainerStyle={styles.typeScrollContent}
            >
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
                  <Text style={[
                    styles.typeChipText, 
                    serviceType === type.id && styles.typeChipTextActive
                  ]}>
                    {type.label}
                  </Text>
                </TouchableOpacity>
              ))}
            </ScrollView>

            {/* Date */}
            <Text style={styles.label}>Service Date *</Text>
            <TextInput
              style={styles.input}
              value={date}
              onChangeText={setDate}
              placeholder="YYYY-MM-DD"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Mileage */}
            <Text style={styles.label}>Mileage at Service</Text>
            <TextInput
              style={styles.input}
              value={mileage}
              onChangeText={setMileage}
              placeholder="e.g., 45000"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="numeric"
            />

            {/* Cost */}
            <Text style={styles.label}>Cost</Text>
            <TextInput
              style={styles.input}
              value={cost}
              onChangeText={setCost}
              placeholder="e.g., 75.00"
              placeholderTextColor={colors.text.tertiary}
              keyboardType="decimal-pad"
            />

            {/* Vendor */}
            <Text style={styles.label}>Service Provider</Text>
            <TextInput
              style={styles.input}
              value={vendor}
              onChangeText={setVendor}
              placeholder="e.g., Joe's Auto Shop"
              placeholderTextColor={colors.text.tertiary}
            />

            {/* Description */}
            <Text style={styles.label}>Description</Text>
            <TextInput
              style={styles.input}
              value={description}
              onChangeText={setDescription}
              placeholder="Details about the service..."
              placeholderTextColor={colors.text.tertiary}
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

            {/* Notes */}
            <Text style={styles.label}>Notes</Text>
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
  container: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  keyboard: {
    flex: 1,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  closeButton: {
    padding: spacing[2],
    marginLeft: -spacing[2],
  },
  title: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  placeholder: {
    width: 40,
  },
  content: {
    flex: 1,
    padding: spacing[4],
  },
  label: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
    marginTop: spacing[4],
  },
  input: {
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  textArea: {
    minHeight: 80,
    textAlignVertical: 'top',
  },
  typeScroll: {
    marginHorizontal: -spacing[4],
  },
  typeScrollContent: {
    paddingHorizontal: spacing[4],
    gap: spacing[2],
  },
  typeChip: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    gap: spacing[1],
    marginRight: spacing[2],
  },
  typeChipActive: {
    backgroundColor: colors.haven.champagne[500],
  },
  typeChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeChipTextActive: {
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
  },
  uploadButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    borderWidth: 1,
    borderColor: colors.haven.champagne[300],
    borderStyle: 'dashed',
    borderRadius: borderRadius.lg,
    backgroundColor: colors.haven.champagne[50],
  },
  uploadButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.champagne[500],
  },
  documentRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.md,
    marginTop: spacing[2],
  },
  documentName: {
    flex: 1,
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  footer: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  cancelButton: {
    flex: 1,
  },
  saveButton: {
    flex: 1,
  },
});
```

### Update Vehicle Detail Screen

In `apps/mobile/app/(tabs)/family/vehicle/[id].tsx`:

```typescript
// Add import at top
import { AddServiceHistoryModal } from '../../../../src/components/forms/AddServiceHistoryModal';

// Add state with other modal states
const [showAddServiceModal, setShowAddServiceModal] = useState(false);

// Update Service History section (around line 620)
<SectionHeader
  title="SERVICE HISTORY"
  action="+ Add"
  onAction={() => setShowAddServiceModal(true)}  // CHANGED from router.push
/>

// Add modal at bottom with other modals
<AddServiceHistoryModal
  visible={showAddServiceModal}
  onClose={() => setShowAddServiceModal(false)}
  vehicleId={id!}
  householdId={householdInfo?.id || ''}
  onSuccess={fetchVehicle}
/>
```

### Create API Endpoint

Create: `apps/api/src/family/vehicle-service.controller.ts`

```typescript
@Controller('family/household/:householdId/vehicle/:vehicleId/service')
export class VehicleServiceController {
  constructor(private readonly prisma: PrismaService) {}

  @Post()
  async addServiceRecord(
    @Param('householdId') householdId: string,
    @Param('vehicleId') vehicleId: string,
    @Body() dto: CreateServiceRecordDto,
    @CurrentUser() user: User,
  ) {
    // Verify vehicle belongs to household
    const vehicle = await this.prisma.vehicle.findFirst({
      where: { id: vehicleId, householdId },
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');

    // Create service record
    const record = await this.prisma.vehicleServiceRecord.create({
      data: {
        vehicleId,
        type: dto.type,
        date: new Date(dto.date),
        mileage: dto.mileage,
        cost: dto.cost,
        vendor: dto.vendor,
        description: dto.description,
        notes: dto.notes,
      },
    });

    // Update vehicle's current mileage if provided and higher
    if (dto.mileage && (!vehicle.currentMileage || dto.mileage > vehicle.currentMileage)) {
      await this.prisma.vehicle.update({
        where: { id: vehicleId },
        data: { currentMileage: dto.mileage },
      });
    }

    // Create activity log
    await this.prisma.activityFeed.create({
      data: {
        householdId,
        category: 'VEHICLE',
        action: 'SERVICE_RECORDED',
        title: `Service recorded for ${vehicle.year} ${vehicle.make} ${vehicle.model}`,
        description: dto.description || dto.type,
        actorName: user.firstName || 'User',
      },
    });

    return record;
  }

  @Get()
  async getServiceHistory(
    @Param('householdId') householdId: string,
    @Param('vehicleId') vehicleId: string,
  ) {
    return this.prisma.vehicleServiceRecord.findMany({
      where: { vehicleId },
      orderBy: { date: 'desc' },
    });
  }
}
```

---

## Part 2: Vehicle Maintenance Intelligence with Alfred

### Problem

The maintenance section currently doesn't:
- Use current mileage to calculate when service is due
- Know make/model-specific maintenance intervals
- Show recalls for the vehicle

### Solution: VehicleMaintenanceResearchService

Create: `apps/api/src/vehicles/vehicle-maintenance-research.service.ts`

```typescript
import { Injectable } from '@nestjs/common';
import Anthropic from '@anthropic-ai/sdk';
import { PrismaService } from '../prisma/prisma.service';

interface MaintenanceItem {
  type: string;
  name: string;
  description: string;
  intervalMiles: number;
  intervalMonths?: number;
  estimatedCostLow: number;
  estimatedCostHigh: number;
  priority: 'CRITICAL' | 'IMPORTANT' | 'RECOMMENDED';
  diyDifficulty: 'EASY' | 'MODERATE' | 'PROFESSIONAL_REQUIRED';
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

interface VehicleMaintenanceSchedule {
  maintenanceItems: MaintenanceItem[];
  recalls: RecallInfo[];
  tips: string[];
  specificNotes: string[];
}

@Injectable()
export class VehicleMaintenanceResearchService {
  private anthropic = new Anthropic();

  constructor(private readonly prisma: PrismaService) {}

  async researchVehicleMaintenance(
    year: number,
    make: string,
    model: string,
  ): Promise<VehicleMaintenanceSchedule> {
    const systemPrompt = `You are an expert automotive technician with deep knowledge of vehicle maintenance schedules, manufacturer recommendations, and common issues for all vehicle makes and models.

For the given vehicle, provide MANUFACTURER-SPECIFIC maintenance schedules based on the actual owner's manual recommendations, not generic advice.

Include:
1. Complete maintenance schedule with mileage/time intervals
2. Estimated costs (realistic ranges for professional service)
3. DIY difficulty rating
4. Warning signs for each item
5. Known recalls from NHTSA in the last 5 years
6. Model-specific tips and common issues`;

    const userPrompt = `Research the complete maintenance schedule for a ${year} ${make} ${model}.

Provide comprehensive data in JSON format:
{
  "maintenanceItems": [
    {
      "type": "OIL_CHANGE",
      "name": "Oil Change",
      "description": "Full synthetic oil change with filter replacement",
      "intervalMiles": 7500,
      "intervalMonths": 6,
      "estimatedCostLow": 50,
      "estimatedCostHigh": 90,
      "priority": "CRITICAL",
      "diyDifficulty": "EASY",
      "warningSignsToWatch": ["Oil light on dashboard", "Engine knocking", "Dark or gritty oil on dipstick"]
    }
  ],
  "recalls": [
    {
      "campaignNumber": "21V-123",
      "component": "Airbag",
      "summary": "Passenger airbag may not deploy properly",
      "consequence": "Increased risk of injury in a crash",
      "remedy": "Dealers will replace airbag module free of charge",
      "dateIssued": "2021-03-15"
    }
  ],
  "tips": [
    "This model uses a timing chain, not a belt, so no timing belt replacement needed",
    "The ${make} ${model} is known for premature brake wear - inspect brakes frequently"
  ],
  "specificNotes": [
    "Uses 0W-20 full synthetic oil",
    "Cabin air filter is difficult to access - recommend professional service"
  ]
}

Include ALL standard maintenance items based on manufacturer recommendations:
- Oil & filter
- Air filter (engine)
- Cabin air filter
- Tire rotation
- Tire replacement
- Brake inspection
- Brake pad replacement
- Brake fluid flush
- Transmission fluid
- Coolant flush
- Spark plugs
- Battery
- Serpentine belt
- Timing belt/chain (if applicable)
- Differential fluid (if applicable)
- Transfer case fluid (if AWD)
- Wheel alignment
- Suspension inspection
- Wiper blades

For recalls, only include REAL recalls from NHTSA. If uncertain, omit the recalls array or include an empty array.`;

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

  calculateMaintenanceDue(
    item: MaintenanceItem,
    currentMileage: number,
    lastServiceMileage?: number,
    lastServiceDate?: Date,
  ): {
    dueMileage: number;
    dueDate?: Date;
    milesUntilDue: number;
    daysUntilDue?: number;
    status: 'ok' | 'due_soon' | 'overdue';
  } {
    // Calculate next due mileage
    const baseMileage = lastServiceMileage || 0;
    const dueMileage = baseMileage + item.intervalMiles;
    const milesUntilDue = dueMileage - currentMileage;

    // Calculate next due date
    let dueDate: Date | undefined;
    let daysUntilDue: number | undefined;
    if (item.intervalMonths) {
      if (lastServiceDate) {
        dueDate = new Date(lastServiceDate);
        dueDate.setMonth(dueDate.getMonth() + item.intervalMonths);
      } else {
        // No last service, assume due based on interval from now
        dueDate = new Date();
        dueDate.setMonth(dueDate.getMonth() + item.intervalMonths);
      }
      daysUntilDue = Math.ceil((dueDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    }

    // Determine status (use stricter of mileage or time)
    let status: 'ok' | 'due_soon' | 'overdue' = 'ok';
    
    // Check mileage
    if (milesUntilDue < 0) {
      status = 'overdue';
    } else if (milesUntilDue < 1000) {
      status = 'due_soon';
    }

    // Check time (if applicable)
    if (daysUntilDue !== undefined) {
      if (daysUntilDue < 0 && status !== 'overdue') {
        status = 'overdue';
      } else if (daysUntilDue < 30 && status === 'ok') {
        status = 'due_soon';
      }
    }

    return {
      dueMileage,
      dueDate,
      milesUntilDue,
      daysUntilDue,
      status,
    };
  }

  async getMaintenanceDue(vehicleId: string) {
    const vehicle = await this.prisma.vehicle.findUnique({
      where: { id: vehicleId },
      include: {
        serviceHistory: {
          orderBy: { date: 'desc' },
        },
      },
    });

    if (!vehicle) throw new Error('Vehicle not found');

    // Check if we have researched maintenance for this vehicle
    let schedule = vehicle.maintenanceSchedule as VehicleMaintenanceSchedule | null;
    
    if (!schedule) {
      // Research maintenance schedule
      schedule = await this.researchVehicleMaintenance(
        vehicle.year,
        vehicle.make,
        vehicle.model,
      );
      
      // Save to vehicle
      await this.prisma.vehicle.update({
        where: { id: vehicleId },
        data: {
          maintenanceSchedule: schedule as any,
          maintenanceResearchedAt: new Date(),
        },
      });
    }

    const currentMileage = vehicle.currentMileage || 0;

    // Calculate status for each maintenance item
    const items = schedule.maintenanceItems.map(item => {
      // Find last service of this type
      const lastService = vehicle.serviceHistory?.find(
        s => s.type.toUpperCase() === item.type.toUpperCase()
      );

      const dueInfo = this.calculateMaintenanceDue(
        item,
        currentMileage,
        lastService?.mileage || undefined,
        lastService?.date ? new Date(lastService.date) : undefined,
      );

      return {
        ...item,
        lastServiceDate: lastService?.date,
        lastServiceMileage: lastService?.mileage,
        lastServiceCost: lastService?.cost,
        ...dueInfo,
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
      currentMileage,
      items,
      recalls: schedule.recalls || [],
      tips: schedule.tips || [],
      specificNotes: schedule.specificNotes || [],
    };
  }
}
```

### Add Prisma Schema Updates

```prisma
model Vehicle {
  // ... existing fields ...
  
  currentMileage          Int?
  maintenanceSchedule     Json?      // Stores AI-researched schedule
  maintenanceResearchedAt DateTime?
  
  serviceHistory          VehicleServiceRecord[]
}

model VehicleServiceRecord {
  id          String   @id @default(cuid())
  vehicleId   String
  vehicle     Vehicle  @relation(fields: [vehicleId], references: [id], onDelete: Cascade)
  
  type        String   // OIL_CHANGE, TIRE_ROTATION, etc.
  date        DateTime
  mileage     Int?
  cost        Float?
  vendor      String?
  description String?
  notes       String?
  
  documents   Document[]
  
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
}
```

### Update Vehicle Detail Screen - Maintenance Section

```typescript
// Add state
const [maintenanceDue, setMaintenanceDue] = useState<MaintenanceDueResponse | null>(null);
const [isResearching, setIsResearching] = useState(false);
const [showUpdateMileageModal, setShowUpdateMileageModal] = useState(false);

// Fetch maintenance due
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
}, [id]);

// Research maintenance (manual trigger)
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
  } catch (err) {
    Alert.alert('Error', 'Failed to research maintenance');
  } finally {
    setIsResearching(false);
  }
};

// Update mileage
const handleUpdateMileage = async (newMileage: number) => {
  try {
    const token = await getIdToken(true);
    await fetch(
      `${API_BASE_URL}/family/household/${householdInfo?.id}/vehicle/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ currentMileage: newMileage }),
      }
    );
    await fetchVehicle();
    await fetchMaintenanceDue();
    setShowUpdateMileageModal(false);
  } catch (err) {
    Alert.alert('Error', 'Failed to update mileage');
  }
};

// Replace the Maintenance Due Card with:
<Card style={styles.section}>
  <SectionHeader
    title="MAINTENANCE DUE"
    action={isResearching ? 'Researching...' : 'Refresh'}
    onAction={handleResearchMaintenance}
  />
  
  {/* Current Mileage Input */}
  <TouchableOpacity 
    style={styles.mileageRow}
    onPress={() => setShowUpdateMileageModal(true)}
  >
    <View style={styles.mileageInfo}>
      <Ionicons name="speedometer-outline" size={20} color={colors.haven.navy[600]} />
      <View>
        <Text style={styles.mileageLabel}>Current Mileage</Text>
        <Text style={styles.mileageValue}>
          {maintenanceDue?.currentMileage?.toLocaleString() || 'Not set'}
        </Text>
      </View>
    </View>
    <Ionicons name="pencil" size={16} color={colors.haven.champagne[500]} />
  </TouchableOpacity>

  {/* Maintenance Items */}
  {maintenanceDue?.items.map((item, index) => (
    <View key={index} style={[
      styles.maintenanceItem,
      item.status === 'overdue' && styles.maintenanceItemOverdue,
      item.status === 'due_soon' && styles.maintenanceItemDueSoon,
    ]}>
      <View style={styles.maintenanceHeader}>
        <Text style={styles.maintenanceName}>{item.name}</Text>
        <Badge
          label={item.status === 'ok' ? 'OK' : item.status === 'due_soon' ? 'Due Soon' : 'Overdue'}
          variant={item.status === 'ok' ? 'success' : item.status === 'due_soon' ? 'warning' : 'error'}
        />
      </View>
      <Text style={styles.maintenanceDescription}>{item.description}</Text>
      <View style={styles.maintenanceDetails}>
        <Text style={styles.maintenanceInterval}>
          Every {item.intervalMiles.toLocaleString()} miles
          {item.intervalMonths && ` or ${item.intervalMonths} months`}
        </Text>
        {item.lastServiceDate && (
          <Text style={styles.maintenanceLast}>
            Last: {new Date(item.lastServiceDate).toLocaleDateString()}
            {item.lastServiceMileage && ` at ${item.lastServiceMileage.toLocaleString()} mi`}
          </Text>
        )}
        <Text style={[
          styles.maintenanceDue,
          item.status !== 'ok' && styles.maintenanceDueAlert,
        ]}>
          {item.milesUntilDue > 0 
            ? `Due in ${item.milesUntilDue.toLocaleString()} miles`
            : `Overdue by ${Math.abs(item.milesUntilDue).toLocaleString()} miles`
          }
        </Text>
        <Text style={styles.maintenanceCost}>
          Est. ${item.estimatedCostLow}-${item.estimatedCostHigh}
        </Text>
      </View>
    </View>
  ))}

  {/* Recalls Section */}
  {maintenanceDue?.recalls && maintenanceDue.recalls.length > 0 && (
    <View style={styles.recallsSection}>
      <View style={styles.recallsHeader}>
        <Ionicons name="warning" size={20} color={colors.status.error} />
        <Text style={styles.recallsTitle}>
          {maintenanceDue.recalls.length} Active Recall{maintenanceDue.recalls.length > 1 ? 's' : ''}
        </Text>
      </View>
      {maintenanceDue.recalls.map((recall, index) => (
        <View key={index} style={styles.recallItem}>
          <Text style={styles.recallComponent}>{recall.component}</Text>
          <Text style={styles.recallSummary}>{recall.summary}</Text>
          <Text style={styles.recallRemedy}>{recall.remedy}</Text>
          <Text style={styles.recallDate}>Issued: {recall.dateIssued}</Text>
        </View>
      ))}
    </View>
  )}

  {/* Tips */}
  {maintenanceDue?.tips && maintenanceDue.tips.length > 0 && (
    <View style={styles.tipsSection}>
      <Text style={styles.tipsTitle}>Tips for Your Vehicle</Text>
      {maintenanceDue.tips.map((tip, index) => (
        <View key={index} style={styles.tipItem}>
          <Ionicons name="bulb-outline" size={16} color={colors.haven.champagne[500]} />
          <Text style={styles.tipText}>{tip}</Text>
        </View>
      ))}
    </View>
  )}
</Card>
```

---

## Part 3: Pet - Focused Edit Modals

### Problem

In the pet detail screen, these actions navigate to full edit page:
- "Add vaccination records"
- "Add medication"
- "Add IDs & Registration"

### Create Focused Modals

Create these modal components in `apps/mobile/src/components/forms/`:

1. **AddVaccinationModal.tsx**
2. **AddMedicationModal.tsx**
3. **EditPetIdModal.tsx** (already partially exists, update it)

### AddVaccinationModal.tsx

```typescript
import React, { useState } from 'react';
// ... imports

interface AddVaccinationModalProps {
  visible: boolean;
  onClose: () => void;
  petId: string;
  householdId: string;
  petType?: string;
  onSuccess: () => void;
}

const COMMON_VACCINES = {
  dog: ['Rabies', 'DHPP (Distemper)', 'Bordetella', 'Lyme', 'Leptospirosis', 'Canine Influenza'],
  cat: ['Rabies', 'FVRCP', 'FeLV', 'FIV'],
  default: ['Rabies'],
};

export function AddVaccinationModal({ ... }: AddVaccinationModalProps) {
  const [vaccineName, setVaccineName] = useState('');
  const [customName, setCustomName] = useState('');
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  const [expiresAt, setExpiresAt] = useState('');
  const [veterinarian, setVeterinarian] = useState('');
  const [notes, setNotes] = useState('');
  const [documentUri, setDocumentUri] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);

  const vaccines = COMMON_VACCINES[petType as keyof typeof COMMON_VACCINES] || COMMON_VACCINES.default;

  const handleSave = async () => {
    const name = vaccineName === 'other' ? customName : vaccineName;
    if (!name || !date) {
      Alert.alert('Required', 'Vaccination name and date are required');
      return;
    }

    setIsSaving(true);
    try {
      const token = await getIdToken(true);
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

      // Upload document if provided
      // ... document upload logic

      onSuccess();
      onClose();
      Alert.alert('Success', 'Vaccination record added');
    } catch (err) {
      Alert.alert('Error', 'Failed to save vaccination record');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      {/* Similar structure to AddServiceHistoryModal */}
    </Modal>
  );
}
```

### AddMedicationModal.tsx

```typescript
export function AddMedicationModal({ ... }: AddMedicationModalProps) {
  const [name, setName] = useState('');
  const [dosage, setDosage] = useState('');
  const [frequency, setFrequency] = useState('');
  const [prescribedBy, setPrescribedBy] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [notes, setNotes] = useState('');

  const handleSave = async () => {
    if (!name || !dosage || !frequency) {
      Alert.alert('Required', 'Name, dosage, and frequency are required');
      return;
    }

    // ... save logic
  };

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      {/* Form fields for medication */}
    </Modal>
  );
}
```

### Update Pet Detail Screen

In `apps/mobile/app/(tabs)/family/pet/[id].tsx`:

```typescript
// Add imports
import { AddVaccinationModal } from '../../../../src/components/forms/AddVaccinationModal';
import { AddMedicationModal } from '../../../../src/components/forms/AddMedicationModal';
import { EditPetIdModal } from '../../../../src/components/forms/EditPetIdModal';

// Add states
const [showVaccinationModal, setShowVaccinationModal] = useState(false);
const [showMedicationModal, setShowMedicationModal] = useState(false);
const [showIdModal, setShowIdModal] = useState(false);

// Update sections:

{/* Vaccinations */}
<SectionHeader
  title="VACCINATIONS"
  action="+ Add"
  onAction={() => setShowVaccinationModal(true)}  // CHANGED
/>

{/* Medications */}
<SectionHeader
  title="MEDICATIONS"
  action="+ Add"
  onAction={() => setShowMedicationModal(true)}  // CHANGED
/>

{/* IDs & Registration */}
<SectionHeader
  title="IDS & REGISTRATION"
  action="Edit"
  onAction={() => setShowIdModal(true)}  // CHANGED
/>

// Add modals at bottom
<AddVaccinationModal
  visible={showVaccinationModal}
  onClose={() => setShowVaccinationModal(false)}
  petId={id!}
  householdId={householdInfo?.id || ''}
  petType={pet?.type}
  onSuccess={fetchPet}
/>
<AddMedicationModal
  visible={showMedicationModal}
  onClose={() => setShowMedicationModal(false)}
  petId={id!}
  householdId={householdInfo?.id || ''}
  onSuccess={fetchPet}
/>
<EditPetIdModal
  visible={showIdModal}
  onClose={() => setShowIdModal(false)}
  petId={id!}
  householdId={householdInfo?.id || ''}
  initialData={{
    microchipId: pet?.microchipId,
    licenseNumber: pet?.registration?.licenseNumber,
    licenseExpires: pet?.registration?.licenseExpires,
  }}
  onSuccess={fetchPet}
/>
```

---

## Part 4: Alfred-Gathered Data Flows to Home Profile

When Alfred processes emails and learns about systems, vendors, bills, etc., that data should automatically update the home profile.

### Update Alfred Email Processing

In `apps/api/src/alfred/alfred-email.service.ts`:

```typescript
// After extracting data from an email, persist to home profile:

async processEmailAndUpdateProfile(
  emailCase: EmailCase,
  householdId: string,
) {
  const extraction = await this.extractDataFromEmail(emailCase);

  // If we detected a system/appliance
  if (extraction.detectedSystem) {
    await this.homeSystemService.createOrUpdateFromAlfred({
      householdId,
      type: extraction.detectedSystem.type,
      name: extraction.detectedSystem.name,
      brand: extraction.detectedSystem.brand,
      model: extraction.detectedSystem.model,
      serialNumber: extraction.detectedSystem.serialNumber,
      warrantyExpires: extraction.detectedSystem.warrantyExpires,
      source: 'ALFRED_EMAIL',
      sourceEmailId: emailCase.id,
    });
  }

  // If we detected a vendor
  if (extraction.detectedVendor) {
    await this.vendorService.createOrUpdateFromAlfred({
      householdId,
      displayName: extraction.detectedVendor.name,
      category: extraction.detectedVendor.category,
      phone: extraction.detectedVendor.phone,
      email: extraction.detectedVendor.email,
      address: extraction.detectedVendor.address,
      source: 'ALFRED_EMAIL',
      sourceEmailId: emailCase.id,
    });
  }

  // If we detected a bill
  if (extraction.detectedBill) {
    await this.billService.createOrUpdateFromAlfred({
      householdId,
      name: extraction.detectedBill.name,
      category: extraction.detectedBill.category,
      amount: extraction.detectedBill.amount,
      dueDate: extraction.detectedBill.dueDate,
      payee: extraction.detectedBill.payee,
      source: 'ALFRED_EMAIL',
      sourceEmailId: emailCase.id,
    });
  }

  // If we detected utility info
  if (extraction.detectedUtility) {
    await this.propertyService.updateUtilityFromAlfred(householdId, {
      type: extraction.detectedUtility.type,
      provider: extraction.detectedUtility.provider,
      accountNumber: extraction.detectedUtility.accountNumber,
    });
  }

  // If we detected maintenance service
  if (extraction.detectedService) {
    // Find or create the system
    const system = await this.findOrCreateSystem(
      householdId,
      extraction.detectedService.systemType,
    );

    // Add maintenance task
    await this.maintenanceService.addTaskFromAlfred({
      systemId: system.id,
      householdId,
      title: extraction.detectedService.description,
      category: extraction.detectedService.category,
      completedAt: extraction.detectedService.serviceDate,
      cost: extraction.detectedService.cost,
      vendorName: extraction.detectedService.vendorName,
      source: 'ALFRED_EMAIL',
      sourceEmailId: emailCase.id,
    });
  }
}
```

---

## Part 5: Ensure All Updates Persist

Every form and edit action must follow this pattern:

```typescript
const handleSave = async (data: UpdateData) => {
  setIsSaving(true);
  try {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/resource/${id}`,
      {
        method: 'PATCH',  // or POST for new records
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

    // CRITICAL: Refresh data from server
    await fetchData();
    
    // Close modal and show success
    setModalVisible(false);
    // Optional: Show success feedback
  } catch (err) {
    Alert.alert('Error', err instanceof Error ? err.message : 'Failed to save');
  } finally {
    setIsSaving(false);
  }
};
```

### Audit Checklist - Verify Each Screen Persists Data

- [ ] Family member edits → PATCH /family/household/:id/member/:id
- [ ] Pet edits → PATCH /family/household/:id/pet/:id
- [ ] Pet vaccinations → POST /family/household/:id/pet/:id/vaccination
- [ ] Pet medications → POST /family/household/:id/pet/:id/medication
- [ ] Vehicle edits → PATCH /family/household/:id/vehicle/:id
- [ ] Vehicle service records → POST /family/household/:id/vehicle/:id/service
- [ ] Home system edits → PATCH /home/system/:id
- [ ] Maintenance task completion → PATCH /maintenance/task/:id
- [ ] Zone/asset edits → PATCH /property/zone/:id, PATCH /property/asset/:id
- [ ] Profile edits → PATCH /users/profile
- [ ] Vendor edits → PATCH /households/:id/vendors/:id

---

## Implementation Checklist

### Day 1: Vehicle Fixes
- [ ] Create AddServiceHistoryModal component
- [ ] Create VehicleServiceRecord API endpoints
- [ ] Update vehicle detail screen to use modal
- [ ] Update Prisma schema for service records

### Day 2: Vehicle Maintenance Intelligence
- [ ] Create VehicleMaintenanceResearchService
- [ ] Create maintenance-due API endpoint
- [ ] Update vehicle detail maintenance section
- [ ] Add mileage input/update functionality
- [ ] Display recalls and tips

### Day 3: Pet Focused Modals
- [ ] Create AddVaccinationModal
- [ ] Create AddMedicationModal
- [ ] Create/update EditPetIdModal
- [ ] Create pet vaccination/medication API endpoints
- [ ] Update pet detail screen

### Day 4: Alfred Integration & Data Persistence Audit
- [ ] Update Alfred email processing to write to home profile
- [ ] Audit all screens for data persistence
- [ ] Test end-to-end flows
- [ ] Verify all updates refresh UI correctly

---

## Success Criteria

- [ ] "Add Service History" on vehicle opens focused modal with document upload
- [ ] Vehicle maintenance shows mileage-based due dates
- [ ] Vehicle maintenance shows make/model specific intervals
- [ ] Vehicle shows recalls (if any) for that year/make/model
- [ ] Pet "Add vaccination" opens focused modal
- [ ] Pet "Add medication" opens focused modal
- [ ] Pet "Edit IDs" opens focused modal
- [ ] All edits persist to production database
- [ ] UI refreshes after every save
- [ ] Alfred-learned data appears in home profile
