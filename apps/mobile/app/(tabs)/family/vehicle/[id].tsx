import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  TextInput,
  Modal,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useLocalSearchParams, useRouter, Stack } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '../../../../src/contexts/auth-context';
import { Card, Badge, LoadingSpinner, Button } from '../../../../src/components';
import { colors, typography, spacing, borderRadius } from '../../../../src/lib/theme';
import { API_BASE_URL } from '../../../../src/lib/api';
import { getIdToken } from '../../../../src/lib/firebase';
import { EditRegistrationModal } from '../../../../src/components/forms/EditRegistrationModal';
import { EditInsuranceModal } from '../../../../src/components/forms/EditInsuranceModal';
import { AddServiceHistoryModal } from '../../../../src/components/forms/AddServiceHistoryModal';
import { UpdateMileageModal } from '../../../../src/components/forms/UpdateMileageModal';

// =============================================================================
// TYPES
// =============================================================================

interface Registration {
  licensePlate?: string | null;
  state?: string | null;
  expiresAt?: string | null;
  registrationNumber?: string | null;
}

interface Insurance {
  provider?: string | null;
  policyNumber?: string | null;
  expiresAt?: string | null;
  agentName?: string | null;
  agentPhone?: string | null;
  monthlyPremium?: number | null;
}

interface Maintenance {
  oilChangeInterval?: number | null;
  lastOilChange?: string | null;
  lastOilChangeMileage?: number | null;
  nextOilChangeDue?: string | null;
  oilType?: string | null;
  tireType?: string | null;
  tireSize?: string | null;
  lastTireRotation?: string | null;
  tireRotationInterval?: number | null;
  lastTireReplacement?: string | null;
  lastInspection?: string | null;
  inspectionDue?: string | null;
  lastBrakeService?: string | null;
  lastTransmissionService?: string | null;
}

interface VehicleStatus {
  currentMileage?: number | null;
  fuelType?: 'gas' | 'diesel' | 'electric' | 'hybrid' | null;
  averageMPG?: number | null;
}

interface Financing {
  lender?: string | null;
  monthlyPayment?: number | null;
  payoffDate?: string | null;
  remainingBalance?: number | null;
}

interface ServiceRecord {
  id: string;
  date: string;
  type: 'oil_change' | 'tire_rotation' | 'inspection' | 'repair' | 'other';
  description: string;
  mileage?: number | null;
  cost?: number | null;
  vendor?: string | null;
  notes?: string | null;
}

interface ServiceProvider {
  id: string;
  name: string;
  type: string;
  phone?: string | null;
  address?: string | null;
}

// AI-Researched Maintenance Intelligence Types
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
  // Calculated fields from API
  lastServiceDate?: string | null;
  lastServiceMileage?: number | null;
  lastServiceCost?: number | null;
  dueMileage: number;
  dueDate?: string | null;
  milesUntilDue: number;
  daysUntilDue?: number | null;
  status: 'ok' | 'due_soon' | 'overdue';
}

interface RecallInfo {
  campaignNumber: string;
  component: string;
  summary: string;
  consequence: string;
  remedy: string;
  dateIssued: string;
}

interface MaintenanceDueResponse {
  currentMileage: number;
  items: MaintenanceItem[];
  recalls: RecallInfo[];
  tips: string[];
  specificNotes: string[];
}

interface VehicleDetail {
  id: string;
  name?: string | null;
  year: number;
  make: string;
  model: string;
  color?: string | null;
  licensePlate?: string | null;
  vin?: string | null;
  registrationExpiry?: string | null;
  registrationDocUrl?: string | null;
  insuranceExpiry?: string | null;
  insuranceDocUrl?: string | null;
  insuranceProvider?: string | null;
  insurancePolicyNum?: string | null;
  notes?: string | null;
  // Enhanced fields
  registration?: Registration;
  insurance?: Insurance;
  maintenance?: Maintenance;
  status?: VehicleStatus;
  financing?: Financing;
  serviceHistory?: ServiceRecord[];
  serviceProviders?: ServiceProvider[];
}

// =============================================================================
// HELPER COMPONENTS
// =============================================================================

interface SectionHeaderProps {
  title: string;
  action?: string;
  onAction?: () => void;
}

function SectionHeader({ title, action, onAction }: SectionHeaderProps) {
  return (
    <View style={helperStyles.sectionHeader}>
      <Text style={helperStyles.sectionHeaderText}>{title}</Text>
      {action && onAction && (
        <TouchableOpacity onPress={onAction}>
          <Text style={helperStyles.sectionAction}>{action}</Text>
        </TouchableOpacity>
      )}
    </View>
  );
}

interface InfoRowProps {
  icon: keyof typeof Ionicons.glyphMap;
  label: string;
  value?: string | null;
  alert?: boolean;
  mono?: boolean;
}

function InfoRow({ icon, label, value, alert, mono }: InfoRowProps) {
  if (!value) return null;
  return (
    <View style={helperStyles.infoRow}>
      <Ionicons name={icon} size={18} color={colors.text.tertiary} />
      <View style={helperStyles.infoContent}>
        <Text style={helperStyles.infoLabel}>{label}</Text>
        <Text style={[
          helperStyles.infoValue,
          alert && helperStyles.alertText,
          mono && helperStyles.monoText,
        ]}>
          {value}
        </Text>
      </View>
    </View>
  );
}

interface EmptyPromptProps {
  text: string;
  onPress?: () => void;
}

function EmptyPrompt({ text, onPress }: EmptyPromptProps) {
  return (
    <TouchableOpacity style={helperStyles.emptyPrompt} onPress={onPress} disabled={!onPress}>
      <Ionicons name="add-circle-outline" size={20} color={colors.haven.purple[500]} />
      <Text style={helperStyles.emptyPromptText}>{text}</Text>
    </TouchableOpacity>
  );
}

interface MaintenanceAlertProps {
  type: 'oil' | 'tires' | 'inspection' | 'brakes';
  lastService?: string | null;
  nextDue?: string | null;
  interval?: string;
  status?: 'ok' | 'due_soon' | 'overdue';
}

function MaintenanceAlert({ type, lastService, nextDue, interval, status = 'ok' }: MaintenanceAlertProps) {
  const typeConfig = {
    oil: { icon: 'water-outline' as const, label: 'Oil Change' },
    tires: { icon: 'ellipse-outline' as const, label: 'Tire Rotation' },
    inspection: { icon: 'clipboard-outline' as const, label: 'Inspection' },
    brakes: { icon: 'disc-outline' as const, label: 'Brake Service' },
  };

  const config = typeConfig[type];
  const statusColors = {
    ok: colors.status.success,
    due_soon: colors.status.warning,
    overdue: colors.status.error,
  };

  return (
    <View style={[helperStyles.maintenanceAlert, { borderLeftColor: statusColors[status] }]}>
      <View style={helperStyles.maintenanceIcon}>
        <Ionicons name={config.icon} size={20} color={statusColors[status]} />
      </View>
      <View style={helperStyles.maintenanceContent}>
        <Text style={helperStyles.maintenanceLabel}>{config.label}</Text>
        {lastService && (
          <Text style={helperStyles.maintenanceDate}>
            Last: {new Date(lastService).toLocaleDateString()}
          </Text>
        )}
        {nextDue && (
          <Text style={[helperStyles.maintenanceDate, { color: statusColors[status] }]}>
            Due: {new Date(nextDue).toLocaleDateString()}
          </Text>
        )}
        {interval && (
          <Text style={helperStyles.maintenanceInterval}>{interval}</Text>
        )}
      </View>
      <Badge
        label={status === 'ok' ? 'OK' : status === 'due_soon' ? 'Due Soon' : 'Overdue'}
        variant={status === 'ok' ? 'success' : status === 'due_soon' ? 'warning' : 'error'}
      />
    </View>
  );
}

const helperStyles = StyleSheet.create({
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing[3],
  },
  sectionHeaderText: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    letterSpacing: 0.5,
  },
  sectionAction: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    paddingVertical: spacing[2],
  },
  infoContent: {
    flex: 1,
  },
  infoLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  infoValue: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  alertText: {
    color: colors.status.error,
  },
  monoText: {
    fontFamily: 'monospace',
    letterSpacing: 1,
  },
  emptyPrompt: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
  },
  emptyPromptText: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
  },
  maintenanceAlert: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    paddingLeft: spacing[3],
    borderLeftWidth: 3,
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.md,
    marginBottom: spacing[2],
  },
  maintenanceIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.white,
    alignItems: 'center',
    justifyContent: 'center',
  },
  maintenanceContent: {
    flex: 1,
  },
  maintenanceLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  maintenanceDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  maintenanceInterval: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginTop: 2,
  },
});

export default function VehicleDetailScreen() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  const { householdInfo } = useAuth();
  const [vehicle, setVehicle] = useState<VehicleDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modal states
  const [showRegistrationModal, setShowRegistrationModal] = useState(false);
  const [showInsuranceModal, setShowInsuranceModal] = useState(false);
  const [showAddProviderModal, setShowAddProviderModal] = useState(false);
  const [showAddServiceModal, setShowAddServiceModal] = useState(false);
  const [showMileageModal, setShowMileageModal] = useState(false);
  const [newProviderName, setNewProviderName] = useState('');
  const [newProviderType, setNewProviderType] = useState('mechanic');
  const [newProviderPhone, setNewProviderPhone] = useState('');

  // AI Maintenance Intelligence
  const [maintenanceDue, setMaintenanceDue] = useState<MaintenanceDueResponse | null>(null);
  const [isLoadingMaintenance, setIsLoadingMaintenance] = useState(false);

  const fetchVehicle = useCallback(async () => {
    if (!id || !householdInfo?.id) return;

    try {
      const token = await getIdToken(true);
      if (!token) {
        setError('Authentication expired.');
        setIsLoading(false);
        return;
      }

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo.id}/vehicle/${id}`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (!response.ok) {
        throw new Error(`Failed to fetch vehicle: ${response.status}`);
      }

      const data: VehicleDetail = await response.json();
      setVehicle(data);
      setError(null);
    } catch (err) {
      console.error('Fetch vehicle error:', err);
      setError('Failed to load vehicle details.');
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [id, householdInfo?.id]);

  // Fetch AI-powered maintenance due schedule
  const fetchMaintenanceDue = useCallback(async () => {
    if (!id) return;

    setIsLoadingMaintenance(true);
    try {
      const token = await getIdToken(true);
      if (!token) return;

      const response = await fetch(
        `${API_BASE_URL}/family/vehicles/${id}/maintenance-due`,
        {
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
        }
      );

      if (response.ok) {
        const data: MaintenanceDueResponse = await response.json();
        setMaintenanceDue(data);
      }
    } catch (err) {
      console.error('Failed to fetch maintenance due:', err);
    } finally {
      setIsLoadingMaintenance(false);
    }
  }, [id]);

  useEffect(() => {
    fetchVehicle();
  }, [fetchVehicle]);

  useEffect(() => {
    if (vehicle) {
      fetchMaintenanceDue();
    }
  }, [vehicle, fetchMaintenanceDue]);

  const handleDelete = async () => {
    Alert.alert(
      'Delete Vehicle',
      'Are you sure you want to delete this vehicle? This cannot be undone.',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Delete',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) {
                Alert.alert('Error', 'Authentication expired.');
                return;
              }

              const response = await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/vehicle/${id}`,
                {
                  method: 'DELETE',
                  headers: {
                    Authorization: `Bearer ${token}`,
                  },
                }
              );

              if (!response.ok) throw new Error('Failed to delete');

              Alert.alert('Deleted', 'Vehicle has been deleted.');
              router.back();
            } catch (err) {
              Alert.alert('Error', 'Failed to delete vehicle.');
            }
          },
        },
      ]
    );
  };

  // Save registration data
  const handleSaveRegistration = async (data: {
    licensePlate?: string | null;
    vin?: string | null;
    registrationState?: string | null;
    registrationExpiry?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/vehicles/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          licensePlate: data.licensePlate,
          vin: data.vin,
          registrationState: data.registrationState,
          registrationExpiry: data.registrationExpiry,
        }),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchVehicle();
  };

  // Save insurance data
  const handleSaveInsurance = async (data: {
    insuranceProvider?: string | null;
    insurancePolicyNum?: string | null;
    insuranceExpiry?: string | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/vehicles/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          insuranceProvider: data.insuranceProvider,
          insurancePolicyNum: data.insurancePolicyNum,
          insuranceExpiry: data.insuranceExpiry,
        }),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchVehicle();
  };

  // Save mileage data
  const handleSaveMileage = async (data: {
    currentMileage?: number | null;
    lastOilChange?: string | null;
    oilChangeMileage?: number | null;
  }) => {
    const token = await getIdToken(true);
    if (!token) throw new Error('Authentication expired');

    const response = await fetch(
      `${API_BASE_URL}/family/vehicles/${id}`,
      {
        method: 'PATCH',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          currentMileage: data.currentMileage,
          lastOilChange: data.lastOilChange,
          oilChangeMileage: data.oilChangeMileage,
        }),
      }
    );

    if (!response.ok) throw new Error('Failed to save');
    await fetchVehicle();
    fetchMaintenanceDue();
  };

  // Add service provider
  const handleAddServiceProvider = async () => {
    if (!newProviderName.trim()) {
      Alert.alert('Required', 'Provider name is required');
      return;
    }

    try {
      const token = await getIdToken(true);
      if (!token) throw new Error('Authentication expired');

      const response = await fetch(
        `${API_BASE_URL}/family/household/${householdInfo?.id}/vehicle/${id}/provider`,
        {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            name: newProviderName.trim(),
            type: newProviderType,
            phone: newProviderPhone.trim() || null,
          }),
        }
      );

      if (!response.ok) throw new Error('Failed to add provider');

      setNewProviderName('');
      setNewProviderType('mechanic');
      setNewProviderPhone('');
      setShowAddProviderModal(false);
      await fetchVehicle();
    } catch (err) {
      Alert.alert('Error', 'Failed to add service provider');
    }
  };

  // Remove service provider
  const handleRemoveProvider = async (providerId: string) => {
    Alert.alert(
      'Remove Provider',
      'Are you sure you want to remove this service provider?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Remove',
          style: 'destructive',
          onPress: async () => {
            try {
              const token = await getIdToken(true);
              if (!token) return;

              await fetch(
                `${API_BASE_URL}/family/household/${householdInfo?.id}/vehicle/${id}/provider/${providerId}`,
                {
                  method: 'DELETE',
                  headers: { Authorization: `Bearer ${token}` },
                }
              );
              await fetchVehicle();
            } catch (err) {
              Alert.alert('Error', 'Failed to remove provider');
            }
          },
        },
      ]
    );
  };

  const formatDate = (dateString?: string | null) => {
    if (!dateString) return null;
    return new Date(dateString).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
  };

  const isExpiringSoon = (dateString?: string | null) => {
    if (!dateString) return false;
    const daysUntil = Math.ceil(
      (new Date(dateString).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    return daysUntil <= 30 && daysUntil > 0;
  };

  const isExpired = (dateString?: string | null) => {
    if (!dateString) return false;
    return new Date(dateString) < new Date();
  };

  if (isLoading) {
    return <LoadingSpinner fullScreen message="Loading vehicle..." />;
  }

  if (error || !vehicle) {
    return (
      <SafeAreaView style={styles.container} edges={['bottom']}>
        <Stack.Screen options={{ title: 'Vehicle' }} />
        <View style={styles.errorContainer}>
          <Ionicons name="alert-circle" size={48} color={colors.status.error} />
          <Text style={styles.errorTitle}>Unable to Load Vehicle</Text>
          <Text style={styles.errorText}>{error || 'Vehicle not found'}</Text>
          <TouchableOpacity style={styles.retryButton} onPress={fetchVehicle}>
            <Text style={styles.retryText}>Try Again</Text>
          </TouchableOpacity>
        </View>
      </SafeAreaView>
    );
  }

  const vehicleName = `${vehicle.year} ${vehicle.make} ${vehicle.model}`;

  // Format currency
  const formatCurrency = (amount?: number | null) => {
    if (!amount) return null;
    return `$${amount.toLocaleString()}`;
  };

  // Get maintenance status
  const getMaintenanceStatus = (nextDue?: string | null): 'ok' | 'due_soon' | 'overdue' => {
    if (!nextDue) return 'ok';
    const daysUntil = Math.ceil(
      (new Date(nextDue).getTime() - Date.now()) / (1000 * 60 * 60 * 24)
    );
    if (daysUntil < 0) return 'overdue';
    if (daysUntil <= 30) return 'due_soon';
    return 'ok';
  };

  // Get icon for maintenance item type
  const getMaintenanceIcon = (type: string): keyof typeof Ionicons.glyphMap => {
    const iconMap: Record<string, keyof typeof Ionicons.glyphMap> = {
      'OIL_CHANGE': 'water-outline',
      'TIRE_ROTATION': 'ellipse-outline',
      'TIRE_REPLACEMENT': 'ellipse',
      'BRAKE_INSPECTION': 'disc-outline',
      'BRAKE_PAD_REPLACEMENT': 'disc',
      'AIR_FILTER': 'funnel-outline',
      'CABIN_AIR_FILTER': 'leaf-outline',
      'TRANSMISSION_FLUID': 'cog-outline',
      'COOLANT_FLUSH': 'thermometer-outline',
      'SPARK_PLUGS': 'flash-outline',
      'BATTERY': 'battery-charging-outline',
      'SERPENTINE_BELT': 'repeat-outline',
      'TIMING_BELT': 'timer-outline',
      'WHEEL_ALIGNMENT': 'navigate-outline',
      'WIPER_BLADES': 'rainy-outline',
    };
    return iconMap[type.toUpperCase()] || 'construct-outline';
  };

  // Get service type icon and label
  const getServiceTypeInfo = (type: ServiceRecord['type']) => {
    const typeConfig = {
      oil_change: { icon: 'water-outline' as const, label: 'Oil Change' },
      tire_rotation: { icon: 'ellipse-outline' as const, label: 'Tire Rotation' },
      inspection: { icon: 'clipboard-outline' as const, label: 'Inspection' },
      repair: { icon: 'build-outline' as const, label: 'Repair' },
      other: { icon: 'construct-outline' as const, label: 'Service' },
    };
    return typeConfig[type] || typeConfig.other;
  };

  // Check if any maintenance has data
  const hasMaintenanceData = vehicle.maintenance && (
    vehicle.maintenance.lastOilChange ||
    vehicle.maintenance.lastTireRotation ||
    vehicle.maintenance.lastInspection ||
    vehicle.maintenance.lastBrakeService
  );

  // Check if registration has data
  const hasRegistrationData = vehicle.registration && (
    vehicle.registration.licensePlate ||
    vehicle.registration.state ||
    vehicle.registration.expiresAt
  );

  // Check if insurance has data
  const hasInsuranceData = vehicle.insurance && (
    vehicle.insurance.provider ||
    vehicle.insurance.policyNumber ||
    vehicle.insurance.expiresAt
  );

  return (
    <SafeAreaView style={styles.container} edges={['bottom']}>
      <Stack.Screen
        options={{
          title: 'Vehicle',
          headerRight: () => (
            <TouchableOpacity onPress={() => router.push(`/(tabs)/family/vehicle/edit/${id}` as any)}>
              <Ionicons name="create-outline" size={24} color={colors.haven.purple[500]} />
            </TouchableOpacity>
          ),
        }}
      />
      <ScrollView
        contentContainerStyle={styles.scrollContent}
        refreshControl={
          <RefreshControl
            refreshing={isRefreshing}
            onRefresh={() => {
              setIsRefreshing(true);
              fetchVehicle();
            }}
          />
        }
      >
        {/* Hero Card */}
        <Card style={styles.heroCard}>
          <View style={styles.vehicleImagePlaceholder}>
            <Ionicons name="car" size={64} color={colors.haven.purple[500]} />
          </View>
          <Text style={styles.vehicleName}>{vehicleName}</Text>
          {vehicle.name && (
            <Text style={styles.nickname}>"{vehicle.name}"</Text>
          )}
          {vehicle.color && (
            <View style={styles.colorBadge}>
              <View style={[styles.colorDot, { backgroundColor: vehicle.color.toLowerCase() === 'white' ? colors.border.light : vehicle.color.toLowerCase() }]} />
              <Text style={styles.colorText}>{vehicle.color}</Text>
            </View>
          )}
          {vehicle.status?.currentMileage ? (
            <TouchableOpacity onPress={() => setShowMileageModal(true)}>
              <Text style={styles.mileage}>
                {vehicle.status.currentMileage.toLocaleString()} miles
              </Text>
              <Text style={styles.mileageHint}>Tap to update</Text>
            </TouchableOpacity>
          ) : (
            <TouchableOpacity
              style={styles.addMileageButton}
              onPress={() => setShowMileageModal(true)}
            >
              <Ionicons name="speedometer-outline" size={16} color={colors.haven.purple[500]} />
              <Text style={styles.addMileageText}>Add Mileage</Text>
            </TouchableOpacity>
          )}
        </Card>

        {/* Registration */}
        <Card style={styles.section}>
          <SectionHeader
            title="REGISTRATION"
            action="Edit"
            onAction={() => setShowRegistrationModal(true)}
          />
          {hasRegistrationData || vehicle.licensePlate || vehicle.vin ? (
            <>
              <InfoRow
                icon="card-outline"
                label="License Plate"
                value={vehicle.registration?.licensePlate || vehicle.licensePlate}
                mono
              />
              <InfoRow
                icon="document-text-outline"
                label="VIN"
                value={vehicle.vin}
                mono
              />
              <InfoRow
                icon="flag-outline"
                label="State"
                value={vehicle.registration?.state}
              />
              {(vehicle.registration?.expiresAt || vehicle.registrationExpiry) && (
                <View style={styles.expiryRow}>
                  <View style={styles.expiryInfo}>
                    <Ionicons name="calendar-outline" size={18} color={colors.text.tertiary} />
                    <View style={styles.expiryContent}>
                      <Text style={styles.expiryLabel}>Expires</Text>
                      <Text
                        style={[
                          styles.expiryDate,
                          isExpired(vehicle.registration?.expiresAt || vehicle.registrationExpiry) && styles.expiredText,
                        ]}
                      >
                        {formatDate(vehicle.registration?.expiresAt || vehicle.registrationExpiry)}
                      </Text>
                    </View>
                  </View>
                  {isExpired(vehicle.registration?.expiresAt || vehicle.registrationExpiry) ? (
                    <Badge label="Expired" variant="error" />
                  ) : isExpiringSoon(vehicle.registration?.expiresAt || vehicle.registrationExpiry) ? (
                    <Badge label="Soon" variant="warning" />
                  ) : (
                    <Badge label="Valid" variant="success" />
                  )}
                </View>
              )}
              {vehicle.registrationDocUrl && (
                <TouchableOpacity style={styles.documentButton}>
                  <Ionicons name="document-attach-outline" size={18} color={colors.haven.purple[500]} />
                  <Text style={styles.documentButtonText}>View Registration Document</Text>
                </TouchableOpacity>
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add registration details"
              onPress={() => setShowRegistrationModal(true)}
            />
          )}
        </Card>

        {/* Insurance */}
        <Card style={styles.section}>
          <SectionHeader
            title="INSURANCE"
            action="Edit"
            onAction={() => setShowInsuranceModal(true)}
          />
          {hasInsuranceData || vehicle.insuranceExpiry || vehicle.insuranceProvider ? (
            <>
              <InfoRow
                icon="shield-checkmark-outline"
                label="Provider"
                value={vehicle.insurance?.provider || vehicle.insuranceProvider}
              />
              <InfoRow
                icon="document-outline"
                label="Policy #"
                value={vehicle.insurance?.policyNumber || vehicle.insurancePolicyNum}
                mono
              />
              {(vehicle.insurance?.expiresAt || vehicle.insuranceExpiry) && (
                <View style={styles.expiryRow}>
                  <View style={styles.expiryInfo}>
                    <Ionicons name="calendar-outline" size={18} color={colors.text.tertiary} />
                    <View style={styles.expiryContent}>
                      <Text style={styles.expiryLabel}>Expires</Text>
                      <Text
                        style={[
                          styles.expiryDate,
                          isExpired(vehicle.insurance?.expiresAt || vehicle.insuranceExpiry) && styles.expiredText,
                        ]}
                      >
                        {formatDate(vehicle.insurance?.expiresAt || vehicle.insuranceExpiry)}
                      </Text>
                    </View>
                  </View>
                  {isExpired(vehicle.insurance?.expiresAt || vehicle.insuranceExpiry) ? (
                    <Badge label="Expired" variant="error" />
                  ) : isExpiringSoon(vehicle.insurance?.expiresAt || vehicle.insuranceExpiry) ? (
                    <Badge label="Soon" variant="warning" />
                  ) : (
                    <Badge label="Valid" variant="success" />
                  )}
                </View>
              )}
              {vehicle.insurance?.agentName && (
                <View style={styles.agentCard}>
                  <Ionicons name="person-outline" size={20} color={colors.haven.purple[600]} />
                  <View style={styles.agentInfo}>
                    <Text style={styles.agentName}>{vehicle.insurance.agentName}</Text>
                    {vehicle.insurance.agentPhone && (
                      <TouchableOpacity>
                        <Text style={styles.agentPhone}>{vehicle.insurance.agentPhone}</Text>
                      </TouchableOpacity>
                    )}
                  </View>
                </View>
              )}
              <InfoRow
                icon="cash-outline"
                label="Monthly Premium"
                value={formatCurrency(vehicle.insurance?.monthlyPremium)}
              />
              {vehicle.insuranceDocUrl && (
                <TouchableOpacity style={styles.documentButton}>
                  <Ionicons name="document-attach-outline" size={18} color={colors.haven.purple[500]} />
                  <Text style={styles.documentButtonText}>View Insurance Card</Text>
                </TouchableOpacity>
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add insurance details"
              onPress={() => setShowInsuranceModal(true)}
            />
          )}
        </Card>

        {/* AI-Powered Maintenance Due */}
        <Card style={styles.section}>
          <SectionHeader title="MAINTENANCE DUE" />
          {isLoadingMaintenance ? (
            <View style={styles.maintenanceLoadingContainer}>
              <Text style={styles.maintenanceLoadingText}>
                Researching maintenance schedule for your {vehicle.year} {vehicle.make} {vehicle.model}...
              </Text>
            </View>
          ) : maintenanceDue && maintenanceDue.items.length > 0 ? (
            <>
              {/* Show overdue and due soon items first */}
              {maintenanceDue.items
                .filter(item => item.status === 'overdue' || item.status === 'due_soon')
                .slice(0, 5)
                .map((item, index) => (
                  <View
                    key={`${item.type}-${index}`}
                    style={[
                      helperStyles.maintenanceAlert,
                      { borderLeftColor: item.status === 'overdue' ? colors.status.error : colors.status.warning }
                    ]}
                  >
                    <View style={helperStyles.maintenanceIcon}>
                      <Ionicons
                        name={getMaintenanceIcon(item.type)}
                        size={20}
                        color={item.status === 'overdue' ? colors.status.error : colors.status.warning}
                      />
                    </View>
                    <View style={helperStyles.maintenanceContent}>
                      <Text style={helperStyles.maintenanceLabel}>{item.name}</Text>
                      {item.lastServiceDate && (
                        <Text style={helperStyles.maintenanceDate}>
                          Last: {new Date(item.lastServiceDate).toLocaleDateString()}
                          {item.lastServiceMileage ? ` @ ${item.lastServiceMileage.toLocaleString()} mi` : ''}
                        </Text>
                      )}
                      <Text style={[
                        helperStyles.maintenanceDate,
                        { color: item.status === 'overdue' ? colors.status.error : colors.status.warning }
                      ]}>
                        {item.milesUntilDue < 0
                          ? `${Math.abs(item.milesUntilDue).toLocaleString()} miles overdue`
                          : `Due in ${item.milesUntilDue.toLocaleString()} miles`}
                      </Text>
                      <Text style={helperStyles.maintenanceInterval}>
                        Est. ${item.estimatedCostLow}-${item.estimatedCostHigh}
                      </Text>
                    </View>
                    <Badge
                      label={item.status === 'overdue' ? 'Overdue' : 'Due Soon'}
                      variant={item.status === 'overdue' ? 'error' : 'warning'}
                    />
                  </View>
                ))}
              {/* Show upcoming OK items (collapsed) */}
              {maintenanceDue.items.filter(item => item.status === 'ok').length > 0 && (
                <View style={styles.upcomingSection}>
                  <Text style={styles.upcomingLabel}>
                    {maintenanceDue.items.filter(item => item.status === 'ok').length} upcoming maintenance items
                  </Text>
                </View>
              )}
              {/* Recalls */}
              {maintenanceDue.recalls && maintenanceDue.recalls.length > 0 && (
                <View style={styles.recallsSection}>
                  <View style={styles.recallHeader}>
                    <Ionicons name="warning" size={18} color={colors.status.error} />
                    <Text style={styles.recallTitle}>Active Recalls ({maintenanceDue.recalls.length})</Text>
                  </View>
                  {maintenanceDue.recalls.map((recall, index) => (
                    <View key={`recall-${index}`} style={styles.recallItem}>
                      <Text style={styles.recallComponent}>{recall.component}</Text>
                      <Text style={styles.recallSummary}>{recall.summary}</Text>
                    </View>
                  ))}
                </View>
              )}
              {/* Tips */}
              {maintenanceDue.tips && maintenanceDue.tips.length > 0 && (
                <View style={styles.tipsSection}>
                  <Text style={styles.tipsLabel}>Tips for your {vehicle.make}</Text>
                  {maintenanceDue.tips.slice(0, 2).map((tip, index) => (
                    <Text key={`tip-${index}`} style={styles.tipText}>• {tip}</Text>
                  ))}
                </View>
              )}
            </>
          ) : hasMaintenanceData ? (
            <>
              {vehicle.maintenance?.lastOilChange && (
                <MaintenanceAlert
                  type="oil"
                  lastService={vehicle.maintenance.lastOilChange}
                  nextDue={vehicle.maintenance.nextOilChangeDue}
                  interval={vehicle.maintenance.oilChangeInterval
                    ? `Every ${vehicle.maintenance.oilChangeInterval.toLocaleString()} miles`
                    : undefined}
                  status={getMaintenanceStatus(vehicle.maintenance.nextOilChangeDue)}
                />
              )}
            </>
          ) : (
            <View style={styles.noMaintenanceContainer}>
              <Ionicons name="speedometer-outline" size={32} color={colors.text.tertiary} />
              <Text style={styles.noMaintenanceText}>
                Add your current mileage so Alfred can research manufacturer-recommended maintenance intervals for your vehicle.
              </Text>
              <TouchableOpacity
                style={styles.addMileagePromptButton}
                onPress={() => setShowMileageModal(true)}
              >
                <Ionicons name="add-circle-outline" size={18} color={colors.haven.purple[500]} />
                <Text style={styles.addMileagePromptText}>Update Mileage</Text>
              </TouchableOpacity>
            </View>
          )}
        </Card>

        {/* Service History */}
        <Card style={styles.section}>
          <SectionHeader
            title="SERVICE HISTORY"
            action="+ Add"
            onAction={() => setShowAddServiceModal(true)}
          />
          {vehicle.serviceHistory && vehicle.serviceHistory.length > 0 ? (
            <>
              {vehicle.serviceHistory.slice(0, 5).map((service) => {
                const typeInfo = getServiceTypeInfo(service.type);
                return (
                  <TouchableOpacity key={service.id} style={styles.serviceRow}>
                    <View style={styles.serviceIcon}>
                      <Ionicons name={typeInfo.icon} size={18} color={colors.haven.purple[600]} />
                    </View>
                    <View style={styles.serviceContent}>
                      <Text style={styles.serviceType}>{service.description || typeInfo.label}</Text>
                      <View style={styles.serviceMeta}>
                        <Text style={styles.serviceDate}>
                          {new Date(service.date).toLocaleDateString()}
                        </Text>
                        {service.mileage && (
                          <Text style={styles.serviceMileage}>
                            {service.mileage.toLocaleString()} mi
                          </Text>
                        )}
                      </View>
                    </View>
                    {service.cost && (
                      <Text style={styles.serviceCost}>${service.cost.toLocaleString()}</Text>
                    )}
                  </TouchableOpacity>
                );
              })}
              {vehicle.serviceHistory.length > 5 && (
                <TouchableOpacity style={styles.seeAllButton}>
                  <Text style={styles.seeAllText}>
                    See all {vehicle.serviceHistory.length} records
                  </Text>
                  <Ionicons name="chevron-forward" size={16} color={colors.haven.purple[500]} />
                </TouchableOpacity>
              )}
            </>
          ) : (
            <EmptyPrompt
              text="Add service record"
              onPress={() => setShowAddServiceModal(true)}
            />
          )}
        </Card>

        {/* Financing (if applicable) */}
        {vehicle.financing?.lender && (
          <Card style={styles.section}>
            <SectionHeader
              title="FINANCING"
              action="Edit"
              onAction={() => router.push(`/(tabs)/family/vehicle/edit/${id}` as any)}
            />
            <InfoRow
              icon="business-outline"
              label="Lender"
              value={vehicle.financing.lender}
            />
            <InfoRow
              icon="cash-outline"
              label="Monthly Payment"
              value={formatCurrency(vehicle.financing.monthlyPayment)}
            />
            <InfoRow
              icon="calendar-outline"
              label="Payoff Date"
              value={formatDate(vehicle.financing.payoffDate)}
            />
            {vehicle.financing.remainingBalance && (
              <View style={styles.balanceRow}>
                <Text style={styles.balanceLabel}>Remaining Balance</Text>
                <Text style={styles.balanceValue}>
                  {formatCurrency(vehicle.financing.remainingBalance)}
                </Text>
              </View>
            )}
          </Card>
        )}

        {/* Service Providers */}
        <Card style={styles.section}>
          <SectionHeader
            title="SERVICE PROVIDERS"
            action="+ Add"
            onAction={() => setShowAddProviderModal(true)}
          />
          {vehicle.serviceProviders && vehicle.serviceProviders.length > 0 ? (
            <>
              {vehicle.serviceProviders.map((provider) => (
                <View key={provider.id} style={styles.providerRow}>
                  <View style={styles.providerIcon}>
                    <Ionicons name="construct-outline" size={18} color={colors.haven.purple[600]} />
                  </View>
                  <View style={styles.providerContent}>
                    <Text style={styles.providerName}>{provider.name}</Text>
                    <Text style={styles.providerType}>{provider.type}</Text>
                    {provider.phone && (
                      <TouchableOpacity>
                        <Text style={styles.providerPhone}>{provider.phone}</Text>
                      </TouchableOpacity>
                    )}
                  </View>
                  <TouchableOpacity
                    style={styles.removeProviderButton}
                    onPress={() => handleRemoveProvider(provider.id)}
                  >
                    <Ionicons name="close-circle" size={20} color={colors.text.tertiary} />
                  </TouchableOpacity>
                </View>
              ))}
            </>
          ) : (
            <EmptyPrompt
              text="Add service provider"
              onPress={() => setShowAddProviderModal(true)}
            />
          )}
        </Card>

        {/* Notes */}
        {vehicle.notes && (
          <Card style={styles.section}>
            <SectionHeader title="NOTES" />
            <Text style={styles.notes}>{vehicle.notes}</Text>
          </Card>
        )}

        {/* Delete Button */}
        <TouchableOpacity style={styles.deleteButton} onPress={handleDelete}>
          <Ionicons name="trash-outline" size={20} color={colors.status.error} />
          <Text style={styles.deleteButtonText}>Delete Vehicle</Text>
        </TouchableOpacity>
      </ScrollView>

      {/* Focused Edit Modals */}
      <EditRegistrationModal
        visible={showRegistrationModal}
        onClose={() => setShowRegistrationModal(false)}
        onSave={handleSaveRegistration}
        initialData={{
          licensePlate: vehicle.registration?.licensePlate || vehicle.licensePlate,
          vin: vehicle.vin,
          registrationState: vehicle.registration?.state || (vehicle as any).registrationState,
          registrationExpiry: vehicle.registration?.expiresAt || vehicle.registrationExpiry,
        }}
      />

      <EditInsuranceModal
        visible={showInsuranceModal}
        onClose={() => setShowInsuranceModal(false)}
        onSave={handleSaveInsurance}
        initialData={{
          insuranceProvider: vehicle.insurance?.provider || vehicle.insuranceProvider,
          insurancePolicyNum: vehicle.insurance?.policyNumber || vehicle.insurancePolicyNum,
          insuranceExpiry: vehicle.insurance?.expiresAt || vehicle.insuranceExpiry,
        }}
      />

      <AddServiceHistoryModal
        visible={showAddServiceModal}
        onClose={() => setShowAddServiceModal(false)}
        vehicleId={id!}
        householdId={householdInfo?.id || ''}
        onSuccess={() => {
          fetchVehicle();
          fetchMaintenanceDue();
        }}
      />

      <UpdateMileageModal
        visible={showMileageModal}
        onClose={() => setShowMileageModal(false)}
        onSave={handleSaveMileage}
        initialData={{
          currentMileage: vehicle.status?.currentMileage,
          lastOilChange: vehicle.maintenance?.lastOilChange,
          oilChangeMileage: vehicle.maintenance?.lastOilChangeMileage,
        }}
        vehicleName={vehicleName}
      />

      {/* Add Service Provider Modal */}
      <Modal
        visible={showAddProviderModal}
        animationType="slide"
        presentationStyle="pageSheet"
      >
        <SafeAreaView style={styles.modalContainer} edges={['top']}>
          <KeyboardAvoidingView
            behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
            style={styles.modalKeyboard}
          >
            <View style={styles.modalHeader}>
              <TouchableOpacity onPress={() => setShowAddProviderModal(false)} style={styles.modalCloseButton}>
                <Ionicons name="close" size={24} color={colors.text.primary} />
              </TouchableOpacity>
              <Text style={styles.modalTitle}>Add Service Provider</Text>
              <View style={styles.modalPlaceholder} />
            </View>

            <ScrollView style={styles.modalContent}>
              <View style={styles.inputGroup}>
                <Text style={styles.inputLabel}>Provider Name</Text>
                <TextInput
                  style={styles.textInput}
                  value={newProviderName}
                  onChangeText={setNewProviderName}
                  placeholder="e.g., Joe's Auto Shop"
                  placeholderTextColor={colors.text.tertiary}
                />
              </View>

              <View style={styles.inputGroup}>
                <Text style={styles.inputLabel}>Type</Text>
                <ScrollView horizontal showsHorizontalScrollIndicator={false}>
                  {['mechanic', 'body_shop', 'dealer', 'tire_shop', 'detailing', 'other'].map((type) => (
                    <TouchableOpacity
                      key={type}
                      style={[styles.typeChip, newProviderType === type && styles.typeChipActive]}
                      onPress={() => setNewProviderType(type)}
                    >
                      <Text style={[styles.typeChipText, newProviderType === type && styles.typeChipTextActive]}>
                        {type.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase())}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>

              <View style={styles.inputGroup}>
                <Text style={styles.inputLabel}>Phone (optional)</Text>
                <TextInput
                  style={styles.textInput}
                  value={newProviderPhone}
                  onChangeText={setNewProviderPhone}
                  placeholder="(555) 123-4567"
                  placeholderTextColor={colors.text.tertiary}
                  keyboardType="phone-pad"
                />
              </View>
            </ScrollView>

            <View style={styles.modalFooter}>
              <Button
                title="Cancel"
                variant="outline"
                onPress={() => setShowAddProviderModal(false)}
                style={styles.modalCancelButton}
              />
              <Button
                title="Add Provider"
                onPress={handleAddServiceProvider}
                style={styles.modalSaveButton}
              />
            </View>
          </KeyboardAvoidingView>
        </SafeAreaView>
      </Modal>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background.secondary,
  },
  scrollContent: {
    padding: spacing[4],
    paddingBottom: spacing[8],
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: spacing[6],
  },
  errorTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
    marginTop: spacing[4],
  },
  errorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    marginTop: spacing[2],
  },
  retryButton: {
    marginTop: spacing[4],
    paddingHorizontal: spacing[6],
    paddingVertical: spacing[3],
    backgroundColor: colors.haven.purple[500],
    borderRadius: borderRadius.lg,
  },
  retryText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.white,
  },
  // Hero Card
  heroCard: {
    alignItems: 'center',
    padding: spacing[6],
    marginBottom: spacing[4],
  },
  vehicleImagePlaceholder: {
    width: 120,
    height: 120,
    borderRadius: borderRadius.xl,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing[4],
  },
  vehicleName: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
    textAlign: 'center',
    marginBottom: spacing[1],
  },
  nickname: {
    fontSize: typography.fontSizes.base,
    color: colors.text.secondary,
    fontStyle: 'italic',
    marginBottom: spacing[2],
  },
  colorBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[1],
    backgroundColor: colors.background.secondary,
    borderRadius: borderRadius.full,
    marginTop: spacing[2],
  },
  colorDot: {
    width: 12,
    height: 12,
    borderRadius: 6,
    borderWidth: 1,
    borderColor: colors.border.light,
  },
  colorText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  mileage: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    marginTop: spacing[2],
    textAlign: 'center',
  },
  mileageHint: {
    fontSize: typography.fontSizes.xs,
    color: colors.haven.purple[500],
    textAlign: 'center',
    marginTop: 2,
  },
  addMileageButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
    marginTop: spacing[3],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.full,
  },
  addMileageText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  // Sections
  section: {
    padding: spacing[4],
    marginBottom: spacing[4],
  },
  // Expiry rows
  expiryRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[2],
    marginTop: spacing[1],
  },
  expiryInfo: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: spacing[3],
    flex: 1,
  },
  expiryContent: {
    flex: 1,
  },
  expiryLabel: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    marginBottom: 2,
  },
  expiryDate: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  expiredText: {
    color: colors.status.error,
  },
  // Agent card
  agentCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[2],
  },
  agentInfo: {
    flex: 1,
  },
  agentName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  agentPhone: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
  // Maintenance
  noMaintenanceContainer: {
    paddingVertical: spacing[4],
    alignItems: 'center',
  },
  noMaintenanceText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textAlign: 'center',
    lineHeight: 20,
    marginTop: spacing[2],
    marginBottom: spacing[3],
  },
  addMileagePromptButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[2],
    paddingHorizontal: spacing[4],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
  },
  addMileagePromptText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  // Service history
  serviceRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  serviceIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  serviceContent: {
    flex: 1,
  },
  serviceType: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  serviceMeta: {
    flexDirection: 'row',
    gap: spacing[2],
    marginTop: 2,
  },
  serviceDate: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  serviceMileage: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
  },
  serviceCost: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  seeAllButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[1],
    paddingVertical: spacing[3],
    marginTop: spacing[2],
  },
  seeAllText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  // Financing balance
  balanceRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
  },
  balanceLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  balanceValue: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.bold,
    color: colors.text.primary,
  },
  // Notes
  notes: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    lineHeight: 22,
  },
  // Delete button
  deleteButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: spacing[2],
    paddingVertical: spacing[4],
    marginTop: spacing[4],
  },
  deleteButtonText: {
    fontSize: typography.fontSizes.base,
    color: colors.status.error,
    fontWeight: typography.fontWeights.medium,
  },
  // Document buttons
  documentButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.haven.purple[50],
    borderRadius: borderRadius.lg,
    marginTop: spacing[3],
  },
  documentButtonText: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.haven.purple[500],
  },
  // Service Providers
  providerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[3],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  providerIcon: {
    width: 36,
    height: 36,
    borderRadius: borderRadius.full,
    backgroundColor: colors.haven.purple[50],
    alignItems: 'center',
    justifyContent: 'center',
  },
  providerContent: {
    flex: 1,
  },
  providerName: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  providerType: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.tertiary,
    textTransform: 'capitalize',
    marginTop: 2,
  },
  providerPhone: {
    fontSize: typography.fontSizes.sm,
    color: colors.haven.purple[500],
    marginTop: 2,
  },
  removeProviderButton: {
    padding: spacing[2],
  },
  // Modal styles
  modalContainer: {
    flex: 1,
    backgroundColor: colors.background.primary,
  },
  modalKeyboard: {
    flex: 1,
  },
  modalHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    borderBottomWidth: 1,
    borderBottomColor: colors.border.light,
  },
  modalCloseButton: {
    padding: spacing[2],
    marginLeft: -spacing[2],
  },
  modalTitle: {
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.primary,
  },
  modalPlaceholder: {
    width: 40,
  },
  modalContent: {
    flex: 1,
    padding: spacing[4],
  },
  modalFooter: {
    flexDirection: 'row',
    padding: spacing[4],
    backgroundColor: colors.white,
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
    gap: spacing[3],
  },
  modalCancelButton: {
    flex: 1,
  },
  modalSaveButton: {
    flex: 1,
  },
  // Form inputs
  inputGroup: {
    marginBottom: spacing[4],
  },
  inputLabel: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
    marginBottom: spacing[2],
  },
  textInput: {
    backgroundColor: colors.gray[50],
    borderWidth: 1,
    borderColor: colors.border.default,
    borderRadius: borderRadius.lg,
    paddingHorizontal: spacing[4],
    paddingVertical: spacing[3],
    fontSize: typography.fontSizes.base,
    color: colors.text.primary,
  },
  typeChip: {
    paddingHorizontal: spacing[3],
    paddingVertical: spacing[2],
    borderRadius: borderRadius.full,
    backgroundColor: colors.gray[100],
    marginRight: spacing[2],
  },
  typeChipActive: {
    backgroundColor: colors.haven.purple[500],
  },
  typeChipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
  },
  typeChipTextActive: {
    color: colors.white,
    fontWeight: typography.fontWeights.medium,
  },
  // AI Maintenance Intelligence
  maintenanceLoadingContainer: {
    paddingVertical: spacing[4],
    alignItems: 'center',
  },
  maintenanceLoadingText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    textAlign: 'center',
    fontStyle: 'italic',
  },
  upcomingSection: {
    paddingVertical: spacing[3],
    paddingHorizontal: spacing[3],
    backgroundColor: colors.gray[50],
    borderRadius: borderRadius.md,
    marginTop: spacing[2],
  },
  upcomingLabel: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.tertiary,
    textAlign: 'center',
  },
  recallsSection: {
    marginTop: spacing[4],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  recallHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: spacing[2],
    marginBottom: spacing[2],
  },
  recallTitle: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.semibold,
    color: colors.status.error,
  },
  recallItem: {
    paddingVertical: spacing[2],
    paddingLeft: spacing[3],
    borderLeftWidth: 2,
    borderLeftColor: colors.status.error,
    marginBottom: spacing[2],
  },
  recallComponent: {
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.fontWeights.medium,
    color: colors.text.primary,
  },
  recallSummary: {
    fontSize: typography.fontSizes.xs,
    color: colors.text.secondary,
    marginTop: 2,
  },
  tipsSection: {
    marginTop: spacing[4],
    paddingTop: spacing[3],
    borderTopWidth: 1,
    borderTopColor: colors.border.light,
  },
  tipsLabel: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.fontWeights.semibold,
    color: colors.text.tertiary,
    textTransform: 'uppercase',
    marginBottom: spacing[2],
  },
  tipText: {
    fontSize: typography.fontSizes.sm,
    color: colors.text.secondary,
    marginBottom: spacing[1],
    lineHeight: 20,
  },
});
